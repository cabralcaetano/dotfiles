#!/usr/bin/env bash
set -euo pipefail

mkdir -p ~/Imagens/Screenshots

case "${1:-}" in
  full)
    FILE=~/Imagens/Screenshots/$(date +%Y%m%d_%H%M%S).png
    grim "$FILE" && wl-copy --type image/png < "$FILE"
    notify-send "Screenshot" "Tela completa salva"
    ;;
  area)
    grim -g "$(slurp)" ~/Imagens/Screenshots/$(date +%Y%m%d_%H%M%S).png
    notify-send "Screenshot" "Área selecionada salva"
    ;;
  clipboard)
    selection=$(slurp) && grim -g "$selection" - | wl-copy --type image/png && notify-send "Screenshot" "Copiado para o clipboard"
    ;;
esac
