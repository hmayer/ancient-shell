import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.theme

// System tray (StatusNotifierItem). Left: activate, right: menu.
Row {
    id: root
    required property var barWindow
    spacing: 2

    Repeater {
        model: SystemTray.items

        MouseArea {
            id: cell
            required property SystemTrayItem modelData
            width: 26
            height: Theme.barHeight - 12
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            cursorShape: Qt.PointingHandCursor

            onClicked: mouse => {
                if (mouse.button === Qt.RightButton || (mouse.button === Qt.LeftButton && modelData.onlyMenu)) {
                    if (modelData.hasMenu) {
                        const p = cell.mapToItem(null, 0, cell.height + 6);
                        modelData.display(root.barWindow, p.x, p.y);
                    }
                } else if (mouse.button === Qt.MiddleButton) {
                    modelData.secondaryActivate();
                } else {
                    modelData.activate();
                }
            }
            onWheel: wheel => modelData.scroll(wheel.angleDelta.y / 120, false)

            Rectangle {
                anchors.centerIn: parent
                width: 24; height: 24
                radius: 2
                color: cell.containsMouse ? Theme.stone3 : "transparent"
            }
            IconImage {
                anchors.centerIn: parent
                implicitSize: 16
                source: cell.modelData.icon
                opacity: cell.modelData.status === Status.Passive ? 0.5 : 1
            }
        }
    }
}
