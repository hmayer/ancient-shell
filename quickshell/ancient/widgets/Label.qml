import QtQuick
import qs.theme

// UI text in the shell's typeface.
Text {
    property bool display: false   // Orbitron instead of Rajdhani
    property real size: 15

    font.family: display ? Theme.fontDisplay : Theme.fontUi
    font.pixelSize: size
    font.weight: display ? Font.Medium : Font.DemiBold
    font.letterSpacing: display ? 1.2 : 0.3
    color: Theme.text
    verticalAlignment: Text.AlignVCenter
    elide: Text.ElideRight
}
