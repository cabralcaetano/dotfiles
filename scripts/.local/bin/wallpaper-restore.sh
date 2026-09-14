#!/usr/bin/env bash
# Reaplica no boot o último wallpaper escolhido (persistido por wallpaper.sh,
# wallpaper-toggle.sh e theme-set.sh em XDG_STATE_HOME). Sem estado ou com
# arquivo inválido, cai no wallpaper padrão do setup.
set -euo pipefail
STATE_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/wallpaper-picker/current-wallpaper"
WALLPAPER="$(cat "$STATE_FILE" 2>/dev/null || true)"
[[ -n ${WALLPAPER:-} && -f $WALLPAPER ]] || WALLPAPER="$HOME/.config/wallpapers/wallpaper_5.jpg"
awww img "$WALLPAPER" \
    --transition-type fade \
    --transition-duration 1.5 \
    --transition-fps 60
