#!/usr/bin/env bash
# bootstrap.sh — instalação idempotente/tolerante do ambiente (Arch Linux · Hyprland)
# Uso: cd ~/Projects/dotfiles && bash bootstrap.sh [--system]
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES_DIR"

# shellcheck disable=SC1091
source "$DOTFILES_DIR/scripts/.local/bin/_dotfiles-lib.sh"

APPLY_SYSTEM=0

usage() {
  cat <<'EOF'
Uso: bash bootstrap.sh [opções]

Instala pacotes, plugins e symlinks do ambiente em $HOME. Idempotente.

Opções:
  --system   Aplica também os arquivos de /etc versionados em system/
             (earlyoom, sysctl/zram, keyd) via sudo. Sem esta flag nada
             fora de $HOME é tocado e os comandos pendentes são apenas
             impressos no final.
  --help     Mostra esta ajuda e sai.

Só há suporte a Arch Linux; o setup Fedora está arquivado em docs/history/.
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --system) APPLY_SYSTEM=1 ;;
      --help|-h) usage; exit 0 ;;
      *) usage >&2; die "Opção desconhecida: $1" ;;
    esac
    shift
  done
}

manifest_args() {
  grep -Ev '^[[:space:]]*(#|$)' "$1"
}

require_arch() {
  local id="" id_like=""

  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    id="${ID:-}"
    id_like="${ID_LIKE:-}"
  fi

  case " $id $id_like " in
    *" arch "*) return 0 ;;
    *) die "Distro '${id:-desconhecida}' não suportada: suporte apenas a Arch; veja docs/history/ para o setup Fedora arquivado." ;;
  esac
}

stow_preflight() {
  if ! command -v stow >/dev/null; then
    warn "stow não encontrado — preflight de symlinks será pulado até os pacotes serem instalados."
    return 0
  fi

  log "Validando symlinks Stow: ${STOW_PKGS[*]}"
  stow --simulate --restow --target="$HOME" "${STOW_PKGS[@]}" >/dev/null
}

install_system_packages() {
  command -v pacman >/dev/null || die "Arch detectado, mas pacman não foi encontrado."
  log "Instalando pacotes pacman…"
  # shellcheck disable=SC2046
  sudo pacman -S --needed --noconfirm $(manifest_args packages/pacman.txt)

  if command -v yay >/dev/null; then
    warn "Instalando pacotes AUR com revisão interativa do yay."
    # shellcheck disable=SC2046
    yay -S --needed $(manifest_args packages/aur.txt)
  else
    warn "yay não encontrado — pulando pacotes AUR (packages/aur.txt)."
    warn "Instale um AUR helper primeiro: https://github.com/Jguer/yay"
  fi
}

# Arquivos de /etc versionados em system/ (ver system/README.md). Stow só opera
# dentro de $HOME, então estes vão com `install -Dm644` + sudo.
SYSTEM_INSTALLS=(
  "system/etc/default/earlyoom|/etc/default/earlyoom"
  "system/etc/sysctl.d/99-zram.conf|/etc/sysctl.d/99-zram.conf"
  "system/etc/systemd/zram-generator.conf|/etc/systemd/zram-generator.conf"
  "system/etc/keyd/default.conf|/etc/keyd/default.conf"
  "system/etc/keyd/f75.conf|/etc/keyd/f75.conf"
  "system/etc/nftables.conf|/etc/nftables.conf"
)

# Comandos que recarregam o que os arquivos acima mudaram.
SYSTEM_RELOADS=(
  "sysctl --system"
  "systemctl restart earlyoom"
  "systemctl daemon-reload"
  "systemctl restart systemd-zram-setup@zram0.service"
  "systemctl enable --now keyd"
  "keyd reload"
  "nft -f /etc/nftables.conf"
  "systemctl enable nftables"
)

print_system_commands() {
  local pair src dest cmd
  for pair in "${SYSTEM_INSTALLS[@]}"; do
    src="${pair%%|*}"; dest="${pair##*|}"
    printf '  sudo install -Dm644 %-42s %s\n' "$src" "$dest"
  done
  printf '\n'
  for cmd in "${SYSTEM_RELOADS[@]}"; do
    printf '  sudo %s\n' "$cmd"
  done
}

