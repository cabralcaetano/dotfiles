#!/usr/bin/env bash
set -euo pipefail
WALLPAPER_DIR="$HOME/.config/wallpapers"

mapfile -t WALLPAPERS < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) | sort)

(( ${#WALLPAPERS[@]} > 0 )) || { notify-send "Wallpaper" "Nenhum wallpaper encontrado em $WALLPAPER_DIR"; exit 1; }

CURRENT=$(awww query | grep -o 'image: .*' | sed 's/image: //' || true)

NEXT="${WALLPAPERS[0]}"
for i in "${!WALLPAPERS[@]}"; do
    if [[ "${WALLPAPERS[$i]}" == "$CURRENT" ]]; then
        NEXT="${WALLPAPERS[$(( (i + 1) % ${#WALLPAPERS[@]} ))]}"
        break
    fi
done

awww img "$NEXT" --transition-type fade --transition-duration 1.5 --transition-fps 60
