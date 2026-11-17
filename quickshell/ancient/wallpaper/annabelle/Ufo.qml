import QtQuick
import QtQuick.Shapes

// A flying saucer that stops over Annabelle and holds her up in its tractor
// beam for a few beats (she pulls faces), then drops her and zips off. Its
// rim lights chase to the beat. 400×400 units, over the sheep.
Item {
    id: root
    width: 400
    height: 400

    property real t: -1             // seconds since it came; -1 away
    property real phase: 0

    readonly property real duration: 9.2
    readonly property bool active: t >= 0 && t < duration
    // How far the beam lifts her, 0..1, and how bright it is
    readonly property real lift: active && t < 6.8 ? smooth(2.4, 3.6, t) : 0
    readonly property real beam: active ? smooth(1.8, 2.3, t) * (1 - smooth(6.8, 7.0, t)) : 0
    readonly property real ux: pos().x
    readonly property real uy: pos().y

    visible: active

    function start() {
        t = 0;
    }
    function step(dt) {
        if (t >= 0) t = t < duration ? t + dt : -1;
    }

    function smooth(a, b, x) {
        const k = Math.max(0, Math.min(1, (x - a) / (b - a)));
        return k * k * (3 - 2 * k);
    }
    function pos() {
        if (t < 1.8) {
            const u = 1 - Math.pow(1 - Math.max(0, t) / 1.8, 3);
            return { x: 460 - 260 * u, y: -50 + 102 * u, tilt: 18 * (1 - u) };
        }
        if (t < 7.6) return { x: 200 + 6 * Math.sin(t * 1.7), y: 52 + 3 * Math.sin(t * 2.9), tilt: 2 * Math.sin(t * 1.7) };
        const u = Math.pow((t - 7.6) / 1.2, 2);
        return { x: 200 - 330 * u, y: 52 - 150 * u, tilt: -22 * Math.min(1, u * 3) };
    }

    // Tractor beam, in front of her
    Item {
        id: beamItem
        readonly property real from: root.uy + 12
        readonly property real to: 312
        function half(y) {
            return 12 + (y - from) / (to - from) * 98;
        }
        opacity: root.beam
        visible: opacity > 0.01
        Shape {
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: "transparent"
                fillGradient: LinearGradient {
                    x1: 0; y1: beamItem.from
                    x2: 0; y2: beamItem.to
                    GradientStop { position: 0; color: Qt.rgba(0.7, 1, 0.85, 0.6) }
                    GradientStop { position: 1; color: Qt.rgba(0.45, 1, 0.75, 0.16) }
                }
                startX: root.ux - 12
                startY: beamItem.from
                PathLine { x: root.ux + 12; y: beamItem.from }
                PathLine { x: 205 + 110; y: beamItem.to }
                PathLine { x: 205 - 110; y: beamItem.to }
                PathLine { x: root.ux - 12; y: beamItem.from }
            }
        }
        // Rings of light running down the beam
        Repeater {
            model: 4
            Rectangle {
                required property int index
                readonly property real yy: beamItem.from + ((root.t * 90 + index * 62) % (beamItem.to - beamItem.from))
                readonly property real w: beamItem.half(yy) * 2
                x: (root.ux + (205 - root.ux) * (yy - beamItem.from) / (beamItem.to - beamItem.from)) - w / 2
                y: yy
                width: w
                height: 2.5
                radius: 1.25
                color: "#d9fff0"
                opacity: 0.55
            }
        }
    }

    // The saucer
    Item {
        x: root.ux
        y: root.uy
        rotation: root.pos().tilt

        // Glow under it while the beam is on
        Rectangle {
            x: -16; y: 4
            width: 32; height: 12
            radius: 6
            color: "#b8ffe0"
            opacity: 0.3 + root.beam * 0.7
            antialiasing: true
        }
        // Dome, with a little green pilot
        Rectangle {
            x: -19; y: -24
            width: 38; height: 34
            radius: 17
            antialiasing: true
            border.color: "#3d5a66"
            border.width: 1.2
            gradient: Gradient {
                GradientStop { position: 0; color: "#e6fbff" }
                GradientStop { position: 1; color: "#7fc9da" }
            }
        }
        Rectangle { x: -6; y: -16; width: 12; height: 12; radius: 6; color: "#69d64b"; antialiasing: true }
        Rectangle { x: -4; y: -12; width: 3; height: 4; radius: 1.5; color: "#111" }
        Rectangle { x: 1; y: -12; width: 3; height: 4; radius: 1.5; color: "#111" }
        Rectangle { x: -11; y: -20; width: 6; height: 3; radius: 1.5; color: "white"; opacity: 0.8; rotation: -30 }
        // Hull
        Rectangle {
            x: -48; y: -8
            width: 96; height: 22
            radius: 11
            antialiasing: true
            border.color: "#363b46"
            border.width: 1.4
            gradient: Gradient {
                GradientStop { position: 0; color: "#f3f5fa" }
                GradientStop { position: 0.55; color: "#b4bccb" }
                GradientStop { position: 1; color: "#6b7383" }
            }
        }
        // Rim lights chasing round on the beat
        Repeater {
            model: 7
            Rectangle {
                required property int index
                readonly property bool lit: Math.floor(root.phase * 2) % 7 === index
                x: -36 + index * 12 - 3
                y: 1
                width: 6; height: 6
                radius: 3
                antialiasing: true
                color: lit ? "#ffd166" : "#5a6070"
                border.color: lit ? "#fff3c4" : "#404553"
                border.width: 1
            }
        }
    }
}
