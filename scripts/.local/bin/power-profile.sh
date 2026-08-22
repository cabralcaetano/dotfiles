#!/usr/bin/env bash
# Sem `-e`: o modo `waybar-check` usa o exit code de um teste como retorno intencional.
set -uo pipefail
CURRENT=$(tuned-adm active | awk '{print $NF}')
BRIGHTNESS_STATE="/tmp/.power-profile-brightness-before-super-economia"

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
      super-powersave)      NEXT="powersave"           ; LABEL="󰌪 Economia"     ;;
      powersave)            NEXT="balanced-battery"    ; LABEL="󰾅 Balanceado"   ;;
      balanced-battery)     NEXT="balanced"            ; LABEL="󰾅 Balanceado+" ;;
      balanced)             NEXT="latency-performance" ; LABEL="󱐋 Performance"  ;;
      latency-performance)  NEXT="super-powersave"     ; LABEL="󰳗 Super Economia" ;;
      *)                    NEXT="balanced-battery"    ; LABEL="󰾅 Balanceado"   ;;
    esac
    if [ "$NEXT" = "super-powersave" ] && [ "$CURRENT" != "super-powersave" ]; then
        brightnessctl get > "$BRIGHTNESS_STATE" 2>/dev/null
        brightnessctl -n2 set 25% >/dev/null 2>&1
    elif [ "$CURRENT" = "super-powersave" ] && [ -f "$BRIGHTNESS_STATE" ]; then
        brightnessctl set "$(cat "$BRIGHTNESS_STATE")" >/dev/null 2>&1
        rm -f "$BRIGHTNESS_STATE"
    fi
    tuned-adm profile "$NEXT" && notify-send "Perfil de energia" "$LABEL"
    ;;
esac
