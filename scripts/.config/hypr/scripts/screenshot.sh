#!/bin/bash

case $1 in
  full)
    grim ~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png
    notify-send "Screenshot" "Tela completa salva"
    ;;
  area)
    grim -g "$(slurp)" ~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png
    notify-send "Screenshot" "Área selecionada salva"
    ;;
  clipboard)
    grim -g "$(slurp)" - | wl-copy
    notify-send "Screenshot" "Copiado para o clipboard"
    ;;
esac
