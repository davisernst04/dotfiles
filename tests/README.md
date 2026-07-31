# Validation history

The initial TDD baseline was run before implementation. Eight tests ran: JSON parsing passed; seven expected failures recorded unsafe permission-bypass aliases, an ignored Neovim lockfile, a literal personal home path, duplicate Hypr bindings, direct unconfirmed power actions, executable non-scripts, and incomplete Neovim dependency/tool declarations.

The expanded suite adds profile-aware bootstrap/package behavior, current workflow package coverage, wallpaper and idle-policy preservation, non-TTY Zsh startup, ignored Stow artifacts, CI tool coverage, dangling symlinks, JSONC, shell/Lua syntax, tmux startup, `git diff --check`, every profile's Stow simulation, and non-destructive Stow-conflict handling.

Run everything with `./tests/run.sh` or `./dotfiles check`.
