# dotfiles

Portable, low-friction configuration managed with GNU Stow. The repository keeps the existing Zsh, tmux, Neovim, Kitty, Starship, and Hyprland workflow while making package setup, diagnostics, updates, and rollback explicit.

## Profiles

| Profile | Purpose |
| --- | --- |
| `core` | Git, Zsh, tmux, Neovim, Starship, and common CLI tools |
| `development` | `core` plus Node/Corepack, Python, mise, and uv |
| `desktop-hypr` | `development` plus Hyprland, Waybar, Rofi, SwayNC, Kitty, and desktop tools |
| `optional` | Fastfetch, btop, and Cava |
| `ai-optional` | Static OpenCode configuration only; OpenCode is never installed or launched |
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

On Arch, an explicit non-dry-run `install-packages` or `bootstrap` command installs reviewed manifest entries. Desktop setup currently has an AUR dependency; select an already-reviewed helper with `AUR_HELPER=paru` or `AUR_HELPER=yay`. The helper is preflighted before any official packages are installed.

```sh
AUR_HELPER=yay ./dotfiles bootstrap desktop-hypr
sudo git lfs install --system  # or: git lfs install, for the current user only
```

Nothing is installed by `doctor`, `check`, `packages`, or `stow`. Shell startup never installs software. Package installation occurs only through the explicitly named `install-packages` or `bootstrap` commands. On non-Arch systems, use the manifests as a package reference and run Stow directly.

For config-only setup:

```sh
./dotfiles doctor core
./dotfiles --dry-run stow core
./dotfiles stow core
```

Before applying the desktop profile, create the screenshot directory. The Stow command creates an ignored `host.conf` stub from the tracked example when one is absent; copy it yourself first only if you want to edit machine-specific settings before the initial apply.

```sh
mkdir -p "$HOME/Pictures/Screenshots"
# Optional before first apply:
cp hypr/.config/hypr/host.conf.example hypr/.config/hypr/host.conf
./dotfiles --dry-run stow desktop-hypr
./dotfiles stow desktop-hypr
```

`host.conf` is ignored by Git but intentionally visible to Stow. Put connector-specific monitor/workspace rules, scaling, and keyboard-backlight device bindings there. The generated stub keeps the unconditional Hyprland source valid while the shared configuration retains a generic monitor fallback.

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
:lua require("nvim-treesitter").install({ "lua", "javascript", "typescript", "tsx", "html", "css", "json", "python", "bash", "scala", "csv", "http" }):wait(300000)
```

Python uses Pyright basic type checking plus Ruff linting/import organization/formatting. TypeScript uses the TypeScript language server, ESLint daemon, and Prettier/Prettierd. LSP mappings are buffer-local and target Neovim 0.11's native LSP API.

## Shell, secrets, tmux, and optional AI config

The normal `claude` command and `cc` alias retain permission checks; no permission-bypass alias is defined. The OpenCode path is portable (`$HOME/.opencode/bin`), and OpenCode configuration remains optional/static.

History uses `HIST_IGNORE_SPACE`: prefix sensitive one-off commands with a space, but prefer a password manager or protected environment file. Keep `.env.*` private and commit only `.env.example` or `.env.*.example` templates. Protect an existing history file with `chmod 600 ~/.zsh_history`. Machine shell overrides belong in `~/.zshrc.local`.

tmux uses `C-a` as prefix and retains vim-tmux navigator, yank, extrakto, and theme plugins. TPM and fzf-tab are pinned Git submodules; TPM-managed plugin updates remain explicit with prefix + `I`. OpenCode remote MCP servers and project instructions belong in project-local configuration rather than this global repository.
