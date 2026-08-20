#!/usr/bin/env bash
# Waybar active-window label with per-window process stats.
# Continuous mode emits immediately on Hyprland active-window events and also
# refreshes periodically so CPU/RAM do not go stale while focus stays unchanged.
set -euo pipefail
export PATH="/usr/local/bin:/usr/bin:/bin:${PATH:-}"

json_escape_payload() {
  local text="$1" tooltip="$2"
  jq -cn --arg text "$text" --arg tooltip "$tooltip" '{text:$text, tooltip:$tooltip, class:[]}'
}

format_app_name() {
  case "$1" in
    com.mitchellh.ghostty) printf 'ghostty' ;;
    "") printf '' ;;
    *) printf '%s' "$1" ;;
  esac
}

emit_payload() {
  local active_json pid class app stats cpu rss_kib proc_count ram sep tooltip

  active_json="$(hyprctl activewindow -j 2>/dev/null || printf '{}')"
  pid="$(jq -r '.pid // empty' <<<"$active_json")"
  class="$(jq -r '.class // ""' <<<"$active_json")"
  app="$(format_app_name "$class")"

  if [[ -z "$pid" || "$pid" = "0" || -z "$app" ]]; then
    json_escape_payload "" ""
    return 0
  fi

  stats="$(ps -eo pid=,ppid=,pcpu=,rss= 2>/dev/null | awk -v root="$pid" '
    {
      p=$1; parent=$2; cpu[p]=$3; rss[p]=$4; children[parent]=children[parent] " " p
    }
    END {
      queue=root
      while (queue != "") {
        split(queue, q, " ")
        queue=""
        for (i in q) {
          p=q[i]
          if (p == "" || seen[p]) continue
          seen[p]=1
          if (p in cpu) {
            total_cpu += cpu[p]
            total_rss += rss[p]
            count++
          }
          if (p in children) queue = queue children[p]
        }
      }
      printf "%.1f %d %d\n", total_cpu, total_rss, count
    }
  ')"

  read -r cpu rss_kib proc_count <<<"$stats"
  ram="$(awk -v kib="${rss_kib:-0}" 'BEGIN {
    mib = kib / 1024
    if (mib >= 1024) printf "%.1f GiB", mib / 1024
    else printf "%.0f MiB", mib
  }')"

  sep=$'\r'
  tooltip="${app}${sep}CPU: ${cpu:-0.0}%${sep}RAM: ${ram}${sep}Processos: ${proc_count:-0}"
  json_escape_payload "$app" "$tooltip"
}

if [[ "${1:-}" = "--once" ]]; then
  emit_payload
  exit 0
fi

periodic_refresh() {
  while true; do
    sleep 2
    emit_payload
  done
}

emit_payload
periodic_refresh &
ticker_pid=$!
cleanup() { kill "$ticker_pid" 2>/dev/null || true; }
trap cleanup EXIT
trap 'cleanup; exit 0' INT TERM

sock="${XDG_RUNTIME_DIR:?}/hypr/${HYPRLAND_INSTANCE_SIGNATURE:?}/.socket2.sock"
while true; do
  socat -u UNIX-CONNECT:"$sock" - | while IFS= read -r line; do
    event="${line%%>>*}"
    case "$event" in
      activewindow|activewindowv2|openwindow|closewindow|movewindow|workspace|workspacev2)
        emit_payload
        ;;
    esac
  done || true
  sleep 1
done
