#!/usr/bin/env bash
# Tracks which super workspace banks currently have an urgent (attention-
# demanding) window, so the Waybar super-workspace icon can carry the same
# white "urgent" mark that hyprland/workspaces already shows per slot.
#
# Why event-driven: on this Hyprland build (0.56.2) `hyprctl clients -j` does
# NOT expose an "urgent" field at all (verified empirically — the key is
# absent, not false). Urgency only shows up as an `urgent>>ADDR` line on the
# IPC event socket (.socket2.sock). Waybar's own hyprland/workspaces module
# gets it the same way, over its own socket subscription. So this script has
# to stay running and listen, not poll.
#
# State: $STATE_FILE, one super-workspace bank number per line — the set of
# banks with at least one pending urgent window. bank_has_urgent() in
# super-workspace.sh reads this file.
#
# Clearing: mirrors how Hyprland clears urgency on focus for a single
# workspace — when the user focuses a workspace belonging to bank N (a
# `workspace>>` / `workspacev2>>` event for `super-N-*`), bank N is unmarked.
# Closing the urgent window without visiting its bank does NOT clear the
# mark (no per-window tracking, just a per-bank flag) — acceptable
# simplification, matches "you still haven't looked at it".
#
# Restarting this watcher loses marks set before the restart (no persisted
# window→bank map) until the next `urgent>>` event re-marks them.
set -euo pipefail
export PATH="/usr/local/bin:/usr/bin:/bin:${PATH:-}"

STATE_FILE="$HOME/.cache/hypr/super-workspace-urgent-banks"
mkdir -p "$(dirname "$STATE_FILE")"
touch "$STATE_FILE"

SOCK="${XDG_RUNTIME_DIR:?}/hypr/${HYPRLAND_INSTANCE_SIGNATURE:?}/.socket2.sock"

bank_of_workspace() {
  [[ "$1" =~ ^super-([0-9]+)- ]] && printf '%s' "${BASH_REMATCH[1]}"
}

mark_bank() {
  local bank="$1"
  grep -qxF "$bank" "$STATE_FILE" 2>/dev/null && return 0
  printf '%s\n' "$bank" >> "$STATE_FILE"
  pkill -SIGUSR2 waybar 2>/dev/null || true
}

unmark_bank() {
  local bank="$1" tmp
  grep -qxF "$bank" "$STATE_FILE" 2>/dev/null || return 0
  tmp="$(mktemp "${STATE_FILE}.XXXXXX")"
  grep -vxF "$bank" "$STATE_FILE" > "$tmp" || true
  mv "$tmp" "$STATE_FILE"
  pkill -SIGUSR2 waybar 2>/dev/null || true
}

# Respawn loop: socat exits if the Hyprland socket drops (compositor
# restart, VT switch races, etc). Keep listening instead of dying silently.
while true; do
  socat -u UNIX-CONNECT:"$SOCK" - | while IFS= read -r line; do
    event="${line%%>>*}"
    data="${line#*>>}"

    case "$event" in
      urgent)
        addr="0x${data}"
        wsname="$(hyprctl clients -j 2>/dev/null | jq -r --arg a "$addr" '[.[] | select(.address==$a) | .workspace.name][0] // empty')"
        [ -n "$wsname" ] || continue
        bank="$(bank_of_workspace "$wsname")"
        [ -n "$bank" ] && mark_bank "$bank"
        ;;
      workspace|workspacev2)
        wsname="${data##*,}"
        bank="$(bank_of_workspace "$wsname")"
        [ -n "$bank" ] && unmark_bank "$bank"
        ;;
    esac
  done || true
  sleep 1
done
