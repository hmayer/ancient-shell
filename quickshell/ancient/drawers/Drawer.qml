import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.services
import qs.theme
import qs.widgets

// A panel that grows out of the bar: it unrolls downward from the bar's lower edge,
// joined to it by a glowing seam, and rolls back up when closed.
PanelWindow {
    id: root

    required property ShellScreen modelData
    required property string name           // ShellState.drawer value
    property string align: "center"         // "left" | "center" | "right"
    property var barWindow: null           // clicks on the bar keep the drawer open
    property int contentWidth: 420
    property int contentHeight: 400
    default property alias content: body.data

    readonly property bool open: ShellState.drawer === name && ShellState.drawerScreen === modelData.name
    property real progress: open ? 1 : 0
    Behavior on progress {
        NumberAnimation { duration: Theme.animSlow; easing.type: root.open ? Easing.OutExpo : Easing.InCubic }
    }

    screen: modelData
    visible: progress > 0.001
    color: "transparent"

    WlrLayershell.namespace: "ancient-drawer"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    exclusiveZone: 0
    anchors {
        top: true
        left: align === "left"
        right: align === "right"
    }
    margins {
        left: Theme.gap + 40
        right: Theme.gap + 40
    }
    implicitWidth: contentWidth
    implicitHeight: contentHeight + 4

    HyprlandFocusGrab {
        active: root.open
        windows: root.barWindow ? [root, root.barWindow] : [root]
        onCleared: ShellState.closeDrawer()
    }

    FocusScope {
        id: clipper
        width: parent.width
        height: Math.max(1, root.contentHeight * root.progress)
        clip: true
        focus: root.open
        Keys.onEscapePressed: ShellState.closeDrawer()

        ChamferPanel {
            id: plate
            y: root.contentHeight * (root.progress - 1) * 0.35
            width: parent.width
            height: root.contentHeight
            fillColor: Theme.panel
            cutTopLeft: false
            cutTopRight: false
            accentEdge: "bottom"
            accentLength: 0.5
            accentColor: Theme.alpha(Theme.amber, 0.7)

            Item {
                id: body
                anchors.fill: parent
                anchors.margins: Theme.pad + 2
                opacity: Math.max(0, root.progress * 1.6 - 0.6)
            }
        }

        // The seam where the drawer leaves the bar
        Rectangle {
            width: parent.width * (0.4 + 0.6 * root.progress)
            anchors.horizontalCenter: parent.horizontalCenter
            height: 2
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.5; color: Theme.cyan }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }
    }
}
