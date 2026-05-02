#!/usr/bin/env bash
CURRENT=$(tuned-adm active | awk '{print $NF}')

case "$1" in
  waybar)
    case "$CURRENT" in
      latency-performance) echo "󱐋" ;;
      powersave)           echo "󰌪" ;;
    esac
    ;;
  waybar-check)
    [ "$CURRENT" != "balanced" ]
    ;;
  *)
    case "$CURRENT" in
      balanced)            NEXT="latency-performance" ; LABEL="󱐋 Performance" ;;
      latency-performance) NEXT="powersave"           ; LABEL="󰌪 Economia"    ;;
      *)                   NEXT="balanced"            ; LABEL="󰾅 Balanceado"  ;;
    esac
    tuned-adm profile "$NEXT" && notify-send "Perfil de energia" "$LABEL"
    ;;
esac
