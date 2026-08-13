#!/usr/bin/env bash
# Super workspaces: independent banks of numbered workspaces (1-9/0), each
# with its own scratchpad. User-facing identity is numeric only: super
# workspace 1, super workspace 2, ...
#
# Mechanism: the active super workspace number is persisted in $STATE_FILE; the
# last focused slot of each super workspace is persisted under $SLOT_STATE_DIR.
# SUPER+N and SUPER+SHIFT+N binds call this script instead of a raw workspace
# number, so they always resolve to name:super-<sw>-<n>. The Hyprland internal
# name is only a collision-free target; notifications and waybar expose only the numeric super workspace and its icon.
#
# Waybar: on next/prev/sync this rewrites the "ignore-workspaces" regex in
# config.jsonc (plain sed — JSONC comments must survive) and reloads the bar
# via SIGUSR2, so hyprland/workspaces only shows slots for the active super
# workspace. custom/super-workspace chama "waybar" e recebe text+tooltip.
#
# Usage:
#   super-workspace.sh focus <n>            focus name:super-<sw>-<n>
#   super-workspace.sh move <n>             move focused window to name:super-<sw>-<n>
#   super-workspace.sh scratchpad           toggle special:super-<sw>-magic
#   super-workspace.sh scratchpad-move      move focused window to special:super-<sw>-magic
#   super-workspace.sh next|prev            cycle active super workspace, restore its last slot
#   super-workspace.sh move-super <next|prev>  move focused window to same
#                                               slot in neighboring super workspace, and follow it there
#   super-workspace.sh sync-waybar|icon|waybar
set -euo pipefail
export PATH="/usr/local/bin:/usr/bin:/bin:${PATH:-}"

LIST_FILE="$HOME/.config/hypr/super-workspaces.txt"
STATE_FILE="$HOME/.cache/hypr/super-workspace"
SLOT_STATE_DIR="$HOME/.cache/hypr/super-workspace-slots"
WAYBAR_CONFIG="$HOME/.config/waybar/config.jsonc"
mkdir -p "$(dirname "$STATE_FILE")" "$SLOT_STATE_DIR"

mapfile -t SUPER_WORKSPACES < "$LIST_FILE"
[ "${#SUPER_WORKSPACES[@]}" -gt 0 ] || { notify-send "Super workspace" "lista vazia"; exit 1; }

current_sw() {
  if [ -f "$STATE_FILE" ] && grep -qxF "$(cat "$STATE_FILE")" <<<"$(printf '%s\n' "${SUPER_WORKSPACES[@]}")"; then
    cat "$STATE_FILE"
  else
    printf '%s' "${SUPER_WORKSPACES[0]}"
  fi
}

index_of() {
  local target="$1" i
  for i in "${!SUPER_WORKSPACES[@]}"; do
    [ "${SUPER_WORKSPACES[$i]}" = "$target" ] && { printf '%s' "$i"; return; }
  done
  printf '0'
}

neighbor_sw() {
  local dir="$1" idx n
  idx=$(index_of "$SW")
  n=${#SUPER_WORKSPACES[@]}
  if [ "$dir" = next ]; then
    idx=$(( (idx + 1) % n ))
  else
    idx=$(( (idx - 1 + n) % n ))
  fi
  printf '%s' "${SUPER_WORKSPACES[$idx]}"
}

slot_state_file() {
  local safe="${1//\//_}"
  printf '%s/%s' "$SLOT_STATE_DIR" "$safe"
}

active_slot_for() {
  local sw="$1" active pattern
  active="$(hyprctl activeworkspace 2>/dev/null || true)"
  pattern="\\($(workspace_name "$sw" '([0-9]+)')\\)"

  if [[ "$active" =~ $pattern ]]; then
    printf '%s' "${BASH_REMATCH[1]}"
  fi
}

remember_slot() {
  local sw="$1" slot
  slot="$(active_slot_for "$sw")"
  if [ -n "$slot" ]; then
    printf '%s' "$slot" > "$(slot_state_file "$sw")"
  fi
}

saved_slot_for() {
  local sw="$1" file slot
  file="$(slot_state_file "$sw")"
  if [ -f "$file" ]; then
    read -r slot < "$file" || true
    case "$slot" in
      [1-9]|10) printf '%s' "$slot"; return ;;
    esac
  fi

  printf '1'
}

