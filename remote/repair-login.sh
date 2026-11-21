#!/bin/bash
# Run in the SCHOOL account, for example on tuxworld. No SSH or downloads.
# Preserve the installed environment; only guard its existing launcher.
set -euo pipefail
umask 077
cd -- "$HOME"
launcher="$HOME/.local/bin/dev-shell"
if [[ ! -f $launcher ]]; then
  printf 'No installed launcher at %s\n' "$launcher" >&2
  exit 1
fi
if grep -q '^# BEGIN portable login compatibility guard$' "$launcher"; then
  echo 'The installed launcher already has the compatibility guard.'
  exit 0
fi
backup="${launcher}.before-login-repair-$(date +%Y%m%d-%H%M%S)-$$"
replacement=$(mktemp "$HOME/.local/bin/.dev-shell-repair.XXXXXX")
trap 'if [[ -e $replacement ]]; then rm -- "$replacement"; fi' EXIT
cp -pL -- "$launcher" "$backup"
cat > "$replacement" <<'GUARD'
#!/bin/bash
# BEGIN portable login compatibility guard
# Do not expose another CPU type to the installed x86_64 executables.
if ! builtin pwd -P >/dev/null 2>&1; then
  builtin cd -- "$HOME" || exit 1
fi
_portable_login_fallback() {
  [[ ${1:-} != --check ]] || exit 1
  export DEV_ENV_DISABLE=1
  unset DEV_ENV_ACTIVE
  exec /bin/bash -l "$@"
}
if [[ $(uname -s) != Linux || $(uname -m) != x86_64 ]]; then
  _portable_login_fallback "$@"
fi
for _portable_binary in "$HOME/.local/share/dev-env-manager/bin/micromamba" \
                        "$HOME/.local/share/dev-env/bin/zsh"; do
  if [[ ! -x $_portable_binary ]] || ! "$_portable_binary" --version >/dev/null 2>&1; then
    _portable_login_fallback "$@"
  fi
done
unset _portable_binary
[[ ${1:-} != --check ]] || exit 0
# END portable login compatibility guard

GUARD
cat "$backup" >> "$replacement"
bash -n "$replacement"
chmod 755 "$replacement"
mv -- "$replacement" "$launcher"
printf 'Repaired installed launcher: %s\nOriginal saved at: %s\n' "$launcher" "$backup"
echo 'Reconnect normally. On hosts sharing this HOME, compatible x86_64 keeps the dev shell; other CPUs use system Bash.'
