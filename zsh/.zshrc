# ~/.zshrc

# =============================================================================
# 1. CORE SETTINGS & COMPLETIONS
# =============================================================================
# Initialize Zsh's built-in completion engine (required for autosuggestions)
autoload -Uz compinit
compinit

# =============================================================================
# 2. PATHS & EXPORTS
# =============================================================================
export PATH="$PATH:/home/davis/.local/bin"
export PATH="$HOME/.npm-global/bin:$PATH"

export OTEL_METRICS_EXPORTER=none
export OTEL_TRACES_EXPORTER=none
export OTEL_LOGS_EXPORTER=none

# =============================================================================
# 3. ALIASES
# =============================================================================
alias vim="nvim"

# bat (better cat)
alias cat="bat"

# eza (better ls)
alias ls="eza --icons --group-directories-first"
alias ll="eza -lh --icons --group-directories-first --git"
alias la="eza -lah --icons --group-directories-first --git" # Typo fixed here!
alias tree="eza --tree --level=2 --icons"

# =============================================================================
# 4. FZF (FUZZY FINDER)
# =============================================================================
# Make fzf use 'fd' for blazing fast, git-aware searching
export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'

# Make fzf open in a floating Tmux pane instead of taking over the bottom
export FZF_TMUX=1

# Load fzf keybindings and fuzzy completion
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# =============================================================================
# 5. PLUGINS & PROMPT (LOAD ORDER MATTERS)
# =============================================================================

# A. Autosuggestions
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
bindkey '^[[C' forward-char # Bind Right-Arrow to accept suggestion

# B. Zoxide (better cd)
eval "$(zoxide init zsh)"

# C. Starship Prompt
eval "$(starship init zsh)"

# D. Syntax Highlighting (MUST BE ABSOLUTE LAST)
source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
