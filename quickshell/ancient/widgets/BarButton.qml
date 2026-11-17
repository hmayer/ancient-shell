import QtQuick
import qs.theme

// Clickable area with an engraved hover plate. Put content inside.
MouseArea {
    id: root

    property bool active: false
    property color activeColor: Theme.cyan
    property real padding: 8
    default property alias content: holder.data

    implicitWidth: holder.childrenRect.width + padding * 2
    implicitHeight: Theme.barHeight - 12
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

    ChamferPanel {
        anchors.fill: parent
        cut: Theme.cutSmall
        cutTopRight: false
        cutBottomLeft: false
        fillColor: root.active ? Theme.alpha(root.activeColor, 0.14)
            : root.containsMouse ? Theme.stone3 : "transparent"
        borderColor: root.active ? Theme.alpha(root.activeColor, 0.55)
            : root.containsMouse ? Theme.lineBright : "transparent"
        Behavior on fillColor { ColorAnimation { duration: Theme.animFast } }
    }

    Item {
        id: holder
        x: root.padding
        width: childrenRect.width
        height: parent.height
    }
}
