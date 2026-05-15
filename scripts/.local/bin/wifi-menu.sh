#!/bin/bash
nmcli device wifi rescan 2>/dev/null
sleep 2
networkmanager-dmenu
