#!/usr/bin/env bash
# Ancient Shell installer.
#
#   ./install.sh                 link the shell, fonts and Hyprland fragment; dark Qt/GTK apps
#   ./install.sh --replace-ml4w  also stop ML4W's waybar/swaync/hyprpaper from autostarting
#   ./install.sh --hyprlock      also use the Ancient lock screen (backs up hyprlock.conf)
#   ./install.sh --now           restart the running session's shell right away
#   ./install.sh --uninstall     undo all of the above
#
# Flags combine: ./install.sh --replace-ml4w --hyprlock --now
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
HYPR="$CFG/hypr"
FONTS="${XDG_DATA_HOME:-$HOME/.local/share}/fonts/ancient-shell"
MARK="-- [ancient-shell]"
MARK_RE='-- \[ancient-shell\]'
REQUIRE='require("ancient-shell/init")'

replace_ml4w=0 hyprlock=0 now=0 uninstall=0
for a in "$@"; do
    case "$a" in
        --replace-ml4w) replace_ml4w=1 ;;
        --hyprlock) hyprlock=1 ;;
        --now) now=1 ;;
        --uninstall) uninstall=1 ;;
        -h|--help) sed -n '2,11p' "$0"; exit 0 ;;
        *) echo "unknown option: $a" >&2; exit 2 ;;
    esac
done

say()  { printf '\033[36m::\033[0m %s\n' "$*"; }
warn() { printf '\033[33m!!\033[0m %s\n' "$*" >&2; }

link() { # link <target> <link>
    local target="$1" dest="$2"
    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
        mv "$dest" "$dest.bak.$(date +%s)"
        warn "moved existing $dest aside"
    fi
    ln -sfn "$target" "$dest"
}

# The file Hyprland loads user additions from: ML4W's custom.lua, else hyprland.lua
hypr_entry() {
    if [ -f "$HYPR/conf/custom.lua" ]; then echo "$HYPR/conf/custom.lua"
    elif [ -f "$HYPR/hyprland.lua" ]; then echo "$HYPR/hyprland.lua"
    else echo ""; fi
}

ml4w_autostart_lines=(
    'hl.exec_cmd("hyprpaper")'
    'hl.exec_cmd("swaync")'
    'hl.exec_cmd("~/.config/ml4w/scripts/ml4w-autostart.sh")'
)

# ------------------------------------------------------------------ uninstall
if [ "$uninstall" = 1 ]; then
    say "removing links"
    [ -L "$CFG/quickshell/ancient" ] && rm "$CFG/quickshell/ancient"
    [ -L "$HYPR/ancient-shell" ] && rm "$HYPR/ancient-shell"
    [ -L "$FONTS" ] && rm "$FONTS" && fc-cache -f >/dev/null 2>&1 || true

    entry="$(hypr_entry)"
    if [ -n "$entry" ]; then
        sed -i "\|^$REQUIRE\$|d; \|^-- Ancient Shell\$|d" "$entry"
    fi
    if [ -f "$HYPR/conf/autostart.lua" ]; then
        say "restoring ML4W autostart lines"
        sed -i "s|^\(\s*\)$MARK_RE |\1|" "$HYPR/conf/autostart.lua"
    fi
    for ct in qt5ct qt6ct; do
        dir="$CFG/$ct" bak="$CFG/$ct.ancient-backup"
        [ -f "$dir/.ancient-shell" ] || continue
        say "restoring the previous $ct config"
        rm -rf "$dir"
        if [ -e "$bak" ] || [ -L "$bak" ]; then mv "$bak" "$dir"; fi
    done
    if [ -L "$HYPR/hyprlock.conf" ]; then
        rm "$HYPR/hyprlock.conf"
        last="$(ls -t "$HYPR"/hyprlock.conf.bak.* 2>/dev/null | head -1 || true)"
        [ -n "$last" ] && mv "$last" "$HYPR/hyprlock.conf" && say "restored $last"
    fi
    if [ "$now" = 1 ]; then
        qs -c ancient kill >/dev/null 2>&1 || true
        command -v hyprpaper >/dev/null && (hyprpaper >/dev/null 2>&1 &)
        command -v swaync >/dev/null && (swaync >/dev/null 2>&1 &)
        [ -x "$CFG/waybar/launch.sh" ] && ("$CFG/waybar/launch.sh" >/dev/null 2>&1 &)
    fi
    say "done — reload Hyprland (hyprctl reload) to drop the key bindings"
    exit 0
fi

