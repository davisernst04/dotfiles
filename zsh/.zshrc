if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
alias vim=nvim

export OTEL_METRICS_EXPORTER=none
export OTEL_TRACES_EXPORTER=none
export OTEL_LOGS_EXPORTER=none

export PATH="$PATH:/home/davis/.local/bin"

source "/home/davis/.openclaw/completions/openclaw.zsh"
export PATH="$HOME/.npm-global/bin:$PATH"
