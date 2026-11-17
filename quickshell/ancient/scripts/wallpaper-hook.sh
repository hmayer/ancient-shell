#!/usr/bin/env bash
# Runs after the shell changes the wallpaper.
# Writes a blurred copy for the lock screen and keeps ML4W's cache in sync,
# so tools that read it (hyprlock, scripts) follow the new wallpaper.
set -euo pipefail

wall="${1:?usage: wallpaper-hook.sh <image>}"
[ -f "$wall" ] || { echo "no such file: $wall" >&2; exit 1; }

cache="${XDG_CACHE_HOME:-$HOME/.cache}/ancient-shell"
mkdir -p "$cache"
printf '%s\n' "$wall" > "$cache/current_wallpaper"

blur() {
    command -v magick >/dev/null || return 0
    magick "$wall[0]" -resize 1920x1080^ -gravity center -extent 1920x1080 \
        -blur 0x18 -fill '#07090a' -colorize 25% "$1.tmp.png" && mv "$1.tmp.png" "$1"
}

blur "$cache/lock.png"

ml4w="$HOME/.cache/ml4w/hyprland-dotfiles"
if [ -d "$ml4w" ]; then
    printf '%s\n' "$wall" > "$ml4w/current_wallpaper"
    cp -f "$cache/lock.png" "$ml4w/blurred_wallpaper.png" 2>/dev/null || true
fi
