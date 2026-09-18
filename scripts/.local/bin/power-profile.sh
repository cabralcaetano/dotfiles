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
        brightnessctl -n2 set 20% >/dev/null 2>&1
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
    # O fuzzel não tem cursor textual móvel: prefixar `=>` no item ativo só
    # marca o perfil atual, mas a seta não acompanha ↑/↓. Para este menu, usa
    # fzf dentro de um Ghostty flutuante; o `--pointer "=> "` é o cursor real
    # e se move junto com a seleção.
    if command -v hyprctl >/dev/null 2>&1 && command -v ghostty >/dev/null 2>&1 && command -v fzf >/dev/null 2>&1; then
        script_path="$(readlink -f "$0")"
        cmd="ghostty --gtk-single-instance=false --title=power-profile-menu --window-save-state=never --window-decoration=none --window-width=40 --window-height=8 -e $script_path menu-fzf"
        swaync-client --close-panel >/dev/null 2>&1 || true
        hyprctl dispatch "hl.dsp.exec_cmd('$cmd')" >/dev/null
        exit 0
    fi

    CHOICE=$(printf '%s\n' \
      "󰳗 Super Economia" \
      "󰌪 Economia" \
      "󰾅 Balanceado" \
      "󰾅 Balanceado+" \
      "󱐋 Performance" \
      | fuzzel --dmenu --no-exit-on-keyboard-focus-loss --prompt "Perfil de energia: ")
    LABEL="$CHOICE"
    case "$LABEL" in
      *"Super Economia"*) switch_to super-powersave "$LABEL" ;;
      *"Balanceado+"*)    switch_to balanced "$LABEL" ;;
      *"Economia"*)       switch_to powersave "$LABEL" ;;
      *"Balanceado"*)     switch_to balanced-battery "$LABEL" ;;
      *"Performance"*)    switch_to latency-performance "$LABEL" ;;
      *) exit 0 ;;   # Esc / fechou sem escolher
    esac
    ;;
  menu-fzf)
    current_label="$(
        case "$CURRENT" in
          super-powersave)      printf '󰳗 Super Economia' ;;
          powersave)            printf '󰌪 Economia' ;;
          balanced-battery)     printf '󰾅 Balanceado' ;;
          balanced)             printf '󰾅 Balanceado+' ;;
          latency-performance)  printf '󱐋 Performance' ;;
          *)                    printf '󰾅 Balanceado' ;;
        esac
    )"
    current_pos="$(
        case "$CURRENT" in
          super-powersave)      printf 1 ;;
          powersave)            printf 2 ;;
          balanced-battery)     printf 3 ;;
          balanced)             printf 4 ;;
          latency-performance)  printf 5 ;;
          *)                    printf 3 ;;
        esac
    )"
    CHOICE=$(printf '%s\n' \
      "󰳗 Super Economia" \
      "󰌪 Economia" \
      "󰾅 Balanceado" \
      "󰾅 Balanceado+" \
      "󱐋 Performance" \
      | fzf --no-info --height=100% --layout=reverse --no-scrollbar --no-separator --header="Atual: $current_label" --pointer="=>" --marker="  " --prompt=" " --highlight-line --padding=0,2 --color="fg:#f0f0f0,bg:-1,hl:#8a8a8d,fg+:#f0f0f0,bg+:#3a3a3e,hl+:#f0f0f0,pointer:#f0f0f0,header:#a0a0a0,prompt:#a0a0a0" --bind "start:pos($current_pos)")
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
