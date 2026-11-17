import QtQuick
import qs.services
import qs.theme
import qs.widgets

// Month grid. Scroll or use the arrows to change month.
Column {
    id: root
    property date today: new Date()
    property int monthOffset: 0
    readonly property date shown: new Date(today.getFullYear(), today.getMonth() + monthOffset, 1)
    readonly property int firstDay: Config.locale.firstDayOfWeek % 7   // 0 = Sunday
    property int cellHeight: 24
    property int textSize: 14          // day numbers; headings follow it

    spacing: 6

    readonly property var cells: {
        const y = shown.getFullYear(), m = shown.getMonth();
        const lead = (new Date(y, m, 1).getDay() - firstDay + 7) % 7;
        const out = [];
        for (let i = 0; i < 42; i++) {
            const d = new Date(y, m, 1 - lead + i);
            out.push({
                day: d.getDate(),
                inMonth: d.getMonth() === m,
                isToday: d.toDateString() === today.toDateString()
            });
        }
        return out;
    }

    Item {
        width: parent.width
        height: 24
        Label {
            anchors.verticalCenter: parent.verticalCenter
            display: true
            size: root.textSize - 2
            font.letterSpacing: 1.6
            color: Theme.text
            text: Config.locale.standaloneMonthName(root.shown.getMonth()).toUpperCase() + "  " + root.shown.getFullYear()
        }
        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            Repeater {
                model: [["chevron_left", -1], ["radio_button_unchecked", 0], ["chevron_right", 1]]
                MouseArea {
                    required property var modelData
                    width: 22; height: 22
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.monthOffset = modelData[1] === 0 ? 0 : root.monthOffset + modelData[1]
                    MIcon {
                        anchors.centerIn: parent
                        text: parent.modelData[0]
                        size: parent.modelData[1] === 0 ? 10 : 18
                        color: parent.containsMouse ? Theme.cyan : Theme.textDim
                    }
                }
            }
        }
    }

    Row {
        Repeater {
            model: 7
            Label {
                required property int index
                width: root.width / 7
                horizontalAlignment: Text.AlignHCenter
                size: root.textSize - 2
                color: Theme.textMute
                text: Config.locale.dayName((index + root.firstDay) % 7, Locale.NarrowFormat).toUpperCase()
            }
        }
    }

    Grid {
        columns: 7
        Repeater {
            model: root.cells
            Item {
                required property var modelData
                width: root.width / 7
                height: root.cellHeight
                Rectangle {
                    anchors.centerIn: parent
                    width: root.cellHeight - 2; height: root.cellHeight - 2
                    rotation: 45
                    scale: 0.82
                    visible: parent.modelData.isToday
                    color: Theme.alpha(Theme.cyan, 0.18)
                    border.color: Theme.cyan
                    border.width: 1
                }
                Label {
                    anchors.centerIn: parent
                    size: root.textSize
                    text: parent.modelData.day
                    color: parent.modelData.isToday ? Theme.cyanBright
                        : parent.modelData.inMonth ? Theme.text : Theme.textMute
                    opacity: parent.modelData.inMonth ? 1 : 0.5
                }
            }
        }
    }

    WheelHandler {
        onWheel: event => root.monthOffset += event.angleDelta.y > 0 ? -1 : 1
    }
}
