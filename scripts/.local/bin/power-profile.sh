#!/usr/bin/env bash
# Sem `-e`: o modo `waybar-check` usa o exit code de um teste como retorno intencional.
set -uo pipefail
CURRENT=$(tuned-adm active | awk '{print $NF}')
BRIGHTNESS_STATE="/tmp/.power-profile-brightness-before-super-economia"

# Aplica o perfil $1 com label $2 (ícone + nome, pra notificação): brilho
# desce/restaura ao entrar/sair do Super Economia, tuned-adm aplica, notifica.
switch_to() {
    local next="$1" label="$2"
    if [ "$next" = "super-powersave" ] && [ "$CURRENT" != "super-powersave" ]; then
        brightnessctl get > "$BRIGHTNESS_STATE" 2>/dev/null
        brightnessctl -n2 set 25% >/dev/null 2>&1
    elif [ "$CURRENT" = "super-powersave" ] && [ -f "$BRIGHTNESS_STATE" ]; then
        brightnessctl set "$(cat "$BRIGHTNESS_STATE")" >/dev/null 2>&1
        rm -f "$BRIGHTNESS_STATE"
    fi
    tuned-adm profile "$next" && notify-send "Perfil de energia" "$label"
}

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
  menu)
    CHOICE=$(printf '%s\n' \
      "󰳗 Super Economia" \
      "󰌪 Economia" \
      "󰾅 Balanceado" \
      "󰾅 Balanceado+" \
      "󱐋 Performance" \
      | fuzzel --dmenu --prompt "Perfil de energia: ")
    case "$CHOICE" in
      *"Super Economia"*) switch_to super-powersave "$CHOICE" ;;
      *"Balanceado+"*)    switch_to balanced "$CHOICE" ;;
      *"Economia"*)       switch_to powersave "$CHOICE" ;;
      *"Balanceado"*)     switch_to balanced-battery "$CHOICE" ;;
      *"Performance"*)    switch_to latency-performance "$CHOICE" ;;
      *) exit 0 ;;   # Esc / fechou sem escolher
    esac
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
    switch_to "$NEXT" "$LABEL"
    ;;
esac
