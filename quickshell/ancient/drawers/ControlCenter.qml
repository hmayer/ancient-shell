import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.UPower
import qs.notifications
import qs.services
import qs.theme
import qs.widgets

// Control drawer: quick toggles, known Wi-Fi networks, connected Bluetooth
// devices, levels and the notification log.
Drawer {
    id: root
    name: "control"
    align: "right"
    contentWidth: 420
    contentHeight: Math.min(760, (modelData?.height ?? 900) - Theme.barHeight - Theme.gap * 4)

    readonly property var wifiDev: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wifiNet: wifiDev?.networks?.values?.find(n => n.connected) ?? null
    readonly property var wired: Networking.devices.values.find(d => d.type === DeviceType.Wired && d.connected) ?? null
    readonly property var bt: Bluetooth.defaultAdapter
    readonly property int btConnected: Bluetooth.devices.values.filter(d => d.connected).length

    onOpenChanged: if (open) {
        Brightness.refresh();
        if (!ppdCheck.running) ppdCheck.running = true;
    }

    property bool ppdRunning: false
    Process {
        id: ppdCheck
        running: true
        command: ["busctl", "--system", "call", "org.freedesktop.DBus", "/org/freedesktop/DBus",
            "org.freedesktop.DBus", "NameHasOwner", "s", "org.freedesktop.UPower.PowerProfiles"]
        stdout: StdioCollector {
            onStreamFinished: root.ppdRunning = text.trim() === "b true"
        }
    }

    Component {
        id: profileToggle
        QuickToggle {
            icon: PowerProfiles.profile === PowerProfile.Performance ? "bolt"
                : PowerProfiles.profile === PowerProfile.PowerSaver ? "eco" : "balance"
            title: I18n.tr("Power")
            checked: PowerProfiles.profile !== PowerProfile.Balanced
            onColor: PowerProfiles.profile === PowerProfile.PowerSaver ? Theme.crystal : Theme.amber
            subtitle: PowerProfiles.profile === PowerProfile.Performance ? I18n.tr("Performance")
                : PowerProfiles.profile === PowerProfile.PowerSaver ? I18n.tr("Power saver") : I18n.tr("Balanced")
            onClicked: {
                const order = [PowerProfile.PowerSaver, PowerProfile.Balanced];
                if (PowerProfiles.hasPerformanceProfile) order.push(PowerProfile.Performance);
                PowerProfiles.profile = order[(order.indexOf(PowerProfiles.profile) + 1) % order.length];
            }
        }
    }
    Component {
        id: noProfileToggle
        QuickToggle {
            icon: "balance"
            title: I18n.tr("Power")
            subtitle: I18n.tr("No power-profiles")
        }
    }

    Column {
        id: top
        width: parent.width
        spacing: 14

        SectionTitle { width: parent.width; text: I18n.tr("Controls"); color: Theme.cyan }

        Grid {
            width: parent.width
            columns: 2
            spacing: 8

            QuickToggle {
                width: (parent.width - 8) / 2
                icon: root.wired ? "lan" : "wifi"
                title: root.wired ? I18n.tr("Wired") : I18n.tr("Wi-Fi")
                checked: root.wired !== null || Networking.wifiEnabled
                subtitle: root.wired ? I18n.tr("Connected") : root.wifiNet ? root.wifiNet.name : Networking.wifiEnabled ? I18n.tr("No network") : I18n.tr("Off")
                onClicked: Hypr.exec("nmcli radio wifi " + (Networking.wifiEnabled ? "off" : "on"))
                onPressAndHold: Hypr.exec(Config.networkSettingsCommand)
                onSecondaryClicked: Hypr.exec(Config.networkSettingsCommand)
            }
            QuickToggle {
                width: (parent.width - 8) / 2
                icon: "bluetooth"
                title: I18n.tr("Bluetooth")
                checked: root.bt?.enabled ?? false
                subtitle: !root.bt ? I18n.tr("Unavailable") : !root.bt.enabled ? I18n.tr("Off")
                    : root.btConnected > 0 ? I18n.trn("%1 connected", "%1 connected", root.btConnected) : I18n.tr("On")
                onClicked: if (root.bt) root.bt.enabled = !root.bt.enabled
                onPressAndHold: Hypr.exec(Config.bluetoothSettingsCommand)
                onSecondaryClicked: Hypr.exec(Config.bluetoothSettingsCommand)
            }
            QuickToggle {
                width: (parent.width - 8) / 2
                icon: "do_not_disturb_on"
                title: I18n.tr("Do not disturb")
                onColor: Theme.amber
                checked: ShellState.dnd
                subtitle: ShellState.dnd ? I18n.tr("Silenced") : I18n.tr("Off")
                onClicked: ShellState.dnd = !ShellState.dnd
            }
            QuickToggle {
                width: (parent.width - 8) / 2
                icon: "coffee"
                title: I18n.tr("Keep awake")
                onColor: Theme.amber
                checked: ShellState.caffeine
                subtitle: ShellState.caffeine ? I18n.tr("No auto-lock") : I18n.tr("Off")
                onClicked: ShellState.caffeine = !ShellState.caffeine
            }
            // Power profiles only once power-profiles-daemon is already running:
            // touching PowerProfiles D-Bus-activates it, which blocks the shell
            // for 25 s at login and stops conflicting daemons (auto-cpufreq, tlp).
            Loader {
                width: (parent.width - 8) / 2
                sourceComponent: root.ppdRunning ? profileToggle : noProfileToggle
            }
            QuickToggle {
                width: (parent.width - 8) / 2
                icon: "wallpaper"
                title: I18n.tr("Wallpaper")
                subtitle: I18n.tr("Change")
                onClicked: ShellState.toggleWallpaperPicker()
            }
        }

        KnownNetworks {
            width: parent.width
            visible: root.wifiDev !== null
            device: root.wifiDev
            active: root.open
        }

        BluetoothDevices {
            width: parent.width
            active: root.open
        }

        SectionTitle { width: parent.width; text: I18n.tr("Levels"); color: Theme.cyan }

        GlyphSlider {
            width: parent.width
            icon: Audio.icon
            value: Audio.muted ? 0 : Audio.volume
            onMoved: v => Audio.setVolume(v)
            onIconClicked: Audio.toggleMute()
        }
        GlyphSlider {
            width: parent.width
            icon: Audio.micMuted ? "mic_off" : "mic"
            color: Audio.micMuted ? Theme.textMute : Theme.cyan
            value: Audio.micMuted ? 0 : Audio.micVolume
            onMoved: v => Audio.setMicVolume(v)
            onIconClicked: Audio.toggleMic()
        }
        GlyphSlider {
            width: parent.width
            visible: Brightness.available
            icon: "light_mode"
            color: Theme.amber
            value: Brightness.value
            onMoved: v => Brightness.set(v)
        }

        Item {
            width: parent.width
            height: 18
            SectionTitle {
                width: parent.width - clear.width - 10
                text: I18n.tr("Log · %1", Notifs.count)
            }
            MouseArea {
                id: clear
                anchors.right: parent.right
                width: clearLabel.implicitWidth + 4
                height: 18
                visible: Notifs.count > 0
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Notifs.clearAll()
                Label {
                    id: clearLabel
                    anchors.centerIn: parent
                    size: 13
                    color: parent.containsMouse ? Theme.dome : Theme.textDim
                    text: I18n.tr("Clear")
                }
            }
        }
    }

    ListView {
        anchors.top: top.bottom
        anchors.topMargin: 10
        anchors.bottom: parent.bottom
        width: parent.width
        clip: true
        spacing: 6
        model: Notifs.history
        boundsBehavior: Flickable.StopAtBounds

        delegate: NotificationCard {
            required property var modelData
            width: ListView.view.width
            wrapper: modelData
            compact: true
        }

        Column {
            anchors.centerIn: parent
            visible: Notifs.count === 0
            spacing: 8
            OriginGlyph {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 26; height: 32
                color: Theme.textMute
                glow: 0
            }
            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                size: 14
                color: Theme.textMute
                text: I18n.tr("No messages")
            }
        }
    }
}
