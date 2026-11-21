#!/bin/sh
# System changes from the 2026-11-17 developer-environment audit (DEV_AUDIT.md)
# for this ThinkPad T480. Dotfile changes are applied separately with Stow.
#
#   system/dev-audit-2026-11.sh            ask before every step (default: no)
#   system/dev-audit-2026-11.sh --dry-run  describe every step, change nothing
#   system/dev-audit-2026-11.sh --yes      run every step without asking
#
# Run it as your user: privileged commands use sudo. pacman still asks for its
# own confirmation. Each step can be re-run safely. Before replacing a system
# file, the first run keeps the original as <file>.pre-dev-audit.
set -eu

mode=ask
case "${1:-}" in
  '') ;;
  --dry-run) mode=dry ;;
  --yes) mode=yes ;;
  -h|--help) sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  *) printf 'Usage: %s [--dry-run|--yes]\n' "$0" >&2; exit 2 ;;
esac

if [ "$(id -u)" -eq 0 ]; then
  echo 'Run this as your user, not root; privileged steps use sudo.' >&2
  exit 1
fi

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT HUP INT TERM

# step TITLE DETAILS: print what the step does; succeed if it should run.
step() {
  printf '\n\033[1m== %s\033[0m\n%s\n' "$1" "$2"
  case "$mode" in
    dry) printf '(dry run: not changed)\n'; return 1 ;;
    yes) return 0 ;;
  esac
  printf 'Run this step? [y/N] '
  read -r answer || answer=
  case "$answer" in
    y|Y|yes|YES) return 0 ;;
    *) printf 'Skipped.\n'; return 1 ;;
  esac
}

run() {
  printf '+ %s\n' "$*"
  "$@"
}

# install_root_file TARGET MODE SOURCE: back up TARGET once, then replace it.
install_root_file() {
  if [ -e "$1" ] && [ ! -e "$1.pre-dev-audit" ]; then
    run sudo cp -p "$1" "$1.pre-dev-audit"
  fi
  run sudo install -D -m "$2" "$3" "$1"
}

packages='openssh rsync man-db man-pages git-delta lazygit
clang gdb bear valgrind strace shellcheck shfmt ast-grep hyperfine
cliphist libnotify noto-fonts-emoji
intel-media-driver libva-utils
riscv64-elf-gcc riscv64-elf-binutils riscv64-elf-gdb qemu-system-riscv
earlyoom reflector fwupd restic'

if step "Packages (pacman -Syu)" "Upgrades the system and installs, if missing:
$(printf '%s\n' "$packages" | sed 's/^/  /')
The first three lines match the dotfiles manifests. The rest are for this
laptop: Intel hardware video decoding, the RISC-V toolchain and QEMU for xv6,
earlyoom, reflector, fwupd, and restic. mise is not installed here: it would
replace pyenv's Python for new shells, which is a separate decision."; then
  # shellcheck disable=SC2086 # deliberate word splitting of the package list
  run sudo pacman -Syu --needed $packages
  if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] && command -v hyprctl >/dev/null 2>&1; then
    # The clipboard recorder normally starts at login; start it in this session.
    run hyprctl dispatch 'hl.dsp.exec_cmd("~/.config/hypr/scripts/clipboard-history --watch")' >/dev/null
  fi
fi

if step "Battery charge thresholds (TLP)" "Writes /etc/tlp.d/10-charge-thresholds.conf: charge to 80% and resume below 75%,
which slows wear on a battery that is usually on AC. Before travelling, run
'sudo tlp fullcharge BAT1' to charge fully once."; then
  if ! command -v tlp >/dev/null 2>&1; then
    echo 'TLP is not installed; skipped.'
  else
    cat >"$work/tlp" <<'EOF'
# Dev audit 2026-11-17: limit charging while the laptop is usually on AC.
# BAT0 is the internal battery and BAT1 the rear battery; absent ones are ignored.
START_CHARGE_THRESH_BAT0=75
STOP_CHARGE_THRESH_BAT0=80
START_CHARGE_THRESH_BAT1=75
STOP_CHARGE_THRESH_BAT1=80
EOF
    install_root_file /etc/tlp.d/10-charge-thresholds.conf 644 "$work/tlp"
    run sudo tlp start
    for battery in /sys/class/power_supply/BAT*; do
      [ -e "$battery/charge_control_end_threshold" ] || continue
      printf '%s: start %s%%, stop %s%%\n' "${battery##*/}" \
        "$(cat "$battery/charge_control_start_threshold")" "$(cat "$battery/charge_control_end_threshold")"
    done
  fi
