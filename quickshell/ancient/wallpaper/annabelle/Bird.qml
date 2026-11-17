import QtQuick

// A little red bird that flies in, perches on Annabelle's back and rides her
// dance there, bobbing its head to the beat and chirping, then flies off.
// 400×400 units; perchX/perchY follow her back every frame.
Item {
    id: root
    width: 400
    height: 400

    property real perchX: 230
    property real perchY: 150
    property real phase: 0
    property real t: -1
    property real stay: 8           // seconds on her back

    readonly property real arrive: 2.4
    readonly property real leave: 1.8
    readonly property bool active: t >= 0 && t < arrive + stay + leave
    readonly property bool perched: t >= arrive && t < arrive + stay
    property real bx: -40
    property real by: 30
    property bool facingLeft: false
    property real flap: 0
    property int lastBeat: 0

    signal chirp(real x, real y)

    visible: active

    function start(seconds) {
        stay = seconds;
        t = 0;
    }

    function step(dt) {
        if (t < 0) return;
        t += dt;
        if (!active) {
            t = -1;
            return;
        }
        const px = perchX - 6, py = perchY - 9;
        if (t < arrive) {
            // Swoop in from the top left
            const u = t / arrive, e = 1 - Math.pow(1 - u, 2);
            bx = -30 + (px + 30) * e;
            by = 20 + (py - 20) * e - Math.sin(Math.PI * u) * 40;
            facingLeft = false;
            flap = Math.sin(t * 38);
        } else if (perched) {
            bx = px;
            by = py - Math.abs(Math.sin(Math.PI * phase)) * 2.5;
            facingLeft = true;
            flap = -1;
            const b = Math.floor(phase);
            if (b !== lastBeat) {
                lastBeat = b;
                if (Math.random() < 0.3) chirp(bx - 8, by - 12);
            }
        } else {
            const u = (t - arrive - stay) / leave;
            bx = px + (440 - px) * u * u;
            by = py - 200 * u + Math.sin(Math.PI * u) * -20;
            facingLeft = false;
            flap = Math.sin(t * 38);
        }
    }

    Item {
        x: root.bx
        y: root.by
        transform: Scale { xScale: root.facingLeft ? 1 : -1 }

        // Tail
        Rectangle { x: 4; y: -2; width: 9; height: 4; radius: 2; rotation: -25; color: "#1b1b1f"; antialiasing: true }
        // Wing behind
        Rectangle {
            x: -1; y: -9
            width: 5; height: 12
            radius: 2.5
            color: "#1b1b1f"
            antialiasing: true
            transformOrigin: Item.Bottom
            rotation: root.flap < -0.5 ? 70 : 20 + root.flap * 50
        }
        // Body and belly
        Rectangle { x: -8; y: -8; width: 16; height: 15; radius: 7.5; color: "#e5402a"; border.color: "#7d1d12"; border.width: 1; antialiasing: true }
        Rectangle { x: -6; y: -1; width: 9; height: 6; radius: 3; color: "#ff9c6e"; antialiasing: true }
        // Head bob: the head leads on the beat
        Item {
            y: root.perched ? -Math.max(0, Math.cos(2 * Math.PI * root.phase)) * 1.5 : 0
            Rectangle { x: -7; y: -14; width: 11; height: 10; radius: 5; color: "#e5402a"; border.color: "#7d1d12"; border.width: 1; antialiasing: true }
            Rectangle { x: -3; y: -18; width: 3; height: 5; radius: 1.5; rotation: -20; color: "#c22a18"; antialiasing: true }
            Rectangle { x: -5; y: -11; width: 3.4; height: 3.4; radius: 1.7; color: "white"; antialiasing: true }
            Rectangle { x: -4.6; y: -10.4; width: 1.8; height: 1.8; radius: 0.9; color: "#111" }
            Rectangle { x: -11; y: -9.5; width: 5; height: 3; radius: 1; rotation: 10; color: "#ffc21a"; antialiasing: true }
        }
        // Wing in front
        Rectangle {
            x: 0; y: -8
            width: 6; height: 12
            radius: 3
            color: "#232327"
            antialiasing: true
            transformOrigin: Item.Bottom
            rotation: root.flap < -0.5 ? 75 : -10 - root.flap * 55
        }
        // Feet, when perched
        Rectangle { visible: root.perched; x: -3; y: 6; width: 1.4; height: 4; color: "#ffb000" }
        Rectangle { visible: root.perched; x: 1; y: 6; width: 1.4; height: 4; color: "#ffb000" }
    }
}
