#!/bin/bash

sleep 3 && hyprctl dispatch exec "[workspace 1 silent] brave-browser"
sleep 4 && hyprctl dispatch exec "[workspace 2 silent] kitty"
sleep 4 && hyprctl dispatch exec "[workspace 2 silent] flatpak run md.obsidian.Obsidian"
sleep 5 && hyprctl dispatch exec "[workspace 3 silent] spotify"
sleep 6 && hyprctl dispatch exec "[workspace 4 silent] Discord"
