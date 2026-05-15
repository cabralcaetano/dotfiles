#!/bin/bash
if pgrep -x fuzzel > /dev/null; then
    pkill fuzzel
else
    export PATH="$PATH:/home/caetano/.local/bin"
    nmcli device wifi rescan 2>/dev/null &
    /home/caetano/.local/bin/networkmanager-dmenu
fi
