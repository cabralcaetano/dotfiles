#!/usr/bin/env bash
# bootstrap.sh — instalação idempotente/tolerante do ambiente (Arch Linux atual · Fedora legado · Hyprland)
# Uso: cd ~/Projects/dotfiles && bash bootstrap.sh
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES_DIR"

# Pacotes stow automáticos (cada item é um diretório do repo aplicado no $HOME).
# Itens system-wide/manuais ficam fora daqui: desktop-apps, sddm, greetd, xkb, legacy.
STOW_PKGS=(hypr waybar quickshell swaync fuzzel scripts ghostty kitty btop zsh starship gtk-3 gtk-4 wlogout nvim tmux)

log()  { printf '\033[1;34m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*"; }
die()  { warn "$*"; exit 1; }

manifest_args() {
  grep -Ev '^[[:space:]]*(#|$)' "$1"
}

detect_distro() {
  local id="" id_like=""

  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    id="${ID:-}"
    id_like="${ID_LIKE:-}"
  fi

  case " $id $id_like " in
    *" arch "*)   printf 'arch\n' ;;
    *" fedora "*) printf 'fedora\n' ;;
    *)            printf 'unknown\n' ;;
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
  local distro=$1

  case "$distro" in
    arch)
      command -v pacman >/dev/null || die "Distro detectada como Arch, mas pacman não foi encontrado."
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
      ;;
    fedora)
      command -v dnf >/dev/null || die "Distro detectada como Fedora, mas dnf não foi encontrado."
      warn "Fedora é caminho legado deste repo; Arch é o alvo atual."
      log "Instalando pacotes dnf…"
      # shellcheck disable=SC2046
      sudo dnf install -y $(manifest_args packages/dnf.txt)
      ;;
    *)
      warn "Distro desconhecida em /etc/os-release — pulando pacotes do sistema."
      warn "Instale manualmente um dos manifestos em packages/ antes de seguir."
      ;;
  esac
}

distro="$(detect_distro)"
log "Distro detectada: $distro"

# Se stow já existir, falha cedo antes de instalar pacotes/plugins.
stow_preflight

# --- 1. Pacotes do sistema ---
install_system_packages "$distro"

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

# --- 3.1 TPM (tmux plugin manager) ---
log "Instalando TPM em ~/.tmux/plugins/tpm…"
tpm_dest="$HOME/.tmux/plugins/tpm"
if [[ -d "$tpm_dest/.git" ]]; then
  git -C "$tpm_dest" pull --ff-only >/dev/null 2>&1 || warn "Falha ao atualizar TPM"
else
  git clone --depth 1 https://github.com/tmux-plugins/tpm "$tpm_dest"
fi
warn "Plugins do tmux (tmux-power) só instalam na primeira vez que o tmux ler o tmux.conf — se não aparecerem, rode prefix + I dentro de uma sessão tmux."

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

# --- 6. Snapshots Btrfs (Arch — snapper + grub-btrfs, ver docs/arch-migration.md §1.2) ---
if [[ "$distro" == "arch" ]] && command -v snapper >/dev/null; then
  if ! sudo snapper list-configs 2>/dev/null | grep -q '^root'; then
    warn "snapper instalado mas sem config \"root\" — não configurado automaticamente."
    warn "Ver docs/arch-migration.md §1.2 pros comandos de setup."
  fi
fi

# --- 7. Shell padrão ---
if [[ "${SHELL:-}" != *zsh ]]; then
  warn "Shell atual não é zsh. Para trocar: chsh -s \"\$(command -v zsh)\""
fi

log "Bootstrap concluído. Reinicie a sessão Hyprland para aplicar tudo."
