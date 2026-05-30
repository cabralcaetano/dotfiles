#!/bin/bash
WP1="$HOME/.config/wallpapers/wallpaper_1.jpg"
WP2="$HOME/.config/wallpapers/wallpaper_2.jpg"

CURRENT=$(swww query | grep -o 'image: .*' | sed 's/image: //')

if [[ "$CURRENT" == "$WP1" ]]; then
    swww img "$WP2" --transition-type fade --transition-duration 1.5 --transition-fps 60
else
    swww img "$WP1" --transition-type fade --transition-duration 1.5 --transition-fps 60
fi
