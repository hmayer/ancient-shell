#!/usr/bin/env bash
# Runs when the shell starts and after it changes the wallpaper.
# Records the wallpaper in $XDG_CACHE_HOME/ancient-shell/current_wallpaper and
# writes a blurred copy, lock.png, for the lock screen (hypr/hyprlock.conf.in).
# Nothing to do when that wallpaper's copy is already there.
set -euo pipefail

wall="${1:?usage: wallpaper-hook.sh <image>}"
[ -f "$wall" ] || { echo "no such file: $wall" >&2; exit 1; }

# Without ImageMagick there is no background to make, and nothing is recorded,
# so it is made once ImageMagick is there
command -v magick >/dev/null || exit 0

cache="${XDG_CACHE_HOME:-$HOME/.cache}/ancient-shell"
mkdir -p "$cache"

if [ -f "$cache/lock.png" ] && [ "$(cat "$cache/current_wallpaper" 2>/dev/null)" = "$wall" ] \
    && [ ! "$wall" -nt "$cache/lock.png" ]; then
    exit 0
fi

magick "$wall[0]" -resize 1920x1080^ -gravity center -extent 1920x1080 \
    -blur 0x18 -fill '#07090a' -colorize 25% "$cache/lock.tmp.png"
mv "$cache/lock.tmp.png" "$cache/lock.png"
printf '%s\n' "$wall" > "$cache/current_wallpaper"
