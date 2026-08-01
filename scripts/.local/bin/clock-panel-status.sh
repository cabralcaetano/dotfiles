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
  awk -v pct="$1" -v width=26 'BEGIN {
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

  if [[ ! "$used_pct" =~ ^[0-9]+$ ]]; then
    printf '%-5s %s %4s\n' "$label" "$(bar "?")" "n/d"
    return
  fi

  local free_pct=$((100 - used_pct))
  if (( free_pct < 0 )); then free_pct=0; fi
  if (( free_pct > 100 )); then free_pct=100; fi

  printf '%-5s %s %3s%%\n' "$label" "$(bar "$used_pct")" "$free_pct"
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
  local now mtime tmp anthropic openai a_session_pct a_session_reset a_weekly_pct a_weekly_reset o_session_pct o_session_reset o_weekly_pct o_weekly_reset o_reset_label o_reset_value

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
    usage_bar_line "CLD5h" "$a_session_pct"
    usage_bar_line "CLD7d" "$a_weekly_pct"
    if [[ -n "$o_session_pct" ]]; then
      usage_bar_line "OAI5h" "$o_session_pct"
      o_reset_label="O5"
      o_reset_value="$o_session_reset"
    else
      usage_bar_line "OAI7d" "$o_weekly_pct"
      o_reset_label="O7"
      o_reset_value="$o_weekly_reset"
    fi
    printf 'reset C5 %s · C7 %s · %s %s\n' "$(compact_reset "$a_session_reset")" "$(compact_reset "$a_weekly_reset")" "$o_reset_label" "$(compact_reset "$o_reset_value")"
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


mapfile -t ai_usage < <(read_ai_usage)

printf '%s\n%s\n%s\n%-5s %s %3s%%\n%-5s %s %3s%%\n%s\n' \
  "${ai_usage[0]:-CLD5h ░░░░░░░░░░░░░░░░░░░░░░░░░░  n/d}" \
  "${ai_usage[1]:-CLD7d ░░░░░░░░░░░░░░░░░░░░░░░░░░  n/d}" \
  "${ai_usage[2]:-OAI7d ░░░░░░░░░░░░░░░░░░░░░░░░░░  n/d}" \
  "CPU" "$(bar "$cpu_pct")" "$cpu_pct" \
  "MEM" "$(bar "$mem_pct")" "$mem_pct" \
  "${ai_usage[3]:-reset C5 -- · C7 -- · O7 --}"
