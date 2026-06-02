#!/usr/bin/env bash
# Toggle defaultFloating para o workspace atual.
# Ativa: flota todas as janelas abertas + novas janelas entram como float.
# Desativa: desflota todas as janelas abertas + remove a regra.

FLOAT_CONF="$HOME/.config/hypr/workspace-float.conf"
touch "$FLOAT_CONF"

WS=$(hyprctl activeworkspace -j | jq '.id')

if grep -q "^workspace = $WS," "$FLOAT_CONF"; then
    # Desativar: remove a regra e desflota as janelas abertas
    sed -i "/^workspace = $WS,/d" "$FLOAT_CONF"
    hyprctl reload
    hyprctl clients -j \
        | jq -r --argjson ws "$WS" '.[] | select(.workspace.id == $ws and .floating == true) | .address' \
        | xargs -I{} hyprctl dispatch togglefloating address:{}
else
    # Ativar: adiciona a regra e flota as janelas abertas
    echo "workspace = $WS, defaultFloating:1" >> "$FLOAT_CONF"
    hyprctl reload
    hyprctl clients -j \
        | jq -r --argjson ws "$WS" '.[] | select(.workspace.id == $ws and .floating == false) | .address' \
        | xargs -I{} hyprctl dispatch togglefloating address:{}
fi
