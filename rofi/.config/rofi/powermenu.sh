#!/bin/sh
set -eu

theme="$HOME/.config/rofi/powermenu.rasi"
choice=$(printf '%s\n' Lock Logout Suspend Reboot Poweroff | rofi -dmenu -i -p Power -theme "$theme") || exit 0
confirmed=$(printf '%s\n' No Yes | rofi -dmenu -p "Confirm $choice?" -theme "$theme") || exit 0
[ "$confirmed" = Yes ] || exit 0

case "$choice" in
  Lock) loginctl lock-session ;;
  Logout) hyprctl dispatch exit ;;
  Suspend) loginctl lock-session && systemctl suspend ;;
  Reboot) systemctl reboot ;;
  Poweroff) systemctl poweroff ;;
esac
