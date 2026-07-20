#!/usr/bin/env bash
set -uo pipefail

ACTION="${1:-}"

case "$ACTION" in
  poweroff)
    PROMPT="Confirmar desligamento? "
    CONFIRM="Desligar"
    COMMAND=(systemctl poweroff)
    ;;
  reboot)
    PROMPT="Confirmar reinicialização? "
    CONFIRM="Reiniciar"
    COMMAND=(systemctl reboot)
    ;;
  *)
    echo "Uso: ${0##*/} {poweroff|reboot}" >&2
    exit 2
    ;;
esac

if ! command -v fuzzel >/dev/null 2>&1; then
  if command -v notify-send >/dev/null 2>&1; then
    notify-send "Energia" "Fuzzel não encontrado; ação cancelada"
  fi
  echo "fuzzel não encontrado; ação cancelada" >&2
  exit 1
fi

CHOICE=$(printf 'Cancelar\n%s\n' "$CONFIRM" | fuzzel --dmenu --prompt "$PROMPT" --width 28 --lines 2) || exit 0

case "$CHOICE" in
  "$CONFIRM")
    "${COMMAND[@]}"
    ;;
  *)
    exit 0
    ;;
esac
