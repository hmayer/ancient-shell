import QtQuick
import qs.theme

// A console key: chamfered tile with an icon, a title and a status line.
MouseArea {
    id: root

    property bool checked: false
    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property color onColor: Theme.cyan

    // Right click: open the related settings app (`clicked` stays left-only)
    signal secondaryClicked()

    implicitWidth: 150
    implicitHeight: 56
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onPressed: mouse => {
        if (mouse.button === Qt.RightButton) {
            mouse.accepted = false;
            root.secondaryClicked();
        }
    }

    ChamferPanel {
        anchors.fill: parent
        cut: Theme.cutSmall
        cutTopRight: false
        cutBottomLeft: false
        fillColor: root.checked ? Theme.alpha(root.onColor, root.containsMouse ? 0.24 : 0.16)
            : root.containsMouse ? Theme.stone3 : Theme.stone2
        borderColor: root.checked ? Theme.alpha(root.onColor, 0.7) : Theme.line
        Behavior on fillColor { ColorAnimation { duration: Theme.animFast } }
    }

    Row {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 10
        spacing: 10

        MIcon {
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon
            size: 22
            filled: root.checked
            color: root.checked ? root.onColor : Theme.textDim
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 32
            spacing: -2
            Label {
                width: parent.width
                text: root.title
                size: 15
                color: root.checked ? Theme.text : Theme.textDim
            }
            Label {
                width: parent.width
                text: root.subtitle
                size: 12
                visible: text !== ""
                color: root.checked ? Theme.alpha(root.onColor, 0.95) : Theme.textMute
            }
        }
    }
}
