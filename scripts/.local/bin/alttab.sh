#!/usr/bin/env bash
set -euo pipefail
# Cicla para a próxima janela sem mover o cursor.

FLOAT_CONF="$HOME/.config/hypr/workspace-float.lua"
WS=$(hyprctl activeworkspace -j | jq '.id')

if [ "${1:-}" = "prev" ]; then
    CYCLE_NEXT="false"
else
    CYCLE_NEXT="true"
fi

# Só preserva o cursor se o workspace float estiver ativo
if grep -q "workspace = \"$WS\" }, float = true" "$FLOAT_CONF" 2>/dev/null; then
    POS=$(hyprctl cursorpos -j)
    X=$(echo "$POS" | jq '.x | floor')
    Y=$(echo "$POS" | jq '.y | floor')
    hyprctl dispatch "hl.dsp.window.cycle_next({ next = $CYCLE_NEXT })"
    hyprctl dispatch 'hl.dsp.window.alter_zorder({ mode = "top" })'
    hyprctl dispatch "hl.dsp.cursor.move({ x = $X, y = $Y })"
else
    hyprctl dispatch "hl.dsp.window.cycle_next({ next = $CYCLE_NEXT })"
    hyprctl dispatch 'hl.dsp.window.alter_zorder({ mode = "top" })'
fi
