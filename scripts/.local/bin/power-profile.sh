#!/usr/bin/env bash
# Sem `-e`: o modo `waybar-check` usa o exit code de um teste como retorno intencional.
set -uo pipefail
CURRENT=$(tuned-adm active | awk '{print $NF}')

case "${1:-}" in
  waybar)
    case "$CURRENT" in
      balanced)            echo "󰾅" ;;
      latency-performance) echo "󱐋" ;;
      powersave)            echo "󰌪" ;;
      super-powersave)      echo "󰳗" ;;
    esac
    ;;
  waybar-check)
    [ "$CURRENT" != "balanced-battery" ]
    ;;
  *)
    case "$CURRENT" in
      balanced-battery)    NEXT="balanced"            ; LABEL="󰾅 Balanceado+" ;;
      balanced)            NEXT="latency-performance" ; LABEL="󱐋 Performance"  ;;
      latency-performance) NEXT="powersave"           ; LABEL="󰌪 Economia"     ;;
      powersave)            NEXT="super-powersave"     ; LABEL="󰳗 Super Economia" ;;
      super-powersave)      NEXT="balanced-battery"    ; LABEL="󰾅 Balanceado"   ;;
      *)                   NEXT="balanced-battery"    ; LABEL="󰾅 Balanceado"   ;;
    esac
    tuned-adm profile "$NEXT" && notify-send "Perfil de energia" "$LABEL"
    ;;
esac
