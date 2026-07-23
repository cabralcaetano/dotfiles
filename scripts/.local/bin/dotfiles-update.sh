#!/usr/bin/env bash
# dotfiles-update.sh — atualização segura do repo dotfiles.
# Fluxo: git pull --ff-only -> backup timestamped dos targets -> stow --simulate
#        -> confirmação -> stow --restow -> dotfiles-doctor.sh
# Nunca usa git reset --hard nem curl | bash.
# Uso: dotfiles-update.sh [-y]   (-y pula a confirmação interativa)
set -euo pipefail

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$LIB_DIR/_dotfiles-lib.sh"

BACKUP_ROOT="$HOME/.dotfiles-backups"
BACKUP_CONFIG_TARGETS=(hypr waybar swaync ghostty tmux)
BACKUP_HOME_FILES=(.zshrc)
AUTO_YES=0

[[ "${1:-}" == "-y" ]] && AUTO_YES=1

[[ -d "$DOTFILES_DIR/.git" ]] || die "Repo dotfiles não encontrado em $DOTFILES_DIR"
command -v stow >/dev/null || die "stow não encontrado"
command -v git >/dev/null || die "git não encontrado"

log "Repo: $DOTFILES_DIR"

log "git pull --ff-only…"
if ! git -C "$DOTFILES_DIR" pull --ff-only; then
  die "pull --ff-only falhou (histórico divergente) — resolva manualmente, sem reset --hard automático."
fi

ts="$(date +%Y%m%d-%H%M%S)"
backup_dir="$BACKUP_ROOT/$ts"
mkdir -p "$backup_dir"
log "Fazendo backup dos targets em $backup_dir…"
for t in "${BACKUP_CONFIG_TARGETS[@]}"; do
  src="$HOME/.config/$t"
  if [[ -e "$src" ]]; then
    cp -aL "$src" "$backup_dir/$t"
  fi
done
for f in "${BACKUP_HOME_FILES[@]}"; do
  src="$HOME/$f"
  if [[ -e "$src" ]]; then
    cp -aL "$src" "$backup_dir/$f"
  fi
done
ok "Backup salvo em $backup_dir"

log "stow --simulate --restow…"
sim_out=""
if ! sim_out="$(stow --simulate --restow --dir="$DOTFILES_DIR" --target="$HOME" "${STOW_PKGS[@]}" 2>&1)"; then
  printf '%s\n' "$sim_out"
  die "Simulação de stow encontrou conflitos — resolva manualmente antes de aplicar."
fi
[[ -n "$sim_out" ]] && printf '%s\n' "$sim_out"

if [[ $AUTO_YES -eq 0 ]]; then
  read -r -p "Aplicar stow --restow agora? [y/N] " reply
  [[ "$reply" =~ ^[Yy]$ ]] || die "Cancelado — pull e backup já feitos, symlinks não foram tocados."
fi

log "Aplicando stow --restow…"
stow --restow --dir="$DOTFILES_DIR" --target="$HOME" "${STOW_PKGS[@]}"
ok "Symlinks aplicados"

log "Rodando dotfiles-doctor.sh…"
if ! "$LIB_DIR/dotfiles-doctor.sh"; then
  warn "Doctor reportou problemas — revise a saída acima."
fi

log "Update concluído. Backup em $backup_dir"
