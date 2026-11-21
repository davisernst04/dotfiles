# Portable shell environment without sudo

This bundle snapshots Davis's current Zsh, Starship, tmux, Neovim (including
lazy-lock.json), Git config, and installed shell/tmux plugins. The builder uses
the working files, so uncommitted config changes are included. It copies an
explicit allowlist; SSH keys, authentication stores, shell history, editor state,
machine overrides, and desktop configs are excluded.

The remote snapshot removes Copilot, its plugin lock entry and Tab acceptance
hook, AI command aliases, and the OpenCode path addition. Ordinary LSP, buffer,
path, and snippet completion remain enabled. The workstation configs are unchanged.

Micromamba installs the CLI tools (including btop and yazi), Node 24, Python 3.13, mise, uv, and a C/C++
build toolchain from conda-forge in your home directory. Neovim v0.12.5 uses the
official Linux x86_64 archive because conda-forge's Neovim package is too old for
this config. The two release downloads have pinned SHA-256 checksums.

Prerequisites on the remote: Linux x86_64, Bash, curl, tar, sha256sum, writable
executable home storage, sufficient disk quota, and HTTPS access to GitHub and
conda-forge. The full toolchain can use several GB including the package cache;
`--plan` lists the exact package specs and config destinations without downloading.
The kernel string identifies Fedora's x86_64 build but does not report available
commands, glibc, quota, or the account's shell.

## Transfer and install

For the school account, run this on the workstation from a normal terminal.
`tux` is an SSH alias for your school login, kept in the untracked
`~/.ssh/config.d/` (see the `ssh` package in the main README):

```sh
python3 ~/dotfiles/remote/build-bundle.py
bash ~/dotfiles/remote/deploy-school.sh tux
```

The deploy script lets SSH request your password in the terminal, transfers the
bundle over the same authenticated connection, and enables the guarded SSH login
hook. Existing portable tools get a config-only update; a fresh account gets
tools installed under `~/.local`. Neither path needs sudo. The account must allow
executables in home storage. Reconnect after deployment, or launch explicitly:

```sh
ssh -t tux 'exec "$HOME/.local/bin/dev-shell"'
```

Build on the workstation whenever you want a fresh config snapshot:

```sh
python3 ~/dotfiles/remote/build-bundle.py
```

Run the transfer yourself, replacing `YOUR_USER` and the host as needed:

```sh
scp ~/remote-dev-env.tar.gz YOUR_USER@tux8:~/
```

In your own remote session:

```sh
bundle_dir=$(mktemp -d "$HOME/remote-dev-env.XXXXXX")
tar -xzf ~/remote-dev-env.tar.gz -C "$bundle_dir" --strip-components=1
cd "$bundle_dir"
bash install.sh --plan --enable-ssh
bash install.sh --enable-ssh
exec "$HOME/.local/bin/dev-shell"
```

If you already installed the previous bundle, use this instead of the full
install command to preserve every installed tool version:

```sh
bash install.sh --configs-only --enable-ssh
exec "$HOME/.local/bin/dev-shell"
```

Extract each new bundle into a fresh directory as above so removed files cannot
survive from an older archive. Close and reopen Neovim after applying the update.
An existing downloaded Copilot plugin is moved into the installer's backup.

The installer backs up replaced configs (including existing symlinks) under
`~/.local/state/dev-env/backups/<timestamp>-<pid>/`. It leaves `~/.zshrc.local`
alone; existing overrides there can still affect the copied setup. Shell startup
does not install anything. Re-running the installer reapplies the snapshot and
may resolve newer conda packages satisfying environment.txt. The resolved
packages are recorded in `~/.config/dev-env/packages-linux-64.lock`.

`--enable-ssh` appends a launcher to `.bashrc` that runs only for interactive SSH
Bash sessions after verifying that the host and installed binaries are compatible.
The installer replaces its existing managed block when updating. It does not change
the account's system login shell. If your Bash
login profile does not source `.bashrc`, add `[ -f ~/.bashrc ] && . ~/.bashrc` to
the profile it actually loads. If the account uses a different shell, either
start `~/.local/bin/dev-shell` explicitly or use this command from your client:

```sh
ssh -t YOUR_USER@tux8 'exec "$HOME/.local/bin/dev-shell"'
```

