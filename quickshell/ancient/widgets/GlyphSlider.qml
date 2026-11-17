import QtQuick
import QtQuick.Effects
import qs.theme

// Segmented slider: a row of console cells that light up like a power gauge.
Item {
    id: root

    property real value: 0          // 0..1
    property int segments: 24
    property color color: Theme.cyan
    property string icon: ""
    property string label: ""
    signal moved(real value)
    signal iconClicked()

    implicitHeight: 34
    implicitWidth: 260

    Row {
        anchors.fill: parent
        spacing: 10

        MouseArea {
            id: iconArea
            width: 30; height: parent.height
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: root.iconClicked()
            MIcon {
                anchors.centerIn: parent
                text: root.icon
                size: 20
                color: iconArea.containsMouse ? Theme.cyanBright : root.color
            }
        }

        Item {
            id: track
            width: parent.width - 30 - 46 - 20
            height: parent.height

            Row {
                id: cells
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                Repeater {
                    model: root.segments
                    Rectangle {
                        required property int index
                        readonly property bool lit: (index + 0.5) / root.segments <= root.value
                        width: (track.width - (root.segments - 1) * 2) / root.segments
                        height: 14
                        color: lit ? root.color : Theme.stone2
                        border.width: 1
                        border.color: lit ? Theme.alpha(Theme.cyanBright, 0.6) : Theme.line
                        Behavior on color { ColorAnimation { duration: 90 } }
                    }
                }
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: root.color
                    shadowBlur: 0.45
                    shadowHorizontalOffset: 0
                    shadowVerticalOffset: 0
                    blurMax: 12
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                function setFrom(x) {
                    root.moved(Math.max(0, Math.min(1, x / width)));
                }
                onPressed: mouse => setFrom(mouse.x)
                onPositionChanged: mouse => { if (pressed) setFrom(mouse.x); }
                onWheel: wheel => root.moved(Math.max(0, Math.min(1, root.value + (wheel.angleDelta.y > 0 ? 0.02 : -0.02))))
            }
        }

        Label {
            width: 46
            height: parent.height
            display: true
            size: 12
            horizontalAlignment: Text.AlignRight
            color: Theme.textDim
            text: root.label !== "" ? root.label : Math.round(root.value * 100) + "%"
        }
    }
}
