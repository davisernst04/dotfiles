#!/bin/sh
# Claude Code SessionStart hook: fast-forward ~/dotfiles so the shared
# global CLAUDE.md stays the same on every machine. Never blocks or prompts.
repo="$HOME/dotfiles"
[ -d "$repo/.git" ] || exit 0
before=$(git -C "$repo" rev-parse HEAD) || exit 0

if ! out=$(GIT_TERMINAL_PROMPT=0 GIT_SSH_COMMAND="ssh -o BatchMode=yes -o ConnectTimeout=5" \
    timeout 20 git -C "$repo" pull --ff-only --quiet 2>&1); then
  echo "Note: could not update ~/dotfiles (pull --ff-only failed): $(echo "$out" | head -1)"
  exit 0
fi

after=$(git -C "$repo" rev-parse HEAD)
if [ "$before" != "$after" ] &&
   ! git -C "$repo" diff --quiet "$before" "$after" -- agents/.claude/CLAUDE.md; then
  echo "Note: ~/dotfiles was just updated and the global CLAUDE.md changed. Re-read ~/.claude/CLAUDE.md before you start work."
fi
exit 0
