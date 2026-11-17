import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs.services
import qs.theme
import qs.widgets

// Connected Bluetooth devices. Audio devices get one-click switches for the
// mode (music over A2DP, calls with the microphone over HFP) and the codec,
// which are PipeWire card profiles (services/BluetoothAudio).
Column {
    id: root

    property bool active: false      // drawer open: follow profile changes

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var devices: Bluetooth.devices.values
        .filter(d => d.connected)
        .sort((a, b) => a.name.localeCompare(b.name))

    spacing: 8

    Binding {
        target: BluetoothAudio
        property: "watching"
        value: root.active && root.devices.length > 0
    }
    // A device connecting or leaving changes the cards to read
    onDevicesChanged: if (active) BluetoothAudio.refresh()

    Item {
        width: parent.width
        height: 18
        SectionTitle {
            width: parent.width - manage.width - 10
            color: Theme.cyan
            text: root.devices.length > 0 ? I18n.tr("Bluetooth · %1", root.devices.length) : I18n.tr("Bluetooth")
        }
        MouseArea {
            id: manage
            visible: Config.bluetoothSettingsCommand !== ""
            anchors.right: parent.right
            width: manageLabel.implicitWidth + 4
            height: 18
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Hypr.exec(Config.bluetoothSettingsCommand)
            Label {
                id: manageLabel
                anchors.centerIn: parent
                size: 13
                color: parent.containsMouse ? Theme.cyan : Theme.textDim
                text: I18n.tr("Manage")
            }
        }
    }

    Label {
        width: parent.width
        visible: root.devices.length === 0
        horizontalAlignment: Text.AlignHCenter
        size: 13
        color: Theme.textMute
        text: !root.adapter ? I18n.tr("No Bluetooth adapter")
            : !root.adapter.enabled ? I18n.tr("Bluetooth off")
            : I18n.tr("No connected devices")
    }

    Repeater {
        model: ScriptModel { values: root.devices }

        delegate: Item {
            id: dev

            required property var modelData
            readonly property var audio: BluetoothAudio.cards[modelData?.address] ?? null
            readonly property var activeMode: audio?.modes.find(m => m.profiles.some(p => p.name === audio.active)) ?? null
            readonly property bool busy: modelData?.state === BluetoothDeviceState.Disconnecting

            width: root.width
            height: body.implicitHeight + 16

            ChamferPanel {
                anchors.fill: parent
                cut: Theme.cutSmall
                cutTopRight: false
                cutBottomLeft: false
                fillColor: Theme.stone2
                borderColor: dev.busy ? Theme.alpha(Theme.amber, 0.6) : Theme.alpha(Theme.cyan, 0.45)
            }

            Column {
                id: body
                x: 12; y: 8
                width: parent.width - 24
                spacing: 8

                // Name, battery and disconnect
                Item {
                    width: parent.width
                    height: 24

                    MIcon {
                        id: kind
                        anchors.verticalCenter: parent.verticalCenter
                        size: 20
                        filled: true
                        color: Theme.cyan
                        text: {
                            const i = dev.modelData?.icon ?? "";
                            if (/audio-(headset|headphones)/.test(i)) return "headphones";
                            if (i.startsWith("audio")) return "speaker";
                            if (i === "input-mouse") return "mouse";
                            if (i === "input-keyboard") return "keyboard";
                            if (i === "input-gaming") return "sports_esports";
                            if (i === "phone") return "smartphone";
                            if (i === "computer") return "computer";
                            return "bluetooth";
                        }
                    }
                    Label {
                        anchors.left: kind.right
                        anchors.leftMargin: 10
                        anchors.right: battery.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        size: 15
                        color: Theme.text
                        text: dev.modelData?.name ?? ""
                    }
                    Row {
                        id: battery
                        anchors.right: disconnect.left
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        visible: dev.modelData?.batteryAvailable ?? false
                        spacing: 2
                        readonly property int pct: Math.round((dev.modelData?.battery ?? 0) * 100)
                        MIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            size: 15
                            color: battery.pct <= 20 ? Theme.dome : Theme.textDim
                            text: battery.pct > 85 ? "battery_full" : battery.pct > 60 ? "battery_5_bar"
                                : battery.pct > 40 ? "battery_4_bar" : battery.pct > 20 ? "battery_2_bar" : "battery_alert"
                        }
                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            size: 12
                            color: battery.pct <= 20 ? Theme.dome : Theme.textDim
                            text: battery.pct + "%"
                        }
                    }
                    MouseArea {
                        id: disconnect
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 24; height: 24
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: !dev.busy
                        onClicked: dev.modelData?.disconnect()
                        MIcon {
                            anchors.centerIn: parent
                            size: 18
                            color: dev.busy ? Theme.amber : parent.containsMouse ? Theme.dome : Theme.textMute
                            text: "link_off"
                        }
                    }
                }

                // Mode: music (A2DP) or calls with the microphone (HFP)
                Flow {
                    width: parent.width
                    visible: (dev.audio?.modes.length ?? 0) > 1
                    spacing: 6
                    Repeater {
                        model: dev.audio?.modes ?? []
                        Chip {
                            required property var modelData
                            text: modelData.label
                            hint: modelData.hint
                            selected: dev.activeMode?.id === modelData.id
                            busy: BluetoothAudio.pending === modelData.profiles[0].name
                            // Switch to the mode's best codec
                            onClicked: if (!selected) BluetoothAudio.setProfile(dev.audio.card, modelData.profiles[0].name)
                        }
                    }
                }

                // Codec within the current mode
                Flow {
                    width: parent.width
                    visible: (dev.activeMode?.profiles.length ?? 0) > 0
                    spacing: 6
                    Label {
                        height: 26
                        size: 11
                        display: true
                        font.letterSpacing: 1.6
                        color: Theme.textMute
                        text: "CODEC"
                    }
                    Repeater {
                        model: dev.activeMode?.profiles ?? []
                        Chip {
                            required property var modelData
                            text: modelData.codec
                            tint: Theme.amber
                            selected: dev.audio?.active === modelData.name
                            busy: BluetoothAudio.pending === modelData.name
                            onClicked: if (!selected) BluetoothAudio.setProfile(dev.audio.card, modelData.name)
                        }
                    }
                }
            }
        }
    }

    component Chip: MouseArea {
        id: chip

        property string text: ""
        property string hint: ""
        property bool selected: false
        property bool busy: false
        property color tint: Theme.cyan

        implicitWidth: chipRow.implicitWidth + 20
        implicitHeight: 26
        hoverEnabled: true
        cursorShape: selected ? Qt.ArrowCursor : Qt.PointingHandCursor

        Rectangle {
            anchors.fill: parent
            radius: 2
            color: chip.selected ? Theme.alpha(chip.tint, 0.18)
                : chip.containsMouse ? Theme.stone3 : Theme.stone1
            border.width: 1
            border.color: chip.busy ? Theme.amber : chip.selected ? chip.tint : Theme.line
            Behavior on color { ColorAnimation { duration: Theme.animFast } }
        }
        Row {
            id: chipRow
            anchors.centerIn: parent
            spacing: 6
            Label {
                anchors.verticalCenter: parent.verticalCenter
                size: 13
                color: chip.selected ? Theme.text : Theme.textDim
                text: chip.text
            }
            Label {
                anchors.verticalCenter: parent.verticalCenter
                visible: chip.hint !== ""
                size: 11
                color: chip.selected ? chip.tint : Theme.textMute
                text: chip.hint
            }
        }
        SequentialAnimation on opacity {
            running: chip.busy
            loops: Animation.Infinite
            alwaysRunToEnd: true
            NumberAnimation { to: 0.45; duration: 380 }
            NumberAnimation { to: 1; duration: 380 }
        }
    }
}
