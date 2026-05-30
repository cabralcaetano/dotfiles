#!/bin/bash
hyprctl switchxkblayout all next

LAYOUT=$(hyprctl devices -j | jq -r '[.keyboards[] | select(.name != "")][0].active_keymap')
notify-send \
  -h string:x-canonical-private-synchronous:keyboard \
  -i input-keyboard \
  -t 1500 \
  "Teclado" "$LAYOUT"
