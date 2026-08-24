#!/usr/bin/env bash
set -euo pipefail
# Toggle defaultFloating para o workspace atual.
# Ativa: flota todas as janelas abertas + novas janelas entram como float.
# Desativa: desflota todas as janelas abertas + remove a regra.
#
# Estado intencionalmente por sessão: o arquivo fica em XDG_RUNTIME_DIR, então
# no próximo boot todos os workspaces voltam ao default tiled/desativado.
# A regra usa o nome lógico do workspace (ex.: super-1-2), não o ID negativo
# transitório do Hyprland.

runtime_base="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
[[ -d "$runtime_base" ]] || runtime_base="/tmp"
runtime_dir="$runtime_base/hypr"
FLOAT_CONF="$runtime_dir/workspace-float.lua"
mkdir -p "$runtime_dir"

if [[ ! -f "$FLOAT_CONF" ]]; then
    cat >"$FLOAT_CONF" <<'LUA'
-- Gerado por workspace-float.sh para a sessão atual.
-- Removido no reboot junto com XDG_RUNTIME_DIR.
LUA
fi

active_workspace_json=$(hyprctl activeworkspace -j)
WS_NAME=$(jq -r '.name // empty' <<<"$active_workspace_json")
if [[ -z "$WS_NAME" ]]; then
    WS_NAME=$(jq -r '.id | tostring' <<<"$active_workspace_json")
fi

lua_workspace=${WS_NAME//\\/\\\\}
lua_workspace=${lua_workspace//\"/\\\"}
rule="hl.window_rule({ match = { workspace = \"$lua_workspace\" }, float = true })"

toggle_windows() {
    local floating_state="$1"
    hyprctl clients -j \
        | jq -r --arg ws "$WS_NAME" --argjson floating "$floating_state" '.[] | select(.workspace.name == $ws and .floating == $floating) | .address' \
        | xargs -r -I{} hyprctl dispatch 'hl.dsp.window.float({ window = "address:{}" })'
}

if grep -Fxq "$rule" "$FLOAT_CONF"; then
    # Desativar: remove a regra, desflota as janelas e restaura follow_mouse.
    tmp=$(mktemp)
    grep -Fxv "$rule" "$FLOAT_CONF" >"$tmp" || true
    mv "$tmp" "$FLOAT_CONF"
    hyprctl reload
    hyprctl keyword input:follow_mouse 1
    toggle_windows true
else
    # Ativar: adiciona a regra, flota as janelas e desativa follow_mouse.
    printf '%s\n' "$rule" >>"$FLOAT_CONF"
    hyprctl reload
    hyprctl keyword input:follow_mouse 0
    toggle_windows false
fi
