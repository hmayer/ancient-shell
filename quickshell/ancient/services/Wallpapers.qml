pragma Singleton

import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io

// Wallpaper state (replaces hyprpaper/waypaper).
Singleton {
    id: root

    readonly property string current: state.current !== "" ? state.current : Config.defaultWallpaper
    readonly property alias model: folder
    readonly property string hook: Quickshell.shellPath("scripts/wallpaper-hook.sh")

    function set(path) {
        if (!path || path === state.current) return;
        state.current = path;
        hookProc.command = [hook, path];
        hookProc.running = true;
    }

    function random() {
        if (folder.count < 2) return;
        let i;
        do { i = Math.floor(Math.random() * folder.count); }
        while (folder.get(i, "filePath") === current);
        set(folder.get(i, "filePath"));
    }

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
        }
    }
}
