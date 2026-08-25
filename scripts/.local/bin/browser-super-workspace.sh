#!/usr/bin/env bash
# Uso: browser-super-workspace.sh [url]
#
# Roteia Super+B e links xdg-open pelo super workspace ativo:
# - SW1 usa Brave pessoal (swprofile1)
# - SW2+ usa Chromium dedicado aos super workspaces (swprofileN)
set -euo pipefail

URL="${1:-}"
BRAVE_PROFILE_CMD="${BRAVE_PROFILE_CMD:-$HOME/.local/bin/brave-profile.sh}"
CHROMIUM_PROFILE_CMD="${CHROMIUM_PROFILE_CMD:-$HOME/.local/bin/chromium-profile.sh}"
STATE_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/hypr/super-workspace"

current_sw() {
  local ws=""
  ws="$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.name // ""' 2>/dev/null || true)"
  if [[ "$ws" =~ ^(special:)?super-([0-9]+)- ]]; then
    printf '%s' "${BASH_REMATCH[2]}"
    return
  fi

  if [ -f "$STATE_FILE" ]; then
    tr -cd '0-9' <"$STATE_FILE"
    return
  fi

  printf '1'
}

sw="$(current_sw)"
profile="swprofile${sw}"
slot="super-${sw}-1"

if [ "$sw" = "1" ]; then
  if [ -n "$URL" ]; then
    exec "$BRAVE_PROFILE_CMD" --browser "$profile" "$slot" "$URL"
  fi
  exec "$BRAVE_PROFILE_CMD" --browser "$profile" "$slot"
fi

if [ -n "$URL" ]; then
  exec "$CHROMIUM_PROFILE_CMD" "$profile" "$slot" "$URL"
fi
exec "$CHROMIUM_PROFILE_CMD" "$profile" "$slot"
