#!/usr/bin/env bash
# Sem `-e`: o loop depende de comandos que retornam não-zero por design (grep sem match).
set -uo pipefail

DUCK_LEVEL=0.3
FADE_STEPS=20
FADE_DELAY=0.03
is_ducked=false
saved_spotifast_volume=""
DUCK_STATE="${XDG_RUNTIME_DIR:-/run/user/$UID}/spotifast-duck-volume"



get_spotifast_id() {
  local spotifast_client
  spotifast_client=$(wpctl status | grep -i "spotifast" | grep -oP '^\s+\K\d+' | head -1)
  [ -z "$spotifast_client" ] && return

  pactl list sink-inputs 2>/dev/null | awk -v cid="\"$spotifast_client\"" '
    /client\.id /  { matched = ($3 == cid) }
    /object\.id /  { if (matched) { gsub(/"/, "", $3); print $3; exit } }
  '
}

get_spotifast_volume() {
  wpctl get-volume "$1" 2>/dev/null | awk '/^Volume:/ { print $2; exit }'
}

duck_target_volume() {
  awk -v current="$1" -v duck="$DUCK_LEVEL" \
    'BEGIN { printf "%.4f", (current < duck ? current : duck) }'
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
  local current=$2
  local target
  target=$(duck_target_volume "$current")
  fade_volume "$1" "$current" "$target"
}

fade_in() {
  local current=$2
  local target=$3
  fade_volume "$1" "$current" "$target"
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

has_whatsapp_chromium_window() {
  resolve_hyprland_env || return 1

  hyprctl clients 2>/dev/null | awk '
    /^Window / {
      if (class ~ /chromium/ && title ~ /whatsapp/) found = 1
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
      if (class ~ /chromium/ && title ~ /whatsapp/) found = 1
      exit found ? 0 : 1
    }
  '
}

check_chromium() {
  local chromium_audio
  chromium_audio=$(LC_ALL=C pactl list sink-inputs 2>/dev/null | awk '
    /^Sink Input/ {
      if (chromium && playing) count++
      chromium=0; playing=0
    }
    /application\.process\.binary.*"chromium"/ { chromium=1 }
    /Cork(ed)?:.*(não|no)/ { playing=1 }
    END {
      if (chromium && playing) count++
      print count+0
    }
  ')

  [ "${chromium_audio:-0}" -eq 0 ] && echo 0 && return

  if has_whatsapp_chromium_window; then
    echo "$chromium_audio"
  else
    echo 0
  fi
}

chromium_really_stopped() {
  for i in 1 2 3; do
    [ "$(check_chromium)" -gt 0 ] && return 1
    sleep 0.3
  done
  return 0
}

while true; do
  SPOTIFAST_ID=$(get_spotifast_id)
  CHROMIUM_PLAYING=$(check_chromium)

  if [ "$CHROMIUM_PLAYING" -gt 0 ] && [ "$is_ducked" = "false" ] && [ -n "$SPOTIFAST_ID" ]; then
    saved_spotifast_volume=$(get_spotifast_volume "$SPOTIFAST_ID")
    if [ -n "$saved_spotifast_volume" ]; then
      printf '%s\n' "$saved_spotifast_volume" > "$DUCK_STATE"
      echo "$(date +%T.%N) - Chromium tocando, fade_out para preservar volume $saved_spotifast_volume"
      fade_out "$SPOTIFAST_ID" "$saved_spotifast_volume"
      is_ducked=true
    fi
  elif [ "$CHROMIUM_PLAYING" -eq 0 ] && [ "$is_ducked" = "true" ]; then
    if chromium_really_stopped; then
      if [ -f "$DUCK_STATE" ]; then
        saved_spotifast_volume=$(cat "$DUCK_STATE")
      fi
      echo "$(date +%T.%N) - Chromium parou, fade_in para $saved_spotifast_volume"
      SPOTIFAST_ID=$(get_spotifast_id)
      if [ -n "$SPOTIFAST_ID" ] && [ -n "$saved_spotifast_volume" ]; then
        current_spotifast_volume=$(get_spotifast_volume "$SPOTIFAST_ID")
        [ -n "$current_spotifast_volume" ] && fade_in "$SPOTIFAST_ID" "$current_spotifast_volume" "$saved_spotifast_volume"
      fi
      echo "$(date +%T.%N) - fade_in concluido"
      rm -f "$DUCK_STATE"
      saved_spotifast_volume=""
      is_ducked=false
    fi
  fi

  sleep 0.5
done
