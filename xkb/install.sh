#!/bin/bash
# Instala o variant us-br no arquivo XKB do sistema.
# Requer sudo. Roda uma vez após instalar o sistema.

FILE=/usr/share/X11/xkb/symbols/us

if grep -q '"us-br"' "$FILE"; then
    echo "Variant us-br já instalado."
    exit 0
fi

sudo tee -a "$FILE" < "$(dirname "$0")/us-br.xkb"
echo "Instalado. Rode: hyprctl reload"
