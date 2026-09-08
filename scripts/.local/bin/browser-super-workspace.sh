#!/usr/bin/env bash
# Uso: browser-super-workspace.sh [url]
#
# Abre o Zen Browser para Super+B e para handlers que ainda chamam este wrapper.
# O default XDG direto fica em zen.desktop; este script continua como alvo estável
# do bind do Hyprland e de chamadas manuais.
set -euo pipefail

URL="${1:-}"
ZEN_CMD="${ZEN_CMD:-$HOME/.local/bin/zen}"

if [ -n "$URL" ]; then
  exec "$ZEN_CMD" "$URL"
fi

exec "$ZEN_CMD" --new-window
