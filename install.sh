#!/usr/bin/env bash
# Ancient Shell installer, for any Hyprland setup with a Lua config (hyprland.lua).
#
#   ./install.sh                      link the shell, fonts and Hyprland fragment; dark Qt/GTK apps;
#                                     write the shell's config.json if there is none
#   ./install.sh --entry FILE         load the fragment from FILE (a .lua that Hyprland loads)
#                                     instead of hyprland.lua
#   ./install.sh --disable-autostart  also comment out the autostart of the bars, notification and
#                                     wallpaper daemons the shell replaces (waybar, swaync, mako…)
#   ./install.sh --hyprlock           also use the Ancient lock screen (backs up hyprlock.conf)
#   ./install.sh --now                switch the running session right away
#   ./install.sh --uninstall          undo all of the above
#
# Flags combine: ./install.sh --disable-autostart --hyprlock --now
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
HYPR="$CFG/hypr"
FONTS="${XDG_DATA_HOME:-$HOME/.local/share}/fonts/ancient-shell"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/ancient-shell"   # same as scripts/wallpaper-hook.sh
SHELL_CONFIG="$CFG/ancient-shell/config.json"           # same as services/Config.qml
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/ancient-shell"
ENTRY_RECORD="$STATE/hypr-entry"                         # the file the require line was added to
LOCK_SUM="$STATE/hyprlock.sum"                           # checksum of the hyprlock.conf written last
MARK="-- [ancient-shell]"
MARK_RE='-- \[ancient-shell\] '
LOCK_MARK="# [ancient-shell]"                            # first line of a generated hyprlock.conf
REQUIRE='require("ancient-shell/init")'
REQUIRE_RE='^[[:space:]]*require[[:space:]]*\(?[[:space:]]*["'\'']ancient-shell[./]init["'\''][[:space:]]*\)?[[:space:]]*;?[[:space:]]*(--.*)?$'

# What the shell replaces: bars, notification daemons, wallpaper daemons. Process names
# for --now, plus the names an autostart line may call them by (and other Quickshell configs).
CONFLICTS=(waybar swaync mako dunst fnott hyprpaper swww-daemon swaybg wpaperd hyprpanel)
CONFLICT_NAMES="$(IFS='|'; echo "${CONFLICTS[*]}")|swww|qs|quickshell"
B='[^[:alnum:]_-]'
# hl.exec_cmd with a single string literal, as a whole statement on its line; the
# literal (\2\3 of LIT_RE) is the command
LIT_RE="hl\\.exec_cmd[[:space:]]*\\([[:space:]]*(\"([^\"]*)\"|'([^']*)')[[:space:]]*\\)"
# Such a line whose command names one of them as a whole word ("waybar",
# "~/.config/waybar/launch.sh"). Only these lines are commented out: commenting one
# line of a longer statement, or a line with other statements, breaks the file.
DQ="\"([^\"]*[^[:alnum:]_\"-])?($CONFLICT_NAMES)([^[:alnum:]_\"-][^\"]*)?\""
SQ="'([^']*[^[:alnum:]_'-])?($CONFLICT_NAMES)([^[:alnum:]_'-][^']*)?'"
AUTOSTART_RE="^([[:space:]]*)(hl\\.exec_cmd[[:space:]]*\\([[:space:]]*($DQ|$SQ)[[:space:]]*\\)[[:space:]]*;?[[:space:]]*(--.*)?)\$"
# …except lines that stop one of them: left alone, so --uninstall --now never re-runs them
STOP_RE="hl\\.exec_cmd[[:space:]]*\\([[:space:]]*[\"'](pkill|killall)[[:space:]]"

entry="" disable_autostart=0 hyprlock=0 now=0 uninstall=0
while [ $# -gt 0 ]; do
    case "$1" in
        --entry) [ $# -ge 2 ] || { echo "--entry needs a file" >&2; exit 2; }; entry="$2"; shift ;;
        --entry=*) entry="${1#--entry=}" ;;
        --disable-autostart) disable_autostart=1 ;;
        --hyprlock) hyprlock=1 ;;
        --now) now=1 ;;
        --uninstall) uninstall=1 ;;
        -h|--help) sed -n '2,14p' "$0"; exit 0 ;;
        *) echo "unknown option: $1" >&2; exit 2 ;;
    esac
    shift
