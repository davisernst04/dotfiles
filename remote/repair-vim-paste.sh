#!/usr/bin/env bash
# Run with Bash on the school host. No SSH, downloads, sudo, or package changes.
# Optional --kitty-local mode belongs on the computer running Kitty, not in SSH.
set -euo pipefail
umask 077

usage() {
  cat <<'EOF'
Usage: bash repair-vim-paste.sh [--check | --kitty-local]

Default: append a guarded bracketed-paste fix to the existing Vim config.
--check: print diagnostics without changing files.
--kitty-local: disable Kitty paste confirmations on the LOCAL computer.
              This applies to every application in Kitty, including shells.

Every change has a backup and a printed undo command. Re-running is harmless.
EOF
}
mode=${1:-}
[[ $# -le 1 ]] || { usage >&2; exit 2; }
case "$mode" in
  ''|--check|--kitty-local) ;;
  --help|-h) usage; exit 0 ;;
  *) usage >&2; exit 2 ;;
esac

diagnose() {
  printf 'TERM=%s; inside tmux=%s\n' "${TERM:-unset}" "${TMUX:+yes}"
  for editor in vim nvim; do
    if command -v "$editor" >/dev/null 2>&1; then
      printf '%s executable: %s\n' "$editor" "$(command -v "$editor")"
    fi
  done
  cat <<'EOF'
In your interactive shell, run: type vim
In the editor, run: :echo has('nvim')
  1 means Neovim, which already supports bracketed paste.
  0 means Vim; inspect its active config with: :echo $MYVIMRC
In Vim, inspect paste support with: :set t_BE? t_BD? t_PS? t_PE?

If the popup mentions unsafe/control codes or asks to approve a paste,
it may come from your LOCAL terminal. A server-side config cannot change
that terminal's confirmation policy. Your earlier Kitty setting was:
  paste_actions quote-urls-at-prompt
Reload local Kitty with Ctrl+Shift+F5 after changing its configuration.
EOF
}
if [[ $mode == --check ]]; then
  diagnose
  exit 0
fi

if [[ $mode == --kitty-local ]]; then
  if [[ -n ${SSH_CONNECTION:-} || -n ${SSH_TTY:-} ]]; then
    echo '--kitty-local must run on the computer running Kitty, outside SSH.' >&2
    exit 1
  fi
  config="${KITTY_CONFIG_DIRECTORY:-${XDG_CONFIG_HOME:-$HOME/.config}/kitty}/kitty.conf"
  marker='# BEGIN school paste confirmation repair'
else
  config="$HOME/.vimrc"
  # Vim also supports this location when ~/.vimrc does not exist.
  if [[ ! -e $config && ! -L $config && -f $HOME/.vim/vimrc ]]; then
    config="$HOME/.vim/vimrc"
  fi
  marker='" BEGIN school bracketed paste repair'
fi

# Follow a config symlink without replacing it. Refuse dangling links.
target=$config
if [[ -L $config ]]; then
  command -v readlink >/dev/null || { echo 'readlink is required for config symlinks.' >&2; exit 1; }
  target=$(readlink -f -- "$config")
  [[ -f $target ]] || { printf 'Refusing broken config symlink: %s\n' "$config" >&2; exit 1; }
fi
if [[ -e $target && ! -f $target ]]; then
  printf 'Not a regular config file: %s\n' "$target" >&2
  exit 1
fi
if [[ -f $target ]] && grep -Fqx -- "$marker" "$target"; then
  printf 'Already applied: %s\n' "$config"
  exit 0
fi

mkdir -p -- "$(dirname -- "$target")"
staging=$(mktemp "$(dirname -- "$target")/.paste-repair.XXXXXX")
trap 'rm -f -- "$staging"' EXIT
existed=false
if [[ -f $target ]]; then
  existed=true
  cp -p -- "$target" "$staging"
fi
if [[ $mode == --kitty-local ]]; then
  cat >> "$staging" <<'EOF'

# BEGIN school paste confirmation repair
# Keep URL quoting; paste without a confirmation popup.
paste_actions quote-urls-at-prompt
# END school paste confirmation repair
EOF
else
  cat >> "$staging" <<'EOF'

" BEGIN school bracketed paste repair
" Explicit paste negotiation for Vim over modern terminals and tmux.
" Neovim handles this internally; do not change its terminal options.
if !has('nvim') && !has('gui_running') && exists('+t_BE')
      \ && exists('+t_BD') && exists('+t_PS') && exists('+t_PE')
      \ && $TERM =~# '^\(xterm\|screen\|tmux\|rxvt\|kitty\|foot\|alacritty\|wezterm\)'
  let &t_BE = "\e[?2004h"
  let &t_BD = "\e[?2004l"
  let &t_PS = "\e[200~"
  let &t_PE = "\e[201~"
endif
" END school bracketed paste repair
EOF
fi

backup=''
if $existed; then
  backup=$(mktemp "${target}.before-paste-repair.XXXXXX")
  cp -p -- "$target" "$backup"
fi
# Atomic replacement at the resolved path retains any config symlink.
mv -f -- "$staging" "$target"
printf 'Updated: %s\n' "$config"
if $existed; then
  printf 'Backup: %s\nUndo: cp -p -- %q %q\n' "$backup" "$backup" "$target"
else
  printf 'Previously absent. Undo: rm -- %q\n' "$target"
fi
if [[ $mode == --kitty-local ]]; then
  echo 'Reload Kitty with Ctrl+Shift+F5, or open a new Kitty process.'
else
  echo 'Close and reopen Vim, then try a normal multiline paste in Insert mode.'
  echo 'If Vim loads a custom config, check :echo $MYVIMRC; this repair targets the standard user config.'
  echo 'If the prompt remains, run this script with --check for terminal/Neovim diagnostics.'
fi
