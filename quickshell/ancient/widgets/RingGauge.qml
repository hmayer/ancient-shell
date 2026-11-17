import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import qs.theme

// A ring gauge drawn like the inner ring of a gate: a dim track and a lit arc,
// with a value readout in the middle.
Item {
    id: root

    property real value: 0          // 0..1
    property string label: ""
    property string valueText: Math.round(value * 100) + "%"
    property color color: value > 0.85 ? Theme.dome : value > 0.65 ? Theme.amber : Theme.cyan
    property real thickness: 5

    implicitWidth: 92
    implicitHeight: 92

    Behavior on value { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }

    readonly property real _r: Math.min(width, height) / 2 - thickness

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        // Tick ring
        ShapePath {
            fillColor: "transparent"
            strokeColor: Theme.line
            strokeWidth: 1
            strokeStyle: ShapePath.DashLine
            dashPattern: [1, 3]
            PathAngleArc {
                centerX: root.width / 2; centerY: root.height / 2
                radiusX: root._r + root.thickness; radiusY: root._r + root.thickness
                startAngle: 0; sweepAngle: 360
            }
        }
        // Track
        ShapePath {
            fillColor: "transparent"
            strokeColor: Theme.stone2
            strokeWidth: root.thickness
            capStyle: ShapePath.FlatCap
            PathAngleArc {
                centerX: root.width / 2; centerY: root.height / 2
                radiusX: root._r; radiusY: root._r
                startAngle: 135; sweepAngle: 270
            }
        }
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: root.color
            shadowBlur: 0.5
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 0
            blurMax: 14
        }
        ShapePath {
            fillColor: "transparent"
            strokeColor: root.color
            strokeWidth: root.thickness
            capStyle: ShapePath.FlatCap
            PathAngleArc {
                centerX: root.width / 2; centerY: root.height / 2
                radiusX: root._r; radiusY: root._r
                startAngle: 135; sweepAngle: Math.max(0.5, 270 * Math.min(1, root.value))
            }
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: -3
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            display: true
            size: Math.round(15 * root.width / 92)
            text: root.valueText
            color: Theme.text
        }
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            size: Math.round(12 * root.width / 92)
            font.letterSpacing: 1.5
            text: root.label
            color: Theme.textMute
        }
    }
}