# ------------------------------------------------------------------ checks
missing=()
for c in qs hyprctl brightnessctl nmcli; do command -v "$c" >/dev/null || missing+=("$c"); done
[ ${#missing[@]} -gt 0 ] && warn "missing commands: ${missing[*]} (pacman -S quickshell brightnessctl networkmanager)"
command -v magick >/dev/null || warn "imagemagick not found: the lock screen background will not be generated"
command -v cava >/dev/null || warn "cava not found (pacman -S cava): the music effects will stay still"
grep -q "Material Symbols Rounded" <(fc-list : family) \
    || warn "font 'Material Symbols Rounded' not found (AUR: ttf-material-symbols-variable-git)"
grep -q "FiraCode Nerd Font" <(fc-list : family) || warn "font 'FiraCode Nerd Font' not found (pacman -S ttf-firacode-nerd)"

# ------------------------------------------------------------------ links
say "linking shell → $CFG/quickshell/ancient"
mkdir -p "$CFG/quickshell"
link "$REPO/quickshell/ancient" "$CFG/quickshell/ancient"

say "linking fonts → $FONTS"
mkdir -p "$(dirname "$FONTS")"
link "$REPO/quickshell/ancient/assets/fonts" "$FONTS"
fc-cache -f >/dev/null 2>&1 || true

if [ -d "$HYPR" ]; then
    say "linking Hyprland fragment → $HYPR/ancient-shell"
    link "$REPO/hypr" "$HYPR/ancient-shell"

    entry="$(hypr_entry)"
    if [ -z "$entry" ]; then
        warn "no hyprland.lua found; add  $REQUIRE  to your config by hand"
    elif ! grep -qxF "$REQUIRE" "$entry"; then
        [ -n "$(tail -c1 "$entry")" ] && echo >> "$entry"
        printf -- '-- Ancient Shell\n%s\n' "$REQUIRE" >> "$entry"
        say "added $REQUIRE to $entry"
    fi
else
    warn "$HYPR not found; skipping the Hyprland fragment"
fi

# ------------------------------------------------------------------ dark apps
# Qt 5 and 6: qt5ct/qt6ct with Fusion and the Ancient palette. An existing
# config (ML4W links qt6ct into its dotfiles) is kept as <dir>.ancient-backup
# and restored on --uninstall.
say "Qt apps → qt5ct/qt6ct, Fusion, Ancient dark palette"
for ct in qt5ct qt6ct; do
    dir="$CFG/$ct" bak="$CFG/$ct.ancient-backup"
    if [ ! -f "$dir/.ancient-shell" ]; then
        if [ -e "$dir" ] || [ -L "$dir" ]; then
            rm -rf "$bak"
            mv "$dir" "$bak"
        fi
        mkdir -p "$dir"
        touch "$dir/.ancient-shell"
    fi
    link "$REPO/apps/$ct/colors" "$dir/colors"
    sed "s|@DIR@|$dir|" "$REPO/apps/$ct/$ct.conf.in" > "$dir/$ct.conf"
    command -v "$ct" >/dev/null || warn "$ct not found (pacman -S $ct): those Qt apps will stay light"
done

# GTK: dark Adwaita for GTK 3, prefer-dark for libadwaita/Electron (via the portal)
say "GTK apps → Adwaita-dark, color-scheme prefer-dark"
if command -v gsettings >/dev/null; then
    gsettings set org.gnome.desktop.interface color-scheme prefer-dark
    gsettings set org.gnome.desktop.interface gtk-theme Adwaita-dark
fi
for v in 3.0 4.0; do
    ini="$CFG/gtk-$v/settings.ini"
    [ -f "$ini" ] || continue
    if grep -q '^gtk-application-prefer-dark-theme=' "$ini"; then
        sed -i 's/^gtk-application-prefer-dark-theme=.*/gtk-application-prefer-dark-theme=1/' "$ini"
    else
        sed -i '/^\[Settings\]/a gtk-application-prefer-dark-theme=1' "$ini"
    fi
done

# ------------------------------------------------------------------ ML4W shell pieces
if [ "$replace_ml4w" = 1 ] && [ -f "$HYPR/conf/autostart.lua" ]; then
    say "disabling ML4W waybar/swaync/hyprpaper autostart"
    for l in "${ml4w_autostart_lines[@]}"; do
        esc="$(printf '%s' "$l" | sed 's/[][\.*^$/|]/\\&/g')"
        sed -i "s|^\(\s*\)\($esc\)|\1$MARK \2|" "$HYPR/conf/autostart.lua"
    done
fi

# ------------------------------------------------------------------ lock screen
if [ "$hyprlock" = 1 ]; then
    if [ -e "$HYPR/hyprlock.conf" ] && [ ! -L "$HYPR/hyprlock.conf" ]; then
        cp "$HYPR/hyprlock.conf" "$HYPR/hyprlock.conf.bak.$(date +%s)"
    fi
    ln -sfn "$REPO/hypr/hyprlock.conf" "$HYPR/hyprlock.conf"
    say "hyprlock now uses the Ancient lock screen"
fi

# Lock-screen background for the current wallpaper
wall="$(cat "${XDG_STATE_HOME:-$HOME/.local/state}"/quickshell/by-shell/*/wallpaper.json 2>/dev/null \
    | sed -n 's/.*"current": *"\([^"]*\)".*/\1/p' | head -1)"
[ -z "$wall" ] && wall="$HOME/Pictures/Wallpapers/earth_stargate.png"
[ -f "$wall" ] && "$REPO/quickshell/ancient/scripts/wallpaper-hook.sh" "$wall" || true

# ------------------------------------------------------------------ start
if [ "$now" = 1 ]; then
    say "switching the running session to Ancient Shell"
    if [ "$replace_ml4w" = 1 ]; then
        pkill -x waybar || true
        pkill -x swaync || true
        pkill -x hyprpaper || true
    fi
    qs -c ancient kill >/dev/null 2>&1 || true
    sleep 0.5
    qs -c ancient -n -d >/dev/null 2>&1
    hyprctl reload >/dev/null || true
fi

say "done. Bindings: SUPER+D launcher · SUPER+A dashboard · SUPER+N controls · SUPER+CTRL+W wallpapers · SUPER+CTRL+Q session"
