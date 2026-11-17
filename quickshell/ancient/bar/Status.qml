import QtQuick
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.UPower
import qs.services
import qs.theme
import qs.widgets

// Network, Bluetooth, volume, battery and notifications. Opens the control drawer.
BarButton {
    id: root
    required property string screenName

    active: ShellState.drawer === "control" && ShellState.drawerScreen === screenName
    onClicked: ShellState.toggleDrawer("control", screenName)
    onWheel: wheel => Audio.step(wheel.angleDelta.y > 0 ? 0.03 : -0.03)

    readonly property var battery: UPower.displayDevice
    readonly property bool hasBattery: battery?.isLaptopBattery ?? false
    readonly property bool charging: battery?.state === UPowerDeviceState.Charging
        || battery?.state === UPowerDeviceState.FullyCharged
    readonly property real pct: (battery?.percentage ?? 0)

    readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wired: Networking.devices.values.find(d => d.type === DeviceType.Wired && d.connected) ?? null
    readonly property var wifiNet: wifi?.networks?.values?.find(n => n.connected) ?? null

    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 9

        MIcon {
            anchors.verticalCenter: parent.verticalCenter
            size: 17
            color: Theme.textDim
            text: root.wired ? "lan"
                : root.wifiNet ? (root.wifiNet.signalStrength > 0.66 ? "wifi" : root.wifiNet.signalStrength > 0.33 ? "wifi_2_bar" : "wifi_1_bar")
                : Networking.wifiEnabled ? "wifi_find" : "wifi_off"
        }
        MIcon {
            anchors.verticalCenter: parent.verticalCenter
            visible: Bluetooth.defaultAdapter !== null
            size: 17
            color: Bluetooth.defaultAdapter?.enabled ? Theme.textDim : Theme.textMute
            text: Bluetooth.defaultAdapter?.enabled ? "bluetooth" : "bluetooth_disabled"
        }
        MIcon {
            anchors.verticalCenter: parent.verticalCenter
            size: 17
            color: Audio.muted ? Theme.dome : Theme.textDim
            text: Audio.icon
        }
        Row {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.hasBattery
            spacing: 3
            MIcon {
                anchors.verticalCenter: parent.verticalCenter
                size: 17
                rotation: 90
                color: root.charging ? Theme.crystal : root.pct < 0.15 ? Theme.dome : Theme.textDim
                text: root.charging ? "battery_charging_full"
                    : ["battery_0_bar", "battery_1_bar", "battery_2_bar", "battery_3_bar", "battery_4_bar", "battery_5_bar", "battery_6_bar", "battery_full"][Math.min(7, Math.floor(root.pct * 8))]
            }
            Label {
                anchors.verticalCenter: parent.verticalCenter
                size: 14
                color: Theme.textDim
                text: Math.round(root.pct * 100) + "%"
            }
        }
        Item {
            anchors.verticalCenter: parent.verticalCenter
            width: 18; height: 18
            MIcon {
                anchors.centerIn: parent
                size: 17
                filled: Notifs.count > 0
                color: ShellState.dnd ? Theme.textMute : Notifs.count > 0 ? Theme.amber : Theme.textDim
                text: ShellState.dnd ? "notifications_off" : Notifs.count > 0 ? "notifications_unread" : "notifications"
            }
        }
    }
}
