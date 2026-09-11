# ~/.zshrc — Arch/Hyprland (Caetano)

# binds
bindkey "^[[H" beginning-of-line
bindkey "^[[F" end-of-line
# tmux (default-terminal tmux-256color) repassa Home/End nesse formato
# vt220 (terminado em ~), não no ^[[H/^[[F acima — sem isso, End/Home
# reais dentro do tmux inseriam um "~" literal em vez de mover o cursor.
bindkey "^[[1~" beginning-of-line
bindkey "^[[4~" end-of-line
bindkey "^[[3~" delete-char
bindkey "^H" backward-kill-word
bindkey "^[[3;5~" kill-word
bindkey "^[[1;5D" backward-word
bindkey "^[[1;5C" forward-word
bindkey "^[h" backward-word
bindkey "^[l" forward-word

# === Completions ===
# compinit com cache diário: -C pula o scan de segurança quando o dump está
# fresco, o que é o custo dominante do compinit em cada shell novo.
# Precisa vir ANTES dos plugins (syntax-highlighting/autosuggestions) e do
# fzf, que dependem do sistema de widgets e do compdef já carregados.
autoload -Uz compinit
_zcompdump="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump-${ZSH_VERSION}"
mkdir -p "${_zcompdump:h}"
if [[ -n "$_zcompdump"(#qN.mh-24) ]]; then
  compinit -C -d "$_zcompdump"
else
  compinit -d "$_zcompdump"
fi
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"

# === Pyenv ===
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && path=("$PYENV_ROOT/bin" $path)
[[ -d $PYENV_ROOT/shims ]] && path=("$PYENV_ROOT/shims" $path)
# `pyenv init - zsh` custa ~40ms por shell só pra registrar os shims que já
# estão no PATH acima (mais completions e a função `pyenv`). Adiamos tudo
# isso pra primeira chamada real de `pyenv`: o wrapper se auto-substitui.
pyenv() {
  unfunction pyenv
  eval "$(command pyenv init - zsh)"
  pyenv "$@"
}

# === Starship Prompt ===
command -v starship &>/dev/null && eval "$(starship init zsh)"

# Aliases úteis
alias ls='eza --icons'
alias ll='eza -lah --icons --git'
alias tree='eza --tree --icons'
alias grep='grep --color=auto'
alias python='python3'
alias pip='pip3'
alias lg='lazygit'
alias top='btop'
# Plugins instalados pelo bootstrap.sh em ~/.zsh (guardas evitam quebra em máquina nova)
[[ -f ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
  source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
[[ -f ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
  source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -f ~/.zsh/zsh-shift-select/zsh-shift-select.plugin.zsh ]] && \
  source ~/.zsh/zsh-shift-select/zsh-shift-select.plugin.zsh

# Seleção com Ctrl+Shift+Setas (zsh-shift-select acima) — Alt+W ou
# Ctrl+Shift+C copiam a seleção pro kill-ring do zsh e também sincronizam
# com o clipboard do sistema via wl-copy, igual o copy-mode do tmux já faz.
# Ctrl+Shift+C só chega aqui como "\e[99;6u" por causa do bind-key -n C-S-c
# em tmux.conf (fora do tmux ela não funcionaria — degrada pra Ctrl+C).
# Delete/Backspace apagam a seleção (definido pelo plugin) sem tocar o
# clipboard, igual em editores GUI. Ctrl+Shift+V cola: já funciona nativo
# via Ghostty (paste_from_clipboard), não precisa de bind aqui.
_copy-region-as-kill-clipboard() {
  zle copy-region-as-kill -w
  print -rn -- "$CUTBUFFER" | wl-copy
}
zle -N _copy-region-as-kill-clipboard
bindkey '^[w' _copy-region-as-kill-clipboard
bindkey '^[[99;6u' _copy-region-as-kill-clipboard

# === zoxide ===
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"

# === fzf ===
command -v fzf &>/dev/null && eval "$(fzf --zsh)"
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"
export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git"'
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --line-range :50 {}'"

# Ctrl+T e Alt+C (defaults do fzf) ficam presos dentro do tmux — Ctrl+T é
# nova janela e Alt+C é copy-mode lá. Ctrl+G/Alt+G viram atalhos extras pros
# mesmos widgets, sem remover os originais (continuam funcionando fora do
# tmux normalmente). Ctrl+F não dá — já é usado pelo zsh-autosuggestions
# pra aceitar a sugestão inline (forward-char está em
# ZSH_AUTOSUGGEST_ACCEPT_WIDGETS), não só mover o cursor. Ctrl+G hoje é só
# send-break (Ctrl+C já cobre isso na prática).
bindkey '^G' fzf-file-widget
bindkey '^[g' fzf-cd-widget

# === yazi — cd ao sair ===
function y() {
    local tmp="$(mktemp -t yazi-cwd.XXXXXX)" cwd
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}

# === neofetch — ASCII aleatório a cada run ===
# Sorteia um .ascii de ~/.config/neofetch/ascii/ (caveira, char, arch…).
# Sem arquivos na pasta, cai no logo padrão do neofetch.
neofetch() {
    local dir="$HOME/.config/neofetch/ascii"
    local files=("$dir"/*.ascii(N))
    if (( ${#files[@]} )); then
        command neofetch --source "${files[RANDOM % ${#files[@]} + 1]}" "$@"
    else
        command neofetch "$@"
    fi
}

# === Histórico ===
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY

# === PATH ===
# typeset -U mantém path/PATH sem duplicatas: sem isso cada shell aninhado
# (tmux dentro de tmux, subshell, `exec zsh`) reempilha as mesmas entradas.
# O PATH base (~/.bun/bin) mora no ~/.zshenv, que também vale pra shells
# não-interativos — por isso não é repetido aqui.
typeset -U path PATH
path=("$HOME/.opencode/bin" "$HOME/.npm-global/bin" "$HOME/.local/bin" $path)
[[ -d "$HOME/.spicetify" ]] && path+=("$HOME/.spicetify")

copy() {
    "$@" 2>&1 | wl-copy
}

export QMD_FORCE_CPU=1

# === Qt / HiDPI ===
# Apps Qt fora do Hyprland (ferramentas da impressora HP, por exemplo)
# ignoram o scale do compositor e saem minúsculos no eDP-1; o fator fixo
# resolve, e o auto-scale precisa ficar desligado pra não brigar com ele.
export QT_SCALE_FACTOR=1.3
export QT_AUTO_SCREEN_SCALE_FACTOR=0

# === Waydroid ===
# wdopen: sobe o container (se preciso) + sessão e abre a UI cheia.
# wdclose: encerra só a sessão. wdstop: sessão + container.
wdopen() {
  systemctl is-active --quiet waydroid-container || sudo systemctl start waydroid-container
  waydroid session start >/dev/null 2>&1 &
  sleep 2
  waydroid show-full-ui
}

wdclose() {
  waydroid session stop
}

wdstop() {
  waydroid session stop
  sudo systemctl stop waydroid-container
}
