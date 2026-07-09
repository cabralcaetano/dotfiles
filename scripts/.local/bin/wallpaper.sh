#!/usr/bin/env bash
set -euo pipefail
WALLPAPER="${1:-$HOME/.config/wallpapers/wallpaper_5.jpg}"
awww img "$WALLPAPER" \
    --transition-type fade \
    --transition-duration 1.5 \
    --transition-fps 60
