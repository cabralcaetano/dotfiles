# ~/.zshrc — Fedora 44 (Caetano)

# binds
bindkey "^[[H" beginning-of-line
bindkey "^[[F" end-of-line
bindkey "^[[3~" delete-char
bindkey "^H" backward-kill-word
bindkey "^[[3;5~" kill-word
bindkey "^[[1;5D" backward-word
bindkey "^[[1;5C" forward-word

# === Pyenv ===
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - zsh)"

# === Starship Prompt ===
eval "$(starship init zsh)"

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

# === zoxide ===
eval "$(zoxide init zsh)"

# === fzf ===
eval "$(fzf --zsh)"
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"
export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git"'
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --line-range :50 {}'"

# === yazi — cd ao sair ===
function y() {
    local tmp="$(mktemp -t yazi-cwd.XXXXXX)" cwd
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}

# === Histórico ===
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY
export PATH="$HOME/.local/bin:$PATH"

copy() {
    "$@" 2>&1 | wl-copy
}

[[ -d "$HOME/.spicetify" ]] && export PATH="$PATH:$HOME/.spicetify"
