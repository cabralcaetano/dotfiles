#!/usr/bin/env bash
set -euo pipefail
WALLPAPER="${1:-$HOME/.config/wallpapers/wallpaper_5.jpg}"
WALLPAPER="$(realpath -m "$WALLPAPER")"
awww img "$WALLPAPER" \
    --transition-type fade \
    --transition-duration 1.5 \
    --transition-fps 60

# Persiste a escolha para wallpaper-restore.sh reaplicar no próximo boot.
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/wallpaper-picker"
mkdir -p "$STATE_DIR"
printf '%s\n' "$WALLPAPER" >"$STATE_DIR/current-wallpaper"
