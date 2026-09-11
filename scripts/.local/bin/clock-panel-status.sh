#!/usr/bin/env bash
set -euo pipefail

read_cpu() {
  local _ label user nice system idle iowait irq softirq steal guest guest_nice
  read -r label user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat
  local idle_all=$((idle + iowait))
  local non_idle=$((user + nice + system + irq + softirq + steal))
  local total=$((idle_all + non_idle))
  printf '%s %s\n' "$idle_all" "$total"
}

bar() {
  awk -v pct="$1" -v width=28 'BEGIN {
    if (pct !~ /^[0-9.]+$/) {
      for (i = 0; i < width; i++) printf "░";
      exit;
    }

    filled = int((pct * width + 50) / 100);
    if (filled < 0) filled = 0;
    if (filled > width) filled = width;

    for (i = 0; i < filled; i++) printf "█";
    for (i = filled; i < width; i++) printf "░";
  }'
}

usage_bar_line() {
  local icon="$1"
  local label="$2"
  local used_pct="$3"
  local state="${4:-ok}"

  if [[ "$state" != "ok" ]]; then
    printf '%s|%s!|%s|%s\n' "$icon" "$label" "$(bar "?")" "erro"
    return
  fi

  if [[ ! "$used_pct" =~ ^[0-9]+$ ]]; then
    printf '%s|%s|%s|%s\n' "$icon" "$label" "$(bar "?")" "n/d"
    return
  fi

  if (( used_pct < 0 )); then used_pct=0; fi
  if (( used_pct > 100 )); then used_pct=100; fi

  printf '%s|%s|%s|%s%%\n' "$icon" "$label" "$(bar "$used_pct")" "$used_pct"
}

format_reset_ms() {
  local resets_ms="$1"
  local now_s resets_s delta days hours minutes

  if [[ ! "$resets_ms" =~ ^[0-9]+$ ]] || (( resets_ms <= 0 )); then
    printf '%s' '--'
    return
  fi

  now_s="$(date +%s)"
  resets_s=$((resets_ms / 1000))
  delta=$((resets_s - now_s))

  if (( delta <= 0 )); then
    printf '%s' 'now'
  elif (( delta >= 86400 )); then
    days=$((delta / 86400))
    hours=$(((delta % 86400) / 3600))
    printf '%dd%dh' "$days" "$hours"
  elif (( delta >= 3600 )); then
    hours=$((delta / 3600))
    minutes=$(((delta % 3600) / 60))
    if (( minutes > 0 )); then
      printf '%dh%dm' "$hours" "$minutes"
    else
      printf '%dh' "$hours"
    fi
  else
    minutes=$(((delta + 59) / 60))
    printf '%dm' "$minutes"
  fi
}

