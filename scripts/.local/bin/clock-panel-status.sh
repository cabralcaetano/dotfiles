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
mem_used="$(awk '/MemTotal:/ { total=$2 } /MemAvailable:/ { avail=$2 } END { if (total > 0) printf "%.1f", (total - avail) / 1048576; else printf "?" }' /proc/meminfo)"
mem_total="$(awk '/MemTotal:/ { printf "%.1f", $2 / 1048576 }' /proc/meminfo)"

disk_pct="$(df -P / | awk 'NR == 2 { gsub("%", "", $5); print $5 }')"
gpu_pct="n/d"
if command -v intel_gpu_top >/dev/null 2>&1; then
  gpu_sample="$(timeout 1s intel_gpu_top -J -s 500 -o - 2>/dev/null || true)"
  gpu_pct="$(printf '%s\n' "$gpu_sample" | awk -F: '/"Render\\/3D\\/0"/ { gsub(/[^0-9.]/, "", $2); if ($2 != "") { printf "%.0f", $2; exit } }')"
  [[ -n "$gpu_pct" ]] || gpu_pct="n/d"
fi

cpu_value="${cpu_pct}%"
mem_value="${mem_pct}%"
disk_value="${disk_pct}%"
gpu_value="$gpu_pct"
[[ "$gpu_pct" =~ ^[0-9.]+$ ]] && gpu_value="${gpu_pct}%"

printf '󰻠 %-4s %4s  %s\n󰍛 %-4s %4s  %s\n󰋊 %-4s %4s  %s\n󰢮 %-4s %4s  %s\n' \
  "CPU" "$cpu_value" "$(bar "$cpu_pct")" \
  "MEM" "$mem_value" "$(bar "$mem_pct")" \
  "DISK" "$disk_value" "$(bar "$disk_pct")" \
  "GPU" "$gpu_value" "$(bar "$gpu_pct")"
