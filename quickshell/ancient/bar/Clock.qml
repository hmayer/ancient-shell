import QtQuick
import Quickshell
import qs.services
import qs.theme
import qs.widgets

BarButton {
    id: root
    required property string screenName

    active: ShellState.drawer === "dashboard" && ShellState.drawerScreen === screenName
    padding: 12
    onClicked: ShellState.toggleDrawer("dashboard", screenName)

    SystemClock {
        id: clock
        precision: Config.showSeconds ? SystemClock.Seconds : SystemClock.Minutes
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        Label {
            anchors.verticalCenter: parent.verticalCenter
            display: true
            size: 15
            font.weight: Font.DemiBold
            color: root.active || root.containsMouse ? Theme.cyanBright : Theme.text
            text: Qt.formatDateTime(clock.date,
                (Config.clock24h ? "HH:mm" : "hh:mm") + (Config.showSeconds ? ":ss" : "") + (Config.clock24h ? "" : " AP"))
        }
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 5; height: 5; rotation: 45
            color: Theme.amber
        }
        Label {
            anchors.verticalCenter: parent.verticalCenter
            size: 14
            color: Theme.textDim
            text: Config.locale.toString(clock.date, "ddd dd MMM").toUpperCase().replace(/\./g, "")
        }
    }
}
