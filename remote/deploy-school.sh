#!/bin/bash
# Run on the workstation so SSH can ask for the school password in your terminal.
set -euo pipefail
umask 077

if [[ ${1:-} == --help || $# -gt 2 ]]; then
  printf '%s\n' 'Usage: bash deploy-school.sh [user@host] [bundle.tar.gz]' \
    'Defaults: the SSH alias tux (set it up in ~/.ssh/config.d/) and ~/remote-dev-env.tar.gz.' \
    'Reuses an existing portable tool installation; otherwise installs in HOME without sudo.'
  exit 0
fi
school_host=${1:-tux}
bundle=${2:-$HOME/remote-dev-env.tar.gz}
[[ $school_host != -* && -f $bundle ]] || {
  echo 'Provide an SSH destination and an existing bundle. Build with remote/build-bundle.py first.' >&2
  exit 2
}
for tool in ssh scp mktemp; do
  command -v "$tool" >/dev/null || { printf 'Missing local command: %s\n' "$tool" >&2; exit 1; }
done

# Share one authenticated connection across the probe, transfer, and installation.
scratch=$(mktemp -d /tmp/dev-env-ssh.XXXXXXXX)
ssh_options=(-o ControlMaster=auto -o "ControlPath=$scratch/ssh-%C" -o ControlPersist=60 -o ConnectTimeout=15)
cleanup() {
  ssh -o "ControlPath=$scratch/ssh-%C" -O exit "$school_host" >/dev/null 2>&1 || true
  rm -rf -- "$scratch"
}
trap cleanup EXIT

printf 'Connecting to %s. Enter your school password if SSH requests it.\n' "$school_host"
remote_stage=$(ssh "${ssh_options[@]}" "$school_host" '
  [ "$(uname -s)" = Linux ] && [ "$(uname -m)" = x86_64 ] || {
    echo "The portable tools require Linux x86_64." >&2; exit 1;
  }
  for tool in bash tar; do
    command -v "$tool" >/dev/null || { echo "Missing remote command: $tool" >&2; exit 1; }
  done
  mktemp -d /tmp/remote-dev-env.XXXXXXXX
')
# Keep the path safe to embed in the remote shell command and SCP destination.
[[ $remote_stage =~ ^/tmp/remote-dev-env\.[[:alnum:]]+$ ]] || {
  echo 'Unexpected remote staging path; nothing uploaded.' >&2
  exit 1
}
scp "${ssh_options[@]}" -- "$bundle" "$school_host:$remote_stage/bundle.tar.gz"
ssh "${ssh_options[@]}" "$school_host" "bash -s -- '$remote_stage'" <<'REMOTE'
set -euo pipefail
stage=$1
tar -xzf "$stage/bundle.tar.gz" -C "$stage" --strip-components=1
installer_args=(--enable-ssh)
if [[ -x "$HOME/.local/share/dev-env-manager/bin/micromamba" &&
      -x "$HOME/.local/share/dev-env/bin/zsh" &&
      -x "$HOME/.local/share/dev-env/bin/tic" &&
      -x "$HOME/.local/share/dev-env-neovim/bin/nvim" ]]; then
  installer_args+=(--configs-only)
  echo 'Existing portable tools found: applying configs without changing tool versions.'
else
  echo 'Installing portable tools under ~/.local; no sudo or system package changes.'
fi
bash "$stage/install.sh" "${installer_args[@]}"
"$HOME/.local/bin/dev-shell" --check
rm -rf -- "$stage"
REMOTE
printf '\nDeployment finished. Connect with: ssh -t %s\n' "$school_host"
printf 'For an explicit launch: ssh -t %s '\''exec "$HOME/.local/bin/dev-shell"'\''\n' "$school_host"
