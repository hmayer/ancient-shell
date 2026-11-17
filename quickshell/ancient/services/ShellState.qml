pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

// Which overlay is open, and on which screen.
Singleton {
    id: root

    // "", "dashboard", "media", "control", "session", "upgrades"
    property string drawer: ""
    property string drawerScreen: ""
    property bool mediaEffects: false     // the media drawer shows its music effects side

    property bool launcherOpen: false
    property string launcherText: ""      // prefilled query for the next opening
    property bool wallpaperPickerOpen: false
    property string overlayScreen: ""

    property bool dnd: false
    property bool caffeine: false

    readonly property string focusedScreen: Hyprland.focusedMonitor?.name ?? (Quickshell.screens[0]?.name ?? "")

    function toggleDrawer(name, screenName) {
        const scr = screenName || focusedScreen;
        if (drawer === name && drawerScreen === scr) {
            drawer = "";
        } else {
            closeOverlays();
            drawerScreen = scr;
            drawer = name;
        }
    }

    // The media drawer, opened on its music effects side
    function openMusicFx() {
        if (drawer !== "media") toggleDrawer("media", "");
        mediaEffects = true;
    }

    function closeDrawer() {
        drawer = "";
    }

    function toggleLauncher() {
        const open = !launcherOpen;
        closeAll();
        overlayScreen = focusedScreen;
        launcherOpen = open;
    }

    function openLauncherWith(text) {
        closeAll();
        overlayScreen = focusedScreen;
        launcherText = text;
        launcherOpen = true;
    }

    function toggleWallpaperPicker() {
        const open = !wallpaperPickerOpen;
        closeAll();
        overlayScreen = focusedScreen;
        wallpaperPickerOpen = open;
    }

    function closeOverlays() {
        launcherOpen = false;
        wallpaperPickerOpen = false;
    }

    function closeAll() {
        closeOverlays();
        drawer = "";
    }
}
