import QtQuick
import QtQuick.Effects
import qs.services
import qs.theme
import qs.widgets
import qs.wallpaper.annabelle

// The desktop visualizer, drawn over the wallpaper and under the windows.
// One of six shapes follows the spectrum (MusicFx.bars); star streaks can
// fly out from the centre behind it. Everything scales with the intensity.
// The drawing is one fragment shader (shaders/visualizer.frag), so the
// spectrum costs a few uniforms per frame instead of hundreds of items. The
// sixth shape is the ring round a window where Annabelle the sheep dances
// (annabelle/), loaded while it is chosen and kept through a pause.
Item {
    id: root

    readonly property var opts: MusicFx.settings
    readonly property bool shown: MusicFx.playing && opts.visualizer
    readonly property int modeIndex: Math.max(0, ["bars", "wave", "mirror", "ring", "halo", "sheep"].indexOf(opts.mode))

    opacity: shown ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: 450; easing.type: Easing.InOutQuad } }

    // How far the streaks have flown: their speed follows the music
    property real travel: 0
    property real boost: 0.3
    FrameAnimation {
        running: root.visible && root.opts.particles
        onTriggered: {
            root.boost = 0.3 + (MusicFx.level * 2.4 + MusicFx.kick * 2.2) * root.opts.intensity;
            root.travel += Math.min(frameTime, 0.05) * root.boost;
        }
    }

    ShaderEffect {
        anchors.fill: parent
        fragmentShader: Qt.resolvedUrl("shaders/visualizer.frag.qsb")

        readonly property var b: MusicFx.bars
        property vector2d size: Qt.vector2d(width, height)
        property real mode: root.modeIndex
        property real gain: root.opts.intensity
        property real kick: MusicFx.kick
        property real particles: root.opts.particles ? 1 : 0
        property real travel: root.travel
        property real boost: root.boost
        property color cyan: Theme.cyan
        property color cyanBright: Theme.cyanBright
        property color cyanDeep: Theme.cyanDeep
        property color amber: Theme.amber
        property vector4d b0: Qt.vector4d(b[0], b[1], b[2], b[3])
        property vector4d b1: Qt.vector4d(b[4], b[5], b[6], b[7])
        property vector4d b2: Qt.vector4d(b[8], b[9], b[10], b[11])
        property vector4d b3: Qt.vector4d(b[12], b[13], b[14], b[15])
        property vector4d b4: Qt.vector4d(b[16], b[17], b[18], b[19])
        property vector4d b5: Qt.vector4d(b[20], b[21], b[22], b[23])
        property vector4d b6: Qt.vector4d(b[24], b[25], b[26], b[27])
        property vector4d b7: Qt.vector4d(b[28], b[29], b[30], b[31])
        property vector4d b8: Qt.vector4d(b[32], b[33], b[34], b[35])
        property vector4d b9: Qt.vector4d(b[36], b[37], b[38], b[39])
        property vector4d b10: Qt.vector4d(b[40], b[41], b[42], b[43])
        property vector4d b11: Qt.vector4d(b[44], b[45], b[46], b[47])
        property vector4d b12: Qt.vector4d(b[48], b[49], b[50], b[51])
        property vector4d b13: Qt.vector4d(b[52], b[53], b[54], b[55])
        property vector4d b14: Qt.vector4d(b[56], b[57], b[58], b[59])
        property vector4d b15: Qt.vector4d(b[60], b[61], b[62], b[63])
    }

    // Sheep: Annabelle in the window the ring goes round (SHEEP_R in the shader)
    Item {
        readonly property real r: Math.min(root.width, root.height) * 0.25
        visible: root.modeIndex === 5
        x: root.width / 2 - r
        y: root.height / 2 - r
        width: r * 2
        height: width

        Loader {
            id: annabelle
            anchors.fill: parent
            active: root.modeIndex === 5 && root.opts.visualizer
            sourceComponent: Annabelle {
                bars: MusicFx.bars
                level: MusicFx.level
                bass: MusicFx.bass
                kick: MusicFx.kick
                gain: root.opts.intensity
                lyricLine: root.opts.lyrics && Lyrics.current !== ""
                track: [MusicFx.player?.trackArtist ?? "", MusicFx.player?.trackTitle ?? ""].filter(s => s !== "").join(" - ")
                running: root.visible
            }
        }
        Connections {
            target: MusicFx
            enabled: annabelle.status === Loader.Ready
            function onBeat(strength) {
                annabelle.item.beat(strength);
            }
        }
        // Rim over the window's edge
        Rectangle {
            anchors.fill: parent
            anchors.margins: -1
            radius: width / 2
            color: "transparent"
            border.color: Theme.cyan
            border.width: 2.5
        }
        Rectangle {
            anchors.fill: parent
            anchors.margins: -4
            radius: width / 2
            color: "transparent"
            border.color: Theme.cyanGlow
            border.width: 3
            opacity: 0.6 + MusicFx.kick * 0.4
        }
    }

    // Halo: the cover art in the middle of the blob the shader draws
    Item {
        readonly property real r: Math.min(root.width, root.height) * 0.13
        visible: root.modeIndex === 4
        x: root.width / 2 - r
        y: root.height / 2 - r
        width: r * 2
        height: width
        scale: 1 + MusicFx.kick * 0.06 * root.opts.intensity

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: Theme.stone1
        }
        Image {
            id: art
            anchors.fill: parent
            source: MusicFx.player?.trackArtUrl ?? ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize: Qt.size(width, height)
            visible: false
        }
        Rectangle {
            id: circle
            anchors.fill: parent
            radius: width / 2
            layer.enabled: true
            visible: false
        }
        MultiEffect {
            anchors.fill: parent
            source: art
            maskEnabled: true
            maskSource: circle
            visible: art.status === Image.Ready
        }
        OriginGlyph {
            anchors.centerIn: parent
            visible: art.status !== Image.Ready
            width: parent.width * 0.3
            height: width * 1.2
            glow: 0.6
        }
    }
}