read_usage_limit() {
  local usage_json="$1"
  local provider="$2"
  local window="$3"
  local tier="${4:-}"

  jq -r --arg provider "$provider" --arg window "$window" --arg tier "$tier" '
    [
      .reports[]?
      | select(.provider == $provider)
      | .limits[]?
      | select(.window.id == $window)
      | select(
          if $tier == "" then
            ((.scope.tier // "chat") == "chat")
          else
            ((.scope.tier // "") == $tier)
          end
        )
    ][0] as $limit
    | if $limit == null then
        "||error"
      else
        [
          (($limit.amount.used // 0) | round | tostring),
          (($limit.window.resetsAt // 0) | tostring),
          ($limit.status // "ok")
        ] | @tsv
      end
  ' <<< "$usage_json"
}

usage_state() {
  case "$1" in
    ok|exhausted) printf '%s' 'ok' ;;
    *) printf '%s' 'error' ;;
  esac
}

reset_or_error() {
  local state="$1"
  local resets_ms="$2"

  if [[ "$state" != "ok" ]]; then
    printf 'erro'
    return
  fi

  format_reset_ms "$resets_ms"
}

read_omp_usage() {
  local cache="${XDG_RUNTIME_DIR:-/tmp}/clock-panel-omp-usage.cache"
  local now mtime tmp usage_json
  local a_session_pct a_session_reset a_session_status a_weekly_pct a_weekly_reset a_weekly_status
  local o_weekly_pct o_weekly_reset o_weekly_status a_session_state a_weekly_state o_weekly_state

  now="$(date +%s)"
  if [[ -r "$cache" ]]; then
    mtime="$(stat -c %Y "$cache" 2>/dev/null || printf 0)"
    if (( now - mtime < 300 )); then
      cat "$cache"
      return
    fi
  fi

  tmp="$(mktemp)"

  if ! command -v omp >/dev/null 2>&1 || ! usage_json="$(omp usage --json 2>/dev/null)" || ! jq -e '.reports | type == "array"' >/dev/null 2>&1 <<< "$usage_json"; then
    {
      usage_bar_line "󰚩" "C5" "" "error"
      usage_bar_line "󰚩" "C7" "" "error"
      usage_bar_line "" "O7" "" "error"
      printf '↻|C5 erro|C7 erro|O7 erro\n'
    } > "$tmp"
    mv "$tmp" "$cache"
    cat "$cache"
    return
  fi

  IFS=$'\t' read -r a_session_pct a_session_reset a_session_status < <(read_usage_limit "$usage_json" "anthropic" "5h")
  IFS=$'\t' read -r a_weekly_pct a_weekly_reset a_weekly_status < <(read_usage_limit "$usage_json" "anthropic" "7d")
  IFS=$'\t' read -r o_weekly_pct o_weekly_reset o_weekly_status < <(read_usage_limit "$usage_json" "openai-codex" "7d")

  a_session_state="$(usage_state "$a_session_status")"
  a_weekly_state="$(usage_state "$a_weekly_status")"
  o_weekly_state="$(usage_state "$o_weekly_status")"

  {
    usage_bar_line "󰚩" "C5" "$a_session_pct" "$a_session_state"
    usage_bar_line "󰚩" "C7" "$a_weekly_pct" "$a_weekly_state"
    usage_bar_line "" "O7" "$o_weekly_pct" "$o_weekly_state"
    printf '↻|C5 %s|C7 %s|O7 %s\n' "$(reset_or_error "$a_session_state" "$a_session_reset")" "$(reset_or_error "$a_weekly_state" "$a_weekly_reset")" "$(reset_or_error "$o_weekly_state" "$o_weekly_reset")"
  } > "$tmp"
  mv "$tmp" "$cache"
  cat "$cache"
}

read -r idle1 total1 < <(read_cpu)
sleep 0.5
read -r idle2 total2 < <(read_cpu)

cpu_delta=$((total2 - total1))
idle_delta=$((idle2 - idle1))
if (( cpu_delta > 0 )); then
  cpu_pct="$(awk -v idle="$idle_delta" -v total="$cpu_delta" 'BEGIN { printf "%.0f", (1 - idle / total) * 100 }')"
else
  cpu_pct="?"
fi

mem_pct="$(awk '/MemTotal:/ { total=$2 } /MemAvailable:/ { avail=$2 } END { if (total > 0) printf "%.0f", (total - avail) / total * 100; else printf "?" }' /proc/meminfo)"


mapfile -t ai_usage < <(read_omp_usage)

printf '%s\n%s\n%s\n%s|%s|%s|%s%%\n%s|%s|%s|%s%%\n%s\n' \
  "${ai_usage[0]:-󰚩|C5|░░░░░░░░░░░░░░░░░░░░░░░░░░░░|n/d}" \
  "${ai_usage[1]:-󰚩|C7|░░░░░░░░░░░░░░░░░░░░░░░░░░░░|n/d}" \
  "${ai_usage[2]:-|O7|░░░░░░░░░░░░░░░░░░░░░░░░░░░░|n/d}" \
  "" "CPU" "$(bar "$cpu_pct")" "$cpu_pct" \
  "" "RAM" "$(bar "$mem_pct")" "$mem_pct" \
  "${ai_usage[3]:-↻|C5 --|C7 --|O7 --}"