Only the explicit transfer/connection commands above contact the remote host.
Neither the builder nor the installer initiates SSH connections.

## Shared homes and other CPU types

This bundle installs x86_64 binaries. If school machines share your home directory,
an ARM host may see those files but cannot execute them. `armv7l` is 32-bit ARM;
it is also different from the ARM64/aarch64 platform in micromamba's downloads.
The updated SSH hook keeps incompatible hosts in their normal Bash shell.
The launcher itself falls back to system Bash if called by an older hook, a
binary cannot execute, or environment activation fails. It sets
`DEV_ENV_DISABLE=1` during fallback to prevent a launcher loop.

To recover access with the earlier launcher, connect from your client:

```sh
ssh -t cmpt332-arm 'DEV_ENV_DISABLE=1 /bin/bash --noprofile --norc -i'
```

To fix the installed launcher without reinstalling packages, transfer the updated
executable from the workstation (the builder also includes it in new bundles):

```sh
scp ~/dotfiles/remote/dev-shell cmpt332-arm:~/.local/bin/dev-shell
```

Then reconnect normally. This restores login on ARM; use that host's system tools.
An ARMv7 development installation requires separate native packages/builds and
cannot reuse this x86_64 environment. On supported x86_64 hosts, automatic Zsh
startup continues. On a supported host, reapply with `--configs-only --enable-ssh`
to upgrade the managed `.bashrc` block too.

### Repair an older installed launcher from tuxworld

Errors mentioning micromamba on lines 7 and 8 match the first version of the
launcher, before the compatibility guard. Updating the workstation's copy or
building a new archive does not update the installed copy in `/student/<user>`.
Run the standalone `repair-login.sh` in the school account on tuxworld to guard
the launcher already installed there. It backs up that file and preserves its
existing environment activation. No packages, shell configs, or Neovim configs
are changed. Re-running the repair leaves the existing guard in place.

From the workstation, transfer the repair script:

```sh
scp ~/dotfiles/remote/repair-login.sh tux:~/repair-dev-login.sh
```

Then on tuxworld:

```sh
bash ~/repair-dev-login.sh
```

Hosts sharing that school home use the repaired launcher on their next login.
To also repair the ARM account when it has a different home, run these on
tuxworld. A distinct destination filename is safe when the homes are shared too:

```sh
scp ~/repair-dev-login.sh cmpt332-arm:~/repair-dev-login-arm.sh
ssh cmpt332-arm 'bash "$HOME/repair-dev-login-arm.sh"'
ssh cmpt332-arm
```

The command-based SSH invocation runs the repair without requesting an
interactive login, so the old interactive startup hook is bypassed.
An AMD64 login that reaches a prompt has already succeeded. A PPC host refusing
the TCP connection requires checking its hostname/SSH endpoint or SSH service;
the user's shell launcher has not run at that stage.

## Deleted tmux working directories

If a pane's current directory or one of its parents is deleted/replaced while
the shell stays open, getcwd errors can appear during shell/tool startup.
The launcher and the beginning of the bundled `.zshrc` fall back to HOME when
the inherited working directory is invalid. Valid project directories are preserved.

In an affected pane, recover its working directory first:

```sh
cd -- "$HOME"
```

From outside tmux, start a new session explicitly in your home directory:

```sh
cd -- "$HOME"
tmux new-session -c "$HOME"
```

If already inside tmux, use `tmux new-window -c "$HOME"` for a fresh window.
Attaching to an existing session keeps its existing panes; change directory in
each affected pane. Apply the rebuilt bundle with `--configs-only --enable-ssh`
to pick up the startup guards, then source the installed `.zshrc` in existing
Zsh panes after recovering their directories. These changes do not restart the
tmux server or terminate existing sessions.

## Editor and terminal

### Repair paste confirmation without reinstalling

The standalone `repair-vim-paste.sh` runs on the school host without SSH,
downloads, or sudo:

```sh
bash ~/repair-vim-paste.sh --check
bash ~/repair-vim-paste.sh
```

