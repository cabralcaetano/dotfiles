#!/usr/bin/env bash
# Cicla para a próxima janela sem mover o cursor.

FLOAT_CONF="$HOME/.config/hypr/workspace-float.conf"
WS=$(hyprctl activeworkspace -j | jq '.id')

# Só preserva o cursor se o workspace float estiver ativo
if grep -q "^workspace = $WS," "$FLOAT_CONF" 2>/dev/null; then
    POS=$(hyprctl cursorpos -j)
    X=$(echo "$POS" | jq '.x | floor')
    Y=$(echo "$POS" | jq '.y | floor')
    hyprctl dispatch cyclenext "$1"
    hyprctl dispatch bringactivetotop
    hyprctl dispatch movecursor "$X" "$Y"
else
    hyprctl dispatch cyclenext "$1"
    hyprctl dispatch bringactivetotop
fi
