export LANG=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8

autoload -Uz compinit
# Only regenerate compinit dump once per day (massive startup speedup)
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

# Compile zshrc for faster loading
if [[ ~/.zshrc -nt ~/.zshrc.zwc ]]; then
  zcompile ~/.zshrc 2>/dev/null
fi

export PATH="$PATH:$HOME/.local/bin"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

export OTEL_METRICS_EXPORTER=none
export OTEL_TRACES_EXPORTER=none
export OTEL_LOGS_EXPORTER=none

alias vim="nvim"
alias mkdir="mkdir -pv"
alias cp="cp -i"
alias mv="mv -i"
alias rm="rm -i"
alias sz="source ~/.zshrc"
alias cc="claude --dangerously-skip-permissions"
alias claude="claude --dangerously-skip-permissions"
alias oc="opencode"

# tmux aliases
alias ta="tmux attach -t"
alias tl="tmux list-sessions"
alias tn="tmux new-session -s"

alias cat="bat"

alias ls="eza --icons --group-directories-first"
alias ll="eza -lh --icons --group-directories-first --git"
alias la="eza -lah --icons --group-directories-first --git"
alias tree="eza --tree --level=2 --icons=always"

export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
export FZF_TMUX=1

# fzf keybindings (Ctrl-R history, Ctrl-T files, Alt-C cd) and **<Tab> completion
if [ -f /usr/share/fzf/key-bindings.zsh ]; then
  source /usr/share/fzf/key-bindings.zsh
  source /usr/share/fzf/completion.zsh
elif [ -f ~/.fzf.zsh ]; then
  source ~/.fzf.zsh
fi

source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
bindkey '^[[C' forward-char
# Shift-Tab cycles backwards through the completion menu
bindkey '^[[Z' reverse-menu-complete

eval "$(dircolors -b)"

eval "$(zoxide init zsh)"

eval "$(starship init zsh)"

# pyenv: activate shims so `pyenv global` versions take effect
eval "$(pyenv init -)"

source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt append_history
setopt share_history
setopt hist_ignore_all_dups
setopt hist_ignore_space

zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
# Show an interactive menu and cycle through candidates with Tab
zstyle ':completion:*' menu select

# fzf-tab: fuzzy completion menu (Tab to trigger, type to filter, Enter to accept)
source ~/.zsh/plugins/fzf-tab/fzf-tab.plugin.zsh
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always --icons=always $realpath'

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

export EDITOR=nvim
export VISUAL=nvim