It appends a guarded bracketed-paste configuration to `~/.vimrc` (or the existing
`~/.vim/vimrc` when there is no `~/.vimrc`). Existing settings and config symlinks
are preserved. Each change has a backup and a printed undo command; repeated
runs leave the managed block alone. Reopen Vim afterward. Custom Vim config
locations need the block applied to the file shown by `:echo $MYVIMRC` instead.

This portable shell aliases `vim` to Neovim, which already handles bracketed
paste. If a confirmation popup persists, it may belong to the local terminal.
The workstation Kitty config already contains `paste_actions quote-urls-at-prompt`;
reload it with `Ctrl+Shift+F5`. For another local Kitty installation, run
`bash repair-vim-paste.sh --kitty-local` **on the computer running Kitty** and
reload Kitty. That option removes paste confirmations for every application in
Kitty, including shells, and refuses to run inside an SSH session. Neither mode
changes the remote shell launcher, tmux, plugins, or installed tool versions.

The Vim repair follows the bracketed-paste sequences in the
[Kitty Vim guidance](https://sw.kovidgoyal.net/kitty/faq/#using-a-color-theme-with-a-background-color-does-not-work-well-in-vim).
The optional local setting uses Kitty's
[`paste_actions`](https://sw.kovidgoyal.net/kitty/conf/#opt-kitty.paste_actions).

### Portable editor setup

Run `nvim`; lazy.nvim fetches your locked plugins on first launch. Then install
your language servers/formatters and parsers explicitly:

```vim
:MasonToolsInstall
:lua require("nvim-treesitter").install({ "lua", "javascript", "typescript", "tsx", "html", "css", "json", "python", "bash", "scala", "csv", "http" }):wait(300000)
:checkhealth
```

The launcher activates the compiler toolchain for Telescope and Treesitter.
Use project-local `mise use node@VERSION` or `uv` environments when you need
different runtime versions. The bundle contains no AI plugins or command aliases
and does not install AI CLIs or copy their login credentials.

Your existing tmux prefix is `Ctrl-z`. Already installed tmux plugins travel with
the snapshot. Resurrect and Continuum are no longer included; applying a new
bundle backs up and replaces the old plugin directory. Sessions survive
disconnects while the host keeps your processes running; server reboot or site
logout cleanup ends them, and they are not automatically restored. The bundle
also includes `~/.tmux/scripts/session-picker` for the existing prefix + `f` and
prefix + `x` shortcuts. After a config update, prefix + `r` reloads an existing
tmux server without ending its sessions. Prefix + `q` and prefix + `w` close a
pane or window immediately. A locally installed terminal description supports
Kitty/tmux over SSH.
Nerd Font glyphs use the font in your local terminal; no remote font install is
needed. Remote clipboard behavior depends on the local terminal's OSC 52 support.

Verify inside the new shell:

```sh
command -v zsh nvim tmux starship fzf fd rg eza bat zoxide mise uv node python
zsh --version
nvim --version
tmux -V
node --version
python --version
printf 'int main(void) { return 0; }\n' | "$CC" -x c - -o /tmp/dev-env-compiler-check
/tmp/dev-env-compiler-check
rm /tmp/dev-env-compiler-check
```

For noninteractive SSH commands the Bash launcher intentionally does not run.
To use installed tools there, run `~/.local/bin/dev-shell -c 'YOUR_COMMAND'`.

## Disable and restore

To disable automatic startup, remove the block between
`# BEGIN portable dev environment` and `# END portable dev environment` from
the remote `.bashrc`. For a one-session bypass from the client:

```sh
ssh -t YOUR_USER@tux8 'DEV_ENV_DISABLE=1 bash -il'
```

To restore configs, choose the backup directory printed during installation,
move the installed paths listed in `config-paths.txt` aside, and move the saved
paths back to their corresponding home locations. A path absent from the backup
did not exist before that install. Restore `.bashrc` from
`bashrc-before-ssh-launcher` when present. The tool installation directories are
`~/.local/share/dev-env`, `dev-env-manager`, and `dev-env-neovim`; keep them until
you have left the portable shell and closed its tmux sessions.

References: [micromamba installation](https://mamba.readthedocs.io/en/stable/installation/micromamba-installation.html),
[official Neovim installation](https://github.com/neovim/neovim/blob/master/INSTALL.md),
and [fzf shell integration](https://github.com/junegunn/fzf#setting-up-shell-integration).
