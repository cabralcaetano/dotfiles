#!/usr/bin/env bash
set -euo pipefail

# Move uma janela para o workspace assim que ela aparece.
# Teto de ~30s para não virar processo zumbi se o app nunca subir.
move_when_ready() {
    local class=$1
    local workspace=$2
    local tries=0
    until hyprctl clients | grep -q "class: $class"; do
        sleep 1
        (( ++tries >= 30 )) && return 0
    done
    hyprctl dispatch movetoworkspacesilent "$workspace,class:$class"
}

move_when_ready Spotify 3 &
move_when_ready discord 4 &

wait
