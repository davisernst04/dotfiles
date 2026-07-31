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

typeset -U path PATH
export BUN_INSTALL="$HOME/.bun"
path=("$HOME/.local/bin" "$HOME/.opencode/bin" "$BUN_INSTALL/bin" $path)

export OTEL_METRICS_EXPORTER=none
export OTEL_TRACES_EXPORTER=none
export OTEL_LOGS_EXPORTER=none

alias vim="nvim"
alias mkdir="mkdir -pv"
alias cp="cp -i"
alias mv="mv -i"
alias rm="rm -i"
alias sz="source ~/.zshrc"
alias cc="claude"
alias oc="opencode"

# tmux aliases
alias ta="tmux attach -t"
alias tl="tmux list-sessions"
alias tn="tmux new-session -s"

alias cat="bat --paging=never --style=plain"

alias ls="eza --icons --group-directories-first"
alias ll="eza -lh --icons --group-directories-first --git"
alias la="eza -lah --icons --group-directories-first --git"
alias tree="eza --tree --level=2 --icons=always"

export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
export FZF_TMUX=1

# fzf keybindings (Ctrl-R history, Ctrl-T files, Alt-C cd) and **<Tab> completion.
# Widget files require a real terminal; skip them for CI/non-TTY interactive probes.
if [[ -t 0 ]]; then
  _fzf_sourced=0
  for _fzf_dir in /usr/share/fzf /usr/share/doc/fzf/examples; do
    if [ -f "$_fzf_dir/key-bindings.zsh" ]; then
      source "$_fzf_dir/key-bindings.zsh"
      source "$_fzf_dir/completion.zsh"
      _fzf_sourced=1
      break
    fi
  done
  [ "$_fzf_sourced" -eq 0 ] && [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
  unset _fzf_dir _fzf_sourced
fi

# zsh-autosuggestions: path differs between Arch, Debian, and manual clones
for _plugin in /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh \
               /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
               ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh; do
  [ -f "$_plugin" ] && source "$_plugin" && break
done
unset _plugin
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
bindkey '^[[C' forward-char
# Shift-Tab cycles backwards through the completion menu
bindkey '^[[Z' reverse-menu-complete

(( $+commands[dircolors] )) && eval "$(dircolors -b)"

(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"

(( $+commands[starship] )) && eval "$(starship init zsh)"

# Prefer mise for project runtimes; retain pyenv as a Python-only fallback.
if (( $+commands[mise] )); then
  eval "$(mise activate zsh)"
elif (( $+commands[pyenv] )); then
  eval "$(pyenv init -)"
fi
(( $+commands[uv] )) && eval "$(uv generate-shell-completion zsh)"

# zsh-syntax-highlighting: path differs between Arch, Debian, and manual clones
for _plugin in /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
               /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
               ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh; do
  [ -f "$_plugin" ] && source "$_plugin" && break
done
unset _plugin

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
[ -f ~/.zsh/plugins/fzf-tab/fzf-tab.plugin.zsh ] && source ~/.zsh/plugins/fzf-tab/fzf-tab.plugin.zsh
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always --icons=always $realpath'

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

export EDITOR=nvim
export VISUAL=nvim

# Machine-specific overrides (not tracked in the repo)
if [ -f ~/.zshrc.local ]; then
  source ~/.zshrc.local
fi
