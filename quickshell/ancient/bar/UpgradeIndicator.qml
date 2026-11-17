import QtQuick
import qs.services
import qs.theme
import qs.widgets

// Package upgrades: a green check when everything is up to date, a yellow
// download arrow when something can be upgraded. Opens the upgrades drawer,
// or the upgrade's output while it runs.
BarButton {
    id: root
    required property string screenName

    readonly property bool busy: Upgrades.active || (Upgrades.checking && !Upgrades.checked)

    active: Upgrades.active ? Upgrades.consoleOpen && Upgrades.consoleScreen === screenName
        : ShellState.drawer === "upgrades" && ShellState.drawerScreen === screenName
    activeColor: Upgrades.active || Upgrades.total > 0 ? Theme.amber : Theme.cyan
    onClicked: Upgrades.active ? Upgrades.toggleConsole(screenName) : ShellState.toggleDrawer("upgrades", screenName)

    MIcon {
        id: icon
        anchors.verticalCenter: parent.verticalCenter
        size: 17
        filled: Upgrades.checked && !root.busy
        text: root.busy || !Upgrades.checked ? "sync" : Upgrades.total > 0 ? "download" : "check_circle"
        color: Upgrades.active ? Theme.amber
            : !Upgrades.checked ? Theme.textMute
            : Upgrades.total > 0 ? Theme.yellow : Theme.crystal

        NumberAnimation on rotation {
            running: root.busy
            from: 0
            to: -360
            duration: 1600
            loops: Animation.Infinite
            onRunningChanged: if (!running) icon.rotation = 0
        }
    }
}
