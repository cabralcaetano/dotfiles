#!/usr/bin/env bash
set -euo pipefail
# Toggle defaultFloating para o workspace atual.
# Ativa: flota todas as janelas abertas + novas janelas entram como float.
# Desativa: desflota todas as janelas abertas + remove a regra.

FLOAT_CONF="$HOME/.config/hypr/workspace-float.conf"
touch "$FLOAT_CONF"

WS=$(hyprctl activeworkspace -j | jq '.id')

if grep -q "^workspace = $WS," "$FLOAT_CONF"; then
    # Desativar: remove a regra, desflota as janelas e restaura follow_mouse
    sed -i "/^workspace = $WS,/d" "$FLOAT_CONF"
    hyprctl reload
    hyprctl keyword input:follow_mouse 1
    hyprctl clients -j \
        | jq -r --argjson ws "$WS" '.[] | select(.workspace.id == $ws and .floating == true) | .address' \
        | xargs -I{} hyprctl dispatch togglefloating address:{}
else
    # Ativar: adiciona a regra, flota as janelas e desativa follow_mouse
    echo "workspace = $WS, defaultFloating:1" >> "$FLOAT_CONF"
    hyprctl reload
    hyprctl keyword input:follow_mouse 0
    hyprctl clients -j \
        | jq -r --argjson ws "$WS" '.[] | select(.workspace.id == $ws and .floating == false) | .address' \
        | xargs -I{} hyprctl dispatch togglefloating address:{}
fi
