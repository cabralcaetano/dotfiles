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
    LOG="$XDG_RUNTIME_DIR/power-confirm.log"
    {
      echo "$(date -Iseconds) action=$ACTION cmd=${COMMAND[*]}"
      "${COMMAND[@]}"
      STATUS=$?
      echo "$(date -Iseconds) action=$ACTION exit=$STATUS"
    } >>"$LOG" 2>&1
    if [ "${STATUS:-0}" -ne 0 ] && command -v notify-send >/dev/null 2>&1; then
      notify-send -u critical "Energia" "Falha ao executar: ${COMMAND[*]} (exit $STATUS). Ver $LOG"
    fi
    ;;
  *)
    exit 0
    ;;
esac
