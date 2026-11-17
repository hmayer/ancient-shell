import QtQuick
import qs.theme

// Small engraved heading: a diamond, the title, and a fading rule.
Row {
    id: root
    property string text: ""
    property color color: Theme.amber
    spacing: 8
    height: 18

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 5; height: 5; rotation: 45
        color: root.color
    }
    Label {
        id: t
        anchors.verticalCenter: parent.verticalCenter
        display: true
        size: 10
        font.letterSpacing: 2.4
        color: root.color
        text: root.text.toUpperCase()
        elide: Text.ElideNone
    }
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(0, root.width - t.width - 21)
        height: 1
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Theme.alpha(root.color, 0.5) }
            GradientStop { position: 1; color: "transparent" }
        }
    }
}
