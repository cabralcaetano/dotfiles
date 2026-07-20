#!/usr/bin/env bash
set -euo pipefail

if [ "${EUID:-$(id -u)}" -ne 0 ]; then
    exec sudo "$0" "$@"
fi

SCRIPT_PATH="$(readlink -f -- "${BASH_SOURCE[0]}")"
BIN_DIR="$(cd -- "$(dirname -- "$SCRIPT_PATH")" && pwd)"
BATTERY_SHARE_DIR="$(cd -- "$BIN_DIR/../share/battery-conservation" && pwd)"
ROOT_HELPER_SRC="$BATTERY_SHARE_DIR/battery-conservation-root"
ROOT_HELPER_DST="/usr/local/sbin/battery-conservation-root"
SERVICE_SRC="$BATTERY_SHARE_DIR/battery-conservation.service"
SERVICE_DST="/etc/systemd/system/battery-conservation.service"
SUDOERS_FILE="/etc/sudoers.d/battery-conservation"
SUDOERS_LINE="caetano ALL=(root) NOPASSWD: $ROOT_HELPER_DST enable, $ROOT_HELPER_DST disable"

install -o root -g root -m 0755 "$ROOT_HELPER_SRC" "$ROOT_HELPER_DST"
install -o root -g root -m 0644 "$SERVICE_SRC" "$SERVICE_DST"
printf '%s\n' "$SUDOERS_LINE" > "$SUDOERS_FILE"
chmod 0440 "$SUDOERS_FILE"
visudo -cf "$SUDOERS_FILE" >/dev/null
systemctl daemon-reload

echo "Installed $ROOT_HELPER_DST"
echo "Installed $SERVICE_DST"
echo "Installed $SUDOERS_FILE"
