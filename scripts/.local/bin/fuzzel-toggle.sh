#!/usr/bin/env bash
set -euo pipefail

# Toggle Fuzzel while ignoring zombie processes left by detached launchers.
# A plain `pkill fuzzel || fuzzel` gets stuck when pgrep/pkill match a zombie:
# pkill returns success, but no visible launcher exists and a new one never starts.
found_live=false

while IFS= read -r pid; do
    [[ -n $pid ]] || continue

    state=$(ps -p "$pid" -o stat= 2>/dev/null | tr -d '[:space:]' || true)
    [[ -n $state && $state != Z* ]] || continue

    kill "$pid" 2>/dev/null || true
    found_live=true
done < <(pgrep -x fuzzel || true)

if [[ $found_live == true ]]; then
    exit 0
fi

setsid -f fuzzel >/tmp/fuzzel.log 2>&1
