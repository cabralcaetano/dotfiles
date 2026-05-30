#!/bin/bash
hyprctl devices -j | jq -r '.keyboards[].name' | while read -r kb; do
    hyprctl switchxkblayout "$kb" next
done

LAYOUT=$(hyprctl devices -j | jq -r '[.keyboards[] | select(.name != "")][0].active_keymap')
notify-send \
  -h string:x-canonical-private-synchronous:keyboard \
  -i input-keyboard \
  -t 1500 \
  "Teclado" "$LAYOUT"
