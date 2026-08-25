#!/usr/bin/env bash
# Uso: brave-profile.sh [--app|--browser] <profile> <slot ex: super-2-1> [url]
#
# Abre (ou foca, se já existir) uma janela do Brave num profile dedicado
# dentro do MESMO user-data-dir da instância principal. Perfis assim
# compartilham processo GPU, network service e zygote com o Brave que já
# está rodando — só o profile fica isolado (cookies/sessão/histórico),
# em vez de subir um engine de navegador inteiro (GPU/network/zygote
# duplicados) só para uma janela. Ver docs/hyprland-super-workspaces.md
# (seção "Perfis de navegador on-demand").
#
# Modo default/--app com [url]: abre em app-mode (--app=, sem chrome de
# abas/bookmarks). --browser com [url]: abre URL como aba/janela normal
# do profile, para uso como handler de links.
set -euo pipefail

MODE="app"
case "${1:-}" in
  --app)
    MODE="app"
    shift
    ;;
  --browser)
    MODE="browser"
    shift
    ;;
esac

DISPLAY_PROFILE="${1:?uso: brave-profile.sh [--app|--browser] <profile> <slot ex: super-2-1> [url]}"
SLOT="${2:?uso: brave-profile.sh [--app|--browser] <profile> <slot ex: super-2-1> [url]}"
URL="${3:-}"

BRAVE_USER_DATA_DIR="${BRAVE_USER_DATA_DIR:-$HOME/.config/BraveSoftware/Brave-Browser}"
LOCAL_STATE="$BRAVE_USER_DATA_DIR/Local State"

resolve_profile_dir() {
  local wanted="$1"
  if [ -f "$LOCAL_STATE" ]; then
    local resolved
    resolved="$(jq -r --arg wanted "$wanted" '
      .profile.info_cache // {}
      | to_entries
      | map(select(.value.name == $wanted))
      | .[0].key // empty
    ' "$LOCAL_STATE")"
    if [ -n "$resolved" ]; then
      printf '%s' "$resolved"
      return
    fi
  fi
  printf '%s' "$wanted"
}

PROFILE_DIR="$(resolve_profile_dir "$DISPLAY_PROFILE")"

# App-mode do Brave termina a classe com "__-<profile-directory>"
# (--profile-directory=Profile\ 1 --app=http://... -> "brave-<host>__-Profile 1").
# Browser-mode normal geralmente mantém class="brave-browser"; por isso o
# script também persiste o endereço da janela criada por profile directory.
CLASS_SUFFIX="__-${PROFILE_DIR}"
STATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/brave-profile-windows"
STATE_KEY="$(printf '%s' "$PROFILE_DIR" | tr -c 'A-Za-z0-9_.-' '_')"
STATE_FILE="$STATE_DIR/$STATE_KEY.address"
mkdir -p "$STATE_DIR"

client_exists() {
  local addr="$1"
  [ -n "$addr" ] && hyprctl clients -j | jq -e --arg addr "$addr" '.[] | select(.address == $addr)' >/dev/null
}

profile_window() {
  local stored=""
  [ -f "$STATE_FILE" ] && stored="$(cat "$STATE_FILE")"
  if client_exists "$stored"; then
    printf '%s' "$stored"
    return
  fi

  hyprctl clients -j | jq -r --arg suf "$CLASS_SUFFIX" \
    '[.[] | select(.class | endswith($suf)) | .address][0] // empty'
}

focus_and_place() {
  local addr="$1"
  printf '%s' "$addr" >"$STATE_FILE"
  hyprctl dispatch "hl.dsp.focus({ window = \"address:$addr\" })" >/dev/null
  hyprctl dispatch "hl.dsp.window.move({ workspace = \"name:$SLOT\" })" >/dev/null
}

launch_brave() {
  if [ "$MODE" = "browser" ]; then
    if [ -n "$URL" ]; then
      brave "--profile-directory=$PROFILE_DIR" "$URL" >/dev/null 2>&1 &
    else
      brave "--profile-directory=$PROFILE_DIR" --new-window >/dev/null 2>&1 &
    fi
  elif [ -n "$URL" ]; then
    brave "--profile-directory=$PROFILE_DIR" "--app=$URL" >/dev/null 2>&1 &
  else
    brave "--profile-directory=$PROFILE_DIR" --new-window >/dev/null 2>&1 &
  fi
}

existing="$(profile_window)"
if [ -n "$existing" ]; then
  if [ "$MODE" = "browser" ] && [ -n "$URL" ]; then
    launch_brave
  fi
  focus_and_place "$existing"
  exit 0
fi

orig_ws="$(hyprctl activeworkspace -j | jq -r '.name')"
before_addrs="$(hyprctl clients -j | jq -c '[.[].address]')"

launch_brave

new_addr=""
for _ in $(seq 1 40); do
  new_addr="$(hyprctl clients -j | jq -r --argjson before "$before_addrs" --arg suf "$CLASS_SUFFIX" '
    [.[] | select((.class == "brave-browser") or (.class | endswith($suf)))
          | select((.address as $addr | $before | index($addr)) | not)
          | .address][0] // empty
  ')"
  [ -n "$new_addr" ] && break
  sleep 0.25
done

if [ -z "$new_addr" ]; then
  echo "brave-profile.sh: janela do profile '$DISPLAY_PROFILE' (dir '$PROFILE_DIR') não apareceu a tempo" >&2
  exit 1
fi

focus_and_place "$new_addr"
hyprctl dispatch "hl.dsp.focus({ workspace = \"$orig_ws\" })" >/dev/null
