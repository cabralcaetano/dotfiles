#!/usr/bin/env bash
# Uso: chromium-profile.sh <profile ex: swprofile2> <slot ex: super-2-1> [url]
#
# Abre/foca uma janela Chromium para super workspaces não pessoais. Usa um
# user-data-dir dedicado aos super workspaces para isolar do Brave pessoal.
# Profiles diferentes compartilham o mesmo processo Chromium quando possível;
# o banner de debug/relay fica fora do Brave do SW1.
set -euo pipefail

PROFILE="${1:?uso: chromium-profile.sh <profile ex: swprofile2> <slot ex: super-2-1> [url]}"
SLOT="${2:?uso: chromium-profile.sh <profile ex: swprofile2> <slot ex: super-2-1> [url]}"
URL="${3:-}"
USER_DATA_DIR="${CHROMIUM_SW_USER_DATA_DIR:-$HOME/.config/chromium-super-workspaces}"
STATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/chromium-profile-windows"
STATE_KEY="$(printf '%s' "$PROFILE" | tr -c 'A-Za-z0-9_.-' '_')"
STATE_FILE="$STATE_DIR/$STATE_KEY.address"
mkdir -p "$USER_DATA_DIR" "$STATE_DIR"

client_exists() {
  local addr="$1"
  [ -n "$addr" ] && hyprctl clients -j | jq -e --arg addr "$addr" '.[] | select(.address == $addr)' >/dev/null
}

profile_window() {
  local stored=""
  [ -f "$STATE_FILE" ] && stored="$(cat "$STATE_FILE")"
  if client_exists "$stored"; then
    printf '%s' "$stored"
  fi
}

focus_and_place() {
  local addr="$1"
  printf '%s' "$addr" >"$STATE_FILE"
  hyprctl dispatch "hl.dsp.focus({ window = \"address:$addr\" })" >/dev/null
  hyprctl dispatch "hl.dsp.window.move({ workspace = \"name:$SLOT\" })" >/dev/null
}

launch_chromium() {
  local args=(
    "--user-data-dir=$USER_DATA_DIR"
    "--profile-directory=$PROFILE"
    "--no-first-run"
    "--no-default-browser-check"
  )

  if [ -n "$URL" ]; then
    chromium "${args[@]}" "$URL" >/dev/null 2>&1 &
  else
    chromium "${args[@]}" --new-window >/dev/null 2>&1 &
  fi
}

existing="$(profile_window)"
if [ -n "$existing" ]; then
  if [ -n "$URL" ]; then
    launch_chromium
  fi
  focus_and_place "$existing"
  exit 0
fi

orig_ws="$(hyprctl activeworkspace -j | jq -r '.name')"
before_addrs="$(hyprctl clients -j | jq -c '[.[].address]')"

launch_chromium

new_addr=""
for _ in $(seq 1 40); do
  new_addr="$(hyprctl clients -j | jq -r --argjson before "$before_addrs" '
    [.[] | select(.class == "chromium")
          | select((.address as $addr | $before | index($addr)) | not)
          | .address][0] // empty
  ')"
  [ -n "$new_addr" ] && break
  sleep 0.25
done

if [ -z "$new_addr" ]; then
  echo "chromium-profile.sh: janela do profile '$PROFILE' não apareceu a tempo" >&2
  exit 1
fi

focus_and_place "$new_addr"
hyprctl dispatch "hl.dsp.focus({ workspace = \"$orig_ws\" })" >/dev/null