done
case "$entry" in ""|/*) ;; *) entry="$PWD/$entry" ;; esac

say()  { printf '\033[36m::\033[0m %s\n' "$*"; }
warn() { printf '\033[33m!!\033[0m %s\n' "$*" >&2; }

# A name for a backup of FILE that no earlier backup has: FILE.bak.<time>[.<n>]
bak_name() {
    local b="$1.bak.$(date +%s)" n=1
    while [ -e "$b" ] || [ -L "$b" ]; do b="$1.bak.$(date +%s).$n"; n=$((n + 1)); done
    printf '%s' "$b"
}

link() { # link <target> <link>
    local target="$1" dest="$2"
    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
        mv "$dest" "$(bak_name "$dest")"
        warn "moved existing $dest aside"
    fi
    ln -sfn "$target" "$dest"
}

# A value for the replacement side of sed's s|…|…|
sed_escape() { printf '%s' "$1" | sed 's/[&|\\]/\\&/g'; }

# Every Lua file of the Hyprland config, following links to files and directories
# (dotfiles managers link either) but not our own fragment, plus the file the require
# line went to, wherever it is
lua_files() {
    if [ -d "$HYPR" ]; then
        find -L "$HYPR" -path "$HYPR/ancient-shell" -prune -o -name '*.lua' -type f -print 2>/dev/null || true
    fi
    if [ -f "$ENTRY_RECORD" ]; then cat "$ENTRY_RECORD"; fi
    if [ -n "$entry" ]; then printf '%s\n' "$entry"; fi
}
# Each file once, however many paths lead to it (a link, the recorded real path)
files=()
declare -A seen=()
while IFS= read -r f; do
    [ -f "$f" ] || continue
    real="$(readlink -f "$f")"
    [ -z "${seen[$real]:-}" ] || continue
    seen[$real]=1
    files+=("$f")
done < <(lua_files)

# The commands of the autostart lines marked as disabled, one per line
marked_commands() {
    [ ${#files[@]} -gt 0 ] || return 0
    sed -nE "s/^[[:space:]]*$MARK_RE$LIT_RE.*/\\2\\3/p" "${files[@]}"
}

# The user's own process of that name
user_pid() { pgrep -u "$(id -u)" -x "$1" | head -1 || true; }

