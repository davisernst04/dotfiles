#!/bin/bash
set -euo pipefail
umask 077
bundle=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
manager="$HOME/.local/share/dev-env-manager"
prefix="$HOME/.local/share/dev-env"
neovim="$HOME/.local/share/dev-env-neovim"
enable_ssh=false
plan=false
configs_only=false
for argument in "$@"; do
  case "$argument" in
    --plan) plan=true ;;
    --enable-ssh) enable_ssh=true ;;
    --configs-only) configs_only=true ;;
    --help)
      printf '%s\n' 'Usage: bash install.sh [--plan] [--enable-ssh] [--configs-only]' \
        'Installs in HOME; backs up replaced configs. --enable-ssh adds an interactive SSH-only Bash launcher.' \
        '--configs-only reapplies configs without downloading or changing installed tool versions.'
      exit 0 ;;
    *) printf 'Unknown argument: %s\n' "$argument" >&2; exit 2 ;;
  esac
done
[ -f "$bundle/payload/.zshrc" ] || {
  echo 'Run this installer from the generated remote-dev-env bundle, not the source directory.' >&2
  exit 1
}
if $configs_only; then
  printf 'Config-only update; installed tool versions are preserved.\n'
else
  printf 'Packages from conda-forge into %s:\n' "$prefix"
  cat "$bundle/environment.txt"
  printf '\nNeovim v0.12.5 into %s\n' "$neovim"
