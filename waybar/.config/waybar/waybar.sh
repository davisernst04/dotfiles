#!/bin/sh
set -eu

if pgrep -x waybar >/dev/null 2>&1; then
    pkill -x waybar
else
    waybar >/dev/null 2>&1 &
fi
