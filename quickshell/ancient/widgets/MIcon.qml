import QtQuick
import qs.theme

// Material Symbols glyph.
Text {
    id: root
    property real size: 18
    property bool filled: false

    font.family: Theme.fontIcon
    font.pixelSize: size
    font.variableAxes: ({ "FILL": filled ? 1 : 0, "wght": 400, "opsz": 24 })
    color: Theme.text
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter
    renderType: Text.NativeRendering
}
