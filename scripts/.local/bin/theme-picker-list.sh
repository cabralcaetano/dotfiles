#!/usr/bin/env bash
set -euo pipefail

SCRIPT_REAL="$(readlink -f "${BASH_SOURCE[0]}")"
DOTFILES_DIR="$(cd "$(dirname "$SCRIPT_REAL")/../../.." && pwd)"
THEMES_DIR="$DOTFILES_DIR/themes"
CURRENT_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/theme-picker/current-theme"
CURRENT_THEME="$(cat "$CURRENT_FILE" 2>/dev/null || true)"

read_color() {
    local file="$1" key="$2" line value
    line=$(grep -E "^[[:space:]]*$key[[:space:]]*=" "$file" 2>/dev/null | head -n 1 || true)
    [[ -n $line ]] || return 0
    value="${line#*\"}"
    value="${value%%\"*}"
    printf '%s' "$value"
}

preview_for() {
    local dir="$1" candidate
    for candidate in "$dir"/preview.{png,jpg,jpeg,webp,gif,bmp} "$dir"/wallpaper.{png,jpg,jpeg,webp,gif,bmp}; do
        [[ -f $candidate ]] && { printf '%s' "$candidate"; return 0; }
    done
}

[[ -d $THEMES_DIR ]] || exit 0

for theme_dir in "$THEMES_DIR"/*; do
    [[ -d $theme_dir && -f $theme_dir/colors.toml ]] || continue

    name="${theme_dir##*/}"
    colors="$theme_dir/colors.toml"
    background=$(read_color "$colors" background)
    surface=$(read_color "$colors" surface)
    surface_hover=$(read_color "$colors" surface_hover)
    foreground=$(read_color "$colors" foreground)
    accent=$(read_color "$colors" accent)
    error=$(read_color "$colors" error)
    color1=$(read_color "$colors" color1)
    color2=$(read_color "$colors" color2)
    color3=$(read_color "$colors" color3)
    color4=$(read_color "$colors" color4)
    color5=$(read_color "$colors" color5)
    color6=$(read_color "$colors" color6)
    preview=$(preview_for "$theme_dir" || true)
    current=0
    [[ $name == "$CURRENT_THEME" ]] && current=1

    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$name" "$theme_dir" "$background" "$surface" "$surface_hover" "$foreground" "$accent" "$error" \
        "$color1" "$color2" "$color3" "$color4" "$color5" "$color6" "$preview" "$current"
done | sort
