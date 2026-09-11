#!/usr/bin/env bash
# Instala o helper root do battery-conservation (/usr/local/sbin/battery-conservation-root),
# a unit de sistema e a regra de sudoers.
# Uso: install-battery-conservation-root.sh [usuario]
# Sem argumento, o usuário da regra de sudoers é derivado de $SUDO_USER.
set -euo pipefail

if [ "${EUID:-$(id -u)}" -ne 0 ]; then
    exec sudo "$0" "$@"
fi

# Usuário que ganha o NOPASSWD: argumento explícito ou quem chamou o sudo.
# Nunca um nome fixo — o repo é usado por mais de uma máquina/conta.
TARGET_USER="${1:-${SUDO_USER:-}}"
if [ -z "$TARGET_USER" ] || [ "$TARGET_USER" = "root" ]; then
    echo "Não consegui determinar o usuário para a regra de sudoers." >&2
    echo "Rode via sudo a partir da sua conta, ou passe o usuário: $0 <usuario>" >&2
    exit 1
fi
if ! id -u -- "$TARGET_USER" >/dev/null 2>&1; then
    echo "Usuário inexistente: $TARGET_USER" >&2
    exit 1
fi
case "$TARGET_USER" in
    *[!a-zA-Z0-9._-]*)
        echo "Nome de usuário inválido para sudoers: $TARGET_USER" >&2
        exit 1
        ;;
esac

SCRIPT_PATH="$(readlink -f -- "${BASH_SOURCE[0]}")"
BIN_DIR="$(cd -- "$(dirname -- "$SCRIPT_PATH")" && pwd)"
BATTERY_SHARE_DIR="$(cd -- "$BIN_DIR/../share/battery-conservation" && pwd)"
ROOT_HELPER_SRC="$BATTERY_SHARE_DIR/battery-conservation-root"
ROOT_HELPER_DST="/usr/local/sbin/battery-conservation-root"
SERVICE_SRC="$BATTERY_SHARE_DIR/battery-conservation.service"
SERVICE_DST="/etc/systemd/system/battery-conservation.service"
SUDOERS_FILE="/etc/sudoers.d/battery-conservation"
SUDOERS_LINE="$TARGET_USER ALL=(root) NOPASSWD: $ROOT_HELPER_DST enable, $ROOT_HELPER_DST disable"

install -o root -g root -m 0755 "$ROOT_HELPER_SRC" "$ROOT_HELPER_DST"
install -o root -g root -m 0644 "$SERVICE_SRC" "$SERVICE_DST"

# Valida antes de publicar: um sudoers.d inválido quebra o sudo da máquina.
SUDOERS_TMP="$(mktemp)"
trap 'rm -f "$SUDOERS_TMP"' EXIT
printf '%s\n' "$SUDOERS_LINE" > "$SUDOERS_TMP"
visudo -cf "$SUDOERS_TMP" >/dev/null
install -o root -g root -m 0440 "$SUDOERS_TMP" "$SUDOERS_FILE"

systemctl daemon-reload

echo "Installed $ROOT_HELPER_DST"
echo "Installed $SERVICE_DST"
echo "Installed $SUDOERS_FILE"
