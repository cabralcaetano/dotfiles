#!/usr/bin/env bash
# Super workspaces: independent banks of numbered workspaces (1-9/0), each
# with its own scratchpad. User-facing identity stays numeric; Waybar symbols
# come from icon_for().
#
# Mechanism: the active super workspace number is persisted in $STATE_FILE; the
# last focused slot of each super workspace is persisted under $SLOT_STATE_DIR.
# SUPER+N and SUPER+SHIFT+N binds call this script instead of a raw workspace
# number, so they always resolve to name:super-<sw>-<n>. The Hyprland internal
# name is only a collision-free target; notifications and Waybar expose the
# numeric super workspace and its configured symbol.
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
#   super-workspace.sh switch <sw>          switch directly to a specific super workspace
#   super-workspace.sh move-super <next|prev>  move focused window to same
#                                               slot in neighboring super workspace, and follow it there
#   super-workspace.sh sync-waybar|icon|waybar
set -euo pipefail
export PATH="/usr/local/bin:/usr/bin:/bin:${PATH:-}"

LIST_FILE="$HOME/.config/hypr/super-workspaces.txt"
STATE_FILE="$HOME/.cache/hypr/super-workspace"
URGENT_STATE_FILE="$HOME/.cache/hypr/super-workspace-urgent-banks"
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

known_sw() {
  local target="$1" item
  for item in "${SUPER_WORKSPACES[@]}"; do
    [ "$item" = "$target" ] && return 0
  done
  return 1
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

# Igual neighbor_sw(), mas só considera bancos com janela aberta
# (bank_has_windows) — usado por next/prev (SUPER+Tab), não por move-super
# (que precisa alcançar bancos vazios pra poder popular eles pela primeira
# vez). Sem nenhum banco ativo, cai pro par 1/2.
active_neighbor_sw() {
  local dir="$1" item idx=-1 n i
  local -a pool=()
  for item in "${SUPER_WORKSPACES[@]}"; do
    bank_has_windows "$item" && pool+=("$item")
  done
  [ "${#pool[@]}" -eq 0 ] && pool=(1 2)

  for i in "${!pool[@]}"; do
    [ "${pool[$i]}" = "$SW" ] && { idx=$i; break; }
  done

  n=${#pool[@]}
  if [ "$idx" -eq -1 ]; then
    if [ "$dir" = next ]; then idx=0; else idx=$((n - 1)); fi
  elif [ "$dir" = next ]; then
    idx=$(( (idx + 1) % n ))
  else
    idx=$(( (idx - 1 + n) % n ))
  fi
  printf '%s' "${pool[$idx]}"
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

# Um cliente urgente (Hyprland urgent hint) num banco que não é o ativo fica
# invisível pro usuário — hyprland/workspaces só mostra os slots do banco
# atual (ignore-workspaces). bank_has_urgent() lê $URGENT_STATE_FILE, mantido
# por super-workspace-urgent-watch.sh: hyprctl clients -j NÃO expõe campo
# "urgent" nesse build do Hyprland (0.56.2) — só existe como evento
# `urgent>>ADDR` no socket2, então precisa de um listener em background, não
# dá pra fazer polling.
bank_has_urgent() {
  local sw="$1"
  [ -f "$URGENT_STATE_FILE" ] && grep -qxF "$sw" "$URGENT_STATE_FILE"
}

# Banco tem pelo menos uma janela aberta em algum slot (super-<sw>-*)? Usado
# pra filtrar o tooltip — só lista bancos com conteúdo, não os 5 sempre.
bank_has_windows() {
  local sw="$1"
  hyprctl clients -j 2>/dev/null \
    | jq -e --arg pfx "super-${sw}-" \
        '[.[] | select(.workspace.name | startswith($pfx))] | length > 0' \
        >/dev/null 2>&1
}

# Símbolo por número de super workspace. Mapa escolhido: 1=">", 2="~",
# 3="=", 4="^", 5="*".
icon_for() {
  case "$1" in
    1) printf '>' ;;
    2) printf '~' ;;
    3) printf '=' ;;
    4) printf '^' ;;
    5) printf '*' ;;
    *) printf '%s' "$1" ;;
  esac
}

waybar_payload() {
  local text class="[]" item tooltip=""
  # Waybar só mostra tooltip sobre a área real do label, não sobre padding CSS.
  # Espaços dos dois lados mantêm o hover/click no canto e tiram o símbolo da borda.
  text=" $(icon_for "$SW")  "

  # Tooltip: banco ativo sempre aparece (marcado com •); os outros só entram
  # se tiverem janela aberta (bank_has_windows) — não lista os 5 à toa. Lista
  # completa sempre disponível no menu (super-workspace.sh menu).
  for item in "${SUPER_WORKSPACES[@]}"; do
    local line=""
    if [ "$item" = "$SW" ]; then
      line="• $(icon_for "$item") $item"
    elif bank_has_windows "$item"; then
      line="  $(icon_for "$item") $item"
      if bank_has_urgent "$item"; then
        line="$line !"
        class='["urgent"]'
      fi
    else
      continue
    fi
    if [ -z "$tooltip" ]; then
      tooltip="$line"
    else
      tooltip="${tooltip}\\r${line}"
    fi
  done

  printf '{"text":"%s","tooltip":"%s","class":%s}\n' "$text" "$tooltip" "$class"
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
  switch)
    NEW="${1:-}"
    if ! known_sw "$NEW"; then
      echo "usage: super-workspace.sh switch <super-workspace>" >&2
      exit 1
    fi
    remember_slot "$SW"
    SLOT="$(saved_slot_for "$NEW")"
    printf '%s' "$NEW" > "$STATE_FILE"
    hyprctl dispatch "hl.dsp.focus({ workspace = \"name:$(workspace_name "$NEW" "$SLOT")\" })" >/dev/null
    printf '%s' "$SLOT" > "$(slot_state_file "$NEW")"
    sync_waybar "$NEW"
    notify-send -t 1200 "Super workspace" "$NEW"
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

    NEW="$(active_neighbor_sw "$cmd")"
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
  menu)
    CHOICE=$(
      for item in "${SUPER_WORKSPACES[@]}"; do
        mark=" "
        [ "$item" = "$SW" ] && mark="•"
        printf '%s %s %s\n' "$mark" "$(icon_for "$item")" "$item"
      done | fuzzel --dmenu --prompt "Super workspace: "
    )
    [ -n "$CHOICE" ] || exit 0
    NEW="${CHOICE##* }"
    known_sw "$NEW" || exit 0
    exec "$0" switch "$NEW"
    ;;
  icon)
    icon_for "${1:-$SW}"
    ;;
  waybar)
    waybar_payload
    ;;
  *)
    echo "usage: super-workspace.sh {focus|move|move-super|switch|scratchpad|scratchpad-move|next|prev|menu|sync-waybar|icon|waybar} [n]" >&2
    exit 1
    ;;
esac
