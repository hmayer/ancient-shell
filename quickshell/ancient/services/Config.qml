pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// User settings, read from $XDG_CONFIG_HOME/ancient-shell/config.json
// (~/.config/ancient-shell/config.json). The file is created with defaults on
// first run and reloaded on change. Paths may start with "~/".
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || home + "/.config"
    readonly property alias options: adapter

    // "~/x" → "$HOME/x"
    function path(p) {
        p = String(p ?? "");
        if (p === "~") return home;
        return p.startsWith("~/") ? home + p.slice(1) : p;
    }
    // "$HOME/x" → "~/x", for display
    function tilde(p) {
        p = String(p ?? "");
        if (p === home) return "~";
        return p.startsWith(home + "/") ? "~" + p.slice(home.length) : p;
    }

    readonly property string wallpaperDir: path(adapter.wallpaperDir)
    readonly property string defaultWallpaper: path(adapter.defaultWallpaper)
    readonly property string upgradesNodeBin: path(adapter.upgradesNodeBin)
    readonly property string upgradesLog: path(adapter.upgradesLog)
    // A list (a JSON array arrives as a sequence, not an Array); a lone string is a list of one
    readonly property var upgradesPath: {
        const v = adapter.upgradesPath;
        return (typeof v === "string" ? [v] : Array.from(v ?? [])).map(p => path(p));
    }
    readonly property string diskPath: path(adapter.diskPath)
    property alias clock24h: adapter.clock24h
    property alias workspaces: adapter.workspaces
    property alias terminal: adapter.terminal
    property alias lockCommand: adapter.lockCommand
    property alias suspendCommand: adapter.suspendCommand
    property alias rebootCommand: adapter.rebootCommand
    property alias poweroffCommand: adapter.poweroffCommand
    property alias networkSettingsCommand: adapter.networkSettingsCommand
    property alias bluetoothSettingsCommand: adapter.bluetoothSettingsCommand
    property alias showSeconds: adapter.showSeconds
    property alias workspaceCube: adapter.workspaceCube
    property alias gateClose: adapter.gateClose
    // Locale for dates; "" = the environment's (LC_ALL, LC_TIME, LANG)
    readonly property var locale: Qt.locale(adapter.locale || I18n.timeLocale)

    FileView {
        id: file
        path: root.configHome + "/ancient-shell/config.json"
        watchChanges: true
        onFileChanged: reload()
        onLoadFailed: error => {
            // FileViewError.FileNotFound: write the defaults so the user has a file to edit
            writeAdapter();
        }

        JsonAdapter {
            id: adapter
            property string wallpaperDir: "~/Pictures/Wallpapers"
            // Wallpaper until one is picked; "" = the first image in wallpaperDir
            property string defaultWallpaper: ""
            property bool clock24h: true
            property bool showSeconds: false
            property int workspaces: 9
            // Runs apps that need a terminal as `<terminal> -e <command>`
            property string terminal: "kitty"
            property string lockCommand: "loginctl lock-session"
            property string suspendCommand: "systemctl suspend"
            property string rebootCommand: "systemctl reboot"
            property string poweroffCommand: "systemctl poweroff"
            // Opened from the control centre; "" = nothing
            property string networkSettingsCommand: "nm-connection-editor"
            property string bluetoothSettingsCommand: "blueman-manager"
            // Mount point whose usage the dashboard shows
            property string diskPath: "/"
            property string locale: ""
            // Turn workspace switches into a rotating cube (workspace/WorkspaceCube)
            property bool workspaceCube: true
            // Close windows (the close key) by sucking them into a stargate (windowfx/GateClose)
            property bool gateClose: true
            // bin directory of the Node whose global npm packages the upgrades module
            // counts and topgrade upgrades ("" = the npm in PATH)
            property string upgradesNodeBin: ""
            // Where the upgrade runs' output is appended
            property string upgradesLog: "~/upgrade.log"
            // Directories added to PATH for the upgrade checks and runs: the
            // session's PATH often lacks the per-user ones
            property var upgradesPath: ["~/.cargo/bin", "~/.local/bin"]
        }
    }
}
