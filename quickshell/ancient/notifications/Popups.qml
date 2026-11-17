import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.theme

// Incoming notifications, stacked under the bar on the focused screen.
PanelWindow {
    id: root

    screen: Quickshell.screens.find(s => s.name === ShellState.focusedScreen) ?? Quickshell.screens[0]
    visible: Notifs.popups.length > 0 && ShellState.drawer !== "control"
    color: "transparent"

    WlrLayershell.namespace: "ancient-notifications"
    WlrLayershell.layer: WlrLayer.Overlay
    exclusiveZone: 0
    anchors { top: true; right: true }
    margins { top: 6; right: Theme.gap + 4 }
    implicitWidth: 380
    implicitHeight: Math.max(1, list.contentHeight)

    ListView {
        id: list
        anchors.fill: parent
        spacing: 8
        interactive: false
        model: Notifs.popups.slice(0, 5)

        delegate: NotificationCard {
            required property var modelData
            width: list.width
            wrapper: modelData
        }

        add: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.animMid }
                NumberAnimation { property: "x"; from: 60; to: 0; duration: Theme.animMid; easing.type: Easing.OutCubic }
            }
        }
        displaced: Transition {
            NumberAnimation { property: "y"; duration: Theme.animMid; easing.type: Easing.OutCubic }
        }
    }
}
