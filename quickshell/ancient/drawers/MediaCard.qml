import QtQuick
import QtQuick.Effects
import Quickshell.Services.Mpris
import qs.services
import qs.theme
import qs.widgets

// Player with cover art set in a chamfered frame.
Item {
    id: root
    readonly property MprisPlayer player: Players.active
    implicitHeight: 160

    // Position only updates on demand; tick it while visible and playing
    Timer {
        running: root.visible && (root.player?.isPlaying ?? false)
        interval: 1000
        repeat: true
        onTriggered: root.player?.positionChanged()
    }

    Label {
        visible: !root.player
        anchors.centerIn: parent
        color: Theme.textMute
        size: 15
        text: I18n.tr("Nothing playing")
    }

    Row {
        visible: root.player !== null
        anchors.fill: parent
        spacing: 16

        Item {
            id: art
            width: 140; height: 140
            anchors.verticalCenter: parent.verticalCenter

            ChamferPanel {
                anchors.fill: parent
                fillColor: Theme.stone2
                borderColor: Theme.alpha(Theme.amber, 0.6)
                cut: 14
            }
            Image {
                id: cover
                anchors.fill: parent
                anchors.margins: 3
                source: root.player?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize: Qt.size(280, 280)
                visible: false
            }
            ChamferPanel {
                id: mask
                anchors.fill: cover
                cut: 12
                fillColor: "white"
                borderWidth: 0
                layer.enabled: true
                visible: false
            }
            MultiEffect {
                anchors.fill: cover
                source: cover
                maskEnabled: true
                maskSource: mask
                visible: cover.status === Image.Ready
            }
            OriginGlyph {
                anchors.centerIn: parent
                visible: cover.status !== Image.Ready
                width: 38; height: 46
                color: Theme.alpha(Theme.amber, 0.7)
                glow: 0.4
            }
        }

        Column {
            width: parent.width - art.width - parent.spacing
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Label {
                width: parent.width
                size: 12
                font.letterSpacing: 1.5
                color: Theme.amber
                text: (root.player?.identity ?? "").toUpperCase()
            }
            Label {
                width: parent.width
                size: 20
                color: Theme.text
                text: root.player?.trackTitle ?? ""
            }
            Label {
                width: parent.width
                size: 15
                color: Theme.textDim
                text: root.player?.trackArtist ?? ""
            }

            Item { width: 1; height: 6 }

            // Progress
            Item {
                width: parent.width
                height: 10
                visible: root.player?.lengthSupported ?? false
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width; height: 2
                    color: Theme.stone3
                }
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * Math.min(1, (root.player?.position ?? 0) / Math.max(1, root.player?.length ?? 1))
                    height: 2
                    color: Theme.amber
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: root.player?.canSeek ?? false
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => root.player.position = root.player.length * mouse.x / width
                }
            }
            Row {
                width: parent.width
                visible: root.player?.lengthSupported ?? false
                Label {
                    width: parent.width / 2
                    size: 12; color: Theme.textMute
                    text: Players.fmt(root.player?.position ?? 0)
                }
                Label {
                    width: parent.width / 2
                    size: 12; color: Theme.textMute
                    horizontalAlignment: Text.AlignRight
                    text: Players.fmt(root.player?.length ?? 0)
                }
            }

            Row {
                spacing: 6
                Repeater {
                    model: [
                        { icon: "shuffle", act: () => root.player.shuffle = !root.player.shuffle, on: root.player?.shuffle ?? false, show: root.player?.shuffleSupported ?? false },
                        { icon: "skip_previous", act: () => root.player.previous(), show: root.player?.canGoPrevious ?? false },
                        { icon: root.player?.isPlaying ? "pause" : "play_arrow", act: () => root.player.togglePlaying(), big: true, show: true },
                        { icon: "skip_next", act: () => root.player.next(), show: root.player?.canGoNext ?? false },
                        { icon: "swap_horiz", act: () => Players.cycle(), show: Players.all.length > 1 }
                    ]
                    MouseArea {
                        required property var modelData
                        visible: modelData.show
                        width: modelData.big ? 40 : 30
                        height: 32
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: modelData.act()
                        ChamferPanel {
                            anchors.fill: parent
                            visible: parent.modelData.big || parent.containsMouse
                            cut: 5
                            fillColor: parent.modelData.big ? Theme.alpha(Theme.amber, parent.containsMouse ? 0.3 : 0.18) : Theme.stone3
                            borderColor: parent.modelData.big ? Theme.amber : Theme.line
                        }
                        MIcon {
                            anchors.centerIn: parent
                            text: parent.modelData.icon
                            size: parent.modelData.big ? 24 : 20
                            filled: true
                            color: parent.modelData.big || parent.modelData.on ? Theme.amberBright : Theme.textDim
                        }
                    }
                }
            }
        }
    }
}
