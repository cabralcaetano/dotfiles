#!/usr/bin/env bash
# tmux-swap-window-animated.sh — usado só pelos binds de Alt+Shift+N em
# tmux-animated.conf (tmux-animated, não o tmux normal).
#
# swap-window/move-window só realocam o índice da janela — o conteúdo
# exibido não muda, então o tmux-animated não anima essa ação sozinho
# (só anima troca de janela ativa de verdade). Aqui, depois do swap,
# "espiamos" rapidamente a janela que foi deslocada (que ficou no índice
# antigo) e voltamos — as duas transições disparam a animação de slide
# normal do switch, dando o efeito visual de reordenamento.
#
# animation-window-switch/animation-status-highlight ficam OFF por padrão
# em tmux-animated.conf (Alt+N normal não anima) — aqui ligamos só
# durante o bounce e desligamos de novo depois.
#
# #{window_index} não expande dentro da ação de um if-shell (só na
# condição -F) — por isso isso vira um script em vez de ficar tudo
# dentro do bind-key; aqui usamos display-message -F, que expande.
#
# Uso: tmux-swap-window-animated.sh <slot-alvo>
set -euo pipefail

target="$1"
old_idx=$(tmux display-message -p -F '#{window_index}')
count=$(tmux display-message -p -F '#{session_windows}')

if [ "$target" -le "$count" ]; then
    tmux set-option -g animation-window-switch slide
    tmux set-option -g animation-status-highlight on
    tmux swap-window -t ":$target"
    tmux select-window -t ":$old_idx"
    tmux select-window -t ":$target"
    tmux set-option -g animation-window-switch off
    tmux set-option -g animation-status-highlight off
else
    tmux move-window -t ":$target"
fi
