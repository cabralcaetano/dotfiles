#!/bin/bash
WALLPAPER="${1:-$HOME/.config/wallpapers/wallpaper_2.jpg}"
swww img "$WALLPAPER" \
    --transition-type fade \
    --transition-duration 1.5 \
    --transition-fps 60