fi

if step "Inbound firewall (nftables)" "Replaces /etc/nftables.conf with Arch's default inbound policy (drop unsolicited
connections) plus Tailscale, local Docker bridges, and DHCPv6 replies, then
enables nftables.service. Forwarding stays open so Docker containers keep
networking. Dev servers bound to all interfaces stop being reachable from
other machines on the same Wi-Fi. To turn the firewall off temporarily:
'sudo nft delete table inet filter'."; then
  cat >"$work/nftables.conf" <<'EOF'
#!/usr/bin/nft -f
# Inbound default-deny for a laptop on untrusted networks, based on Arch's
# default ruleset (dev audit 2026-11-17). Only this table is replaced, so the
# tables that Docker and Tailscale manage survive reloads.

destroy table inet filter
table inet filter {
  chain input {
    type filter hook input priority filter
    policy drop

    ct state invalid drop comment "early drop of invalid connections"
    ct state {established, related} accept comment "allow tracked connections"
    iif lo accept comment "allow from loopback"
    meta l4proto { icmp, icmpv6 } accept comment "allow icmp"
    iifname "tailscale0" accept comment "allow the tailnet"
    udp dport 41641 accept comment "allow direct Tailscale connections"
    iifname "docker0" accept comment "allow local containers"
    iifname "br-*" accept comment "allow local compose networks"
    ip6 saddr fe80::/10 udp dport dhcpv6-client accept comment "allow DHCPv6 replies"
    tcp dport ssh accept comment "allow sshd"
    pkttype host limit rate 5/second counter reject with icmpx type admin-prohibited
    counter
  }
  chain forward {
    # Docker container traffic passes through this hook; a drop here would
    # break it even though Docker adds its own rules.
    type filter hook forward priority filter
    policy accept
  }
}
EOF
  run sudo nft -c -f "$work/nftables.conf"
  install_root_file /etc/nftables.conf 644 "$work/nftables.conf"
  run sudo systemctl enable --now nftables.service
  run sudo nft -f /etc/nftables.conf
  if command -v tailscale >/dev/null 2>&1; then
    tailscale status >/dev/null 2>&1 && echo 'Tailscale: connected.' || echo 'Tailscale: check "tailscale status".'
  fi
fi

if step "Out-of-memory guard (earlyoom)" "Enables earlyoom with /etc/default/earlyoom set to keep Hyprland, kitty, tmux,
Neovim, and Xwayland, and to stop browser content processes first. It acts
when free RAM and swap both drop below 10%, before the desktop freezes."; then
  if ! command -v earlyoom >/dev/null 2>&1; then
    echo 'earlyoom is not installed; run the packages step first.'
  else
    if ! systemctl cat earlyoom.service 2>/dev/null | grep -q 'EARLYOOM_ARGS'; then
      echo 'warning: earlyoom.service does not read EARLYOOM_ARGS; the defaults below may be ignored.'
    fi
    # systemd splits $EARLYOOM_ARGS on whitespace and does not expand '$' here,
    # so the regular expressions avoid spaces and end anchors.
    cat >"$work/earlyoom" <<'EOF'
# Dev audit 2026-11-17: protect the desktop and editors; free browser tabs first.
EARLYOOM_ARGS="-r 3600 --avoid ^(Hyprland|kitty|tmux|nvim|Xwayland) --prefer ^(Isolated.Web.Co|Web.Content)"
EOF
    install_root_file /etc/default/earlyoom 644 "$work/earlyoom"
    run sudo systemctl enable --now earlyoom.service
    run sudo systemctl restart earlyoom.service
    journalctl -u earlyoom.service -n 6 --no-pager -o cat 2>/dev/null || true
  fi
fi

if step "Boot menu timeout (GRUB)" "Sets GRUB_TIMEOUT from its current value to 1 second in /etc/default/grub and
regenerates /boot/grub/grub.cfg. The menu still appears for that second."; then
  if [ ! -f /etc/default/grub ] || ! command -v grub-mkconfig >/dev/null 2>&1; then
    echo 'GRUB is not in use here; skipped.'
  else
    sed 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=1/' /etc/default/grub >"$work/grub"
    install_root_file /etc/default/grub 644 "$work/grub"
    run sudo grub-mkconfig -o /boot/grub/grub.cfg
  fi
