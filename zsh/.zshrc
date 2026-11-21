export LANG=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8

# A tmux pane can outlive a deleted or replaced project directory.
if [[ ! . -ef $PWD ]]; then
  builtin cd -- "$HOME" || return 1
fi

autoload -Uz compinit
setopt extendedglob
# Check completion directories on first launch and once per day. compinit may
# reuse an unchanged dump, so refresh its timestamp after a successful check.
if [[ ! -r ~/.zcompdump || -n ~/.zcompdump(#qN.mh+24) ]]; then
  compinit && [[ -f ~/.zcompdump ]] && command touch ~/.zcompdump
else
  compinit -C
fi

# Compile zshrc for faster loading. `-nt` alone is false when the target is
# absent on some zsh versions, so handle the first launch explicitly.
if [[ ! -r ~/.zshrc.zwc || ~/.zshrc -nt ~/.zshrc.zwc ]]; then
  zcompile ~/.zshrc 2>/dev/null
fi

typeset -U path PATH
export BUN_INSTALL="$HOME/.bun"
path=("$HOME/.local/bin" "$BUN_INSTALL/bin" $path)
[[ -d "$HOME/.opencode/bin" ]] && path=("$HOME/.opencode/bin" $path)

# Use the session's socket-activated agent locally, but preserve an agent
# forwarded into an SSH login.
if [[ -z ${SSH_CONNECTION:-} && -z ${SSH_AUTH_SOCK:-} && -S ${XDG_RUNTIME_DIR:-}/gcr/ssh ]]; then
  export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/gcr/ssh"
fi

alias vim="nvim"
alias mkdir="mkdir -pv"
alias cp="cp -i"
alias mv="mv -i"
alias rm="rm -i"
alias sz="source ~/.zshrc"
alias opencode="OTEL_METRICS_EXPORTER=none OTEL_TRACES_EXPORTER=none OTEL_LOGS_EXPORTER=none command opencode --auto"
alias opencode-auto="OTEL_METRICS_EXPORTER=none OTEL_TRACES_EXPORTER=none OTEL_LOGS_EXPORTER=none command opencode --auto"
alias codex="OTEL_METRICS_EXPORTER=none OTEL_TRACES_EXPORTER=none OTEL_LOGS_EXPORTER=none command codex --yolo"
alias codex-yolo="OTEL_METRICS_EXPORTER=none OTEL_TRACES_EXPORTER=none OTEL_LOGS_EXPORTER=none command codex --yolo"

# tmux aliases
alias ta="tmux attach -t"
alias tl="tmux list-sessions"
alias tn="tmux new-session -s"

alias cat="bat --paging=never --style=plain"
# Use the terminal's palette for syntax colours without a separate theme cache.
export BAT_THEME=ansi

alias ls="eza --icons --group-directories-first"
alias ll="eza -lh --icons --group-directories-first --git"
alias l="eza -lh --icons --group-directories-first --git"
alias la="eza -lah --icons --group-directories-first --git"
alias tree="eza --tree --level=2 --icons=always"

export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git --exclude .cache --exclude .local --exclude .npm --exclude .hermes --exclude .codex --exclude .pyenv --exclude node_modules --exclude .venv --exclude target --exclude .next'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="${FZF_DEFAULT_COMMAND/--type f/--type d}"
export FZF_TMUX=1

# Tokyo Night colours only: keep fzf's existing layout and key bindings.
# Match the installed tokyonight.nvim palette used by Kitty and Neovim.
_fzf_theme='--color=bg+:#283457,bg:#16161e,border:#27a1b9,fg:#c0caf5,gutter:#16161e,header:#ff9e64,hl+:#2ac3de,hl:#2ac3de,info:#545c7e,marker:#ff007c,pointer:#ff007c,prompt:#2ac3de,query:#c0caf5:regular,scrollbar:#27a1b9,separator:#ff9e64,spinner:#ff007c'
if [[ ${FZF_DEFAULT_OPTS:-} != *"$_fzf_theme"* ]]; then
  export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:+$FZF_DEFAULT_OPTS }$_fzf_theme"
fi

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

(( $+commands[dircolors] )) && eval "$(dircolors -b)"
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# fzf-tab must precede plugins that wrap completion widgets.
if (( $+commands[fzf] )) && [[ -f ~/.zsh/plugins/fzf-tab/fzf-tab.plugin.zsh ]]; then
  zstyle ':completion:*' menu no
  # fzf-tab deliberately ignores FZF_DEFAULT_OPTS; share only the colours.
  zstyle ':fzf-tab:*' fzf-flags "$_fzf_theme"
  source ~/.zsh/plugins/fzf-tab/fzf-tab.plugin.zsh
  zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always --icons=always -- "$realpath"'
else
  zstyle ':completion:*' menu select
fi
unset _fzf_theme

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

(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"

(( $+commands[starship] )) && eval "$(starship init zsh)"

# Prefer mise for project runtimes; lazily initialize pyenv as a Python-only
# fallback. Its shims work immediately, while the slower shell integration is
# deferred until an interactive `pyenv` command actually needs it.
if (( $+commands[mise] )); then
  eval "$(mise activate zsh)"
elif (( $+commands[pyenv] )); then
  export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
  path=("$PYENV_ROOT/shims" $path)
  pyenv() {
    unfunction pyenv
    eval "$(command pyenv init -)"
    pyenv "$@"
  }
fi
# Distribution packages often already provide _uv through compinit.
if (( $+commands[uv] )) && [[ -z ${_comps[uv]:-} ]]; then
  eval "$(uv generate-shell-completion zsh)"
fi

HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt append_history
setopt share_history
setopt hist_ignore_all_dups
setopt hist_ignore_space

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

export EDITOR=nvim
export VISUAL=nvim
# Read man pages in Neovim: search, folds, and K / Ctrl-] to follow references.
(( $+commands[nvim] )) && export MANPAGER='nvim +Man!'

# Machine-specific overrides (not tracked in the repo)
if [ -f ~/.zshrc.local ]; then
  source ~/.zshrc.local
fi

# Load last so highlighting sees widgets installed above and in local overrides.
for _plugin in /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
               /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
               ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh; do
  [ -f "$_plugin" ] && source "$_plugin" && break
done
unset _plugin
