import QtQuick
import QtQuick.Shapes

// A beach ball that bounces in and off Annabelle's back three times, each
// bounce on a beat, then flies out the other side. 400×400 units.
Item {
    id: root
    width: 400
    height: 400

    property real backX: 230        // where her back is now
    property real backY: 150
    property real t: -1
    property var plan: []           // arcs: { t0, t1, x0, y0, x1, y1, h, hit } (y null: her back)
    property int nextHit: 0
    property real spin: 0
    property real dir: 1
    readonly property real r: 15
    readonly property bool active: t >= 0 && plan.length > 0 && t < plan[plan.length - 1].t1
    readonly property real bx: at().x
    readonly property real by: at().y

    signal hit()

    visible: active

    // timeToBeat: seconds to the next beat; period: seconds per beat
    function start(timeToBeat, period) {
        const gap = period < 0.45 ? period * 2 : period;
        let first = timeToBeat;
        while (first < 0.8) first += gap;
        const from = Math.random() < 0.5 ? -1 : 1;
        dir = -from;
        const side = from < 0 ? -40 : 440;
        const arcs = [];
        arcs.push({ t0: 0, t1: first, x0: side, y0: 40, x1: backX + 14 * from, y1: null, h: 30 });
        let t0 = first, x0 = backX + 14 * from;
        const xs = [backX - 16 * from, backX + 6 * from];
        for (let i = 0; i < 2; i++) {
            arcs.push({ t0: t0, t1: t0 + gap, x0: x0, y0: null, x1: xs[i], y1: null, h: 46 + 12 * i });
            t0 += gap;
            x0 = xs[i];
        }
        arcs.push({ t0: t0, t1: t0 + 1.1, x0: x0, y0: null, x1: 440 - side + (from < 0 ? 40 : -40), y1: -10, h: 90 });
        plan = arcs;
        nextHit = 0;
        t = 0;
    }

    // One of the six coloured panels
    function wedge(i) {
        const a0 = i * Math.PI / 3, a1 = (i + 1) * Math.PI / 3;
        const f = v => v.toFixed(2);
        return `M 0 0 L ${f(Math.cos(a0) * r)} ${f(Math.sin(a0) * r)} `
            + `A ${r} ${r} 0 0 1 ${f(Math.cos(a1) * r)} ${f(Math.sin(a1) * r)} Z`;
    }

    function at() {
        if (t < 0 || plan.length === 0) return { x: -100, y: -100 };
        let a = plan[plan.length - 1];
        for (const p of plan) {
            if (t < p.t1) {
                a = p;
                break;
            }
        }
        const u = Math.max(0, Math.min(1, (t - a.t0) / (a.t1 - a.t0)));
        const contact = backY - r + 2;
        const y0 = a.y0 === null ? contact : a.y0, y1 = a.y1 === null ? contact : a.y1;
        return { x: a.x0 + (a.x1 - a.x0) * u, y: y0 + (y1 - y0) * u - 4 * a.h * u * (1 - u) };
    }

    function step(dt) {
        if (t < 0) return;
        t += dt;
        spin += dt * 420 * dir;
        // The first three arcs end on her back
        while (nextHit < 3 && nextHit < plan.length && t >= plan[nextHit].t1) {
            nextHit++;
            hit();
        }
        if (!active) t = -1;
    }

    Item {
        x: root.bx
        y: root.by
        rotation: root.spin
        Shape {
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                fillColor: "#ff3b30"
                strokeColor: "transparent"
                PathSvg { path: root.wedge(0) }
            }
            ShapePath {
                fillColor: "#ffcc00"
                strokeColor: "transparent"
                PathSvg { path: root.wedge(1) }
            }
            ShapePath {
                fillColor: "#34c759"
                strokeColor: "transparent"
                PathSvg { path: root.wedge(2) }
            }
            ShapePath {
                fillColor: "#00c7f0"
                strokeColor: "transparent"
                PathSvg { path: root.wedge(3) }
            }
            ShapePath {
                fillColor: "#1e40ff"
                strokeColor: "transparent"
                PathSvg { path: root.wedge(4) }
            }
            ShapePath {
                fillColor: "#ff8a00"
                strokeColor: "transparent"
                PathSvg { path: root.wedge(5) }
            }
        }
        Rectangle {
            x: -root.r; y: -root.r
            width: root.r * 2; height: width
            radius: root.r
            color: "transparent"
            border.color: "#1d1d24"
            border.width: 1.6
            antialiasing: true
        }
        Rectangle { x: -3.5; y: -3.5; width: 7; height: 7; radius: 3.5; color: "white"; antialiasing: true }
    }
    // Shine stays on top while the ball turns
    Rectangle {
        x: root.bx - 9; y: root.by - 11
        width: 7; height: 4
        radius: 2
        rotation: -35
        color: "white"
        opacity: 0.7
        antialiasing: true
    }
}
