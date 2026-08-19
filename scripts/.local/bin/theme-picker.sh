#!/usr/bin/env bash
set -euo pipefail

CONFIG_NAME="theme-picker"
CLOCK_CONFIG_NAME="clock-panel"
CLOCK_TARGET="clockPanel"

TARGET="themePicker"
if ! qs -c "$CONFIG_NAME" list 2>/dev/null | grep -q "^Instance "; then
    qs -c "$CONFIG_NAME" --no-duplicate --daemonize
    sleep 0.15
fi
if qs -c "$CLOCK_CONFIG_NAME" list 2>/dev/null | grep -q "^Instance "; then
    qs ipc -c "$CLOCK_CONFIG_NAME" call "$CLOCK_TARGET" hide >/dev/null 2>&1 || true
fi


qs ipc -c "$CONFIG_NAME" call "$TARGET" open
