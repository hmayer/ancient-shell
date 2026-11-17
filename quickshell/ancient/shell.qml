//@ pragma UseQApplication
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import QtQuick
import Quickshell
import Quickshell.Io
import qs.bar
import qs.launcher
import qs.notifications
import qs.osd
import qs.services
import qs.wallpaper
import qs.weather
import qs.windowfx
import qs.workspace

ShellRoot {
    id: root

    Variants {
        model: Quickshell.screens
        Background {}
    }
    Variants {
        model: Quickshell.screens
        Bar {}
    }
    Variants {
        model: Quickshell.screens
        WorkspaceCube {}
    }
    Variants {
        model: Quickshell.screens
        GateClose {}
    }
    Variants {
        model: Quickshell.screens.filter(s => s.name === Weather.screenName)
        WeatherWidget {}
    }

    Popups {}
    Osd {}
    Launcher {}
    WallpaperPicker {}

    // Touch services that must run from startup
    Component.onCompleted: {
        Notifs.count;
        Wallpapers.current;
        WorkspaceNav.cube;
        WindowClose.gate;
    }

    // `qs -c ancient ipc call shell <function>`
    IpcHandler {
        target: "shell"

        function launcher(): void { ShellState.toggleLauncher(); }
        function dial(text: string): void { ShellState.openLauncherWith(text); }
        function dashboard(): void { ShellState.toggleDrawer("dashboard", ""); }
        function media(): void { ShellState.toggleDrawer("media", ""); }
        function musicFx(): void { ShellState.openMusicFx(); }
        function control(): void { ShellState.toggleDrawer("control", ""); }
        function session(): void { ShellState.toggleDrawer("session", ""); }
        function upgrades(): void { ShellState.toggleDrawer("upgrades", ""); }
        function wallpapers(): void { ShellState.toggleWallpaperPicker(); }
        function closeAll(): void { ShellState.closeAll(); }
        function dnd(): void { ShellState.dnd = !ShellState.dnd; }
    }

    IpcHandler {
        target: "wallpaper"

        function set(path: string): void { Wallpapers.set(path); }
        function random(): void { Wallpapers.random(); }
        function get(): string { return Wallpapers.current; }
    }

    // `qs -c ancient ipc call workspace go 3` (or m+1, e-1…), `… move 3`
    IpcHandler {
        target: "workspace"

        function go(target: string): void { WorkspaceNav.go(target); }
        function move(target: string): void { WorkspaceNav.move(target); }
    }

    // Music effects: mode bars|wave|mirror|ring|halo, toggle one of
    // visualizer|particles|lyrics|wallpaperFx|glow|blur|zoom|shake,
    // intensity 10..200 (%)
    IpcHandler {
        target: "musicfx"

        function mode(name: string): void {
            if (["bars", "wave", "mirror", "ring", "halo"].includes(name)) MusicFx.settings.mode = name;
        }
        function toggle(name: string): void {
            if (["visualizer", "particles", "lyrics", "wallpaperFx", "glow", "blur", "zoom", "shake"].includes(name))
                MusicFx.settings[name] = !MusicFx.settings[name];
        }
        function intensity(percent: int): void {
            MusicFx.settings.intensity = Math.max(0.1, Math.min(2, percent / 100));
        }
    }

    // Weather widget: show or hide it, pick a city (first match), fetch
    // again, or bring it to the focused screen
    IpcHandler {
        target: "weather"

        function toggle(): void { Weather.toggle(); }
        function city(name: string): void { Weather.search(name, true); }
        function refresh(): void { Weather.refresh(); }
        function details(): void { Weather.expanded = !Weather.expanded; }
        function here(): void { Weather.moveTo(ShellState.focusedScreen); }
    }

    // Package upgrades: count again, upgrade what is pending (topgrade),
    // show or hide the upgrade's output, or the number of pending packages
    IpcHandler {
        target: "upgrades"

        function check(): void { Upgrades.check(); }
        function run(): void { Upgrades.upgrade(""); }
        function output(): void { Upgrades.toggleConsole(""); }
        function count(): int { return Upgrades.total; }
    }

    IpcHandler {
        target: "audio"

        function up(): void { Audio.step(0.02); }
        function down(): void { Audio.step(-0.02); }
        function mute(): void { Audio.toggleMute(); }
        function mic(): void { Audio.toggleMic(); }
    }

    IpcHandler {
        target: "brightness"

        function up(): void { Brightness.step(0.05); }
        function down(): void { Brightness.step(-0.05); }
    }
}
