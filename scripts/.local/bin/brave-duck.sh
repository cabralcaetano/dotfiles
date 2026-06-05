#!/usr/bin/env bash
# Sem `-e`: o loop depende de comandos que retornam não-zero por design (grep sem match).
set -uo pipefail

DUCK_LEVEL=0.3
SPOTIFY_NORMAL=1.0
FADE_STEPS=15
FADE_DELAY=0.02
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

fade_out() {
  local id=$1
  local step=$(echo "scale=4; ($SPOTIFY_NORMAL - $DUCK_LEVEL) / $FADE_STEPS" | bc)
  local vol=$SPOTIFY_NORMAL
  for i in $(seq 1 $FADE_STEPS); do
    vol=$(echo "scale=4; $vol - $step" | bc)
    wpctl set-volume "$id" "$vol"
    sleep $FADE_DELAY
  done
  wpctl set-volume "$id" "$DUCK_LEVEL"
}

fade_in() {
  local id=$1
  local step=$(echo "scale=4; ($SPOTIFY_NORMAL - $DUCK_LEVEL) / $FADE_STEPS" | bc)
  local vol=$DUCK_LEVEL
  for i in $(seq 1 $FADE_STEPS); do
    vol=$(echo "scale=4; $vol + $step" | bc)
    wpctl set-volume "$id" "$vol"
    sleep $FADE_DELAY
  done
  wpctl set-volume "$id" "$SPOTIFY_NORMAL"
}

check_brave() {
  local brave_audio
  brave_audio=$(pactl list sink-inputs 2>/dev/null | awk '
    /^Entrada|^Sink Input/ {
      if (brave && playing) count++
      brave=0; playing=0
    }
    /application\.process\.binary.*"brave"/ { brave=1 }
    /Cork:.*não|Cork:.*no/ { playing=1 }
    END {
      if (brave && playing) count++
      print count+0
    }
  ')

  echo "${brave_audio:-0}"
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