fi
printf 'Configurations to copy (existing paths are backed up):\n'
cat "$bundle/config-paths.txt"
printf '\nSSH launcher in .bashrc: %s\n' "$enable_ssh"
$plan && exit 0
[ "$(uname -s)" = Linux ] && [ "$(uname -m)" = x86_64 ] || {
  echo 'This bundle supports Linux x86_64.' >&2; exit 1;
}
if $configs_only; then
  for executable in "$manager/bin/micromamba" "$prefix/bin/zsh" "$prefix/bin/tic" "$neovim/bin/nvim"; do
    [ -x "$executable" ] || { printf 'Missing installed tool: %s. Run without --configs-only for initial setup.\n' "$executable" >&2; exit 1; }
  done
  # Add packages introduced after the first install without re-solving existing ones.
  missing=()
  for package in btop yazi; do
    [ -x "$prefix/bin/$package" ] || missing+=("$package")
  done
  if [ ${#missing[@]} -gt 0 ]; then
    printf 'Adding newly bundled packages: %s\n' "${missing[*]}"
    MAMBA_ROOT_PREFIX="$manager" "$manager/bin/micromamba" --no-rc install --yes \
      --root-prefix "$manager" --prefix "$prefix" --override-channels --channel conda-forge \
      --freeze-installed "${missing[@]}"
  fi
else
for tool in curl tar sha256sum; do
  command -v "$tool" >/dev/null || { echo "Required existing command: $tool" >&2; exit 1; }
done
download() {
  curl --fail --location --silent --show-error --retry 3 "$1" -o "$2"
}
verify() {
  printf '%s  %s\n' "$1" "$2" | sha256sum --check --status || {
    echo "Checksum mismatch: $2" >&2; exit 1;
  }
}
scratch=$(mktemp -d)
trap 'rm -rf -- "$scratch"' EXIT
mkdir -p "$manager/bin"
if [ ! -x "$manager/bin/micromamba" ]; then
  download 'https://github.com/mamba-org/micromamba-releases/releases/download/2.9.0-0/micromamba-linux-64' "$scratch/micromamba"
  verify 366cd9cd8be14df1ab8ed50352a82111082a36686b2d389fdb79a92c3fafb3e3 "$scratch/micromamba"
  chmod 755 "$scratch/micromamba"
  mv "$scratch/micromamba" "$manager/bin/micromamba"
fi
export MAMBA_ROOT_PREFIX="$manager"
action=create
[ ! -d "$prefix/conda-meta" ] || action=install
"$manager/bin/micromamba" --no-rc "$action" --yes --root-prefix "$manager" \
  --prefix "$prefix" --override-channels --channel conda-forge --file "$bundle/environment.txt"
if [ ! -x "$neovim/bin/nvim" ]; then
  download 'https://github.com/neovim/neovim/releases/download/v0.12.5/nvim-linux-x86_64.tar.gz' "$scratch/nvim.tar.gz"
  verify bce0f56eda1f1b1db6eee8f4133d7a38813ea07933837dd1777411ca384c6875 "$scratch/nvim.tar.gz"
  tar -xzf "$scratch/nvim.tar.gz" -C "$scratch"
  mv "$scratch/nvim-linux-x86_64" "$neovim"
fi
fi
# Check executable compatibility before replacing the remote shell configs.
"$prefix/bin/zsh" --version
"$neovim/bin/nvim" --version | head -n 3
backup="$HOME/.local/state/dev-env/backups/$(date +%Y%m%d-%H%M%S)-$$"
mkdir -p "$backup"
while IFS= read -r relative; do
  [ -n "$relative" ] || continue
  destination="$HOME/$relative"
  if [ -e "$destination" ] || [ -L "$destination" ]; then
    mkdir -p "$(dirname -- "$backup/$relative")"
    mv -- "$destination" "$backup/$relative"
  fi
  mkdir -p "$(dirname -- "$destination")"
  cp -a -- "$bundle/payload/$relative" "$destination"
done < "$bundle/config-paths.txt"
# Quarantine a Copilot plugin downloaded by an earlier version of this bundle.
copilot_cache="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy/copilot.lua"
if [ -e "$copilot_cache" ] || [ -L "$copilot_cache" ]; then
  mkdir -p "$backup/removed-plugins"
  mv -- "$copilot_cache" "$backup/removed-plugins/copilot.lua"
fi
# Zsh may load a newer compiled cache instead of the copied source file.
for cache in .zshrc.zwc .zcompdump; do
  if [ -e "$HOME/$cache" ] || [ -L "$HOME/$cache" ]; then
    mv -- "$HOME/$cache" "$backup/$cache"
  fi
done
chmod 755 "$HOME/.local/bin/dev-shell"
# Compile terminal descriptions locally; SSH inherits the local terminal type.
mkdir -p "$HOME/.terminfo"
"$prefix/bin/tic" -x -o "$HOME/.terminfo" "$bundle/terminals.ti"
# Initialize completions for the copied config's cached compinit startup.
"$prefix/bin/zsh" -f -c 'autoload -Uz compinit; compinit'
if $enable_ssh; then
    if [ -e "$HOME/.bashrc" ] || [ -L "$HOME/.bashrc" ]; then
      cp -pL "$HOME/.bashrc" "$backup/bashrc-before-ssh-launcher"
      # Replace only our managed block, preserving the rest of the file.
      awk '
        /^# BEGIN portable dev environment$/ { in_block=1; next }
        /^# END portable dev environment$/ { in_block=0; next }
        !in_block { print }
        END { if (in_block) exit 1 }
      ' "$HOME/.bashrc" > "$backup/bashrc-updated"
    else
      touch "$backup/bashrc-was-absent"
      touch "$backup/bashrc-updated"
    fi
    cat >> "$backup/bashrc-updated" <<'EOF'

# BEGIN portable dev environment
if [[ $- == *i* && -n ${SSH_CONNECTION:-} && -z ${DEV_ENV_ACTIVE:-} && ${DEV_ENV_DISABLE:-0} != 1 && -x "$HOME/.local/bin/dev-shell" ]] && "$HOME/.local/bin/dev-shell" --check >/dev/null 2>&1; then
  exec "$HOME/.local/bin/dev-shell"
fi
# END portable dev environment
EOF
    cat "$backup/bashrc-updated" > "$HOME/.bashrc"
    rm -- "$backup/bashrc-updated"
fi
if ! $configs_only; then
  mkdir -p "$HOME/.config/dev-env"
  "$manager/bin/micromamba" --no-rc list --prefix "$prefix" --explicit > "$HOME/.config/dev-env/packages-linux-64.lock"
fi
printf '\nInstalled. Backups: %s\nStart now: exec "$HOME/.local/bin/dev-shell"\n' "$backup"
