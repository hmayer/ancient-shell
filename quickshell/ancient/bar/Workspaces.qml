import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.services
import qs.theme
import qs.widgets

// Number of the active workspace on this screen. Scroll to switch.
Item {
    id: root
    required property ShellScreen screen

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
    readonly property int activeId: monitor?.activeWorkspace?.id ?? -1

    implicitWidth: label.implicitWidth + 8
    implicitHeight: Theme.barHeight - 12

    Label {
        id: label
        anchors.centerIn: parent
        display: true
        size: 14
        font.weight: Font.DemiBold
        color: Theme.cyan
        text: root.activeId > 0 ? String(root.activeId).padStart(2, "0") : "--"
    }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            const next = root.activeId + (event.angleDelta.y > 0 ? -1 : 1);
            if (next >= 1 && next <= Config.workspaces) Hypr.workspace(next);
        }
    }
}