# grep over the config files; nothing (and no error) when there are none
grep_lua() { [ ${#files[@]} -gt 0 ] && grep "$@" "${files[@]}" || true; }

# A generated hyprlock.conf nobody edited since (it can still differ from a new one: another
# language, a newer template)
lock_unedited() {
    [ -f "$LOCK_SUM" ] && [ "$(sha256sum < "$1")" = "$(cat "$LOCK_SUM")" ]
}

# The hyprlock.conf this installer wrote: generated (marked), or the link older versions made
lock_is_ours() {
    local f="$1"
    if [ -L "$f" ]; then
        case "$(readlink "$f")" in "$REPO"/*) return 0 ;; esac
        return 1
    fi
    [ -f "$f" ] && head -n1 "$f" | grep -qF "$LOCK_MARK"
}

# ------------------------------------------------------------------ uninstall
if [ "$uninstall" = 1 ]; then
    # While qs can still find the config to tell which instance to stop
    [ "$now" = 1 ] && { qs -c ancient kill >/dev/null 2>&1 || true; }

    # The require line first: without it, the fragment's link can go
    while IFS= read -r f; do
        [ -n "$f" ] || continue
        sed -i --follow-symlinks -E "\\|$REQUIRE_RE|d; /^-- Ancient Shell\$/d" "$f"
        say "removed the fragment from $f"
    done < <(grep_lua -lE "$REQUIRE_RE")
    rm -f "$ENTRY_RECORD"

    say "removing links"
    [ -L "$CFG/quickshell/ancient" ] && rm "$CFG/quickshell/ancient"
    [ -L "$HYPR/ancient-shell" ] && rm "$HYPR/ancient-shell"
    [ -L "$FONTS" ] && rm "$FONTS" && fc-cache -f >/dev/null 2>&1 || true

    # Autostart lines commented out by --disable-autostart
    restored=()
    while IFS= read -r cmd; do
        [ -n "$cmd" ] && restored+=("$cmd")
    done < <(marked_commands)
    while IFS= read -r f; do
        [ -n "$f" ] || continue
        sed -i --follow-symlinks "s|^\(\s*\)$MARK_RE|\1|" "$f"
        say "restored the autostart lines in $f"
    done < <(grep_lua -lE "^[[:space:]]*$MARK_RE")

    for ct in qt5ct qt6ct; do
        dir="$CFG/$ct" bak="$CFG/$ct.ancient-backup"
        [ -f "$dir/.ancient-shell" ] || continue
        say "restoring the previous $ct config"
        rm -rf "$dir"
        if [ -e "$bak" ] || [ -L "$bak" ]; then mv "$bak" "$dir"; fi
    done

    if lock_is_ours "$HYPR/hyprlock.conf"; then
        # A generated file the user edited is kept as a backup
        if [ ! -L "$HYPR/hyprlock.conf" ] && ! lock_unedited "$HYPR/hyprlock.conf"; then
            cp "$HYPR/hyprlock.conf" "$(bak_name "$HYPR/hyprlock.conf")"
            say "backed up your edited $HYPR/hyprlock.conf"
        fi
        rm "$HYPR/hyprlock.conf" "$LOCK_SUM" 2>/dev/null || true
        # The newest backup of the user's own file (not of a generated one they edited)
        last=""
        while IFS= read -r b; do
            if ! lock_is_ours "$b"; then last="$b"; break; fi
        done < <(ls -t "$HYPR"/hyprlock.conf.bak.* 2>/dev/null || true)
        if [ -n "$last" ]; then mv "$last" "$HYPR/hyprlock.conf" && say "restored $last"; fi
    fi

    if [ "$now" = 1 ]; then
        for cmd in "${restored[@]}"; do
            say "starting $cmd"
            setsid -f sh -c "$cmd" >/dev/null 2>&1 || true
        done
        hyprctl reload >/dev/null 2>&1 || true
    fi
    say "done. $SHELL_CONFIG and the wallpapers were kept."
    [ "$now" = 1 ] || say "reload Hyprland (hyprctl reload) to drop the key bindings"
    exit 0
fi

# ------------------------------------------------------------------ checks
missing=()
for c in qs hyprctl brightnessctl nmcli; do command -v "$c" >/dev/null || missing+=("$c"); done
[ ${#missing[@]} -gt 0 ] && warn "missing commands: ${missing[*]} (pacman -S quickshell brightnessctl networkmanager)"
command -v magick >/dev/null || warn "imagemagick not found: the lock screen background will not be generated"
command -v cava >/dev/null || warn "cava not found (pacman -S cava): the music effects will stay still"
command -v python3 >/dev/null || warn "python3 not found: the upgrades module will not work"
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

# ------------------------------------------------------------------ Hyprland fragment
if [ -d "$HYPR" ]; then
    say "linking Hyprland fragment → $HYPR/ancient-shell"
    link "$REPO/hypr" "$HYPR/ancient-shell"

    loaded="$(grep_lua -lE "$REQUIRE_RE" | head -1)"
    if [ -z "$entry" ] && [ -f "$HYPR/hyprland.lua" ]; then entry="$HYPR/hyprland.lua"; fi

    if [ -n "$loaded" ]; then
        say "the fragment is already loaded from $loaded"
    elif [ -n "$entry" ]; then
        [ -f "$entry" ] || { warn "$entry does not exist"; exit 1; }
        [ -n "$(tail -c1 "$entry")" ] && echo >> "$entry"
        printf -- '-- Ancient Shell\n%s\n' "$REQUIRE" >> "$entry"
        # So --uninstall finds it even outside the config directory
        mkdir -p "$STATE"
        printf '%s\n' "$entry" > "$ENTRY_RECORD"
        say "added $REQUIRE to $entry"
    elif [ -f "$HYPR/hyprland.conf" ]; then
        warn "only hyprland.conf (hyprlang) found: the fragment needs a Lua config; see the README for a manual setup"
    else
        warn "no hyprland.lua found; add  $REQUIRE  to your config by hand"
    fi
else
    warn "$HYPR not found; skipping the Hyprland fragment"
fi

# ------------------------------------------------------------------ shell config
# Written once, with what can be found out here; the shell adds nothing to it and
# uses its defaults for every key left out (see the README).
if [ ! -e "$SHELL_CONFIG" ]; then
    pics="$(xdg-user-dir PICTURES 2>/dev/null || true)"
    if [ -z "$pics" ] || [ "$pics" = "$HOME" ]; then pics="$HOME/Pictures"; fi
    walls="$pics/Wallpapers"
    mkdir -p "$walls" "$(dirname "$SHELL_CONFIG")"
    for w in "$REPO"/wallpapers/*.png; do
        [ -e "$walls/${w##*/}" ] || cp "$w" "$walls/"
    done

    term=""
    for t in kitty foot alacritty ghostty konsole xterm; do   # all take `-e <command>`
        if command -v "$t" >/dev/null; then term="$t"; break; fi
    done
    [ -n "$term" ] || { term=kitty; warn "no known terminal found: set \"terminal\" in $SHELL_CONFIG"; }

    json() { # a JSON string, with $HOME written as ~
        local s="$1"
        case "$s" in "$HOME"/*) s="~${s#"$HOME"}" ;; esac
        printf '"%s"' "$(printf '%s' "$s" | sed 's/[\\"]/\\&/g')"
    }
    cat > "$SHELL_CONFIG" <<EOF
{
    "wallpaperDir": $(json "$walls"),
    "defaultWallpaper": $(json "$walls/earth_origin.png"),
    "terminal": $(json "$term")
}
EOF
    say "wrote $SHELL_CONFIG (wallpapers in $walls, terminal $term)"
fi

# ------------------------------------------------------------------ dark apps
# Qt 5 and 6: qt5ct/qt6ct with Fusion and the Ancient palette. An existing
# config (a directory or a link into some dotfiles) is kept as
# <dir>.ancient-backup and restored on --uninstall.
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
    sed "s|@DIR@|$(sed_escape "$dir")|" "$REPO/apps/$ct/$ct.conf.in" > "$dir/$ct.conf"
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
        sed -i --follow-symlinks 's/^gtk-application-prefer-dark-theme=.*/gtk-application-prefer-dark-theme=1/' "$ini"
    else
        sed -i --follow-symlinks '/^\[Settings\]/a gtk-application-prefer-dark-theme=1' "$ini"
    fi
done

# ------------------------------------------------------------------ competing autostart
disabled=" "     # programs whose autostart line is disabled, this run or an earlier one
qs_configs=()    # other Quickshell configs those lines started, as qs arguments
if [ "$disable_autostart" = 1 ]; then
    while IFS= read -r hit; do
        [ -n "$hit" ] || continue
        f="${hit%%:*}" line="${hit#*:}"
        line="${line#*:}"
        case "$line" in *ancient*) continue ;; esac
        if [[ "$line" =~ $STOP_RE ]]; then continue; fi
        say "disabling in ${f#"$HYPR"/}: $(echo "$line" | sed 's/^[[:space:]]*//')"
    done < <(grep_lua -HnE "$AUTOSTART_RE")
    while IFS= read -r f; do
        [ -n "$f" ] || continue
        sed -i --follow-symlinks -E -e "/ancient/b" -e "/$STOP_RE/b" -e "s/$AUTOSTART_RE/\\1$MARK \\2/" "$f"
    done < <(grep_lua -lE "$AUTOSTART_RE")

    while IFS= read -r cmd; do
        for p in "${CONFLICTS[@]}"; do
            if [[ " $cmd " =~ $B$p$B ]]; then disabled+="$p "; fi
        done
        if [[ " $cmd " =~ [[:space:]/](qs|quickshell)[[:space:]] ]]; then
            if [[ "$cmd" =~ (-c|--config)[[:space:]=]+([^[:space:]]+) ]]; then
                qs_configs+=("-c ${BASH_REMATCH[2]}")
            elif [[ "$cmd" =~ (-p|--path)[[:space:]=]+([^[:space:]]+) ]]; then
                qs_configs+=("-p ${BASH_REMATCH[2]/#\~/$HOME}")
            else
                qs_configs+=("")   # the default config
            fi
        fi
    done < <(marked_commands)

    # Running, but not from a line found here: a systemd user service, a script, D-Bus activation
    hypr_unit="$(ps -o uunit= -p "$(user_pid Hyprland)" 2>/dev/null | tr -d '[:space:]' || true)"
    for p in "${CONFLICTS[@]}"; do
        case "$disabled" in *" $p "*) continue ;; esac
        pid="$(user_pid "$p")"
        [ -n "$pid" ] || continue
        unit="$(ps -o uunit= -p "$pid" 2>/dev/null | tr -d '[:space:]' || true)"
        # Its own enabled unit; not the compositor's (uwsm runs Hyprland and what it starts in one)
        if [ -n "$unit" ] && [ "$unit" != "$hypr_unit" ] \
            && [ "$(systemctl --user is-enabled "$unit" 2>/dev/null || true)" = enabled ]; then
            warn "$p runs as the systemd user service $unit: systemctl --user disable --now $unit"
        else
            warn "$p is running but not started by a one-line hl.exec_cmd in $HYPR: disable it where it starts"
        fi
    done
fi

# ------------------------------------------------------------------ lock screen
# The template with its {{texts}} in this locale's language and the date in this locale's
# names; without python3, all in English
render_lock() {
    local tpl="$REPO/hypr/hyprlock.conf.in" lc_time="${LC_ALL:-${LC_TIME:-${LANG:-C.UTF-8}}}" py=1
    command -v python3 >/dev/null || { py=0; lc_time=C.UTF-8; }
    if [ "$py" = 1 ]; then
        python3 "$REPO/quickshell/ancient/scripts/i18n.py" render "$tpl"
    else
        sed 's/{{\([^}]*\)}}/\1/g' "$tpl"
    fi | sed -e "s|@CACHE@|$(sed_escape "$CACHE")|" -e "s|@LC_TIME@|$(sed_escape "$lc_time")|g"
}

# With --hyprlock, or to keep one that an earlier run made up to date (the link older
# versions made points to a file that is now a template)
lock="$HYPR/hyprlock.conf"
if [ "$hyprlock" = 1 ] || lock_is_ours "$lock"; then
    if [ -d "$HYPR" ]; then
        new="$lock.ancient.tmp"
        if ! render_lock > "$new"; then
            rm -f "$new"
            warn "could not generate $lock from hypr/hyprlock.conf.in; left as it was"
        else
            if [ -L "$lock" ] && lock_is_ours "$lock"; then
                :   # the old link into this repository: nothing of the user's
            elif [ -L "$lock" ] || { [ -e "$lock" ] && ! cmp -s "$new" "$lock" && ! lock_unedited "$lock"; }; then
                # The user's own file or link (into some dotfiles), or a generated file they edited
                cp -P "$lock" "$(bak_name "$lock")"
                say "backed up $lock"
            fi
            mv -f "$new" "$lock"
            mkdir -p "$STATE"
            sha256sum < "$lock" > "$LOCK_SUM"
            say "hyprlock uses the Ancient lock screen ($lock)"
        fi
    else
        warn "$HYPR not found; skipping the lock screen"
    fi
fi

# ------------------------------------------------------------------ start
if [ "$now" = 1 ]; then
    say "switching the running session to Ancient Shell"
    if [ "$disable_autostart" = 1 ]; then
        for p in "${CONFLICTS[@]}"; do pkill -u "$(id -u)" -x "$p" || true; done
        for c in "${qs_configs[@]}"; do
            args=()
            [ -z "$c" ] || read -ra args <<< "$c"
            qs "${args[@]}" kill >/dev/null 2>&1 || true
        done
    fi
    qs -c ancient kill >/dev/null 2>&1 || true
    sleep 0.5
    qs -c ancient -n -d >/dev/null 2>&1
    hyprctl reload >/dev/null || true
fi

say "done. Bindings: SUPER+D launcher · SUPER+A dashboard · SUPER+N controls · SUPER+CTRL+W wallpapers · SUPER+CTRL+Q session"
