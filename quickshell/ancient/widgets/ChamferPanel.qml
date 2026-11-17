import QtQuick
import QtQuick.Shapes
import qs.theme

// A panel with cut (chamfered) corners, like the plates of an Ancient console.
// Each corner can be cut or square. An optional glow line runs along the top edge.
Item {
    id: root

    property real cut: Theme.cut
    property bool cutTopLeft: true
    property bool cutTopRight: true
    property bool cutBottomLeft: true
    property bool cutBottomRight: true

    property color fillColor: Theme.panel
    property color borderColor: Theme.line
    property real borderWidth: 1
    // Bright engraved line along one edge ("none", "top", "bottom")
    property string accentEdge: "none"
    property color accentColor: Theme.cyan
    property real accentLength: 0.35   // fraction of width

    readonly property real _tl: cutTopLeft ? cut : 0
    readonly property real _tr: cutTopRight ? cut : 0
    readonly property real _bl: cutBottomLeft ? cut : 0
    readonly property real _br: cutBottomRight ? cut : 0

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: root.fillColor
            strokeColor: root.borderWidth > 0 ? root.borderColor : "transparent"
            strokeWidth: root.borderWidth
            joinStyle: ShapePath.MiterJoin


            startX: root._tl + 0.5; startY: 0.5
            PathLine { x: root.width - 0.5 - root._tr; y: 0.5 }
            PathLine { x: root.width - 0.5; y: 0.5 + root._tr }
            PathLine { x: root.width - 0.5; y: root.height - 0.5 - root._br }
            PathLine { x: root.width - 0.5 - root._br; y: root.height - 0.5 }
            PathLine { x: 0.5 + root._bl; y: root.height - 0.5 }
            PathLine { x: 0.5; y: root.height - 0.5 - root._bl }
            PathLine { x: 0.5; y: 0.5 + root._tl }
            PathLine { x: root._tl + 0.5; y: 0.5 }
        }
    }

    // Engraved accent line
    Rectangle {
        visible: root.accentEdge !== "none"
        width: root.width * root.accentLength
        height: 1
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.accentEdge === "top" ? 0 : root.height - 1
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.5; color: root.accentColor }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }
}
