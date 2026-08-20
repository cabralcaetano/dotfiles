#!/usr/bin/env bash
set -euo pipefail

# Controls Spotify's own player volume (the slider inside the Spotify UI).
# During Brave/WhatsApp ducking, the desired Spotify volume is persisted in
# DUCK_STATE while the PipeWire stream stays capped at DUCK_LEVEL.

PLAYER="${SPOTIFY_PLAYER:-spotify}"
DUCK_LEVEL=30
DUCK_STATE="${XDG_RUNTIME_DIR:-/run/user/$UID}/spotify-duck-volume"
MUTE_STATE="${XDG_RUNTIME_DIR:-/run/user/$UID}/spotify-panel-volume-before-mute"

spotify_id() {
  pactl -f json list sink-inputs 2>/dev/null \
    | jq -r '.[] | select(.properties["application.name"] == "Spotify") | .properties["object.id"]' \
    | sed -n '1p'
}

clamp_pct() {
  awk -v pct="$1" 'BEGIN { pct = int(pct + 0.5); if (pct < 0) pct = 0; if (pct > 100) pct = 100; print pct }'
}

decimal_to_pct() {
  awk -v value="$1" 'BEGIN { printf "%d", value * 100 + 0.5 }'
}

pct_to_decimal() {
  awk -v pct="$1" 'BEGIN { printf "%.4f", pct / 100 }'
}

ducked_target_pct() {
  awk -v pct="$1" -v duck="$DUCK_LEVEL" 'BEGIN { printf "%d", (pct < duck ? pct : duck) }'
}

player_available() {
  playerctl -p "$PLAYER" status >/dev/null 2>&1
}

player_pct() {
  playerctl -p "$PLAYER" volume 2>/dev/null | awk '{ printf "%d", $1 * 100 + 0.5 }'
}

desired_pct() {
  if [ -f "$DUCK_STATE" ]; then
    decimal_to_pct "$(cat "$DUCK_STATE")"
  else
    player_pct
  fi
}

set_player_pct() {
  playerctl -p "$PLAYER" volume "$(pct_to_decimal "$1")"
}

set_stream_pct() {
  [ -n "${ID:-}" ] && wpctl set-volume -l 1 "$ID" "$1%"
}

cap_stream_if_ducked() {
  local pct actual
  [ -f "$DUCK_STATE" ] || return 0
  pct=$(desired_pct)
  actual=$(ducked_target_pct "$pct")
  set_stream_pct "$actual"
}

set_desired_pct() {
  local pct
  pct=$(clamp_pct "$1")
  set_player_pct "$pct"

  if [ -f "$DUCK_STATE" ]; then
    pct_to_decimal "$pct" > "$DUCK_STATE"
    cap_stream_if_ducked
  fi
}

toggle_mute() {
  local current restore
  current=$(desired_pct)

  if [ "$current" -gt 0 ]; then
    pct_to_decimal "$current" > "$MUTE_STATE"
    set_desired_pct 0
  else
    restore=$(decimal_to_pct "$(cat "$MUTE_STATE" 2>/dev/null || printf '0.5000')")
    set_desired_pct "$restore"
  fi
}

print_state() {
  local vol muted

  if ! player_available; then
    echo "-1|0"
    return
  fi

  vol=$(desired_pct)
  muted=0
  [ "${vol:-0}" -eq 0 ] && muted=1
  echo "${vol:-0}|$muted"
}

ID="$(spotify_id || true)"

case "${1:-get}" in
  up)
    player_available && set_desired_pct "$(($(desired_pct) + 5))"
    ;;
  down)
    player_available && set_desired_pct "$(($(desired_pct) - 5))"
    ;;
  set)
    PCT="${2:?uso: media-volume-spotify.sh set <0-100>}"
    player_available && set_desired_pct "$PCT"
    ;;
  mute)
    player_available && toggle_mute
    ;;
  get)
    ;;
  *)
    echo "uso: $0 {up|down|set <0-100>|mute|get}" >&2
    exit 1
    ;;
esac

print_state
