# Ancient Shell

**English** | [Português (Brasil)](README.pt_BR.md)

A [Quickshell](https://quickshell.org) desktop shell for Hyprland, styled after the Ancient technology panels from Stargate: charcoal stone, cyan glyph light, and the amber/bronze of the Atlantis consoles.

It replaces waybar, swaync, hyprpaper, waypaper, rofi, and wlogout.

## What's included

| Piece | Shortcut | Notes |
|---|---|---|
| Boot splash | — | When you log in, the Stargate dials while the shell loads. Once the shell responds, the 7th chevron locks, the wormhole opens, and the screen plunges into it down to the desktop. On connecting, it picks a random destination planet (Abydos, Chulak, Dakara, Atlantis…), shows its name on screen, and sends a system notification. A click skips the animation. If the shell does not respond within 90 s, it shows "DIALING FAILED" and exits. |
| Bar | — | Active workspace number (scroll over it to switch), active window, clock, media, tray, package updates, and status. |
| Dashboard | `SUPER+A` or click the clock | Clock, calendar, uptime/memory/disk, and ring gauges (CPU, MEM, TEMP, DISK). |
| Media player | click the song title in the bar | Cover art, track, progress, and controls for the active MPRIS player. In the bar, right-click toggles play/pause and middle-click skips the track. The "Effects" button flips the player over to the music effects. |
| Music effects | "Effects" in the player | While the player is playing, the desktop reacts to the music, underneath the windows. A visualizer in six shapes (bars, wave, mirror, ring, halo with the album cover, Annabelle) and particles flying out from the center; synced lyrics, with words lighting up in rhythm; and the wallpaper with glow, blur, zoom, and shake on the beats. One intensity control (10–200%) applies to everything. Details below. |
| Control center | `SUPER+N` or click the status; right-click on Wi-Fi or Bluetooth opens `nm-connection-editor` or `blueman-manager` (`networkSettingsCommand` and `bluetoothSettingsCommand` in the config) | Wi-Fi, known Wi-Fi networks in range (profiles saved in NetworkManager: click to connect or disconnect, "Edit" opens `nm-connection-editor`), Bluetooth (connected devices with battery level and a disconnect button; for audio devices, one-click switching of mode, Music/A2DP or Call/HFP with microphone, and of codec, via PipeWire profiles), Do not disturb, Keep awake (idle inhibit), power profile (only with `power-profiles-daemon` already running: the shell never enables it, because that blocks login and stops auto-cpufreq/tlp); volume, microphone, and brightness; notification history. |
| Updates | click the icon next to the status | In the bar, a green check when everything is up to date and a yellow download arrow when there is something to update. The drawer shows a table with how many packages each manager has to update: System (pacman and AUR via yay), Oh My Zsh, Rust (cargo), VS Code Extensions, NeoVim (lazy.nvim plugins), Node (global npm packages), Docker images, PHP Composer (global), GitHub (`gh` extensions and skills), Claude Code (and its plugins), and Python UV (uv tools). "Check" queries again. The amber "Upgrade" button runs [topgrade](https://github.com/topgrade-rs/topgrade) only on the managers with pending updates, and the output appears in a panel that rises from the bottom edge of the screen (90% of the width, one third of the height) and closes by itself when the upgrade finishes. Details below. |
| Session | `SUPER+CTRL+Q` or the ⏻ button | Works like a DHD: pick the key and confirm on the red dome. Double-click executes directly. |
| Launcher | `SUPER+D` or the point-of-origin glyph | Works like the SGC dialing computer: each letter typed encodes a chevron and spins the glyph ring, the selected app appears in the event horizon, and Enter locks the 7th chevron and opens the wormhole (launches the app). Starting with `>`, it dials a command. |
| Workspace cube | `SUPER+1…0`, `SUPER+SHIFT+1…0` (moves the window along), `SUPER+Tab`/`SUPER+SHIFT+Tab`, `SUPER+mouse wheel`, scroll over the number in the bar | Switching workspaces spins a vertical cube on the monitor where the switch happens: the next workspace rises from below, the previous one drops from above, with windows and wallpaper on the faces and cyan light on the edges. The bar stays still. Details below. |
| Close window | `SUPER+Q` | The window is sucked into an SG-1 style Stargate (steel ring with glyphs): the gate opens over it, the lamps of the nine chevrons light up one by one, the blue event horizon forms, the window spins and falls into it, and the gate shuts with a flash and a shockwave. Details below. |
| Weather forecast | — | A plate on the desktop, underneath the windows, that can be dragged anywhere on the monitor. It shows the weather with a light animation (sun, moon with stars, white clouds, gray clouds with rain, drizzle or snow, dark clouds with lightning, fog), the temperature, the feels-like temperature, and the wind direction and speed. A click opens a table of the next 6 hours (temperature, feels-like, chance of rain, and wind). The gear picks the city, typed and searched by name (no GeoIP), and the monitor. Data from [Open-Meteo](https://open-meteo.com), refreshed every 15 minutes. The animation stops when tiled windows cover the desktop. |
| Wallpapers | `SUPER+CTRL+W` | Carousel of tilted plates. `SUPER+SHIFT+W` picks a random wallpaper. |
| Notifications | — | Its own server: popups, actions, and history. |
| OSD | volume/brightness keys | — |
| Lock screen | — | `hypr/hyprlock.conf.in`, optional (`./install.sh --hyprlock`). |
| Dark mode apps | — | Qt 5 and 6 via qt5ct/qt6ct (Fusion style with the Ancient palette, `apps/qt*ct/colors/ancient.conf`); GTK 3 with Adwaita-dark; GTK 4/libadwaita and Electron with `color-scheme prefer-dark`. |

The drawers drop down from the bar, attached to it by a glowing seam. They close with `Esc` or a click outside.

`hypr/init.lua` also makes the NetworkManager tools open floating and centered instead of tiled: `nm-connection-editor`, the `nm-applet` dialogs (Wi-Fi password, connection information), and the VPN login dialogs (`nm-*-auth-dialog`).

### How the cube works

Hyprland has no such animation, so the shell draws it on a layer of its own (`ancient-cube`, below the bar):

1. It captures the screen as it is; that becomes the front face, frozen.
2. With the cube already on screen, it asks Hyprland to switch. The cube pulls back until the face fills about 80% of the screen (240 ms), rotates (520 ms), and moves in again until the new face fills the screen (240 ms).
3. The new face is assembled from pieces, because the covered screen cannot be captured: the wallpaper and each window captured where Hyprland placed it. Some windows are not exported by Hyprland (Firefox, for example). In their place goes a crop of the last snapshot of that workspace, saved the last time the cube left it, or a panel with the app name if there is no snapshot.
4. The cube disappears with a short fade over the real workspace.

The keys call the shell's global shortcuts (`ancient:go-<target>` and `ancient:move-<target>`) only while the bar is up. Without the shell, they switch workspaces directly through Hyprland, so they never stop working. The cube spins on the monitor where the workspace appears, even if focus is on another one: on the workspace open there, or on the monitor a Hyprland rule binds it to (`workspace 8 → DP-1`), if it does not exist yet. A workspace already on screen on another monitor (Hyprland only moves focus there), a named one, or a special one switches without the cube. A switch requested during the animation waits for the cube to finish and is then redone from the workspace where it stopped. To turn the cube off, use `"workspaceCube": false` in the config.

### How the Stargate close works

A window that has already closed can no longer be drawn, so the shell saves it beforehand, on a layer of its own (`ancient-gate`, above everything):

1. It captures the screen as it is and covers the window with that frozen snapshot.
2. With the snapshot on screen, it turns off Hyprland's close animation for that window only and asks to close it.
3. When Hyprland reports that it closed, the gate opens over the snapshot and swallows it (`windowfx/shaders/gate.frag`, about 1.2 s).

Only `SUPER+Q` goes through the gate, and only with the shell up (global shortcut `ancient:close-window`); without the shell, it closes the window directly through Hyprland. Windows closed some other way (their own button, the app quitting) keep Hyprland's animation. An app that asks before closing (unsaved work) stays open: the snapshot disappears and the window gets its animation back. To turn the gate off, use `"gateClose": false` in the config. After editing the shader, regenerate the `.qsb` with `/usr/lib/qt6/bin/qsb --qt6 -o gate.frag.qsb gate.frag` and restart the shell (`qs -c ancient kill` and start it again): reloading the config does not replace an already loaded shader.

On hybrid laptops (Intel or AMD plus NVIDIA), `hypr/init.lua` starts the shell on the integrated GPU, the same one Hyprland composites on, even if the session sends apps to the NVIDIA. On the NVIDIA, each capture crosses between GPUs through memory and takes 3 to 5 times longer. Apps opened by the shell (launcher, control center, session) are run by Hyprland and so still receive the session environment.

### How the music effects work

- The spectrum comes from [cava](https://github.com/karlstav/cava), reading the PipeWire audio output (64 bands at 60 frames per second). It only runs while the player is playing and some effect is on; with the music paused, the shell goes back to being idle.
- The beats are bass peaks above the recent average. They drive the wallpaper's zoom, glow, and shake, and speed up the particles.
- The visualizer is a single fragment shader (`wallpaper/shaders/visualizer.frag`), drawn on each monitor's wallpaper layer. After editing the shader, regenerate the `.qsb` with `/usr/lib/qt6/bin/qsb --qt6 -o visualizer.frag.qsb visualizer.frag` (package `qt6-shadertools`).
- Synced lyrics come from [LRCLIB](https://lrclib.net), a free and open collection. With lyrics on, the shell sends the track's artist and title to lrclib.net, once per track and session. Turn lyrics off in the panel to send nothing.
- The panel's choices are stored in `~/.local/state/quickshell/by-shell/<id>/music-fx.json`.

### Annabelle

The "Annabelle" shape recreates the sheep from the early-2000s RealPlayer visualization, drawn as vectors (`wallpaper/annabelle/`), in a round window that the spectrum's ring of rays surrounds.

- **She listens to the music with you.** The tempo comes from the spectrum itself: how much it rises from one frame to the next marks the onsets, the autocorrelation of the last 8 s gives the beat period (from ~70 to ~170 bpm), and a comb with that period aligned to the onsets tells where the beats fall. A clock at that tempo, gently pulled toward the beats, drives the steps. It runs ahead by as much as the spectrum lags behind the sound (~80 ms), and each movement is advanced by as much as its smoothing delays it, so that knees, head, and hooves come down when the beat sounds, not a moment later. A drum fill or a stretch of off-beat accents does not throw her off; she only shifts phase if the beat shows up somewhere else for 4 s in a row. With a steady beat and a full sound she dances more: knees dipping on every beat and head bobbing, one hoof tapping at a time (tap dancing), and at the peak double-time tap dancing, ears flapping, and jumps that land on the next beat (or halfway through it, in a slow song). In a stretch much calmer than the rest of the song, she closes her eyes and sways; when the music comes back, she jumps with wide-open eyes. She sings along when there are vocals in the music (always with the microphone, and often while a line of the synced lyrics is being sung). On a new track, she perks up her ears, looks at you, and starts listening for the tempo from scratch.
- **Scenes** change at random, in no particular order, on a strong beat, every 16–36 s: day in the pasture, night with moon and shooting stars (which twinkle with the treble), disco with a mirror ball, psychedelic (sky and grass in a color that cycles with the music), and old film (gray, with dust and scratches).
- **Looks** change along with the scene: classic, sunglasses with a ☮ tattoo, anarchist Ⓐ tattoo, top hat with microphone, purple mohawk, red beret.
- **Visitors** now and then: a flying saucer that lifts her in its tractor beam while she pulls faces, a beach ball that bounces on her back on every beat, a little bird that lands on her back, dances along, and chirps notes, a blimp with the spectrum on its screen.

### How the updates work

`scripts/upgrades.py check` queries the managers in parallel, without installing anything, one minute after login and every 3 hours. Each number is what the corresponding topgrade step would change, so an upgrade brings the count to zero:

| Manager | How it counts | topgrade step |
|---|---|---|
| System | `checkupdates` (temporary copy of the pacman databases, no root) and `yay -Qua` | `system` |
| Oh My Zsh | `git fetch` and commits behind `origin/master` (counts as 1; topgrade does not update the plugins in `custom/`) | `shell` |
| Rust | `cargo install-update --list --git` | `cargo` |
| VS Code Extensions | installed version against the latest Marketplace version compatible with VS Code and the platform (pinned ones are left out) | `vscode` |
| NeoVim | lazy.nvim's own check, in a headless Neovim with your config | `vim` |
| Node | `npm outdated -g` ("wanted" version) with the Node from `upgradesNodeBin` | `node` |
| Docker images | the tag's digest in the registry (anonymous `HEAD` request, which does not count against the Docker Hub rate limit) against the local image's; locally built images are left out. With the daemon stopped, it does not query (and does not wake it up) | `containers` |
| PHP Composer | `composer global update --dry-run` | `composer` |
| GitHub | `gh extension upgrade --all --dry-run` and `gh skill update --all --dry-run` | `github_cli_extensions`, `github_cli_skills` |
| Claude Code | installed version against the release channel (`autoUpdatesChannel`), and plugins whose marketplace lists a different version | `claude_code`, `claude_code_plugins` |
| Python UV | `uv tool list --outdated`, uv itself (when it can update itself), and uv-managed Pythons with a new patch release | `uv` |

The upgrade runs `topgrade --no-tmux --no-self-update --no-ask-retry --yes --only <steps>` in a process detached from the shell, which keeps going even if the shell restarts (a pacman interrupted midway would leave the system half-upgraded). The output, without colors, is appended to the log (`upgradesLog` in the config, `~/upgrade.log` by default), with a header and the exit code of each run. A shell that restarts during the upgrade picks up tracking it again, and the updates icon spins while it runs (clicking it shows or hides the output). Meanwhile, shutdown and suspend are blocked (`systemd-inhibit`), and an upgrade requested in the middle of a check waits for it to finish. The panel closes when it finishes, with or without failures: topgrade reports the result in a notification, and the drawer shows when the last upgrade failed. Without a terminal, sudo has nowhere to ask for a password: the system step needs passwordless sudo for pacman.

## Dependencies

The package names are Arch Linux's; on other distributions, install the equivalent packages. The System row of the updates module only works on Arch and its derivatives, since it counts with pacman and yay. Tested with Hyprland 0.57.2 and Quickshell 0.3.2.

### Required

| Dependency | Package | What for |
|---|---|---|
| Hyprland, with a Lua config (`hyprland.lua`) | `hyprland` | The compositor the shell runs on. |
| Quickshell | `quickshell` | Runs the shell. |
| PipeWire, with its PulseAudio server and WirePlumber | `pipewire`, `pipewire-pulse`, `wireplumber` | Volume, microphone, the OSD, the music effects, and Bluetooth audio profiles (through `pactl`). |
| Material Symbols Rounded | `ttf-material-symbols-variable-git` (AUR) | The icons throughout the shell. |

The Orbitron and Rajdhani fonts come with the repository, and the installer links them.

### Optional

Each one is needed only by the feature next to it.

| Feature | Packages |
|---|---|
| Wi-Fi and known networks in the control center | `networkmanager`; `nm-connection-editor` for "Edit" and right-click (`networkSettingsCommand`) |
| Bluetooth in the control center | `bluez`, with `bluetooth.service` enabled; `blueman` for right-click (`bluetoothSettingsCommand`) |
| Battery in the bar | `upower` |
| Power profile in the control center | `power-profiles-daemon`, already running (the shell never starts it) |
| Brightness and its OSD | `brightnessctl` |
| Music effects | `cava` |
| Weather forecast and synced lyrics | `curl`, and internet access |
| Lock screen (`--hyprlock`) | `hyprlock`; `imagemagick` for the blurred background. The session menu locks with `loginctl lock-session` (`lockCommand`), which only works when something handles that signal, such as `hypridle` with `lock_cmd = pidof hyprlock \|\| hyprlock` |
| Package updates | `python`, `pacman-contrib` (`checkupdates`), and `topgrade` (AUR); `yay` (AUR) to count the AUR packages. The other managers (cargo, npm, uv…) are only checked when installed |
| Notification naming the destination after the boot splash | `libnotify` (`notify-send`) |
| Monospace text (launcher, upgrade output) | `ttf-firacode-nerd` |
| Dark Qt apps | `qt5ct`, `qt6ct` |
| Terminal apps in the launcher | one of `kitty`, `foot`, `alacritty`, `ghostty`, `konsole`, or `xterm` (`terminal` in the config) |

Everything above in one go:

```sh
sudo pacman -S --needed hyprland quickshell pipewire pipewire-pulse wireplumber \
    networkmanager nm-connection-editor bluez blueman upower brightnessctl cava curl \
    hyprlock hypridle imagemagick python pacman-contrib libnotify ttf-firacode-nerd qt5ct qt6ct
yay -S --needed ttf-material-symbols-variable-git topgrade   # AUR, with yay or another helper
```

### For development

| Task | Package |
|---|---|
| Editing the shaders (`qsb`) | `qt6-shadertools` |
| Translations (`xgettext`, `msgmerge`, `msgfmt`) | `gettext` |
| Regenerating the wallpapers (`rsvg-convert`) | `librsvg` |

See [CONTRIBUTING.md](CONTRIBUTING.md) for the rest of the development setup.

## Installation

Works with any Hyprland using a Lua config (`hyprland.lua`), whether your own or one from a dotfiles bundle. Install the [dependencies](#dependencies) first.

```sh
./install.sh                      # links, fonts, Hyprland fragment, dark apps, and config.json
./install.sh --entry FILE.lua     # loads the fragment from this file instead of hyprland.lua
./install.sh --disable-autostart  # also disables autostart of the bars and daemons the shell replaces
./install.sh --hyprlock           # also uses the Ancient lock screen (backs up hyprlock.conf)
./install.sh --now                # switches the current session's shell immediately
./install.sh --uninstall          # undoes everything (with --now, restarts what was disabled)
```

What the installer does:

- Links `quickshell/ancient` to `~/.config/quickshell/ancient`, the fonts to `~/.local/share/fonts/ancient-shell`, and `hypr/` to `~/.config/hypr/ancient-shell` (honoring `XDG_CONFIG_HOME` and `XDG_DATA_HOME`).
- Looks for `require("ancient-shell/init")` in every `.lua` under `~/.config/hypr`, following links to files and folders (like those from GNU stow). If it does not find it, it appends the line to the end of `hyprland.lua`, or of the file passed in `--entry`. Use `--entry` when your dotfiles overwrite `hyprland.lua` on updates and have a file of their own for customizations, loaded by it. The line has to come after your keybindings, because the fragment replaces the bindings it uses (`SUPER+D`, `SUPER+Q`, `SUPER+1…0`…).
- Creates `~/.config/ancient-shell/config.json` if it does not exist, with the wallpaper folder (`Wallpapers` inside the `xdg-user-dir` pictures folder, where it copies the repository's wallpapers) and the first installed terminal among kitty, foot, alacritty, ghostty, konsole, and xterm.
- `--disable-autostart` comments out, in any `.lua` under `~/.config/hypr`, the `hl.exec_cmd("…")` lines that start waybar, swaync, mako, dunst, fnott, hyprpaper, swww, swaybg, wpaperd, hyprpanel, or another Quickshell config. Only lines that are a complete call with a single quoted string (`hl.exec_cmd("waybar")`) qualify: commenting out one line of a call that continues on the next, or that has other statements, would break the config, and a command built with `..` could not be restarted. They are marked with `-- [ancient-shell]`, and `--uninstall` restores them. With `--now`, those programs are terminated (the other Quickshell configs with `qs -c <name> kill`). One of these programs that is running but is started from somewhere else produces a warning: if it is a systemd user service (the hyprpaper package, for example, ships with `hyprpaper.service` enabled), the warning includes its `systemctl --user disable --now`; if it is a script, disable it where it is started.
- `--hyprlock` generates `~/.config/hypr/hyprlock.conf` from `hypr/hyprlock.conf.in`, with the path of the cache where the shell writes the blurred background. A `hyprlock.conf` that was not generated by it, or that you edited afterwards, becomes `hyprlock.conf.bak.<date>`, and `--uninstall` gives yours back. After the first `--hyprlock`, each `./install.sh` updates the generated file (and replaces the link that earlier versions created). The text and the date format follow the locale language of whoever runs the installer (see [Translations](#translations)).

To force dark mode, the installer replaces `~/.config/qt5ct` and `~/.config/qt6ct` with its own configuration. The previous one is kept in `~/.config/qt5ct.ancient-backup` and `~/.config/qt6ct.ancient-backup`, and `--uninstall` restores it. It also runs `gsettings set org.gnome.desktop.interface color-scheme prefer-dark` and turns on `gtk-application-prefer-dark-theme` in the GTK `settings.ini` files. `hypr/init.lua` sets `QT_QPA_PLATFORMTHEME=qt6ct` (both the qt5ct and qt6ct plugins accept that name) and `ADW_DEBUG_COLOR_SCHEME=prefer-dark`. Apps that were already open only change when reopened.

`--uninstall` keeps `config.json` and the copied wallpapers.

With a hyprlang config (`hyprland.conf`), the fragment does not load: run `./install.sh` for the links and `config.json`, start the shell with `exec-once = qs -c ancient`, and create the keybindings by calling the IPC (below). The shell itself works with both syntaxes.

## Configuration

Edit `~/.config/ancient-shell/config.json` (or `$XDG_CONFIG_HOME/ancient-shell/config.json`). It reloads automatically when it changes. Missing keys use the default (a key deleted while the shell is running only goes back to the default when it restarts), and paths can start with `~/`.

```json
{
  "wallpaperDir": "~/Pictures/Wallpapers",
  "defaultWallpaper": "",
  "clock24h": true,
  "showSeconds": false,
  "workspaces": 9,
  "terminal": "kitty",
  "lockCommand": "loginctl lock-session",
  "suspendCommand": "systemctl suspend",
  "rebootCommand": "systemctl reboot",
  "poweroffCommand": "systemctl poweroff",
  "networkSettingsCommand": "nm-connection-editor",
  "bluetoothSettingsCommand": "blueman-manager",
  "diskPath": "/",
  "locale": "",
  "workspaceCube": true,
  "gateClose": true,
  "upgradesNodeBin": "",
  "upgradesLog": "~/upgrade.log",
  "upgradesPath": ["~/.cargo/bin", "~/.local/bin"]
}
```

| Key | What it is |
|---|---|
| `wallpaperDir` | Wallpaper folder for the picker and for `wallpaper random`. |
| `defaultWallpaper` | Wallpaper used while none has been chosen; empty uses the first image in `wallpaperDir`. |
| `terminal` | Opens the launcher's terminal apps as `<terminal> -e <command>`. |
| `lockCommand`, `suspendCommand`, `rebootCommand`, `poweroffCommand` | Session menu actions; empty removes the action from the menu. |
| `networkSettingsCommand`, `bluetoothSettingsCommand` | Apps opened by the control center; empty hides the link and disables right-click. |
| `diskPath` | Mount point whose usage is shown on the dashboard. |
| `locale` | Locale for dates (for example, `pt_BR`); empty uses the environment's (`LC_ALL`, `LC_TIME`, `LANG`). |
| `workspaceCube`, `gateClose` | Turns on the workspace cube and the Stargate close. |
| `upgradesNodeBin` | Node `bin` folder whose global npm packages are included in the updates (for example, `~/.nvm/versions/node/v22.14.0/bin`); empty uses the `npm` on the PATH. |
| `upgradesLog` | File the upgrade output is appended to. |
| `upgradesPath` | Folders prepended to the PATH for the checks and the upgrade, which run with the session PATH (usually without the user's folders). |

The checks find the tools in their default locations and honor each one's variables: `ZSH` (Oh My Zsh), `VSCODE_EXTENSIONS`, and `CLAUDE_CONFIG_DIR`.

The colors live in `quickshell/ancient/theme/Theme.qml`, and Hyprland's in `hypr/palette.lua`.

## Translations

The strings in the code are in English, and the translations live in gettext catalogs in `quickshell/ancient/i18n/` (`pt_BR.po` ships ready). The shell picks the language from the locale variables of the environment it runs in, like programs that use gettext:

1. The messages locale is the first one set among `LC_ALL`, `LC_MESSAGES`, and `LANG`.
2. If it is `C`, `C.UTF-8`, or `POSIX` (or none is set), everything stays in English, and `LANGUAGE` is ignored.
3. Otherwise, the shell tries the languages in `LANGUAGE` (separated by `:`, for example `pt_BR:en`) and then the locale's, without the encoding: each with and without the modifier and the region (`sr_RS@latin`, `sr@latin`, `sr_RS`, `sr`). The first one that has a catalog wins, in full: whatever is missing from it stays in English. English ends the list, because it is the language of the code (with `LANGUAGE=en:pt_BR`, English). With no catalog at all, English.

Day and month names follow `LC_ALL`, `LC_TIME`, or `LANG`, unless `locale` is set in `config.json`. The order of the date elements comes from the translation, so with `LC_TIME` and `LC_MESSAGES` in different languages the date mixes both. The weather forecast's city search uses the language of the loaded catalog.

The shell inherits the environment of the Hyprland session. If the session runs with `LANG=C.UTF-8` (the systemd default when `/etc/locale.conf` does not set another), it stays in English. For Portuguese, set the session locale, for example in `/etc/locale.conf` (`LANG=pt_BR.UTF-8`) or in the Hyprland config, before the shell starts:

```lua
hl.env("LANG", "pt_BR.UTF-8")
```

The shell's translations and dates do not depend on the locale being generated on the system (Qt has its own data), but the lock screen date and the session's other programs do: check with `locale -a` (on Arch, uncomment the line in `/etc/locale.gen` and run `locale-gen`). After switching, restart the shell (`qs -c ancient kill` and start it again, or log out of the session).

The updates script (`scripts/upgrades.py`) uses the same catalogs and the same rule. The lock screen is translated when `install.sh` generates `hyprlock.conf`, in the locale of whoever runs the installer; run `./install.sh` again after switching languages.

### Adding a language

Requires GNU gettext (`xgettext`, `msginit`, `msgmerge`, `msgfmt`).

```sh
cd quickshell/ancient/i18n
msginit --no-translator -l fr_FR -i ancient-shell.pot -o fr.po   # or fr_FR.po, if it is region-specific
# translate the msgstr entries in fr.po (Poedit, Lokalize, GTranslator, or a text editor)
./update.sh --check
```

In QML, translatable strings go through `I18n.tr("Text")`, `I18n.tr("Checked at %1", time)`, `I18n.trn("%1 package", "%1 packages", n)`, or `I18n.trc("context", "Text")`; in Python, through `_()` from `scripts/i18n.py`; in `hypr/hyprlock.conf.in`, they go between `{{ }}`. An `i18n:` comment right before becomes a note for translators. After changing strings, run `quickshell/ancient/i18n/update.sh`: it regenerates `ancient-shell.pot` and updates the `.po` files, flagging what still needs translating. The shell reloads the catalog when the `.po` changes.

## IPC

```sh
qs -c ancient ipc call shell dial "firefox"      # opens the launcher already filled in
qs -c ancient ipc call shell launcher|dashboard|media|musicFx|control|session|upgrades|wallpapers|closeAll|dnd
qs -c ancient ipc call upgrades check|run|output|count   # output: shows/hides the upgrade output
qs -c ancient ipc call musicfx mode bars|wave|mirror|ring|halo
qs -c ancient ipc call musicfx toggle visualizer|particles|lyrics|wallpaperFx|glow|blur|zoom|shake
qs -c ancient ipc call musicfx intensity 150         # in %, from 10 to 200
qs -c ancient ipc call wallpaper set /path/img.png | random | get
qs -c ancient ipc call weather toggle|refresh|details|here   # here: brings it to the focused monitor
qs -c ancient ipc call weather city "Campinas"            # the first city with that name
qs -c ancient ipc call audio up|down|mute|mic
qs -c ancient ipc call brightness up|down
qs -c ancient ipc call workspace go 3|m+1|e-1      # switches with the cube
qs -c ancient ipc call workspace move 3            # takes the active window along
qs -p ~/.config/quickshell/ancient/splash.qml ipc call splash skip|ready
```

The splash runs in its own instance (`qs -p …/splash.qml`), started by `hypr/init.lua` alongside the shell. That way it shows up even if the shell is slow to start. It knows the shell is ready by querying the shell's `ipc show`. To turn it off, comment out the `hl.exec_cmd(SPLASH .. " -d")` line.

When the shell starts and when the wallpaper changes, `scripts/wallpaper-hook.sh` generates `$XDG_CACHE_HOME/ancient-shell/lock.png` (`~/.cache/ancient-shell/lock.png`), the blurred version hyprlock uses as its background. If the background for that wallpaper already exists, it does nothing.

## Structure

```
quickshell/ancient/
  shell.qml          root + IPC
  splash.qml         boot splash (separate instance)
  theme/             palette, fonts, metrics
  widgets/           ChamferPanel, OriginGlyph, GlyphSlider, RingGauge…
  services/          Config, I18n, ShellState, Audio, Brightness, SysStats, Notifs, Wallpapers, Players, Hypr, WorkspaceNav, WindowClose, MusicFx, Lyrics, Weather, Upgrades
  scripts/           wallpaper-hook.sh, upgrades.py (update counts and the topgrade upgrade), i18n.py (translations for Python and the lock screen)
  i18n/              translation catalogs (ancient-shell.pot, pt_BR.po) and update.sh
  workspace/         workspace switching cube (Cube, WorkspaceCube, WorkspaceFace)
  wallpaper/         wallpaper with the music effects, visualizer (shaders/), and lyrics
  weather/           weather forecast widget (WeatherWidget, WeatherScene)
  windowfx/          window closing sucked into a Stargate (GateClose, shaders/)
  bar/  drawers/  notifications/  launcher/  wallpaper/  osd/  splash/
  assets/fonts/      Orbitron and Rajdhani (SIL OFL)
hypr/                init.lua, palette.lua, hyprlock.conf.in (lock screen template)
apps/qt5ct/ qt6ct/   dark Qt palette and qt5ct.conf/qt6ct.conf templates
wallpapers/          earth_origin.png and pegasus_chart.png (3840×2160, the Ancients' star map), with the scripts that generate them as vectors
```

## References

Inspired by r/unixporn posts: Vitreus/pleamar (panels that sprout from the bar), the Quickshell wallpaper picker, ETEA, and a KDE "tuned just right".

## Contributing

Bug reports, ideas, translations, code, and artwork are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for how to set up a development copy, the project's conventions, and what a pull request needs.

## License

Ancient Shell is released under the [MIT License](LICENSE.txt). The Orbitron and Rajdhani fonts in `quickshell/ancient/assets/fonts/` are third-party works under the SIL Open Font License; their license texts are next to them.
