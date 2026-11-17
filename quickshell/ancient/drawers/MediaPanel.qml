import QtQuick
import qs.services
import qs.theme
import qs.widgets

// The media player, unrolled under the now-playing module of the bar. Its
// back holds the music effects (MusicFxPanel).
Drawer {
    id: root
    name: "media"
    align: "right"
    contentWidth: 500
    contentHeight: effects ? fx.implicitHeight + 2 * (Theme.pad + 2) : 226

    readonly property bool effects: ShellState.mediaEffects
    onOpenChanged: if (!open) ShellState.mediaEffects = false

    Column {
        anchors.fill: parent
        spacing: 12
        visible: !root.effects

        Item {
            width: parent.width
            height: 22
            SectionTitle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - fxBtn.width - 12
                text: I18n.tr("Now playing")
            }
            MouseArea {
                id: fxBtn
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: fxRow.width + 12
                height: 24
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: ShellState.mediaEffects = true
                Row {
                    id: fxRow
                    anchors.centerIn: parent
                    spacing: 4
                    MIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "graphic_eq"
                        size: 18
                        color: fxBtn.containsMouse ? Theme.amberBright : Theme.amber
                    }
                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        text: I18n.tr("Effects")
                        size: 13
                        color: fxBtn.containsMouse ? Theme.text : Theme.textDim
                    }
                }
            }
        }
        MediaCard { width: parent.width; height: 160 }
    }

    MusicFxPanel {
        id: fx
        width: parent.width
        visible: root.effects
        onBack: ShellState.mediaEffects = false
    }
}
