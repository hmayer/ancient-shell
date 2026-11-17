import QtQuick
import qs.theme

// On/off switch: a chamfered slot with a lit block that slides across.
MouseArea {
    id: root

    property bool checked: false
    property color color: Theme.cyan
    signal toggled(bool checked)

    implicitWidth: 44
    implicitHeight: 22
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: toggled(!checked)

    ChamferPanel {
        anchors.fill: parent
        cut: 5
        fillColor: root.checked ? Theme.alpha(root.color, 0.2) : Theme.stone2
        borderColor: root.checked ? Theme.alpha(root.color, 0.75) : root.containsMouse ? Theme.lineBright : Theme.line
        Behavior on fillColor { ColorAnimation { duration: Theme.animFast } }
    }
    Rectangle {
        width: parent.height - 8
        height: width
        y: 4
        x: root.checked ? parent.width - width - 4 : 4
        rotation: 45
        scale: 0.8
        color: root.checked ? root.color : Theme.textMute
        Behavior on x { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }
    }
}