fi

if step "Mirrors and pacman output" "Writes /etc/xdg/reflector/reflector.conf (the 10 fastest of the 20 most recently
synced HTTPS mirrors in Canada and the US), refreshes the mirror list now and
weekly, and removes the obsolete mirrorlist.pacnew. In /etc/pacman.conf it
enables Color and VerbosePkgLists and raises ParallelDownloads to 10."; then
  if ! command -v reflector >/dev/null 2>&1; then
    echo 'reflector is not installed; run the packages step first.'
  else
    cat >"$work/reflector.conf" <<'EOF'
# Dev audit 2026-11-17: nearby, recently synced HTTPS mirrors.
--save /etc/pacman.d/mirrorlist
--protocol https
--country CA,US
--latest 20
--sort rate
--number 10
EOF
    install_root_file /etc/xdg/reflector/reflector.conf 644 "$work/reflector.conf"
    [ -e /etc/pacman.d/mirrorlist.pre-dev-audit ] || run sudo cp -p /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.pre-dev-audit
    run sudo systemctl start reflector.service
    run sudo systemctl enable --now reflector.timer
    [ ! -e /etc/pacman.d/mirrorlist.pacnew ] || run sudo rm /etc/pacman.d/mirrorlist.pacnew
    grep -m 3 '^Server' /etc/pacman.d/mirrorlist || true
  fi
  sed -e 's/^#Color$/Color/' -e 's/^#VerbosePkgLists$/VerbosePkgLists/' \
      -e 's/^ParallelDownloads = .*/ParallelDownloads = 10/' /etc/pacman.conf >"$work/pacman.conf"
  if ! cmp -s /etc/pacman.conf "$work/pacman.conf"; then
    install_root_file /etc/pacman.conf 644 "$work/pacman.conf"
  fi
fi

if step "Package cache and orphans" "Keeps two versions of each installed package in the pacman cache (weekly
paccache.timer, through a drop-in), prunes the cache now, removes cached
packages that are no longer installed, and offers to remove orphaned
dependencies (pacman lists them and asks)."; then
  printf '[Service]\nEnvironment=PACCACHE_ARGS=-k2\n' >"$work/paccache.conf"
  run sudo install -D -m 644 "$work/paccache.conf" /etc/systemd/system/paccache.service.d/keep-two.conf
  run sudo systemctl daemon-reload
  run sudo paccache -rk2
  run sudo paccache -ruk0
  orphans=$(pacman -Qdtq || true)
  if [ -n "$orphans" ]; then
    # shellcheck disable=SC2086 # one argument per package name
    run sudo pacman -Rns $orphans
  else
    echo 'No orphaned packages.'
  fi
fi

if step "User caches" "Clears the npm and pip download caches (about 11 GB together when audited).
Packages download again on demand; nothing installed is removed."; then
  if command -v npm >/dev/null 2>&1; then run npm cache clean --force; fi
  if command -v pip >/dev/null 2>&1; then run pip cache purge; fi
fi

if step "Firmware check (fwupd)" "Refreshes firmware metadata from the Linux Vendor Firmware Service and lists
available BIOS, embedded controller, and Thunderbolt updates. It installs
nothing; apply an update later with 'fwupdmgr update' while on AC."; then
  if ! command -v fwupdmgr >/dev/null 2>&1; then
    echo 'fwupd is not installed; run the packages step first.'
  else
    run sudo fwupdmgr refresh --force || true
    run fwupdmgr get-updates || true
  fi
fi

if step "SSH key passphrase" "Adds a passphrase to ~/.ssh/id_ed25519 (ssh-keygen asks for it). The key
then stays encrypted on disk; with the new ~/.ssh/config, the agent asks for
the passphrase once per login. Existing authorized_keys entries keep working."; then
  run ssh-keygen -p -f "$HOME/.ssh/id_ed25519"
fi

printf '\n'
if [ ! -d "/usr/lib/modules/$(uname -r)" ]; then
  echo 'The kernel was upgraded: restart the machine when convenient to finish.'
fi
echo 'Done. DEV_AUDIT.md lists follow-ups that need your decision (backups, mise, commit signing).'
