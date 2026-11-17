import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.services
import qs.theme

// A workspace rebuilt from its parts, for the face the cube turns to (the
// screen itself is covered by the cube, so it cannot be captured): the
// wallpaper, then each window where Hyprland placed it. A window's picture
// comes from a toplevel capture; Hyprland cannot export some windows (Firefox
// fails, for one), so under it lies the window's area from the last snapshot
// of this workspace, or a plain panel with the app's name when there is none.
Item {
    id: root

    required property ShellScreen screen
    property HyprlandWorkspace workspace: null
    property url snapshot: ""          // last picture of this workspace, whole screen
    property real offsetX: 0           // where this face sits on the screen
    property real offsetY: 0

    // Tiled windows first, floating above, fullscreen on top
    readonly property var windows: (workspace?.toplevels?.values ?? [])
        .filter(t => t.lastIpcObject?.at !== undefined)
        .sort((a, b) => layer(a) - layer(b))

    function layer(t) {
        const o = t.lastIpcObject;
        return o.fullscreen ? 2 : o.floating ? 1 : 0;
    }

    Image {
        x: -root.offsetX
        y: -root.offsetY
        width: root.screen.width
        height: root.screen.height
        fillMode: Image.PreserveAspectCrop
        smooth: true
        // Same request as the copy WorkspaceCube keeps loaded, so it comes
        // from the pixmap cache
        source: Wallpapers.current ? "file://" + Wallpapers.current : ""
        sourceSize.width: root.screen.width
        sourceSize.height: root.screen.height
    }

    Repeater {
        model: root.windows

        delegate: Item {
            id: win

            required property var modelData
            readonly property var ipc: modelData.lastIpcObject
            readonly property bool active: ipc.focusHistoryID === Math.min(...root.windows.map(t => t.lastIpcObject.focusHistoryID))

            x: ipc.at[0] - root.screen.x - root.offsetX
            y: ipc.at[1] - root.screen.y - root.offsetY
            width: ipc.size[0]
            height: ipc.size[1]

            // Hyprland's border sits outside the window
            Rectangle {
                anchors.fill: parent
                anchors.margins: -2
                radius: Theme.radius + 2
                color: Theme.stone1
                border.width: 2
                border.color: win.active ? Theme.cyan : Theme.line
            }
            Text {
                anchors.centerIn: parent
                width: parent.width - 32
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                font.family: Theme.fontDisplay
                font.pixelSize: 18
                font.letterSpacing: 2
                color: Theme.textMute
                text: (win.ipc.class ?? "").toUpperCase()
            }

            Item {
                anchors.fill: parent
                clip: true
                visible: root.snapshot != ""
                Image {
                    x: -win.x - root.offsetX
                    y: -win.y - root.offsetY
                    width: root.screen.width
                    height: root.screen.height
                    source: root.snapshot
                    smooth: true
                }
            }

            ScreencopyView {
                anchors.fill: parent
                live: false
                captureSource: win.modelData.wayland
                visible: hasContent
            }
        }
    }
}
