import QtQuick
import QtQuick.Shapes

// The mirror ball's light, over everything in the disco: spots that wheel
// round once every eight beats and flash on the kicks, and two coloured beams
// sweeping from the ball. 400×400 units.
Item {
    id: root
    width: 400
    height: 400

    property real amount: 0          // how much of the disco shows
    property real phase: 0
    property real kick: 0
    property real drive: 0

    visible: amount > 0.01
    opacity: amount

    component Beam: Shape {
        property color tint
        x: 200
        y: 50
        transformOrigin: Item.TopLeft
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: "transparent"
            fillGradient: LinearGradient {
                x1: 0; y1: 0
                x2: 380; y2: 0
                GradientStop { position: 0; color: Qt.rgba(tint.r, tint.g, tint.b, 0.4) }
                GradientStop { position: 1; color: Qt.rgba(tint.r, tint.g, tint.b, 0) }
            }
            PathSvg { path: "M 0 0 L 380 -34 L 380 34 Z" }
        }
    }
    Beam {
        tint: "#ff4fd8"
        rotation: 120 + Math.sin(root.phase * Math.PI / 4) * 30
        opacity: 0.5 + root.kick * 0.5
    }
    Beam {
        tint: "#41e3ff"
        rotation: 60 - Math.sin(root.phase * Math.PI / 4 + 1) * 30
        opacity: 0.5 + root.kick * 0.5
    }

    Repeater {
        model: 20
        Rectangle {
            required property int index
            readonly property bool low: index < 11
            readonly property real a: root.phase * Math.PI / 4 + index * 2.39996
            readonly property real cx: 200 + Math.cos(a) * (low ? 165 : 185)
            readonly property real cy: low ? 312 + Math.sin(a) * 52 : 150 + Math.sin(a) * 110
            readonly property real s: low ? 1 : 0.65
            x: cx - width / 2
            y: cy - height / 2
            width: 15 * s
            height: (low ? 6 : 15) * s
            radius: height / 2
            antialiasing: true
            color: index % 5 === 0 && root.drive > 0.5 ? ["#ff7ae6", "#7ff0ff", "#fff27a"][index % 3] : "white"
            opacity: 0.45 + 0.55 * root.kick
        }
    }
}
