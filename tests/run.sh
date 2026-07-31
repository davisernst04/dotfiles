#!/bin/sh
set -eu
repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
PYTHONDONTWRITEBYTECODE=1 python3 "$repo_dir/tests/test_audit.py"

sh -n "$repo_dir/dotfiles" "$repo_dir/tests/run.sh" \
  "$repo_dir/rofi/.config/rofi/powermenu.sh" \
  "$repo_dir/waybar/.config/waybar/waybar.sh"

if command -v zsh >/dev/null 2>&1; then
  zsh -n "$repo_dir/zsh/.zshrc"
else
  echo "skip: zsh syntax (zsh missing)"
fi

if command -v luac >/dev/null 2>&1; then
  find "$repo_dir/nvim/.config/nvim" -name '*.lua' -exec luac -p {} \;
else
  echo "skip: Lua syntax (luac missing)"
fi

if command -v tmux >/dev/null 2>&1; then
  socket="dotfiles-check-$$"
  tmux -L "$socket" -f "$repo_dir/tmux/.tmux.conf" new-session -d 'sleep 3'
  [ "$(tmux -L "$socket" show-options -gv prefix)" = "C-a" ]
  tmux -L "$socket" kill-server 2>/dev/null || true
else
  echo "skip: tmux config load (tmux missing)"
fi

if command -v stow >/dev/null 2>&1; then
  simulation_root=$(mktemp -d)
  trap 'find "$simulation_root" -depth -delete' EXIT HUP INT TERM
  for profile in core development desktop-hypr optional ai-optional all; do
    mkdir -p "$simulation_root/$profile"
    DOTFILES_TARGET="$simulation_root/$profile" "$repo_dir/dotfiles" --dry-run stow "$profile" >/dev/null
  done
  mkdir -p "$simulation_root/conflict"
  printf 'local file\n' >"$simulation_root/conflict/.zshrc"
  if DOTFILES_TARGET="$simulation_root/conflict" "$repo_dir/dotfiles" --dry-run stow core >/dev/null 2>&1; then
    echo "error: Stow conflict was not rejected" >&2
    exit 1
  fi
  [ "$(cat "$simulation_root/conflict/.zshrc")" = "local file" ] || {
    echo "error: Stow conflict changed the target" >&2
    exit 1
  }
else
  echo "skip: Stow profile simulations (stow missing)"
fi

git -C "$repo_dir" diff --check
