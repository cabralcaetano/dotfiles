#!/usr/bin/env bash
# tmux-reopen-window.sh — chamado pelo bind de Ctrl+Shift+T (tmux.conf).
# Desempilha a última janela fechada via Ctrl+W (tmux-close-window.sh) e
# reabre no mesmo diretório, rerodando o comando que estava ativo (se não
# era só o shell parado no prompt). Não restaura o estado do processo em si
# (scrollback, buffers de vim, sessão ssh) — só diretório + comando, igual
# "reopen closed tab" de navegador só recarrega a URL, não o estado JS da
# página. Uso: tmux-reopen-window.sh
set -euo pipefail

STACK="$HOME/.tmux/closed-windows.stack"

if [ ! -s "$STACK" ]; then
    tmux new-window
    exit 0
fi

last=$(tail -n 1 "$STACK")
sed -i '$d' "$STACK"

# \x1f (unit separator), não tab — ver comentário em tmux-close-window.sh.
IFS=$'\x1f' read -r dir cmd name <<< "$last"
[ -d "$dir" ] || dir="$HOME"

idx=$(tmux new-window -c "$dir" -n "$name" -P -F '#{window_index}')

if [ -n "$cmd" ]; then
    tmux send-keys -t ":$idx" "$cmd" Enter
fi
