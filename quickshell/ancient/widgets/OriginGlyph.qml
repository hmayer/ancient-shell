import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import qs.theme

// Earth's point-of-origin glyph: a circle above a pyramid with two feet.
Item {
    id: root
    property color color: Theme.cyan
    property real glow: 0.6       // 0 disables the glow
    property real lineWidth: Math.max(1.2, width / 14)

    implicitWidth: 22
    implicitHeight: 26

    layer.enabled: glow > 0
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: root.color
        shadowBlur: root.glow
        shadowHorizontalOffset: 0
        shadowVerticalOffset: 0
        blurMax: 20
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        // Circle
        ShapePath {
            fillColor: "transparent"
            strokeColor: root.color
            strokeWidth: root.lineWidth
            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height * 0.17
                radiusX: root.height * 0.14
                radiusY: root.height * 0.14
                startAngle: 0
                sweepAngle: 360
            }
        }

        // Pyramid with the two horizontal feet
        ShapePath {
            fillColor: "transparent"
            strokeColor: root.color
            strokeWidth: root.lineWidth
            joinStyle: ShapePath.MiterJoin
            capStyle: ShapePath.FlatCap
            startX: root.width * 0.30; startY: root.height * 0.97
            PathLine { x: root.width * 0.06; y: root.height * 0.97 }
            PathLine { x: root.width * 0.50; y: root.height * 0.40 }
            PathLine { x: root.width * 0.94; y: root.height * 0.97 }
            PathLine { x: root.width * 0.70; y: root.height * 0.97 }
        }
    }
}
