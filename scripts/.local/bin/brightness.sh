#!/bin/bash
case "$1" in
  up)   brightnessctl -e4 -n2 set 5%+ ;;
  down) brightnessctl -e4 -n2 set 5%- ;;
esac

BRIGHT=$(brightnessctl -m | awk -F',' '{gsub(/%/,"",$4); print $4}')

notify-send \
  -h string:x-canonical-private-synchronous:brightness \
  -h int:value:"$BRIGHT" \
  -i "display-brightness" \
  -t 1500 \
  "Brilho" "$BRIGHT%"