workspace_name() {
  printf 'super-%s-%s' "$1" "$2"
}

scratchpad_name() {
  printf 'super-%s-magic' "$1"
}

# Ícone por número de super workspace. Sem nome textual na waybar.
icon_for() {
  case "$1" in
    1) printf '\uee15' ;;  # fa-skull
    2) printf '\uebc6' ;;  # cod-terminal_linux
    3) printf '\uea8b' ;;  # cod-symbol_namespace
    4) printf '\uea85' ;;  # cod-terminal
    5) printf '\uebc4' ;;  # cod-terminal_cmd
    *) printf '\uf111' ;;  # nf-fa-circle (fallback)
  esac
}

waybar_payload() {
  local tooltip="" item line text
  text="$(icon_for "$SW")"

  for item in "${SUPER_WORKSPACES[@]}"; do
    line="$(icon_for "$item") $item"
    if [ "$item" = "$SW" ]; then
      line="• $line"
    else
      line="  $line"
    fi

    if [ -z "$tooltip" ]; then
      tooltip="$line"
    else
      tooltip="${tooltip}\\n${line}"
    fi
  done

  printf '{"text":"%s","tooltip":"%s"}\n' "$text" "$tooltip"
}


sync_waybar() {
  local sw="$1"
  [ -f "$WAYBAR_CONFIG" ] || return 0
  sed -i "s|\"ignore-workspaces\":.*|\"ignore-workspaces\": [\"^(?!super-${sw}-).*\$\"],|" "$WAYBAR_CONFIG"
  pkill -SIGUSR2 waybar 2>/dev/null || true
}

cmd="${1:-}"; [ $# -gt 0 ] && shift
SW="$(current_sw)"

case "$cmd" in
  focus)
    hyprctl dispatch "hl.dsp.focus({ workspace = \"name:$(workspace_name "$SW" "$1")\" })" >/dev/null
    printf '%s' "$1" > "$(slot_state_file "$SW")"
    ;;
  move)
    hyprctl dispatch "hl.dsp.window.move({ workspace = \"name:$(workspace_name "$SW" "$1")\" })" >/dev/null
    ;;
  scratchpad)
    hyprctl dispatch "hl.dsp.workspace.toggle_special(\"$(scratchpad_name "$SW")\")" >/dev/null
    ;;
  scratchpad-move)
    hyprctl dispatch "hl.dsp.window.move({ workspace = \"special:$(scratchpad_name "$SW")\" })" >/dev/null
    ;;
  move-super)
    dir="${1:-next}"
    case "$dir" in
      next|prev) ;;
      *) echo "usage: super-workspace.sh move-super {next|prev}" >&2; exit 1 ;;
    esac
    NEW="$(neighbor_sw "$dir")"
    SLOT="$(active_slot_for "$SW")"
    [ -n "$SLOT" ] || SLOT="$(saved_slot_for "$SW")"
    hyprctl dispatch "hl.dsp.window.move({ workspace = \"name:$(workspace_name "$NEW" "$SLOT")\" })" >/dev/null
    printf '%s' "$SLOT" > "$(slot_state_file "$NEW")"
    printf '%s' "$NEW" > "$STATE_FILE"
    hyprctl dispatch "hl.dsp.focus({ workspace = \"name:$(workspace_name "$NEW" "$SLOT")\" })" >/dev/null
    sync_waybar "$NEW"
    notify-send -t 1200 "Super workspace" "$NEW"
    ;;
  next|prev)
    remember_slot "$SW"

    NEW="$(neighbor_sw "$cmd")"
    SLOT="$(saved_slot_for "$NEW")"
    printf '%s' "$NEW" > "$STATE_FILE"
    hyprctl dispatch "hl.dsp.focus({ workspace = \"name:$(workspace_name "$NEW" "$SLOT")\" })" >/dev/null
    printf '%s' "$SLOT" > "$(slot_state_file "$NEW")"
    sync_waybar "$NEW"
    notify-send -t 1200 "Super workspace" "$NEW"
    ;;
  sync-waybar)
    sync_waybar "$SW"
    ;;
  icon)
    icon_for "${1:-$SW}"
    ;;
  waybar)
    waybar_payload
    ;;
  *)
    echo "usage: super-workspace.sh {focus|move|move-super|scratchpad|scratchpad-move|next|prev|sync-waybar|icon|waybar} [n]" >&2
    exit 1
    ;;
esac
