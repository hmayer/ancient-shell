pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// User settings, read from ~/.config/ancient-shell/config.json.
// The file is created with defaults on first run and reloaded on change.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property alias options: adapter

    property alias wallpaperDir: adapter.wallpaperDir
    property alias defaultWallpaper: adapter.defaultWallpaper
    property alias clock24h: adapter.clock24h
    property alias workspaces: adapter.workspaces
    property alias terminal: adapter.terminal
    property alias lockCommand: adapter.lockCommand
    property alias showSeconds: adapter.showSeconds
    property alias workspaceCube: adapter.workspaceCube
    property alias gateClose: adapter.gateClose
    property alias upgradesNodeBin: adapter.upgradesNodeBin
    // Locale for dates; empty = system locale
    readonly property var locale: Qt.locale(adapter.locale)

    FileView {
        id: file
        path: root.home + "/.config/ancient-shell/config.json"
        watchChanges: true
        onFileChanged: reload()
        onLoadFailed: error => {
            // FileViewError.FileNotFound: write the defaults so the user has a file to edit
            writeAdapter();
        }

        JsonAdapter {
            id: adapter
            property string wallpaperDir: root.home + "/Pictures/Wallpapers"
            property string defaultWallpaper: root.home + "/Pictures/Wallpapers/earth_stargate.png"
            property bool clock24h: true
            property bool showSeconds: false
            property int workspaces: 9
            property string terminal: "kitty"
            property string lockCommand: "loginctl lock-session"
            property string locale: "pt_BR"
            // Turn workspace switches into a rotating cube (workspace/WorkspaceCube)
            property bool workspaceCube: true
            // Close windows (the close key) by sucking them into a stargate (windowfx/GateClose)
            property bool gateClose: true
            // bin directory of the Node whose global npm packages the upgrades module
            // counts and topgrade upgrades ("" = the npm in PATH)
            property string upgradesNodeBin: root.home + "/.nvm/versions/node/v22.14.0/bin"
        }
    }
}
