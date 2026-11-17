import QtQuick
import Quickshell.Services.Mpris
import qs.services
import qs.theme
import qs.widgets

// Now playing. Left click: show or hide the player. Right click: play/pause.
// Middle: next.
BarButton {
    id: root
    required property string screenName

    readonly property MprisPlayer player: Players.active
    visible: player !== null && (player.trackTitle ?? "") !== ""
    active: ShellState.drawer === "media" && ShellState.drawerScreen === screenName

    onClicked: mouse => {
        if (mouse.button === Qt.RightButton) player?.togglePlaying();
        else if (mouse.button === Qt.MiddleButton) player?.next();
        else ShellState.toggleDrawer("media", screenName);
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        MIcon {
            anchors.verticalCenter: parent.verticalCenter
            text: root.player?.isPlaying ? "graphic_eq" : "pause"
            size: 17
            color: Theme.amber
        }
        Label {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, 220)
            size: 14
            color: Theme.textDim
            text: {
                const p = root.player;
                if (!p) return "";
                return p.trackArtist ? p.trackTitle + "  ·  " + p.trackArtist : p.trackTitle;
            }
        }
    }
}
