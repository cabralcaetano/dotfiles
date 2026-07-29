#!/usr/bin/env bash
set -euo pipefail

CARD=$(pactl list cards short | awk '/bluez_card/ {print $2; exit}')

if [ -z "$CARD" ]; then
    notify-send -t 2000 "Bluetooth" "Nenhum fone Bluetooth conectado"
    exit 0
fi

CURRENT=$(pactl list cards | awk -v card="$CARD" '
  $0 ~ "Name: " card {found=1}
  found && /Active Profile:/ {print $3; exit}
')

if [ "$CURRENT" = "a2dp-sink" ]; then
    TARGET="headset-head-unit"
    LABEL="mSBC (chamada/mic)"
else
    TARGET="a2dp-sink"
    LABEL="LDAC (alta-fidelidade)"
fi

pactl set-card-profile "$CARD" "$TARGET"

notify-send \
  -h string:x-canonical-private-synchronous:bt-codec \
  -i audio-headset-bluetooth \
  -t 1500 \
  "Fone Bluetooth" "$LABEL"
