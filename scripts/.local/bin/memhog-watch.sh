#!/usr/bin/env bash
# memhog-watch — registra processos que passam de um limite de RSS e momentos
# de pouca memória disponível, para identificar runaways que travam o sistema.
# Contexto/investigação (repositório externo, vault wiki-ia — não faz parte
# deste repo): personal/projects/arch-migration/docs/system-freeze-memory-exhaustion.md

set -uo pipefail

THRESHOLD_MB=${MEMHOG_THRESHOLD_MB:-3072}   # loga processos acima disso
AVAIL_WARN_PCT=${MEMHOG_AVAIL_WARN_PCT:-20} # loga quando MemAvailable cai disso
LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/memhog"
LOG="$LOG_DIR/memhog.log"

mkdir -p "$LOG_DIR"

ts=$(date '+%Y-%m-%d %H:%M:%S')

read -r mem_total mem_avail < <(
  awk '/^MemTotal:/{t=$2} /^MemAvailable:/{a=$2} END{print t, a}' /proc/meminfo
)
avail_pct=$(( mem_avail * 100 / mem_total ))
avail_mb=$(( mem_avail / 1024 ))

# Processos acima do limite. RSS em KB na coluna 1.
hogs=$(ps -eo rss=,pid=,comm= --sort=-rss | awk -v lim=$(( THRESHOLD_MB * 1024 )) '$1 >= lim')

if [ -n "$hogs" ]; then
  while read -r rss pid comm; do
    [ -z "${pid:-}" ] && continue
    cmd=$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null | head -c 300)
    [ -z "$cmd" ] && cmd="[$comm]"
    printf '%s HOG rss=%dMB pid=%s comm=%s avail=%dMB(%d%%) cmd=%s\n' \
      "$ts" "$(( rss / 1024 ))" "$pid" "$comm" "$avail_mb" "$avail_pct" "$cmd"
  done <<< "$hogs" >> "$LOG"
fi

if [ "$avail_pct" -le "$AVAIL_WARN_PCT" ]; then
  top5=$(ps -eo rss=,pid=,comm= --sort=-rss | head -5 |
    awk '{printf "%s(%s:%dMB) ", $3, $2, $1/1024}')
  printf '%s LOWMEM avail=%dMB(%d%%) swap_free=%dMB top5=%s\n' \
    "$ts" "$avail_mb" "$avail_pct" \
    "$(awk '/^SwapFree:/{print int($2/1024)}' /proc/meminfo)" \
    "$top5" >> "$LOG"
fi

# Rotação simples: mantém o log abaixo de ~5 MB.
if [ -f "$LOG" ] && [ "$(stat -c%s "$LOG")" -gt 5242880 ]; then
  tail -n 2000 "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"
fi
