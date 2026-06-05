#!/usr/bin/env bash
set -euo pipefail
if pgrep -x fuzzel > /dev/null; then
    pkill fuzzel
else
    export PATH="$PATH:$HOME/.local/bin"
    nmcli device wifi rescan 2>/dev/null &
    networkmanager-dmenu
fi
