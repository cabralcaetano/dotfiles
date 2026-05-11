#!/bin/bash

# Launch apps
sleep 3 && hyprctl dispatch exec "brave-browser" &
sleep 4 && hyprctl dispatch exec "kitty" &
sleep 4 && hyprctl dispatch exec "flatpak run md.obsidian.Obsidian" &
sleep 5 && hyprctl dispatch exec "spotify" &
sleep 6 && hyprctl dispatch exec "Discord" &

# Move each window to its workspace once it appears
move_when_ready() {
    local class=$1
    local workspace=$2
    until hyprctl clients | grep -q "class: $class"; do sleep 1; done
    hyprctl dispatch movetoworkspacesilent "$workspace,class:$class"
}

move_when_ready brave-browser 1 &
move_when_ready kitty        2 &
move_when_ready obsidian     2 &
move_when_ready Spotify      3 &
move_when_ready discord      4 &

wait