apply_system_files() {
  command -v sudo >/dev/null || die "--system exige sudo, que não foi encontrado."

  local pair src dest cmd
  log "Aplicando arquivos de /etc (system/)…"
  for pair in "${SYSTEM_INSTALLS[@]}"; do
    src="${pair%%|*}"; dest="${pair##*|}"
    [[ -f "$src" ]] || die "Arquivo ausente no repo: $src"
    sudo install -Dm644 "$src" "$dest"
    ok "$dest"
  done

  for cmd in "${SYSTEM_RELOADS[@]}"; do
    log "sudo $cmd"
    # shellcheck disable=SC2086
    sudo $cmd || warn "Falhou (siga manualmente): sudo $cmd"
  done
}

parse_args "$@"

require_arch
log "Distro detectada: arch"

# Se stow já existir, falha cedo antes de instalar pacotes/plugins.
stow_preflight

# --- 1. Pacotes do sistema ---
install_system_packages

# Se stow foi instalado na etapa anterior, valide de novo antes de tocar plugins/links.
stow_preflight

# --- 2. Flatpaks ---
if command -v flatpak >/dev/null; then
  log "Garantindo remote flathub…"
  flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  log "Instalando apps Flatpak…"
  # shellcheck disable=SC2046
  flatpak install -y flathub $(manifest_args packages/flatpak.txt) || \
    warn "Alguns Flatpaks falharam (IRPF antigos podem não existir mais no remote)."
else
  warn "flatpak não encontrado — pulando apps."
fi

# --- 3. Plugins Zsh (não versionados; clonados aqui) ---
if command -v git >/dev/null; then
  log "Instalando plugins Zsh em ~/.zsh…"
  mkdir -p "$HOME/.zsh"
  declare -A ZSH_PLUGINS=(
    [zsh-syntax-highlighting]="https://github.com/zsh-users/zsh-syntax-highlighting.git"
    [zsh-autosuggestions]="https://github.com/zsh-users/zsh-autosuggestions.git"
    [zsh-shift-select]="https://github.com/jirutka/zsh-shift-select.git"
  )
  for name in "${!ZSH_PLUGINS[@]}"; do
    dest="$HOME/.zsh/$name"
    if [[ -d "$dest/.git" ]]; then
      git -C "$dest" pull --ff-only >/dev/null 2>&1 || warn "Falha ao atualizar $name"
    else
      git clone --depth 1 "${ZSH_PLUGINS[$name]}" "$dest"
    fi
  done

  # --- 3.1 TPM (tmux plugin manager) ---
  log "Instalando TPM em ~/.tmux/plugins/tpm…"
  tpm_dest="$HOME/.tmux/plugins/tpm"
  if [[ -d "$tpm_dest/.git" ]]; then
    git -C "$tpm_dest" pull --ff-only >/dev/null 2>&1 || warn "Falha ao atualizar TPM"
  else
    git clone --depth 1 https://github.com/tmux-plugins/tpm "$tpm_dest"
  fi
  warn "Plugins do tmux (tmux-power) só instalam na primeira vez que o tmux ler o tmux.conf — se não aparecerem, rode prefix + I dentro de uma sessão tmux."
else
  warn "git não encontrado — pulando plugins Zsh e TPM."
fi

# --- 4. Symlinks via stow ---
if command -v stow >/dev/null; then
  log "Aplicando symlinks com stow…"
  stow --restow --target="$HOME" "${STOW_PKGS[@]}"
else
  warn "stow não encontrado — instale-o e rode novamente."
fi


# --- 5. Extensões do VS Code (opcional) ---
if command -v code >/dev/null; then
  log "Instalando extensões do VS Code…"
  manifest_args packages/vscode-extensions.txt | \
    xargs -L1 code --install-extension >/dev/null 2>&1 || warn "Algumas extensões falharam."
fi

# --- 6. Snapshots Btrfs (snapper + grub-btrfs, ver docs/arch-migration.md §1.2) ---
if command -v snapper >/dev/null; then
  if ! sudo snapper list-configs 2>/dev/null | grep -q '^root'; then
    warn "snapper instalado mas sem config \"root\" — não configurado automaticamente."
    warn "Ver docs/arch-migration.md §1.2 pros comandos de setup."
  fi
fi

# --- 7. Shell padrão ---
if [[ "${SHELL:-}" != *zsh ]]; then
  warn "Shell atual não é zsh. Para trocar: chsh -s \"\$(command -v zsh)\""
fi

# --- 8. Arquivos de /etc (opt-in via --system) ---
if [[ $APPLY_SYSTEM -eq 1 ]]; then
  apply_system_files
else
  echo
  warn "Ajustes de /etc não aplicados (rode com --system ou execute à mão, em $DOTFILES_DIR):"
  print_system_commands
fi

echo
log "Bootstrap concluído. Reinicie a sessão Hyprland para aplicar tudo."
