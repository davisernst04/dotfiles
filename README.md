# dotfiles

Portable, low-friction configuration managed with GNU Stow. The repository keeps the existing Zsh, tmux, Neovim, Kitty, Starship, and Hyprland workflow while making package setup, diagnostics, updates, and rollback explicit.

## Profiles

| Profile | Purpose |
| --- | --- |
| `core` | Git (with delta and lazygit), lean makepkg defaults, Zsh, tmux, Neovim, Starship, SSH client defaults, man pages, and common CLI tools |
| `development` | `core` plus Node/Corepack, Python, mise, uv, and C tooling (clangd, bear, gdb, valgrind, strace), shellcheck/shfmt, ast-grep, and hyperfine |
| `desktop-hypr` | `development` plus Hyprland, Waybar, Rofi, SwayNC, Kitty, and desktop tools |
| `optional` | Fastfetch, btop, Cava, and Yazi |
| `ai-optional` | Static OpenCode configuration and shared Claude Code/Codex instructions; no agent is installed or launched |
| `all` | Every package/config profile |

`development` and `desktop-hypr` are composed fresh-machine profiles. Stowing them also applies the required core configuration. Package manifests live under `packages/arch/` and `packages/aur/`.

## Fresh-machine setup

Minimum supported versions are GNU Stow 2.3, Zsh 5.8, tmux 3.5a, and Neovim 0.11.

```sh
git clone --recurse-submodules <repository> "$HOME/dotfiles"
cd "$HOME/dotfiles"

# Inspect exactly what a profile would install.
./dotfiles packages desktop-hypr

# Print package, submodule, and Stow operations without changing the machine.
DOTFILES_TARGET=$(mktemp -d) ./dotfiles --dry-run bootstrap desktop-hypr
```

On Arch, an explicit non-dry-run `install-packages` or `bootstrap` command installs reviewed manifest entries. The current desktop profile uses only official packages, so a fresh setup does not require an AUR helper.

```sh
./dotfiles bootstrap desktop-hypr
sudo git lfs install --system  # or: git lfs install, for the current user only
```

Nothing is installed by `doctor`, `check`, `packages`, or `stow`. Shell startup never installs software. Package installation occurs only through the explicitly named `install-packages` or `bootstrap` commands. On non-Arch systems, use the manifests as a package reference and run Stow directly.

For config-only setup:

```sh
./dotfiles doctor core
./dotfiles --dry-run stow core
./dotfiles stow core
```

Before applying the desktop profile, create the screenshot directory. The active Hyprland configuration is `hyprland.lua`; the original `.conf` configuration remains as a recovery reference. Stow creates missing ignored `host.lua` and `host.conf` stubs from their tracked examples, preserving existing files. Copy the Lua example yourself first only if you want to edit machine-specific settings before the initial apply.

```sh
mkdir -p "$HOME/Pictures/Screenshots"
# Optional before first apply:
cp hypr/.config/hypr/host.lua.example hypr/.config/hypr/host.lua
./dotfiles --dry-run stow desktop-hypr
./dotfiles stow desktop-hypr
```

Both host files are ignored by Git but intentionally visible to Stow. Put current connector-specific monitor/workspace rules, scaling, and keyboard-backlight bindings in `host.lua`; keep `host.conf` for the retained legacy configuration. The empty Lua stub satisfies `require("host")` while the shared configuration retains its generic monitor fallback.

## Diagnostics and validation

`doctor` is read-only and profile-aware:

```sh
./dotfiles doctor core
./dotfiles doctor development
./dotfiles doctor desktop-hypr
```

Core-composed profiles check commands, submodules, locale, and `tmux-256color`; desktop profiles additionally check screenshot paths and host configuration. Optional and AI-only diagnostics check only their own commands, so they do not fail on unrelated core prerequisites.

```sh
./dotfiles check
DOTFILES_TARGET=$(mktemp -d) ./dotfiles --dry-run stow all
```

The checks cover safety/portability invariants, JSON/JSONC, shell and Lua syntax, tmux startup, Git whitespace, every Stow profile, conflict refusal, and dangling symlinks. GitHub Actions runs the same suite.

