#!/usr/bin/env bash
set -euo pipefail

CONFIG_NAME="clock-panel"
TARGET="clockPanel"

if ! qs -c "$CONFIG_NAME" list 2>/dev/null | grep -q "^Instance "; then
  qs -c "$CONFIG_NAME" --no-duplicate --daemonize
  sleep 0.15
fi

qs ipc -c "$CONFIG_NAME" call "$TARGET" toggle
