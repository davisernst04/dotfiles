#!/usr/bin/env bash
# Run on the computer running Kitty, outside SSH.
set -euo pipefail
umask 077
if [[ -n ${SSH_CONNECTION:-} || -n ${SSH_TTY:-} ]]; then
  echo 'Run this locally, outside SSH. This changes the local Kitty configuration.' >&2
  exit 1
fi
config="${KITTY_CONFIG_DIRECTORY:-${XDG_CONFIG_HOME:-$HOME/.config}/kitty}/kitty.conf"
mkdir -p -- "$(dirname -- "$config")"
target=$config
if [[ -L $config ]]; then
  target=$(readlink -f -- "$config")
  [[ -f $target ]] || { echo 'Refusing a broken config symlink.' >&2; exit 1; }
fi
[[ ! -e $target || -f $target ]] || { echo 'Config is not a regular file.' >&2; exit 1; }
setting='clipboard_control write-clipboard write-primary read-clipboard read-primary-ask'
if [[ -f $target ]] && [[ $(awk '$1 == "clipboard_control" { last=$0 } END { print last }' "$target") == "$setting" ]]; then
  echo 'Clipboard-read permission is already configured. Reload Kitty with Ctrl+Shift+F5.'
  exit 0
fi
staging=$(mktemp "$(dirname -- "$target")/.clipboard-repair.XXXXXX")
trap 'rm -f -- "$staging"' EXIT
backup=''
if [[ -f $target ]]; then
  backup=$(mktemp "${target}.before-clipboard-repair.XXXXXX")
  cp -p -- "$target" "$backup"
  cp -p -- "$target" "$staging"
fi
cat >> "$staging" <<'EOF'

# Allow terminal programs (including over SSH) to read the system clipboard.
# Keep existing write access and confirmation for reading the primary selection.
clipboard_control write-clipboard write-primary read-clipboard read-primary-ask
EOF
mv -f -- "$staging" "$target"
printf 'Updated: %s\n' "$config"
if [[ -n $backup ]]; then
  printf 'Backup: %s\nUndo: cp -p -- %q %q\n' "$backup" "$backup" "$target"
else
  printf 'Previously absent. Undo: rm -- %q\n' "$target"
fi
echo 'Reload Kitty with Ctrl+Shift+F5. Dismiss the current popup and retry the paste.'
