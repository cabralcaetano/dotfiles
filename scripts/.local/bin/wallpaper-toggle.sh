#!/usr/bin/env bash
set -euo pipefail
WP1="$HOME/.config/wallpapers/wallpaper_1.jpg"
WP2="$HOME/.config/wallpapers/wallpaper_2.jpg"
WP3="$HOME/.config/wallpapers/wallpaper_3.png"

CURRENT=$(swww query | grep -o 'image: .*' | sed 's/image: //' || true)

if [[ "$CURRENT" == "$WP1" ]]; then
    swww img "$WP2" --transition-type fade --transition-duration 1.5 --transition-fps 60
elif [[ "$CURRENT" == "$WP2" ]]; then
    swww img "$WP3" --transition-type fade --transition-duration 1.5 --transition-fps 60
else
    swww img "$WP1" --transition-type fade --transition-duration 1.5 --transition-fps 60
fi
