#!/usr/bin/env bash
set -uo pipefail

MODE="fuzzel"
ACTION="${1:-}"

case "${1:-}" in
  --hyprlock)
    MODE="hyprlock"
    ACTION="${2:-}"
    ;;
  --hyprlock-label)
    MODE="hyprlock-label"
    ACTION="${2:-}"
    ;;
esac

case "$ACTION" in
  suspend)
    PROMPT="Confirmar suspensão? "
    CONFIRM="Suspender"
    COMMAND=(systemctl suspend)
    ICON=""
    ;;
  poweroff)
    PROMPT="Confirmar desligamento? "
    CONFIRM="Desligar"
    COMMAND=(systemctl poweroff)
    ICON=""
    ;;
  reboot)
    PROMPT="Confirmar reinicialização? "
    CONFIRM="Reiniciar"
    COMMAND=(systemctl reboot)
    ICON=""
    ;;
  *)
    echo "Uso: ${0##*/} [--hyprlock|--hyprlock-label] {suspend|poweroff|reboot}" >&2
    exit 2
    ;;
esac

RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}"
STATE_FILE="$RUNTIME_DIR/hyprlock-power-confirm"
LOG="$RUNTIME_DIR/power-confirm.log"
TTL="${POWER_CONFIRM_TTL:-6}"

now_seconds() {
  date +%s
}

pending_action() {
  local pending_action="" pending_time="" now=""

  if [ ! -r "$STATE_FILE" ]; then
    return 1
  fi

  read -r pending_action pending_time < "$STATE_FILE" || return 1
  now="$(now_seconds)"

  case "$pending_time" in
    ''|*[!0-9]*) return 1 ;;
  esac

  if [ "$pending_action" = "$ACTION" ] && [ $((now - pending_time)) -le "$TTL" ]; then
    return 0
  fi

  return 1
}

refresh_hyprlock() {
  pkill -USR2 hyprlock >/dev/null 2>&1 || true
}

run_command() {
  local status=0

  {
    echo "$(date -Iseconds) action=$ACTION mode=$MODE cmd=${COMMAND[*]}"
    if [ "${POWER_CONFIRM_DRY_RUN:-0}" = "1" ]; then
      echo "$(date -Iseconds) action=$ACTION dry-run=1"
      status=0
    else
      "${COMMAND[@]}"
      status=$?
    fi
    echo "$(date -Iseconds) action=$ACTION exit=$status"
  } >>"$LOG" 2>&1

  if [ "$status" -ne 0 ] && command -v notify-send >/dev/null 2>&1; then
    notify-send -u critical "Energia" "Falha ao executar: ${COMMAND[*]} (exit $status). Ver $LOG"
  fi

  return "$status"
}

case "$MODE" in
  hyprlock-label)
    if pending_action; then
      printf ''
    else
      printf '%s' "$ICON"
    fi
    ;;
  hyprlock)
    if pending_action; then
      rm -f "$STATE_FILE"
      refresh_hyprlock
      run_command
    else
      printf '%s %s\n' "$ACTION" "$(now_seconds)" > "$STATE_FILE"
      refresh_hyprlock
    fi
    ;;
  fuzzel)
    if ! command -v fuzzel >/dev/null 2>&1; then
      if command -v notify-send >/dev/null 2>&1; then
        notify-send "Energia" "Fuzzel não encontrado; ação cancelada"
      fi
      echo "fuzzel não encontrado; ação cancelada" >&2
      exit 1
    fi

    CHOICE=$(printf 'Cancelar\n%s\n' "$CONFIRM" | fuzzel --dmenu --prompt "$PROMPT" --width 28 --lines 2) || exit 0
    case "$CHOICE" in
      "$CONFIRM") run_command ;;
      *) exit 0 ;;
    esac
    ;;
esac
