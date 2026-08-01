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
  awk -v pct="$1" 'BEGIN {
    if (pct !~ /^[0-9.]+$/) {
      print "░░░░░░░░░░";
      exit;
    }

    filled = int((pct + 5) / 10);
    if (filled < 0) filled = 0;
    if (filled > 10) filled = 10;

    for (i = 0; i < filled; i++) printf "█";
    for (i = filled; i < 10; i++) printf "░";
  }'
}

strip_tags() {
  python3 -c 'import re,sys; print(re.sub(r"<[^>]+>", "", sys.stdin.read()).strip())'
}

compact_reset() {
  local value="$1"
  value="${value// /}"
  value="${value#0h}"
  [[ -n "$value" ]] || value="now"
  printf '%s' "$value"
}

usage_bar_line() {
  local label="$1"
  local used_pct="$2"
  local reset="$3"

  if [[ ! "$used_pct" =~ ^[0-9]+$ ]]; then
    printf '%-4s %s %4s %s\n' "$label" "$(bar "?")" "n/d" "--"
    return
  fi

  local free_pct=$((100 - used_pct))
  if (( free_pct < 0 )); then free_pct=0; fi
  if (( free_pct > 100 )); then free_pct=100; fi

  printf '%-4s %s %3s%% %s\n' "$label" "$(bar "$used_pct")" "$free_pct" "$(compact_reset "$reset")"
}

usagebar_text() {
  local vendor="$1"
  local format="$2"
  local bin="/home/caetano/.local/bin/ai-usagebar"

  if [[ ! -x "$bin" ]]; then
    return 1
  fi

  "$bin" --vendor "$vendor" --format "$format" --json 2>/dev/null | jq -r '.text' | strip_tags
}

read_ai_usage() {
  local cache="${XDG_RUNTIME_DIR:-/tmp}/clock-panel-ai-usage.cache"
  local now mtime tmp anthropic openai a_session_pct a_session_reset a_weekly_pct a_weekly_reset o_session_pct o_session_reset o_weekly_pct o_weekly_reset

  now="$(date +%s)"
  if [[ -r "$cache" ]]; then
    mtime="$(stat -c %Y "$cache" 2>/dev/null || printf 0)"
    if (( now - mtime < 300 )); then
      cat "$cache"
      return
    fi
  fi

  anthropic="$(usagebar_text anthropic '{session_pct}|{session_reset}|{weekly_pct}|{weekly_reset}' || true)"
  openai="$(usagebar_text openai '{oai_session_pct}|{oai_session_reset}|{oai_weekly_pct}|{oai_weekly_reset}' || true)"

  IFS='|' read -r a_session_pct a_session_reset a_weekly_pct a_weekly_reset <<< "$anthropic"
  IFS='|' read -r o_session_pct o_session_reset o_weekly_pct o_weekly_reset <<< "$openai"

  tmp="$(mktemp)"
  {
    usage_bar_line "CLD5" "$a_session_pct" "$a_session_reset"
    usage_bar_line "CLD7" "$a_weekly_pct" "$a_weekly_reset"
    if [[ -n "$o_session_pct" ]]; then
      usage_bar_line "OAI5" "$o_session_pct" "$o_session_reset"
    else
      usage_bar_line "OAI7" "$o_weekly_pct" "$o_weekly_reset"
    fi
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

cpu_value="${cpu_pct}%"
mem_value="${mem_pct}%"

mapfile -t ai_usage < <(read_ai_usage)

printf '%s\n%s\n%s\n󰻠 %-4s %4s  %s\n󰍛 %-4s %4s  %s\n' \
  "${ai_usage[0]:-CLD5 ░░░░░░░░░░  n/d --}" \
  "${ai_usage[1]:-CLD7 ░░░░░░░░░░  n/d --}" \
  "${ai_usage[2]:-OAI7 ░░░░░░░░░░  n/d --}" \
  "CPU" "$cpu_value" "$(bar "$cpu_pct")" \
  "MEM" "$mem_value" "$(bar "$mem_pct")"
