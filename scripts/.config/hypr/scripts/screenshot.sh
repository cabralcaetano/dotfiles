#!/usr/bin/env bash
set -euo pipefail

mkdir -p ~/Pictures/Screenshots

case "${1:-}" in
  full)
    FILE=~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png
    grim "$FILE" && wl-copy --type image/png < "$FILE"
    notify-send "Screenshot" "Tela completa salva"
    ;;
  area)
    FILE=~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png
    grim -g "$(slurp)" "$FILE" && wl-copy --type image/png < "$FILE"
    notify-send "Screenshot" "Área selecionada salva"
    ;;
  clipboard)
    selection=$(slurp) && grim -g "$selection" - | wl-copy --type image/png && notify-send "Screenshot" "Copiado para o clipboard"
    ;;
esac