## Safe updates and rollback

Use the old revision to remove its links before pulling, so deleted package roots cannot leave orphaned symlinks:

```sh
cd "$HOME/dotfiles"
./dotfiles unstow all
git pull --ff-only
git submodule update --init --recursive
./dotfiles check
./dotfiles --dry-run stow all
./dotfiles stow all
```

Stow conflicts are reported and left untouched; this repository never uses destructive `--adopt`. If a conflicting file matters, move it into a timestamped directory such as `$HOME/.dotfiles-backup-YYYYmmdd-HHMMSS`, rerun the dry-run, then apply. To roll back, unstow the current revision first, check out a known-good commit without discarding unrelated local work, initialize its submodules, and restow. Git changes can be reviewed with `git diff`; do not use `git reset --hard` when local work exists.

## Runtime and editor policy

Use [mise](https://mise.jdx.dev/) for project runtime versions. The shell falls back to pyenv only when mise is absent. Use Corepack-managed package managers for TypeScript projects and `uv` for Python environments/tools; commit each project's manifests and lockfiles.

```sh
mise use --global node@lts
corepack enable
mise use --global python@latest
uv --version
```

Neovim plugin versions are recorded in `nvim/.config/nvim/lazy-lock.json`. On the first editor launch, Neovim bootstraps lazy.nvim and installs the locked plugins; this is the only automatic plugin-bootstrap network path. Background update checks are disabled after bootstrap, so run `:Lazy update` intentionally. Mason tools and parser network operations are explicit:

```vim
:MasonToolsInstall
:lua require("nvim-treesitter").install({ "lua", "javascript", "typescript", "tsx", "html", "css", "json", "python", "bash", "c", "make", "scala", "csv", "http" }):wait(300000)
```

Python uses Pyright basic type checking plus Ruff linting/import organization/formatting. TypeScript uses the TypeScript language server, ESLint daemon, and Prettier/Prettierd. LSP mappings are buffer-local and target Neovim 0.11's native LSP API; references, rename, code actions, and implementations use the built-in `grr`, `grn`, `gra`, and `gri`. The cursor line shows its diagnostic inline.

C uses the system clangd (from `clang`, not Mason) and never inserts `#include` lines on completion. For Makefile projects, run `bear -- make` once so clangd sees the real compiler flags. C and shell files are not formatted on save, because they often live in shared or course-provided code: format them explicitly with `<leader>cf` (clang-format honours the project's `.clang-format`). C buffers mark column 81.

Buffers reload when another program changes their file on disk (Claude Code, Codex, or a build), checked on focus, buffer switches, and after a short idle. With claudecode.nvim, Claude Code running in another tmux pane or Kitty window can see the current file and selection and open its proposed edits as Neovim diffs: press `<leader>ai` to start the editor link, then run `/ide` in Claude. `<leader>as` sends a visual selection, `<leader>ab` adds the buffer, and `<leader>aa`/`<leader>ad` accept or reject a diff. The plugin loads only when first used.

`MANPAGER` opens man pages in Neovim (search, `K`/`Ctrl-]` to follow references). Man pages for system calls and the C library come from `man-pages` in the core manifest.

## Shell, secrets, tmux, and optional AI config

AI tools keep their own command names so the standard `cc` compiler command is never shadowed. The current personal `codex` and `opencode` aliases enable their autonomous modes and disable telemetry for those commands only; `codex-yolo` and `opencode-auto` are equivalent explicit aliases. Use `command codex` or `command opencode` to bypass the aliases. The OpenCode path is portable (`$HOME/.opencode/bin`), and OpenCode configuration remains optional/static.

History uses `HIST_IGNORE_SPACE`: prefix sensitive one-off commands with a space, but prefer a password manager or protected environment file. Keep `.env.*` private and commit only `.env.example` or `.env.*.example` templates. Protect an existing history file with `chmod 600 ~/.zsh_history`. Machine shell overrides belong in `~/.zshrc.local`.

tmux uses `C-z` as prefix and retains vim-tmux navigator, yank, and extrakto. TPM and fzf-tab are pinned Git submodules; TPM-managed plugin updates remain explicit with prefix + `I`. OpenCode remote MCP servers and project instructions belong in project-local configuration rather than this global repository.

`Ctrl-r` searches shell history, `Ctrl-t` selects files, and `Alt-c` selects directories. The file and directory widgets use fd with the same generated-directory exclusions as standalone fzf. Tab uses fzf-tab when available, with the ordinary completion menu as a fallback. Completion caches are checked daily, and the shell recovers to HOME if a pane's working directory was deleted.

fzf and fzf-tab use the existing Tokyo Night colours without changing their layout or bindings. Bat uses its built-in `ansi` theme to inherit the terminal palette, so no extra theme assets or cache are needed. Personal overrides can go in `~/.zshrc.local`. The optional btop and Yazi configurations use the same Tokyo Night palette while retaining their default layouts and navigation.

In tmux, prefix + `f` selects a project directory and reuses or creates its session; prefix + `x` switches sessions. Their shared helper lives in `~/.tmux/scripts/session-picker`. Prefix + `q` closes a pane immediately, prefix + `w` closes a window immediately, and prefix + `X` confirms before closing a session. Prefix + `r` reloads the tmux configuration. Prefix + `G` opens lazygit for the current pane's repository (prefix + `g` stays tmux's built-in floating-pane menu).

Git pages through delta when it is installed and through less otherwise, so the same `.gitconfig` works on machines without delta. Rebases autosquash `fixup!` commits, stash a dirty tree, and update stacked branches. Global ignores in `~/.config/git/ignore` cover per-machine agent files and generated `compile_commands.json`.

The `ssh` package links only `~/.ssh/config`: connection sharing (later ssh, scp, rsync, and git commands to a host reuse one authenticated connection for ten minutes), keep-alives, and adding keys to the agent on first use. Because this repository is public, host aliases with personal user names and host names belong in untracked files under `~/.ssh/config.d/`, which the shared config includes.

The `agents` package links one instructions file to both `~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md`. Stowing `ssh` or `agents` first creates `~/.ssh`, `~/.claude`, and `~/.codex` as real private directories, so keys, credentials, and transcripts can never be written into this repository; `.gitignore` admits only the intended files from those packages. The shared file ends by importing `~/.claude/machine.md`: an untracked per-machine file for that machine's facts and rules, which wins on conflict. Never commit it.

Kitty pastes text without confirmation, including multiline text in Neovim. It sends a desktop notification when a command that ran for 30 seconds or more finishes in a window without focus. Notification clicks can activate applications across Hyprland workspaces. The `notification-focus` helper remembers each new desktop notification's sender and restores its local tmux pane when the sender provides that context. For Kitty-protocol notifications, it uses a unique application match in the tmux session, or the pane active when the notification arrived. It starts with Hyprland and requires the system Python with PyGObject (`python-gobject` on Arch).

In Hyprland, Super + `` ` `` toggles a drop-down scratch terminal attached to a persistent tmux session named `scratch` (Super + Shift + `` ` `` sends a window there), and Super + Y picks from text clipboard history (needs `cliphist`; the recorder starts with Hyprland and does nothing until cliphist is installed). Volume and microphone keys work on the lock screen. Pressing the current workspace's key returns to the previous workspace. Volume, network, and Bluetooth utility windows float. Idle suspend applies on battery only: on AC the session still locks after five minutes and the displays still turn off, but long builds and agent runs keep going. `hypr/.config/hypr/.luarc.json` points lua-language-server at Hyprland's installed API stubs, so `hyprland.lua` gets completion and type checking in Neovim.

Neovim file and text search include dotfiles while respecting ignore rules and excluding Git internals. ESLint supports dynamically resolved executable paths, and its daemon exits with the editor. Missing linters are skipped; missing Treesitter parsers leave normal editing available. New shell windows and restarted Neovim instances pick up configuration edits.

### tmux plugins

After applying the core profile, press `C-z` followed by `I` inside tmux to install the configured TPM plugins. Sessions are not automatically saved or restored across tmux server restarts.
