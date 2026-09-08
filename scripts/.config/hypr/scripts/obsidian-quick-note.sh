#!/usr/bin/env bash
# Abre o vault "obsidian-scratch" com uma nota sem título nova e força a
# janela a abrir flutuante, centralizada e num tamanho de bloco de notas.
#
# Existe porque o windowrule de título (obsidian-scratch-float) só floata
# janelas cujo título já nasce formado (ex: o diálogo de Configurações).
# A janela principal do Obsidian abre com título genérico "Obsidian" e só
# ganha o nome do vault no título depois de mapeada — e essa mudança de
# título não retroage sobre uma janela já colocada em tiling. Por isso o
# float é forçado aqui via dispatch direto, mirando a janela pelo address.
set -euo pipefail

before=$(hyprctl clients -j | jq -r '.[] | select(.class=="obsidian") | .address')

flatpak run md.obsidian.Obsidian "obsidian://new?vault=obsidian-scratch" &
disown

for _ in $(seq 1 60); do
    sleep 0.2
    if [ -z "$before" ]; then
        addr=$(hyprctl clients -j | jq -r '.[] | select(.class=="obsidian") | .address' | head -1)
    else
        addr=$(hyprctl clients -j | jq -r '.[] | select(.class=="obsidian") | .address' \
            | grep -vFxf <(printf '%s\n' "$before") | head -1 || true)
    fi
    if [ -n "${addr:-}" ]; then
        sel="address:$addr"
        hyprctl dispatch "hl.dsp.focus({ window = '$sel' })" >/dev/null
        hyprctl dispatch "hl.dsp.window.float({ window = '$sel' })" >/dev/null
        hyprctl dispatch "hl.dsp.window.resize({ x = 760, y = 620, window = '$sel' })" >/dev/null
        hyprctl dispatch "hl.dsp.window.center()" >/dev/null
        break
    fi
done
