#!/usr/bin/env bash
# dotfiles-doctor.sh — checagem read-only de saúde do ambiente dotfiles.
# Não aplica nenhuma mudança; só reporta. Uso: dotfiles-doctor.sh
set -uo pipefail

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$LIB_DIR/_dotfiles-lib.sh"

FAILS=0
WARNS=0

warnc() { warn "$*"; WARNS=$((WARNS + 1)); }
failc() { err "$*"; FAILS=$((FAILS + 1)); }

check_symlinks() {
  log "Verificando symlinks Stow (${STOW_PKGS[*]})…"
  if ! command -v stow >/dev/null; then
    failc "stow não encontrado"
    return
  fi
  if [[ ! -d "$DOTFILES_DIR" ]]; then
    failc "Repo dotfiles não encontrado em $DOTFILES_DIR"
    return
  fi
  local out
  if out="$(stow --simulate --restow --dir="$DOTFILES_DIR" --target="$HOME" "${STOW_PKGS[@]}" 2>&1)"; then
    ok "Symlinks Stow consistentes"
  else
    failc "Conflitos de symlink detectados:"
    printf '%s\n' "$out" | sed 's/^/    /'
  fi
}

check_commands() {
  log "Verificando comandos essenciais…"
  local cmds=(git stow zsh starship eza bat fzf rg zoxide yazi lazygit btop jq podman qs)
  local missing=()
  local c
  for c in "${cmds[@]}"; do
    command -v "$c" >/dev/null || missing+=("$c")
  done
  if [[ ${#missing[@]} -eq 0 ]]; then
    ok "Todos os comandos essenciais presentes"
  else
    warnc "Comandos ausentes: ${missing[*]}"
  fi

  if command -v yay >/dev/null; then
    ok "AUR helper (yay) presente"
  else
    warnc "Nenhum AUR helper (yay) encontrado"
  fi
}

check_flatpak() {
  log "Verificando remote Flatpak…"
  if ! command -v flatpak >/dev/null; then
    warnc "flatpak não instalado"
    return
  fi
  if flatpak remote-list 2>/dev/null | grep -q '^flathub'; then
    ok "Remote flathub configurado"
  else
    warnc "Remote flathub ausente"
  fi
}

check_services() {
  log "Verificando serviços systemd…"
  # brave-duck roda como serviço --user; battery-conservation roda system-wide.
  local user_services=(brave-duck.service)
  local system_services=(battery-conservation.service)
  local s

  for s in "${user_services[@]}"; do
    if systemctl --user list-unit-files "$s" --no-legend 2>/dev/null | grep -q "$s"; then
      local enabled active
      enabled="$(systemctl --user is-enabled "$s" 2>/dev/null || echo unknown)"
      active="$(systemctl --user is-active "$s" 2>/dev/null || echo unknown)"
      if [[ "$active" == "active" ]]; then
        ok "$s (user): enabled=$enabled active=$active"
      else
        warnc "$s (user): enabled=$enabled active=$active"
      fi
    else
      warnc "$s (user) não instalado"
    fi
  done

  for s in "${system_services[@]}"; do
    if systemctl list-unit-files "$s" --no-legend 2>/dev/null | grep -q "$s"; then
      local enabled active
      enabled="$(systemctl is-enabled "$s" 2>/dev/null || echo unknown)"
      active="$(systemctl is-active "$s" 2>/dev/null || echo unknown)"
      if [[ "$active" == "active" ]]; then
        ok "$s: enabled=$enabled active=$active"
      else
        warnc "$s: enabled=$enabled active=$active"
      fi
    else
      warnc "$s não instalado"
    fi
  done
}

check_module_drift() {
  log "Verificando módulos fora de STOW_PKGS…"
  [[ -d "$DOTFILES_DIR" ]] || return
  local declared=" ${STOW_PKGS[*]} "
  local known_manual=" desktop-apps sddm greetd xkb legacy docs packages ducking "
  local drift=()
  local entry name
  for entry in "$DOTFILES_DIR"/*; do
    [[ -d "$entry" ]] || continue
    name="$(basename "$entry")"
    [[ "$declared" == *" $name "* ]] && continue
    [[ "$known_manual" == *" $name "* ]] && continue
    drift+=("$name")
  done
  if [[ ${#drift[@]} -eq 0 ]]; then
    ok "Nenhum módulo novo fora de STOW_PKGS/lista manual"
  else
    warnc "Diretórios não declarados em STOW_PKGS nem na lista manual: ${drift[*]}"
  fi
}

check_symlinks
check_commands
check_flatpak
check_services
check_module_drift

echo
if [[ $FAILS -gt 0 ]]; then
  printf '\033[1;31mDoctor: %d falha(s), %d aviso(s)\033[0m\n' "$FAILS" "$WARNS"
  exit 1
elif [[ $WARNS -gt 0 ]]; then
  printf '\033[1;33mDoctor: %d aviso(s)\033[0m\n' "$WARNS"
  exit 0
else
  printf '\033[1;32mDoctor: tudo certo\033[0m\n'
  exit 0
fi
