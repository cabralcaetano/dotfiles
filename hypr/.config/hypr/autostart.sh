#!/bin/bash

move_when_ready() {
    local class=$1
    local workspace=$2
    until hyprctl clients | grep -q "class: $class"; do sleep 1; done
    hyprctl dispatch movetoworkspacesilent "$workspace,class:$class"
}

move_when_ready Spotify 3 &
move_when_ready discord 4 &

wait
