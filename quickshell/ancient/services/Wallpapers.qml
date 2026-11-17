pragma Singleton

import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io

// Wallpaper state (replaces hyprpaper/waypaper).
Singleton {
    id: root

    // The picked one, else the configured default, else the first image in the folder
    readonly property string current: state.current !== "" ? state.current
        : Config.defaultWallpaper !== "" ? Config.defaultWallpaper
        : folder.count > 0 ? folder.get(0, "filePath") : ""
    readonly property alias model: folder
    readonly property string hook: Quickshell.shellPath("scripts/wallpaper-hook.sh")

    function set(path) {
        if (!path || path === state.current) return;
        state.current = path;
    }

    function random() {
        if (folder.count < 2) return;
        let i;
        do { i = Math.floor(Math.random() * folder.count); }
        while (folder.get(i, "filePath") === current);
        set(folder.get(i, "filePath"));
    }

    // The hook keeps the lock screen background in step; it does nothing when
    // that wallpaper's background is already there, so it also runs on start
    property bool _hookAgain: false
    function runHook() {
        if (current === "") return;
        if (hookProc.running) {
            _hookAgain = true;   // once this run ends, for the newest wallpaper
            return;
        }
        hookProc.command = [hook, current];
        hookProc.running = true;
    }
    onCurrentChanged: runHook()
    Component.onCompleted: runHook()

    FolderListModel {
        id: folder
        folder: "file://" + Config.wallpaperDir
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.JPG", "*.PNG"]
        showDirs: false
        sortField: FolderListModel.Name
    }

    FileView {
        id: stateFile
        path: Quickshell.statePath("wallpaper.json")
        // Read before the windows come up, so they start with the chosen
        // wallpaper instead of loading the default first
        blockLoading: true
        onAdapterUpdated: writeAdapter()
        onLoadFailed: writeAdapter()
        JsonAdapter {
            id: state
            property string current: ""
        }
    }

    Process {
        id: hookProc
        onExited: (code, status) => {
            if (code !== 0) console.warn("wallpaper hook exited with", code);
            if (root._hookAgain) {
                root._hookAgain = false;
                Qt.callLater(root.runHook);
            }
        }
    }
}
