import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Widgets
import qs.theme
import qs.widgets

// The gate on the dialing computer: glyph track, nine chevrons and the event horizon.
// `encoded` chevrons (1–6) light up as the address is typed; `locked` lights the 7th.
Item {
    id: root

    property int encoded: 0          // 0..6
    property bool locked: false      // 7th chevron + wormhole flash
    property int openDuration: 1800  // how long the wormhole takes to open (ms)

    // Drives the horizon visuals one tick after `locked`, so the long
    // durations below are already in place when the animations start.
    property bool _open: false
    onLockedChanged: Qt.callLater(() => root._open = root.locked)
    property bool active: false      // horizon is "open" (there is a destination)
    property real spin: 0            // glyph track rotation, degrees
    property string iconSource: ""   // destination shown in the horizon
    property bool commandMode: false

    readonly property real cx: width / 2
    readonly property real cy: height / 2
    readonly property real r: Math.min(width, height) / 2 - 34   // outer ring radius
    readonly property int glyphCount: 39

    implicitWidth: 420
    implicitHeight: 420

    // Chevron slots: number → angle (clockwise from the top), as on the SGC gate
    readonly property var slots: [
        { n: 1, a: 40 }, { n: 2, a: 80 }, { n: 3, a: 120 },
        { n: 4, a: 240 }, { n: 5, a: 280 }, { n: 6, a: 320 },
        { n: 7, a: 0 }, { n: 8, a: 160 }, { n: 9, a: 200 }
    ]

    // ── Static frame: outer rings and tick marks ─────────────
    Canvas {
        id: frame
        anchors.fill: parent
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const c = getContext("2d");
            c.reset();
            const R = root.r;
            c.lineWidth = 2;
            c.strokeStyle = Theme.cyanMid;
            c.beginPath(); c.arc(root.cx, root.cy, R + 6, 0, Math.PI * 2); c.stroke();
            c.lineWidth = 1;
            c.strokeStyle = Theme.alpha(Theme.cyan, 0.35);
            c.beginPath(); c.arc(root.cx, root.cy, R + 12, 0, Math.PI * 2); c.stroke();
            // Outer ticks
            c.strokeStyle = Theme.alpha(Theme.cyan, 0.45);
            for (let i = 0; i < 72; i++) {
                const a = i / 72 * Math.PI * 2;
                const l = i % 8 === 0 ? 8 : 4;
                c.beginPath();
                c.moveTo(root.cx + Math.sin(a) * (R + 14), root.cy - Math.cos(a) * (R + 14));
                c.lineTo(root.cx + Math.sin(a) * (R + 14 + l), root.cy - Math.cos(a) * (R + 14 + l));
                c.stroke();
            }
            // Inner edge of the track
            c.lineWidth = 2;
            c.strokeStyle = Theme.cyan;
            c.beginPath(); c.arc(root.cx, root.cy, R - 46, 0, Math.PI * 2); c.stroke();
        }
    }

    // ── Glyph track (spins while dialing) ────────────────────
    Canvas {
        id: track
        anchors.fill: parent
        rotation: root.spin
        Behavior on rotation { NumberAnimation { duration: 520; easing.type: Easing.OutCubic } }
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const c = getContext("2d");
            c.reset();
            const R = root.r, r0 = R - 44, r1 = R + 2, n = root.glyphCount;
            // Band
            c.fillStyle = Theme.stone1;
            c.beginPath();
            c.arc(root.cx, root.cy, r1, 0, Math.PI * 2);
            c.arc(root.cx, root.cy, r0, 0, Math.PI * 2, true);
            c.fill();
            // Seeded random so the glyphs are the same every time
            let seed = 9137;
            const rnd = () => (seed = (seed * 16807) % 2147483647) / 2147483647;
            const rm = (r0 + r1) / 2;
            const cellW = 2 * Math.PI * rm / n;
            for (let i = 0; i < n; i++) {
                const a = i / n * Math.PI * 2;
                c.save();
                c.translate(root.cx, root.cy);
                c.rotate(a);
                // Divider
                c.strokeStyle = Theme.line;
                c.lineWidth = 1;
                c.beginPath();
                c.moveTo(0, -r0); c.lineTo(0, -r1);
                c.stroke();
                // Glyph: a short angular polyline, sometimes with a ring
                c.rotate(Math.PI / n);
                const w = cellW * 0.32, top = -r1 + 9, bot = -r0 - 9;
                c.strokeStyle = Theme.alpha(Theme.cyan, 0.55);
                c.lineWidth = 1.4;
                c.beginPath();
                const pts = 3 + Math.floor(rnd() * 2);
                for (let p = 0; p < pts; p++) {
                    const x = (rnd() * 2 - 1) * w, y = top + rnd() * (bot - top);
                    if (p === 0) c.moveTo(x, y); else c.lineTo(x, y);
                }
                c.stroke();
                if (rnd() > 0.7) {
                    c.beginPath();
                    c.arc((rnd() * 2 - 1) * w * 0.5, top + (bot - top) * 0.2, 2.2, 0, Math.PI * 2);
                    c.stroke();
                }
                c.restore();
            }
        }
    }

    // ── Event horizon ────────────────────────────────────────
    Item {
        id: horizon
        anchors.centerIn: parent
        width: (root.r - 50) * 2
        height: width
        scale: root._open ? 1.06 : 1
        Behavior on scale {
            NumberAnimation {
                duration: root.locked ? root.openDuration * 0.8 : 260
                easing.type: Easing.OutBack
                easing.overshoot: 3
            }
        }

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            opacity: root._open ? 1 : root.active ? 0.75 : 0.28
            Behavior on opacity { NumberAnimation { duration: root.locked ? root.openDuration * 0.6 : Theme.animSlow; easing.type: Easing.InOutQuad } }
            ShapePath {
                strokeWidth: 0
                strokeColor: "transparent"
                fillGradient: RadialGradient {
                    centerX: horizon.width / 2; centerY: horizon.height / 2
                    centerRadius: horizon.width / 2
                    focalX: centerX; focalY: centerY
                    GradientStop { position: 0.0; color: root.locked ? Theme.cyanBright : Theme.alpha(Theme.cyan, 0.55) }
                    GradientStop { position: 0.55; color: Theme.alpha(Theme.cyanMid, 0.35) }
                    GradientStop { position: 1.0; color: Theme.alpha(Theme.cyanDeep, 0.85) }
                }
                PathAngleArc {
                    centerX: horizon.width / 2; centerY: horizon.height / 2
                    radiusX: horizon.width / 2; radiusY: horizon.height / 2
                    startAngle: 0; sweepAngle: 360
                }
            }
        }

        // Swirl
        Canvas {
            id: swirl
            anchors.fill: parent
            opacity: root._open ? 0.8 : root.active ? 0.55 : 0.18
            Behavior on opacity { NumberAnimation { duration: root.locked ? root.openDuration * 0.6 : Theme.animSlow } }
            onWidthChanged: requestPaint()
            onPaint: {
                const c = getContext("2d");
                c.reset();
                const R = width / 2;
                c.strokeStyle = Theme.alpha(Theme.cyanBright, 0.5);
                c.lineWidth = 1;
                for (let k = 0; k < 18; k++) {
                    const off = k / 18 * Math.PI * 2;
                    c.beginPath();
                    for (let t = 0; t <= 1.0001; t += 0.04) {
                        const rr = R * (0.08 + 0.92 * t);
                        const a = off + t * 2.4;
                        const x = R + Math.cos(a) * rr, y = R + Math.sin(a) * rr;
                        if (t === 0) c.moveTo(x, y); else c.lineTo(x, y);
                    }
                    c.stroke();
                }
                c.beginPath();
                c.arc(R, R, R * 0.08, 0, Math.PI * 2);
                c.stroke();
            }
            RotationAnimation on rotation {
                running: root.visible && (root.active || root.locked)
                from: 0; to: -360
                duration: root.locked ? 2500 : 24000
                loops: Animation.Infinite
            }
        }

        // Destination in the horizon
        Item {
            anchors.centerIn: parent
            width: 104; height: 104
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: root.commandMode ? Theme.amber : Theme.cyan
                shadowBlur: 1.0
                shadowHorizontalOffset: 0
                shadowVerticalOffset: 0
                blurMax: 32
            }
            IconImage {
                anchors.centerIn: parent
                implicitSize: 92
                visible: !root.commandMode && root.iconSource !== ""
                source: root.iconSource
            }
            MIcon {
                anchors.centerIn: parent
                visible: root.commandMode
                text: "terminal"
                size: 76
                color: Theme.amberBright
            }
            OriginGlyph {
                anchors.centerIn: parent
                visible: !root.commandMode && root.iconSource === ""
                width: 62; height: 74
                glow: 0
                color: Theme.alpha(Theme.cyanBright, 0.85)
            }
        }
    }

    // ── Chevrons ─────────────────────────────────────────────
    Repeater {
        model: root.slots
        Item {
            id: chev
            required property var modelData
            readonly property bool lit: modelData.n <= 6 ? modelData.n <= root.encoded
                : modelData.n === 7 ? root.locked : false
            readonly property real rad: modelData.a * Math.PI / 180
            width: 34; height: 28
            x: root.cx + Math.sin(rad) * (root.r + 4) - width / 2
            y: root.cy - Math.cos(rad) * (root.r + 4) - height / 2
            rotation: modelData.a

            layer.enabled: chev.lit
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Theme.amber
                shadowBlur: 0.9
                shadowHorizontalOffset: 0
                shadowVerticalOffset: 0
                blurMax: 20
            }
            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    fillColor: chev.lit ? Theme.amber : Theme.stone2
                    strokeColor: chev.lit ? Theme.amberBright : Theme.lineBright
                    strokeWidth: 1.4
                    joinStyle: ShapePath.MiterJoin
                    startX: 1; startY: 1
                    PathLine { x: chev.width * 0.32; y: 1 }
                    PathLine { x: chev.width * 0.5; y: chev.height * 0.5 }
                    PathLine { x: chev.width * 0.68; y: 1 }
                    PathLine { x: chev.width - 1; y: 1 }
                    PathLine { x: chev.width * 0.6; y: chev.height - 1 }
                    PathLine { x: chev.width * 0.4; y: chev.height - 1 }
                    PathLine { x: 1; y: 1 }
                }
            }
            // Number, kept upright outside the ring
            Label {
                rotation: -chev.modelData.a
                x: chev.width / 2 - width / 2
                y: -20
                display: true
                size: 10
                color: chev.lit ? Theme.amber : Theme.textMute
                text: chev.modelData.n
            }
        }
    }
}
