import QtQuick
import QtQuick.Effects
import qs.services
import qs.theme

// The line of the song being sung, on the desktop under the windows. Words
// light up as the line goes by; the next line waits, dim, below it.
Item {
    id: root

    readonly property bool shown: MusicFx.settings.lyrics && MusicFx.playing
        && Lyrics.status === "ok" && Lyrics.current !== ""

    opacity: shown ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: 300 } }

    readonly property int size: Math.round(height * 0.03)

    function esc(s) {
        return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
    }

    // Sung words bright, the rest dim. Rebuilt only when a word lights up
    readonly property var words: Lyrics.current.split(/\s+/)
    readonly property int done: Math.ceil(Lyrics.progress * words.length)
    readonly property string sung: {
        const words = root.words, done = root.done;
        const a = esc(words.slice(0, done).join(" ")), b = esc(words.slice(done).join(" "));
        return `<span style="color:${Theme.cyanBright}">${a}</span>${a && b ? " " : ""}`
            + `<span style="color:${Theme.textDim}">${b}</span>`;
    }

    Column {
        id: lines
        anchors.horizontalCenter: parent.horizontalCenter
        // Lower down under Annabelle's window, which reaches further
        y: parent.height * (MusicFx.settings.visualizer && MusicFx.settings.mode === "sheep" ? 0.85 : 0.74)
        width: parent.width * 0.8
        spacing: root.size * 0.3

        Text {
            id: current
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            textFormat: Text.RichText
            font.family: Theme.fontUi
            font.pixelSize: root.size
            font.weight: Font.DemiBold
            font.letterSpacing: 1
            text: root.sung
        }
        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            font.family: Theme.fontUi
            font.pixelSize: Math.round(root.size * 0.6)
            color: Theme.textMute
            text: Lyrics.next
        }

        // A new line rises in
        Connections {
            target: Lyrics
            function onIndexChanged() { enter.restart(); }
        }
        NumberAnimation {
            id: enter
            target: current
            property: "opacity"
            from: 0.2
            to: 1
            duration: 220
        }

        layer.enabled: root.visible
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "black"
            shadowBlur: 0.6
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 2
        }
    }
}
