#!/usr/bin/env bash
# _dotfiles-lib.sh — funções e constantes compartilhadas entre bootstrap.sh,
# dotfiles-doctor.sh e dotfiles-update.sh. Não é executável standalone.

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/Projects/dotfiles}"

# Pacotes stow automáticos (cada item é um diretório do repo aplicado no $HOME).
# Itens system-wide/manuais ficam fora daqui: desktop-apps, sddm, greetd, xkb, legacy,
# reflector (/etc/xdg/reflector, root), udev (regra deprecada, não instalada),
# obsidian (perfil portátil sincronizado manualmente por vault, sem path fixo em $HOME),
# system (espelha /etc — earlyoom, sysctl.d, zram-generator; instalado via
# `install -Dm644` com root, ver system/README.md).
STOW_PKGS=(hypr waybar quickshell swaync fuzzel scripts ghostty kitty btop zsh starship gtk-3 gtk-4 qt6ct wlogout nvim tmux networkmanager-dmenu neofetch claude xdg-desktop-portal)

log()  { printf '\033[1;34m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m✓\033[0m %s\n' "$*"; }
err()  { printf '\033[1;31m✗\033[0m %s\n' "$*"; }
die()  { warn "$*"; exit 1; }
