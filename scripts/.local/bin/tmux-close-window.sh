#!/usr/bin/env bash
# tmux-close-window.sh — chamado pelo bind de Ctrl+W (tmux.conf) antes do
# kill-window. Empilha diretório/comando completo/nome da janela em
# ~/.tmux/closed-windows.stack pro Ctrl+Shift+T (tmux-reopen-window.sh)
# reabrir depois. O comando completo (com argumentos) é lido de
# /proc/<pid>/cmdline do processo em foreground do pane — o tmux só expõe o
# nome do processo (#{pane_current_command}), sem argumentos, o que faria
# ex. "sleep 300" virar só "sleep" (erro ao rerodar). Se o shell estiver
# parado no prompt (sem filho em foreground), guarda comando vazio.
# Uso: tmux-close-window.sh <path> <shell-pid> <window-name>
set -uo pipefail

dir="$1"
shell_pid="$2"
name="$3"

cmd=""
child_pid=$(ps -o pid= --ppid "$shell_pid" 2>/dev/null | awk 'NR==1 {print $1}')
if [ -n "$child_pid" ] && [ -r "/proc/$child_pid/cmdline" ]; then
    cmd=$(tr '\0' ' ' < "/proc/$child_pid/cmdline" | sed 's/ $//')
fi

# Delimitador é \x1f (unit separator), não tab: o bash trata tab como
# "IFS whitespace" e colapsa campos vazios entre delimitadores repetidos
# (perdendo o campo "cmd" quando ele é vazio) — \x1f não sofre esse colapso.
printf '%s\x1f%s\x1f%s\n' "$dir" "$cmd" "$name" >> "$HOME/.tmux/closed-windows.stack"
