#!/usr/bin/env bash
set -euo pipefail

prefs=${1:?usage: browser-tab-mover-sync-shortcuts.sh <Preferences>}
extension_id="lbbccpioeaehfbmgncdkoncheiebaeja"

mkdir -p "$(dirname "$prefs")"
input="$prefs"
tmp_input=""
if [ ! -s "$prefs" ]; then
  tmp_input="$(mktemp)"
  printf '{}\n' >"$tmp_input"
  input="$tmp_input"
fi

tmp="$(mktemp)"
jq --arg ext "$extension_id" '
  .extensions.commands = ((.extensions.commands // {}) + {
    "linux:Alt+Shift+H": {"command_name": "move-left", "extension": $ext, "global": false},
    "linux:Alt+Shift+L": {"command_name": "move-right", "extension": $ext, "global": false},
    "linux:Alt+Shift+1": {"command_name": "move-to-1", "extension": $ext, "global": false},
    "linux:Alt+Shift+2": {"command_name": "move-to-2", "extension": $ext, "global": false},
    "linux:Alt+Shift+3": {"command_name": "move-to-3", "extension": $ext, "global": false},
    "linux:Alt+Shift+4": {"command_name": "move-to-4", "extension": $ext, "global": false},
    "linux:Alt+Shift+5": {"command_name": "move-to-5", "extension": $ext, "global": false},
    "linux:Alt+Shift+6": {"command_name": "move-to-6", "extension": $ext, "global": false},
    "linux:Alt+Shift+7": {"command_name": "move-to-7", "extension": $ext, "global": false},
    "linux:Alt+Shift+8": {"command_name": "move-to-8", "extension": $ext, "global": false},
    "linux:Alt+Shift+9": {"command_name": "move-to-9", "extension": $ext, "global": false},
    "linux:Alt+Shift+0": {"command_name": "move-to-10", "extension": $ext, "global": false}
  })
' "$input" >"$tmp"
mv "$tmp" "$prefs"
[ -z "$tmp_input" ] || rm -f "$tmp_input"
