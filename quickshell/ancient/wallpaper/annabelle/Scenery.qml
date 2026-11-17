import QtQuick
import QtQuick.Shapes

// The world behind Annabelle, 400×400 units: sky, field and fence, dressed
// for one of five scenes and fading into the next when it changes.
//
//   day    blue sky, drifting clouds, a flock far away
//   night  navy sky, a crescent moon, twinkling stars (on the treble),
//          shooting stars, grey clouds
//   disco  a dim purple sky and a mirror ball (its lights are DiscoLights)
//   psy    sky and grass in one hue that cycles with the music
//   film   the day, in grey with grain (the colour is taken off by Annabelle)
Item {
    id: root
    width: 400
    height: 400

    property string scene: "day"
    property real phase: 0          // beat clock
    property real kick: 0
    property real high: 0           // treble, 0..1
    property real bass: 0
    property real air: 0            // how high Annabelle is, for her shadow
    property real hue: 0            // for psy

    readonly property real horizon: 232
    property real t: 0

    // The clock and levels for the layers of one scene, held still while that
    // scene is hidden so their bindings don't re-run every frame
    readonly property real nightT: nightAmt > 0.01 ? t : 0
    readonly property real nightHigh: nightAmt > 0.01 ? high : 0
    readonly property real discoPhase: discoAmt > 0.01 ? phase : 0
    readonly property real discoKick: discoAmt > 0.01 ? kick : 0
    readonly property real discoHigh: discoAmt > 0.01 ? high : 0

    // How much of each scene shows, 0..1, blended by step()
    property real dayAmt: 1
    property real nightAmt: 0
    property real discoAmt: 0
    property real psyAmt: 0
    property real filmAmt: 0

    property color skyTop: "#8b95ff"
    property color skyBottom: "#1d3cf0"
    property color grassTop: "#45e052"
    property color grassBottom: "#1fa636"
    property color cloud: "#ffffff"

    readonly property var palettes: ({
        day: ["#8b95ff", "#1d3cf0", "#45e052", "#1fa636", "#ffffff"],
        night: ["#03061f", "#1b2c80", "#168a2c", "#0a4f18", "#5c6585"],
        disco: ["#16082f", "#4a1d8c", "#28915a", "#11512f", "#6d5aa0"],
        film: ["#8b95ff", "#1d3cf0", "#45e052", "#1fa636", "#ffffff"]
    })

    function rgb(c) {
        return [c.r, c.g, c.b];
    }
    readonly property var paletteRgb: {
        const o = {};
        for (const k in palettes)
            o[k] = palettes[k].map(h => rgb(Qt.color(h)));
        return o;
    }
    function hsv(h, s, v) {
        const c = Qt.hsva(((h % 1) + 1) % 1, s, v, 1);
        return [c.r, c.g, c.b];
    }
    function hash(n) {
        const x = Math.sin(n * 12.9898 + 78.233) * 43758.5453;
        return x - Math.floor(x);
    }

    // Blend the colours and the scene amounts toward the current scene
    function step(dt) {
        t += dt;
        const k = 1 - Math.exp(-dt * 2.4);
        let target;
        if (scene === "psy") {
            // All one hue, as in the original: a pale sky over a deep field
            target = [hsv(hue, 0.4, 1), hsv(hue + 0.02, 0.9, 1), hsv(hue + 0.04, 0.8, 0.9),
                hsv(hue + 0.06, 0.95, 0.62), [1, 1, 1]];
        } else {
            target = paletteRgb[scene] ?? paletteRgb.day;
        }
        const names = ["skyTop", "skyBottom", "grassTop", "grassBottom", "cloud"];
        for (let i = 0; i < 5; i++) {
            const c = root[names[i]], to = target[i];
            root[names[i]] = Qt.rgba(c.r + (to[0] - c.r) * k, c.g + (to[1] - c.g) * k, c.b + (to[2] - c.b) * k, 1);
        }
        const a = 1 - Math.exp(-dt * 2);
        dayAmt += ((scene === "day" || scene === "film" || scene === "psy" ? 1 : 0) - dayAmt) * a;
        nightAmt += ((scene === "night" ? 1 : 0) - nightAmt) * a;
        discoAmt += ((scene === "disco" ? 1 : 0) - discoAmt) * a;
        psyAmt += ((scene === "psy" ? 1 : 0) - psyAmt) * a;
        filmAmt += ((scene === "film" ? 1 : 0) - filmAmt) * a;
        shooting.step(dt);
    }

    // ── Sky ──
    Rectangle {
        width: root.width
        height: root.horizon + 2
        gradient: Gradient {
            GradientStop { position: 0; color: root.skyTop }
            GradientStop { position: 1; color: root.skyBottom }
        }
    }

    // Stars, brighter with the treble
    Repeater {
        model: 44
        Rectangle {
            required property int index
            readonly property real s: 1.4 + root.hash(index * 3.1) * 2
            x: root.hash(index * 1.7) * 400
            y: root.hash(index * 2.3) * (root.horizon - 30) + 4
            width: s
            height: s
            radius: s / 2
            color: index % 7 === 0 ? "#ffe9b0" : "#e8f0ff"
            antialiasing: true
            visible: root.nightAmt > 0.01
            opacity: root.nightAmt * Math.min(1, 0.35 + 0.45 * (0.5 + 0.5 * Math.sin(root.nightT * (0.8 + root.hash(index) * 2.5) + index))
                + root.nightHigh * 1.2 * root.hash(index * 5.7))
        }
    }

    // Crescent moon, with a halo
    Item {
        x: 300
        y: 58
        visible: root.nightAmt > 0.01
        opacity: root.nightAmt
        Rectangle {
            x: -40; y: -40
            width: 80; height: 80
            radius: 40
            color: "#ffe680"
            opacity: 0.1 + root.high * 0.1
        }
        Shape {
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                fillColor: "#ffe35c"
                strokeColor: "#e9c43a"
                strokeWidth: 1
                PathSvg { path: "M 4 -22 A 22 22 0 1 1 -8 20 A 17 17 0 1 0 4 -22 Z" }
            }
        }
    }

    // Shooting stars at night
    Item {
        id: shooting
        property real next: 3
        function step(dt) {
            for (let i = 0; i < 2; i++) {
                const s = rep.itemAt(i);
                if (!s) continue;
                if (s.life > 0) {
                    s.life -= dt;
                    s.x += s.vx * dt;
                    s.y += s.vy * dt;
                }
            }
            next -= dt;
            if (next <= 0 && root.nightAmt > 0.5) {
                next = 2.5 + Math.random() * 6;
                for (let i = 0; i < 2; i++) {
                    const s = rep.itemAt(i);
                    if (s && s.life <= 0) {
                        s.x = 60 + Math.random() * 260;
                        s.y = 20 + Math.random() * 60;
                        const a = (Math.random() < 0.5 ? 0.45 : Math.PI - 0.45);
                        s.vx = Math.cos(a) * 260;
                        s.vy = Math.sin(a) * 260;
                        s.rotation = a * 180 / Math.PI;
                        s.life = 0.7;
                        break;
                    }
                }
            }
        }
        Repeater {
            id: rep
            model: 2
            Rectangle {
                property real life: 0
                property real vx: 0
                property real vy: 0
                width: 34
                height: 2
                radius: 1
                transformOrigin: Item.Right
                opacity: Math.max(0, Math.min(1, life / 0.25)) * root.nightAmt
                visible: life > 0
                antialiasing: true
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: "transparent" }
                    GradientStop { position: 1; color: "#ffffff" }
                }
            }
        }
    }

    // A flock far away, crossing now and then
    Repeater {
        model: 4
        Shape {
            id: flyer
            required property int index
            readonly property real lap: (root.t * 9 + 160) % 900
            readonly property real flap: Math.sin(root.t * 9 + index * 1.3) * 2.6
            x: 430 - lap + index * 13
            y: 70 + (index % 2) * 7 + Math.sin(root.t * 0.7 + index) * 2
            visible: root.dayAmt > 0.01 && lap < 560
            opacity: root.dayAmt * 0.8
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: "#f4f6ff"
                strokeWidth: 1.4
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                PathSvg { path: `M -5 ${-flyer.flap * 0.4} Q -2.5 ${flyer.flap} 0 0 Q 2.5 ${flyer.flap} 5 ${-flyer.flap * 0.4}` }
            }
        }
    }

    // Clouds, drifting left
    component Cloud: Item {
        property real big: 1
        width: 70 * big
        height: 26 * big
        Rectangle { x: 0; y: parent.height * 0.42; width: parent.width; height: parent.height * 0.5; radius: height / 2; color: root.cloud; antialiasing: true }
        Rectangle { x: parent.width * 0.14; y: parent.height * 0.12; width: parent.width * 0.38; height: parent.height * 0.7; radius: height / 2; color: root.cloud; antialiasing: true }
        Rectangle { x: parent.width * 0.4; y: 0; width: parent.width * 0.42; height: parent.height * 0.82; radius: height / 2; color: root.cloud; antialiasing: true }
        Rectangle { x: parent.width * 0.1; y: parent.height * 0.78; width: parent.width * 0.8; height: parent.height * 0.14; radius: height / 2; color: Qt.darker(root.cloud, 1.12); opacity: 0.6; antialiasing: true }
    }
    Repeater {
        model: [{ x: 40, y: 34, big: 1.0, v: 4.5 }, { x: 250, y: 22, big: 0.75, v: 3 }, { x: 330, y: 92, big: 0.6, v: 5.5 },
            { x: 150, y: 120, big: 0.5, v: 2.2 }]
        Cloud {
            required property var modelData
            big: modelData.big
            x: ((modelData.x - root.t * modelData.v) % 520 + 520) % 520 - 80
            y: modelData.y
            opacity: 1 - root.discoAmt * 0.7
        }
    }

    // Mirror ball, lowered in for the disco
    Item {
        x: 200
        y: -90 + 140 * root.discoAmt
        visible: root.discoAmt > 0.01
        Rectangle { x: -0.75; y: -200; width: 1.5; height: 178; color: "#c8c8d8" }
        Rectangle {
            x: -22; y: -22
            width: 44; height: 44
            radius: 22
            antialiasing: true
            gradient: Gradient {
                GradientStop { position: 0; color: "#f4f4fb" }
                GradientStop { position: 1; color: "#6e6e86" }
            }
        }
        // Facets that catch the light as it turns
        Repeater {
            model: 26
            Rectangle {
                required property int index
                readonly property real a: root.hash(index * 7.1) * Math.PI * 2 + root.discoPhase * 0.5
                readonly property real r: 4 + root.hash(index * 3.9) * 15
                readonly property real front: Math.cos(a)
                x: Math.sin(a) * r - 2.5
                y: (root.hash(index * 5.3) - 0.5) * 36 - 2.5
                width: 5
                height: 5
                visible: front > 0
                color: "white"
                opacity: front * (0.25 + 0.75 * Math.max(root.discoKick, root.discoHigh * root.hash(index * 9.1)))
            }
        }
    }

    // ── Field ──
    Rectangle {
        y: root.horizon
        width: root.width
        height: root.height - root.horizon
        gradient: Gradient {
            GradientStop { position: 0; color: root.grassTop }
            GradientStop { position: 1; color: root.grassBottom }
        }
    }
    Rectangle {
        y: root.horizon
        width: root.width
        height: 2
        color: Qt.lighter(root.grassTop, 1.25)
        opacity: 0.6
    }

    // Tufts and daisies, swaying a little with the bass
    Repeater {
        model: [[118, 352, 1], [292, 338, 0.8], [340, 286, 0.7], [58, 322, 0.9], [236, 372, 1.1], [168, 258, 0.6], [310, 382, 1]]
        Shape {
            required property var modelData
            required property int index
            x: modelData[0]
            y: modelData[1]
            transform: [
                Scale { xScale: modelData[2]; yScale: modelData[2] },
                Rotation { angle: Math.sin(root.t * 1.6 + index) * 4 + root.bass * 6 }
            ]
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: Qt.darker(root.grassTop, 1.45)
                strokeWidth: 2
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                PathSvg { path: "M -6 0 Q -6 -8 -9 -12 M 0 0 Q 0 -10 2 -15 M 6 0 Q 6 -7 10 -10" }
            }
        }
    }
    Repeater {
        model: [[86, 366], [262, 356], [356, 326], [142, 384], [40, 290]]
        Item {
            required property var modelData
            x: modelData[0]
            y: modelData[1]
            opacity: 1 - root.nightAmt * 0.5
            Repeater {
                model: 5
                Rectangle {
                    required property int index
                    x: Math.cos(index * 1.2566) * 3.6 - 2.4
                    y: Math.sin(index * 1.2566) * 3.6 - 2.4
                    width: 4.8; height: 4.8; radius: 2.4
                    color: "white"
                    antialiasing: true
                }
            }
            Rectangle { x: -2.2; y: -2.2; width: 4.4; height: 4.4; radius: 2.2; color: "#ffd23a"; antialiasing: true }
        }
    }

    // Fence on the left
    Shape {
        id: fence
        preferredRendererType: Shape.CurveRenderer
        readonly property string rails: "M 36 304 L 40 226 M 70 266 L 72 216 M 24 252 L 84 228 M 24 282 L 84 252"
        ShapePath {
            strokeColor: "#14161a"
            strokeWidth: 7.5
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathSvg { path: fence.rails }
        }
        ShapePath {
            strokeColor: root.nightAmt > 0.5 ? "#c9d1e6" : "#ffffff"
            strokeWidth: 4.2
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathSvg { path: fence.rails }
        }
    }

    // Her shadow, smaller as she rises
    Rectangle {
        readonly property real s: Math.max(0.35, 1 + root.air / 90)
        x: 216 - width / 2
        y: 302 - height / 2
        width: 186 * s
        height: 16 * s
        radius: height / 2
        color: "black"
        opacity: 0.22 * s
        antialiasing: true
    }
}
