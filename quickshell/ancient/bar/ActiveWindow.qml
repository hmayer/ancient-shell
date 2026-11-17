import QtQuick
import Quickshell.Hyprland
import qs.services
import qs.theme
import qs.widgets

// Class of the focused window in amber, title in stone-white.
Item {
    id: root
    property real maxWidth: 400

    readonly property var toplevel: Hyprland.activeToplevel
    readonly property string appClass: toplevel?.lastIpcObject?.class ?? ""

    implicitHeight: Theme.barHeight - 12
    width: Math.max(0, Math.min(maxWidth, cls.implicitWidth + 8 + title.implicitWidth))
    clip: true

    Label {
        id: cls
        anchors.verticalCenter: parent.verticalCenter
        text: root.appClass !== "" ? root.appClass.split(".").pop().toUpperCase() : I18n.tr("DESKTOP")
        size: 12
        font.letterSpacing: 1.5
        color: Theme.amber
        elide: Text.ElideNone
    }
    Label {
        id: title
        anchors.verticalCenter: parent.verticalCenter
        x: cls.implicitWidth + 8
        width: Math.max(0, root.width - x)
        text: root.toplevel?.title ?? ""
        size: 15
        color: Theme.textDim
    }
}
