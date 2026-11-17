import QtQuick
import QtQuick.Shapes

// Annabelle herself, drawn in vector shapes at 240×210 units and posed from
// outside (Dancer). She faces left: a black head with sleepy eyes on the front
// of a wool cloud standing on four thin legs. The legs reach for the ground
// from the hips, so a lower body bends the knees and a raised one leaves them
// hanging. The look (glasses, hat and microphone, mohawk, beret, tattoo)
// is switched by Annabelle.qml.
Item {
    id: root
    width: 240
    height: 210

    // ── Pose ───────────────────────────────────────────────
    property real air: 0            // whole sheep up (negative), off the ground
    property real bob: 0            // body down onto bent knees
    property real sway: 0           // body forward (−) or back (+)
    property real tilt: 0           // body pitch, degrees
    property real squash: 0         // + squashed flat, − stretched tall
    property real nod: 0            // head down, degrees
    property real earBack: 0        // ears up, degrees
    property real earFront: 0
    property real lidL: 0.5         // eyelids, 0 shut .. 1 wide open
    property real lidR: 0.5
    property real eyeScale: 1
    property real pupilX: 0         // -1 .. 1 on each eye
    property real pupilY: 0.3
    property real cross: 0          // cross-eyed, 0..1
    property real mouth: 0          // open, 0..1
    property real mouthRound: 0     // an "O" instead of a grin
    property real tongue: 0         // out, 0..1
    property real tap0: 0           // hooves raised off the ground
    property real tap1: 0
    property real tap2: 0
    property real tap3: 0
    property real dangle: 0         // swing of hanging legs, radians
    property real hair: 0           // mohawk jiggle, degrees

    // ── Look ───────────────────────────────────────────────
    property bool glasses: false
    property bool hat: false
    property bool mic: false
    property bool punk: false
    property bool beret: false
    property string tattoo: ""      // "", "anarchy", "peace"

    // Points other things attach to, in this item's coordinates
    readonly property alias backAnchor: back
    readonly property alias mouthAnchor: mouthPoint
    readonly property alias eyeAnchor: eyePoint

    readonly property color ink: "#0b0b0d"
    readonly property color wool: "#fbfbf7"
    readonly property real ground: 205
    readonly property real legLength: 58.5
    readonly property var hips: [92, 104, 166, 178]   // front near, front far, back near, back far

    // A wool cloud: an ellipse with a puff between each pair of points
    function woolPath(cx, cy, rx, ry, n, puff) {
        let s = "";
        for (let i = 0; i <= n; i++) {
            const a = i / n * 2 * Math.PI;
            const x = cx + rx * Math.cos(a), y = cy + ry * Math.sin(a);
            if (i === 0) {
                s = `M ${x.toFixed(2)} ${y.toFixed(2)}`;
                continue;
            }
            const m = a - Math.PI / n;
            const qx = cx + (rx + puff * 2.1) * Math.cos(m), qy = cy + (ry + puff * 2.1) * Math.sin(m);
            s += ` Q ${qx.toFixed(2)} ${qy.toFixed(2)} ${x.toFixed(2)} ${y.toFixed(2)}`;
        }
        return s + " Z";
    }

    // One leg from its hip (which moves with the body) to its hoof: on the
    // ground when it can reach, bending the knee forward; hanging otherwise
    function leg(i, tap) {
        const a = tilt * Math.PI / 180, ca = Math.cos(a), sa = Math.sin(a);
        const dx = hips[i] - 120, dy = 148 - 105;
        const hx = 120 + dx * ca - dy * sa + sway, hy = 105 + dx * sa + dy * ca + bob;
        let fx = hips[i] - tap * 0.35, fy = ground - air - tap;
        let d = Math.hypot(fx - hx, fy - hy);
        if (d >= legLength) {
            const sw = dangle * (i % 2 ? 1.25 : 1) + (i < 2 ? 0.08 : -0.08);
            fx = hx + Math.sin(sw) * legLength;
            fy = hy + Math.cos(sw) * legLength;
            d = legLength;
        }
        const bend = Math.sqrt(Math.max(0, legLength * legLength - d * d)) * 0.7;
        const ux = (fx - hx) / d, uy = (fy - hy) / d;
        return { hx, hy, fx, fy, kx: (hx + fx) / 2 - uy * bend, ky: (hy + fy) / 2 + ux * bend };
    }

    component Leg: Item {
        id: legItem
        required property var at
        property bool far: false
        Shape {
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: legItem.far ? "#26262b" : root.ink
                strokeWidth: 4.2
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                startX: legItem.at.hx
                startY: legItem.at.hy
                PathQuad {
                    x: legItem.at.fx
                    y: legItem.at.fy
                    controlX: legItem.at.kx
                    controlY: legItem.at.ky
                }
            }
        }
        // Hoof
        Rectangle {
            x: legItem.at.fx - 4.5
            y: legItem.at.fy - 3
            width: 8
            height: 5
            radius: 2.5
            color: legItem.far ? "#26262b" : root.ink
            antialiasing: true
        }
    }

    // An eye: white, a pupil, and a lid as black as the head coming down
    component Eye: Item {
        id: eye
        property real open: 0.5
        property real lookX: 0
        property real lookY: 0
        width: 23
        height: 17
        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: "#f6f6f1"
            antialiasing: true
        }
        Rectangle {
            width: 5.2
            height: 5.2
            radius: 2.6
            color: root.ink
            antialiasing: true
            x: eye.width / 2 - 2.6 + Math.max(-1, Math.min(1, eye.lookX)) * (eye.width / 2 - 5)
            y: eye.height / 2 - 2.6 + Math.max(-1, Math.min(1, eye.lookY)) * (eye.height / 2 - 4.2)
        }
        Rectangle {
            x: -2
            y: -3
            width: eye.width + 4
            height: 3 + (1 - Math.max(0, Math.min(1, eye.open))) * (eye.height + 1)
            color: root.ink
        }
    }

    // A closed eye: a lash line where the eye was
    component Shut: Shape {
        property real cx: 0
        property real cy: 0
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: "#d6d6d0"
            strokeWidth: 2.2
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathSvg { path: `M ${cx - 9} ${cy} Q ${cx} ${cy + 6} ${cx + 9} ${cy}` }
        }
    }

    // A long black ear, its root at the item's origin, pointing along +x.
    // (A Shape is sized to its path, so it turns on the root, not the middle)
    component Ear: Shape {
        property real len: 52
        transformOrigin: Item.TopLeft
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: root.ink
            strokeColor: root.ink
            strokeWidth: 1
            PathSvg {
                path: `M 0 -5 C ${len * 0.3} -9 ${len * 0.75} -7 ${len} -1 C ${len * 0.75} 5 ${len * 0.3} 7 0 5 Z`
            }
        }
    }

    // ── Microphone on a stand, in front of her mouth (stays on the ground) ──
    Item {
        id: micStand
        visible: root.mic
        z: 3
        Shape {
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: "#2a2c31"
                strokeWidth: 3
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                PathSvg { path: "M 12 204 L 18 150 L 26 140 M 2 206 L 12 197 L 24 206" }
            }
        }
        Rectangle {
            x: 23; y: 127
            width: 9; height: 17
            radius: 3
            rotation: 38
            color: "#1c1d21"
            antialiasing: true
        }
        Rectangle {
            x: 25; y: 117
            width: 15; height: 15
            radius: 7.5
            rotation: 38
            antialiasing: true
            border.color: "#55585f"
            border.width: 1.2
            gradient: Gradient {
                GradientStop { position: 0; color: "#f2f3f5" }
                GradientStop { position: 1; color: "#9a9ea6" }
            }
        }
    }

    // ── Everything that leaves the ground with her ──
    Item {
        id: rig
        width: root.width
        height: root.height
        y: root.air

        // Legs behind the wool, the far ones first
        Leg { at: root.leg(1, root.tap1); far: true }
        Leg { at: root.leg(3, root.tap3); far: true }
        Leg { at: root.leg(0, root.tap0) }
        Leg { at: root.leg(2, root.tap2) }

        Item {
            id: body
            width: root.width
            height: root.height
            x: root.sway
            y: root.bob
            rotation: root.tilt
            transform: Scale {
                origin.x: 135
                origin.y: 158
                xScale: 1 + root.squash * 0.55
                yScale: 1 - root.squash
            }

            // Wool, shaded a little underneath
            Shape {
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeColor: root.ink
                    strokeWidth: 3.2
                    joinStyle: ShapePath.RoundJoin
                    fillGradient: LinearGradient {
                        x1: 0; y1: 52
                        x2: 0; y2: 160
                        GradientStop { position: 0; color: root.wool }
                        GradientStop { position: 0.65; color: "#f1f2ef" }
                        GradientStop { position: 1; color: "#d9dcdc" }
                    }
                    PathSvg { path: root.woolPath(135, 105, 80, 50, 22, 4.6) }
                }
                // A few curls in the fleece
                ShapePath {
                    strokeColor: "#c9cdcf"
                    strokeWidth: 1.7
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    PathSvg {
                        path: "M 120 80 q 6 -6 12 0 M 150 70 q 6 -6 12 0 M 176 92 q 6 -6 12 0 "
                            + "M 108 118 q 6 -6 12 0 M 142 128 q 6 -6 12 0 M 182 124 q 6 -6 12 0 "
                            + "M 160 100 q 5 -5 10 0"
                    }
                }
            }

            // Tattoo on the flank
            Shape {
                visible: root.tattoo !== ""
                preferredRendererType: Shape.CurveRenderer
                x: 182
                y: 100
                rotation: -8
                ShapePath {
                    strokeColor: "#262a44"
                    strokeWidth: 2.3
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    joinStyle: ShapePath.RoundJoin
                    PathSvg {
                        path: root.tattoo === "anarchy"
                            ? "M -13 0 A 13 13 0 1 0 13 0 A 13 13 0 1 0 -13 0 M -8 12 L 0 -12 L 8 12 M -14 3 L 14 3"
                            : "M -13 0 A 13 13 0 1 0 13 0 A 13 13 0 1 0 -13 0 M 0 -13 L 0 13 M 0 2 L -9 9 M 0 2 L 9 9"
                    }
                }
            }

            Item { id: back; x: 150; y: 52 }

            // ── Head, turning on the neck ──
            Item {
                id: head
                x: 82
                y: 78
                rotation: -root.nod

                Ear {
                    x: -58
                    y: -1
                    rotation: 192 + root.earBack
                    len: 50
                }

                Shape {
                    preferredRendererType: Shape.CurveRenderer
                    ShapePath {
                        fillColor: root.ink
                        strokeColor: root.ink
                        strokeWidth: 1
                        PathSvg {
                            path: "M -60 -3 C -40 -17 -8 -13 0 9 C 6 27 0 53 -16 69 "
                                + "C -28 81 -52 83 -64 71 C -76 59 -80 33 -76 17 C -73 5 -68 1 -60 -3 Z"
                        }
                    }
                }

                Item { id: eyePoint; x: -40; y: 24 }

                Eye {
                    x: -64.5
                    y: 15.5
                    scale: root.eyeScale
                    open: root.lidL
                    lookX: root.pupilX + root.cross * 0.8
                    lookY: root.pupilY
                }
                Eye {
                    x: -40.5
                    y: 15.5
                    scale: root.eyeScale
                    open: root.lidR
                    lookX: root.pupilX - root.cross * 0.8
                    lookY: root.pupilY
                }
                Shut { cx: -53; cy: 25; opacity: Math.max(0, 1 - root.lidL / 0.14) }
                Shut { cx: -29; cy: 25; opacity: Math.max(0, 1 - root.lidR / 0.14) }

                // Mouth, open when she sings or gasps
                Rectangle {
                    readonly property real w: 17 - root.mouthRound * 5
                    readonly property real h: 1 + root.mouth * 15
                    visible: root.mouth > 0.04
                    x: -46 - w / 2
                    y: 64 - h / 2
                    width: w
                    height: h
                    radius: Math.min(w, h) / 2
                    color: "#7d1724"
                    antialiasing: true
                    clip: true
                    Rectangle {
                        width: parent.width * 0.7
                        height: parent.height * 0.5
                        x: parent.width * 0.15
                        y: parent.height * 0.55
                        radius: height / 2
                        color: "#ee8496"
                        antialiasing: true
                    }
                }
                Item { id: mouthPoint; x: -50; y: 66 }

                // Tongue out over the muzzle
                Rectangle {
                    visible: root.tongue > 0.05
                    x: -61
                    y: 66
                    width: 14
                    height: 4 + root.tongue * 17
                    radius: 7
                    rotation: 12
                    color: "#f08597"
                    border.color: "#b4455a"
                    border.width: 1.2
                    antialiasing: true
                    Rectangle {
                        x: parent.width / 2 - 0.6
                        y: 3
                        width: 1.2
                        height: Math.max(0, parent.height - 7)
                        color: "#c95a6e"
                    }
                }

                Ear {
                    x: -6
                    y: 4
                    rotation: 58 - root.earFront
                    len: 56
                }

                // Mohawk
                Shape {
                    visible: root.punk
                    preferredRendererType: Shape.CurveRenderer
                    transform: Rotation { origin.x: -36; origin.y: 0; angle: root.hair }
                    ShapePath {
                        strokeColor: "#4c0f7c"
                        strokeWidth: 1.6
                        joinStyle: ShapePath.RoundJoin
                        fillGradient: LinearGradient {
                            x1: 0; y1: -40
                            x2: 0; y2: 0
                            GradientStop { position: 0; color: "#d58cff" }
                            GradientStop { position: 1; color: "#8e1fe0" }
                        }
                        PathSvg {
                            path: "M -70 4 L -72 -20 L -60 -5 L -58 -32 L -47 -11 L -40 -38 L -33 -13 "
                                + "L -22 -36 L -19 -10 L -6 -27 L -6 -2 L 4 -14 L 2 8 Z"
                        }
                    }
                }

                // Beret
                Item {
                    visible: root.beret
                    x: -40
                    y: -8
                    rotation: -14
                    Rectangle {
                        x: -31; y: -10
                        width: 62; height: 20
                        radius: 10
                        color: "#d62a2a"
                        border.color: "#8c1313"
                        border.width: 1.6
                        antialiasing: true
                    }
                    Rectangle {
                        x: -2; y: -15
                        width: 4; height: 7
                        radius: 2
                        color: "#a51b1b"
                        antialiasing: true
                    }
                }

                // Top hat, cocked
                Item {
                    visible: root.hat
                    x: -36
                    y: -9
                    rotation: -10
                    Rectangle {
                        x: -19; y: -38
                        width: 38; height: 38
                        radius: 3
                        color: "#1c1c23"
                        border.color: "#4b4b5a"
                        border.width: 1.5
                        antialiasing: true
                    }
                    Rectangle {
                        x: -19; y: -11
                        width: 38; height: 6
                        color: "#e8a33d"
                    }
                    Rectangle {
                        x: -30; y: -3
                        width: 60; height: 7
                        radius: 3.5
                        color: "#1c1c23"
                        border.color: "#4b4b5a"
                        border.width: 1.5
                        antialiasing: true
                    }
                }

                // Sunglasses
                Shape {
                    visible: root.glasses
                    preferredRendererType: Shape.CurveRenderer
                    ShapePath {
                        strokeColor: "#050506"
                        strokeWidth: 2.6
                        joinStyle: ShapePath.RoundJoin
                        fillGradient: LinearGradient {
                            x1: 0; y1: 10
                            x2: 0; y2: 38
                            GradientStop { position: 0; color: "#a9b1b8" }
                            GradientStop { position: 1; color: "#5d666e" }
                        }
                        PathSvg {
                            path: "M -66 24 A 13 13 0 1 0 -40 24 A 13 13 0 1 0 -66 24 "
                                + "M -42 24 A 13 13 0 1 0 -16 24 A 13 13 0 1 0 -42 24"
                        }
                    }
                    ShapePath {
                        strokeColor: "#050506"
                        strokeWidth: 2.6
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap
                        PathSvg { path: "M -16 20 L -2 14" }
                    }
                    ShapePath {
                        strokeColor: Qt.rgba(1, 1, 1, 0.75)
                        strokeWidth: 2
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap
                        PathSvg { path: "M -61 18 Q -57 14 -52 15 M -37 18 Q -33 14 -28 15" }
                    }
                }
            }
        }
    }
}
