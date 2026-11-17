import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.theme

// Wallpaper on the background layer, cross-fading when it changes. While
// music plays it can move with it (MusicFx: glow, blur, zoom, shake), and the
// desktop visualizer and lyrics are drawn on it, under the windows.
PanelWindow {
    id: root
    required property ShellScreen modelData
    screen: modelData

    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "ancient-wallpaper"
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: Theme.void_

    property bool showA: true
    // The image to show. Loads finish in any order, so an image that comes in
    // after the wallpaper has changed again must not take over
    readonly property string wanted: Wallpapers.current ? "file://" + Wallpapers.current : ""

    function load() {
        const shown = showA ? imgA : imgB;
        const next = showA ? imgB : imgA;
        if (String(shown.source) === wanted) return;
        // Back to the image the hidden one still holds: no new load will report
        if (String(next.source) === wanted && next.status === Image.Ready) showA = !showA;
        else next.source = wanted;
    }

    Component.onCompleted: imgA.source = wanted
    onWantedChanged: load()

    component Wall: Image {
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        smooth: true
        sourceSize.width: root.width * (root.screen?.devicePixelRatio ?? 1)
        sourceSize.height: root.height * (root.screen?.devicePixelRatio ?? 1)
        Behavior on opacity { NumberAnimation { duration: 700; easing.type: Easing.InOutQuad } }
    }

    // The wallpaper itself, which the music effects act on
    Item {
        id: wall
        anchors.fill: parent

        readonly property var opts: MusicFx.settings
        readonly property bool fx: MusicFx.live && MusicFx.wallpaperFx
        readonly property real gain: opts.intensity
        readonly property real kick: fx ? MusicFx.kick : 0
        readonly property bool shake: fx && opts.shake

        // Zoom pulses on the beat; shaking needs a little margin so the
        // edges never show
        scale: (fx && opts.zoom ? 1 + (kick * 0.045 + MusicFx.bass * 0.015) * gain : 1) + (shake ? 0.02 : 0)
        Behavior on scale {
            enabled: !wall.fx
            NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
        }
        transform: Translate {
            x: wall.shake && wall.kick > 0.2 ? (Math.random() - 0.5) * 2 * wall.kick * 18 * wall.gain : 0
            y: wall.shake && wall.kick > 0.2 ? (Math.random() - 0.5) * 2 * wall.kick * 12 * wall.gain : 0
        }

        layer.enabled: fx && (opts.glow || opts.blur)
        layer.effect: MultiEffect {
            brightness: wall.opts.glow ? wall.kick * 0.22 * wall.gain : 0
            colorization: wall.opts.glow ? Math.min(0.35, wall.kick * 0.25 * wall.gain) : 0
            colorizationColor: Theme.cyan
            blurEnabled: wall.opts.blur
            blur: Math.min(1, (MusicFx.level * 1.4 + wall.kick * 0.4) * wall.gain)
            blurMax: 48
        }

        Wall {
            id: imgA
            opacity: root.showA ? 1 : 0
            onStatusChanged: if (status === Image.Ready && String(source) === root.wanted) root.showA = true
        }
        Wall {
            id: imgB
            opacity: root.showA ? 0 : 1
            onStatusChanged: if (status === Image.Ready && String(source) === root.wanted) root.showA = false
        }
    }

    Visualizer {
        anchors.fill: parent
    }
    LyricsLine {
        anchors.fill: parent
    }
}
