#!/usr/bin/env bash
# bootstrap.sh — instalação idempotente do ambiente (Fedora 44 ou Arch Linux · Hyprland)
# Uso: cd ~/dotfiles && bash bootstrap.sh
#
# Detecta a distro (dnf vs pacman) e instala os pacotes correspondentes.
# Pode rodar quantas vezes quiser — só faz o que falta.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES_DIR"

# Pacotes stow a aplicar (cada um é um diretório no repo)
STOW_PKGS=(hypr waybar swaync fuzzel scripts ghostty kitty zsh starship gtk-3 gtk-4 wlogout hyprshell nvim)

log()  { printf '\033[1;34m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*"; }

# --- 1. Pacotes do sistema (dnf ou pacman, conforme a distro) ---
if command -v dnf >/dev/null; then
  log "Instalando pacotes dnf…"
  # shellcheck disable=SC2046
  sudo dnf install -y $(grep -v '^#' packages/dnf.txt | grep -v '^$')
elif command -v pacman >/dev/null; then
  log "Instalando pacotes pacman…"
  # shellcheck disable=SC2046
  sudo pacman -S --needed --noconfirm $(grep -v '^#' packages/pacman.txt | grep -v '^$')

  if command -v yay >/dev/null; then
    log "Instalando pacotes AUR…"
    # shellcheck disable=SC2046
    yay -S --needed --noconfirm $(grep -v '^#' packages/aur.txt | grep -v '^$')
  else
    warn "yay não encontrado — pulando pacotes AUR (packages/aur.txt)."
    warn "Instale um AUR helper primeiro: https://github.com/Jguer/yay"
  fi
else
  warn "Nem dnf nem pacman encontrados — pulando pacotes do sistema."
fi

# --- 2. Flatpaks ---
if command -v flatpak >/dev/null; then
  log "Garantindo remote flathub…"
  flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  log "Instalando apps Flatpak…"
  # shellcheck disable=SC2046
  flatpak install -y flathub $(grep -v '^#' packages/flatpak.txt | grep -v '^$') || \
    warn "Alguns Flatpaks falharam (IRPF antigos podem não existir mais no remote)."
else
  warn "flatpak não encontrado — pulando apps."
fi

# --- 3. Plugins Zsh (não versionados; clonados aqui) ---
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

# --- 4. Symlinks via stow ---
if command -v stow >/dev/null; then
  log "Aplicando symlinks com stow…"
  stow --restow --target="$HOME" "${STOW_PKGS[@]}"
else
  warn "stow não encontrado — instale-o e rode novamente."
fi

# --- 5. Crates cargo (opcional) ---
if command -v cargo >/dev/null; then
  log "Instalando crates do cargo…"
  while read -r crate; do
    [[ -z "$crate" || "$crate" == \#* ]] && continue
    command -v "$crate" >/dev/null || cargo install "$crate" || warn "cargo install $crate falhou"
  done < packages/cargo.txt
fi

# --- 6. Extensões do VS Code (opcional) ---
if command -v code >/dev/null; then
  log "Instalando extensões do VS Code…"
  grep -v '^#' packages/vscode-extensions.txt | grep -v '^$' | \
    xargs -L1 code --install-extension >/dev/null 2>&1 || warn "Algumas extensões falharam."
fi

# --- 7. Snapshots Btrfs (Arch — snapper + grub-btrfs, ver docs/arch-migration.md §1.2) ---
if command -v pacman >/dev/null && command -v snapper >/dev/null; then
  if ! sudo snapper list-configs 2>/dev/null | grep -q '^root'; then
    warn "snapper instalado mas sem config \"root\" — não configurado automaticamente."
    warn "Ver docs/arch-migration.md §1.2 pros comandos de setup."
  fi
fi

# --- 8. Shell padrão ---
if [[ "${SHELL:-}" != *zsh ]]; then
  warn "Shell atual não é zsh. Para trocar: chsh -s \"\$(command -v zsh)\""
fi

log "Bootstrap concluído. Reinicie a sessão Hyprland para aplicar tudo."
