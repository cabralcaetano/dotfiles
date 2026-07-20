#!/usr/bin/env bash
# Sem `-e`: o loop depende de comandos que retornam não-zero por design (grep sem match).
set -uo pipefail

DUCK_LEVEL=0.3
SPOTIFY_NORMAL=1.0
FADE_STEPS=20
FADE_DELAY=0.03
is_ducked=false

get_spotify_id() {
  local spotify_client
  spotify_client=$(wpctl status | grep -i "spotify" | grep -oP '^\s+\K\d+' | head -1)
  [ -z "$spotify_client" ] && return

  pactl list sink-inputs 2>/dev/null | awk -v cid="\"$spotify_client\"" '
    /client\.id /  { matched = ($3 == cid) }
    /object\.id /  { if (matched) { gsub(/"/, "", $3); print $3; exit } }
  '
}

calc_volume() {
  awk -v start="$1" -v target="$2" -v step="$3" -v steps="$FADE_STEPS" \
    'BEGIN { printf "%.4f", start + ((target - start) * step / steps) }'
}

fade_volume() {
  local id=$1
  local start=$2
  local target=$3
  local vol

  for i in $(seq 1 "$FADE_STEPS"); do
    vol=$(calc_volume "$start" "$target" "$i")
    wpctl set-volume "$id" "$vol"
    sleep "$FADE_DELAY"
  done

  wpctl set-volume "$id" "$target"
}

fade_out() {
  fade_volume "$1" "$SPOTIFY_NORMAL" "$DUCK_LEVEL"
}

fade_in() {
  fade_volume "$1" "$DUCK_LEVEL" "$SPOTIFY_NORMAL"
}

resolve_hyprland_env() {
  [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] && return 0

  local socket sig
  for socket in "${XDG_RUNTIME_DIR:-/run/user/$UID}"/hypr/*/.socket.sock; do
    [ -S "$socket" ] || continue
    sig=${socket%/.socket.sock}
    sig=${sig##*/}
    export HYPRLAND_INSTANCE_SIGNATURE="$sig"
    return 0
  done

  return 1
}

has_whatsapp_brave_window() {
  resolve_hyprland_env || return 1

  hyprctl clients 2>/dev/null | awk '
    /^Window / {
      if (class ~ /brave/ && title ~ /whatsapp/) found = 1
      class = ""; title = ""
      next
    }
    /^[[:space:]]*class:/ {
      class = tolower($2)
      next
    }
    /^[[:space:]]*title:/ {
      sub(/^[[:space:]]*title:[[:space:]]*/, "", $0)
      title = tolower($0)
      next
    }
    END {
      if (class ~ /brave/ && title ~ /whatsapp/) found = 1
      exit found ? 0 : 1
    }
  '
}

check_brave() {
  local brave_audio
  brave_audio=$(pactl list sink-inputs 2>/dev/null | awk '
    /^Entrada|^Sink Input/ {
      if (brave && playing) count++
      brave=0; playing=0
    }
    /application\.process\.binary.*"brave"/ { brave=1 }
    /Cork(ed)?:.*(não|no)/ { playing=1 }
    END {
      if (brave && playing) count++
      print count+0
    }
  ')

  [ "${brave_audio:-0}" -eq 0 ] && echo 0 && return

  if has_whatsapp_brave_window; then
    echo "$brave_audio"
  else
    echo 0
  fi
}

brave_really_stopped() {
  for i in 1 2 3; do
    [ "$(check_brave)" -gt 0 ] && return 1
    sleep 0.3
  done
  return 0
}

while true; do
  SPOTIFY_ID=$(get_spotify_id)
  BRAVE_PLAYING=$(check_brave)

  if [ "$BRAVE_PLAYING" -gt 0 ] && [ "$is_ducked" = "false" ] && [ -n "$SPOTIFY_ID" ]; then
    echo "$(date +%T.%N) - Brave tocando, fade_out"
    fade_out "$SPOTIFY_ID"
    is_ducked=true
  elif [ "$BRAVE_PLAYING" -eq 0 ] && [ "$is_ducked" = "true" ]; then
    if brave_really_stopped; then
      echo "$(date +%T.%N) - Brave parou, fade_in"
      SPOTIFY_ID=$(get_spotify_id)
      [ -n "$SPOTIFY_ID" ] && fade_in "$SPOTIFY_ID"
      echo "$(date +%T.%N) - fade_in concluido"
      is_ducked=false
    fi
  fi

  sleep 0.5
done
