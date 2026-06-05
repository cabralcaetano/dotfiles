#!/usr/bin/env bash
set -euo pipefail
MAX=$(brightnessctl max)
STEP=$(( MAX / 100 ))
(( STEP < 1 )) && STEP=1   # evita passo zero em backlights de baixa resolução

case "${1:-}" in
  up)   brightnessctl -n2 set +${STEP} ;;
  down) brightnessctl -n2 set ${STEP}- ;;
esac

CUR=$(brightnessctl get)
LEVEL=$(( CUR * 100 / MAX ))

notify-send \
  -h string:x-canonical-private-synchronous:brightness \
  -h int:value:"$LEVEL" \
  -i "display-brightness" \
  -t 1500 \
  "Brilho" "$LEVEL%"
