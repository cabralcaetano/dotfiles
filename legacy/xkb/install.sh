#!/bin/bash
# DEPRECATED — layout customizado us-br não está mais em uso.
# Substituído por layouts padrão br(abnt2) e us sem customizações.
# Não executar.

FILE=/usr/share/X11/xkb/symbols/us
SCRIPT_DIR="$(dirname "$0")"

if grep -q '"us-br"' "$FILE"; then
    echo "Variant us-br já instalado. Removendo versão antiga para atualizar..."
    # Remove as linhas do bloco us-br (da declaração partial até o '};' de fechamento)
    # Usa awk: descarta linhas entre o marcador de início e o '};' do bloco
    sudo awk '
        /partial.*alphanumeric_keys.*modifier_keys/{buf = $0; next}
        buf && /xkb_symbols "us-br"/{buf = buf "\n" $0; in_block = 1; depth = 0; next}
        in_block {
            for (i = 1; i <= length($0); i++) {
                c = substr($0, i, 1)
                if (c == "{") depth++
                if (c == "}") depth--
            }
            if (depth < 0) { in_block = 0; buf = "" }
            next
        }
        buf {print buf; buf = ""}
        {print}
    ' "$FILE" > /tmp/us-xkb-clean && sudo cp /tmp/us-xkb-clean "$FILE"
fi

sudo tee -a "$FILE" < "$SCRIPT_DIR/us-br.xkb"
echo "Instalado/atualizado. Rode: hyprctl reload"
