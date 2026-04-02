autoload -Uz compinit
compinit

export PATH="$PATH:/home/davis/.local/bin"
export PATH="$HOME/.npm-global/bin:$PATH"

export OTEL_METRICS_EXPORTER=none
export OTEL_TRACES_EXPORTER=none
export OTEL_LOGS_EXPORTER=none

alias vim="nvim"
alias mkdir="mkdir -pv"
alias cp="cp -i"
alias mv="mv -i"
alias rm="rm -i"
alias sz="source ~/.zshrc"

alias cat="bat"

alias ls="eza --icons --group-directories-first"
alias ll="eza -lh --icons --group-directories-first --git"
alias la="eza -lah --icons --group-directories-first --git"
alias tree="eza --tree --level=2 --icons"

export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'

export FZF_TMUX=1

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
bindkey '^[[C' forward-char

eval "$(zoxide init zsh)"

eval "$(starship init zsh)"

source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt append_history
setopt share_history
setopt hist_ignore_all_dups
setopt hist_ignore_space

zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu select
