#!/usr/bin/env bash
set -euo pipefail
# Toggle defaultFloating para o workspace atual.
# Ativa: flota todas as janelas abertas + novas janelas entram como float.
# Desativa: desflota todas as janelas abertas + remove a regra.
#
# NOTA (migração 2026-08-07 para hyprland.lua): FLOAT_CONF virou um arquivo
# .lua (carregado via `dofile` no hyprland.lua) em vez de um snippet hyprlang
# via `source =`. O formato da regra escrita mudou de
# `workspace = $WS, defaultFloating:1` para
# `hl.window_rule({ match = { workspace = "$WS" }, float = true })`.

FLOAT_CONF="$HOME/.config/hypr/workspace-float.lua"
touch "$FLOAT_CONF"

WS=$(hyprctl activeworkspace -j | jq '.id')

if grep -q "workspace = \"$WS\" }, float = true" "$FLOAT_CONF"; then
    # Desativar: remove a regra, desflota as janelas e restaura follow_mouse
    sed -i --follow-symlinks "/workspace = \"$WS\" }, float = true/d" "$FLOAT_CONF"
    hyprctl reload
    hyprctl keyword input:follow_mouse 1
    hyprctl clients -j \
        | jq -r --argjson ws "$WS" '.[] | select(.workspace.id == $ws and .floating == true) | .address' \
        | xargs -I{} hyprctl dispatch 'hl.dsp.window.float({ window = "address:{}" })'
else
    # Ativar: adiciona a regra, flota as janelas e desativa follow_mouse
    echo "hl.window_rule({ match = { workspace = \"$WS\" }, float = true })" >> "$FLOAT_CONF"
    hyprctl reload
    hyprctl keyword input:follow_mouse 0
    hyprctl clients -j \
        | jq -r --argjson ws "$WS" '.[] | select(.workspace.id == $ws and .floating == false) | .address' \
        | xargs -I{} hyprctl dispatch 'hl.dsp.window.float({ window = "address:{}" })'
fi
