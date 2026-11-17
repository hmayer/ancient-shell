import QtQuick
import Quickshell
import Quickshell.Networking
import qs.services
import qs.theme
import qs.widgets

// Known Wi-Fi networks in range, i.e. those with a saved NetworkManager
// profile. Click one to connect (NetworkManager activates the saved profile
// and its secrets), click the connected one to disconnect.
// NetworkManager scans only while `active` (the drawer is open).
Column {
    id: root

    property var device: null        // WifiDevice
    property bool active: false
    property int maxRows: 4

    readonly property real rowHeight: 38
    // Connected first, then by name: a stable order, so rows never move under
    // the cursor when the signal strength changes during a scan
    readonly property var networks: (device?.networks?.values ?? [])
        .filter(n => n.known)
        .sort((a, b) => (b.connected - a.connected) || a.name.localeCompare(b.name))

    spacing: 8

    Binding {
        when: root.device !== null
        target: root.device
        property: "scannerEnabled"
        value: root.active
    }

    Item {
        width: parent.width
        height: 18
        SectionTitle {
            width: parent.width - more.width - 10
            color: Theme.cyan
            text: root.networks.length > 0 ? I18n.tr("Known networks · %1", root.networks.length) : I18n.tr("Known networks")
        }
        MouseArea {
            id: more
            visible: Config.networkSettingsCommand !== ""
            anchors.right: parent.right
            width: moreLabel.implicitWidth + 4
            height: 18
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Hypr.exec(Config.networkSettingsCommand)
            Label {
                id: moreLabel
                anchors.centerIn: parent
                size: 13
                color: parent.containsMouse ? Theme.cyan : Theme.textDim
                text: I18n.tr("Edit")
            }
        }
    }

    Label {
        width: parent.width
        visible: root.networks.length === 0
        horizontalAlignment: Text.AlignHCenter
        size: 13
        color: Theme.textMute
        text: !Networking.wifiEnabled ? I18n.tr("Wi-Fi off")
            : I18n.tr("No known networks in range")
    }

    ListView {
        width: parent.width
        height: count > 0 ? Math.min(count, root.maxRows) * (root.rowHeight + spacing) - spacing : 0
        visible: count > 0
        clip: true
        spacing: 4
        interactive: count > root.maxRows
        boundsBehavior: Flickable.StopAtBounds
        // ScriptModel keeps each row alive while its network stays in the list
        model: ScriptModel { values: root.networks }

        delegate: MouseArea {
            id: row

            required property var modelData
            readonly property real strength: modelData?.signalStrength ?? 0   // 0..1
            readonly property bool busy: modelData.stateChanging
                || modelData.state === ConnectionState.Connecting
                || modelData.state === ConnectionState.Disconnecting
            property string failure: ""

            width: ListView.view.width
            height: root.rowHeight
            hoverEnabled: true
            cursorShape: busy ? Qt.BusyCursor : Qt.PointingHandCursor

            onClicked: {
                if (busy) return;
                failure = "";
                if (modelData.connected) modelData.disconnect();
                else modelData.connect();
            }

            Connections {
                target: row.modelData
                function onConnectionFailed(reason) {
                    row.failure = ({
                        [ConnectionFailReason.NoSecrets]: I18n.tr("no saved password"),
                        [ConnectionFailReason.WifiAuthTimeout]: I18n.tr("timed out"),
                        [ConnectionFailReason.WifiNetworkLost]: I18n.tr("network lost"),
                        [ConnectionFailReason.WifiClientFailed]: I18n.tr("Wi-Fi failure"),
                        [ConnectionFailReason.WifiClientDisconnected]: I18n.tr("disconnected")
                    })[reason] ?? I18n.tr("unknown error");
                    failTimer.restart();
                }
            }
            Timer {
                id: failTimer
                interval: 6000
                onTriggered: row.failure = ""
            }

            ChamferPanel {
                anchors.fill: parent
                cut: Theme.cutSmall
                cutTopRight: false
                cutBottomLeft: false
                fillColor: row.modelData.connected
                    ? Theme.alpha(Theme.cyan, row.containsMouse ? 0.2 : 0.12)
                    : row.containsMouse ? Theme.stone3 : Theme.stone2
                borderColor: row.failure !== "" ? Theme.alpha(Theme.dome, 0.7)
                    : row.modelData.connected ? Theme.alpha(Theme.cyan, 0.6)
                    : row.busy ? Theme.alpha(Theme.amber, 0.6) : Theme.line
                Behavior on fillColor { ColorAnimation { duration: Theme.animFast } }
            }

            MIcon {
                id: bars
                x: 12
                anchors.verticalCenter: parent.verticalCenter
                size: 20
                filled: true
                color: row.modelData.connected ? Theme.cyan : Theme.textDim
                text: row.strength > 0.75 ? "signal_wifi_4_bar"
                    : row.strength > 0.5 ? "network_wifi_3_bar"
                    : row.strength > 0.25 ? "network_wifi_2_bar"
                    : row.strength > 0.05 ? "network_wifi_1_bar" : "signal_wifi_0_bar"
            }
            MIcon {
                anchors.left: bars.right
                anchors.leftMargin: -6
                anchors.bottom: bars.bottom
                visible: row.modelData.security !== WifiSecurityType.Open
                size: 11
                filled: true
                color: Theme.textMute
                text: "lock"
            }

            Label {
                anchors.left: bars.right
                anchors.leftMargin: 14
                anchors.right: status.left
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                size: 15
                color: row.modelData.connected ? Theme.text : Theme.textDim
                text: row.modelData.name
            }

            Label {
                id: status
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                size: 12
                elide: Text.ElideNone
                color: row.failure !== "" ? Theme.dome
                    : row.busy ? Theme.amber
                    : row.modelData.connected ? Theme.cyan
                    : row.containsMouse ? Theme.text : Theme.textMute
                text: row.failure !== "" ? I18n.tr("Failed · %1", row.failure)
                    : row.modelData.state === ConnectionState.Disconnecting ? I18n.tr("Disconnecting…")
                    : row.busy ? I18n.tr("Connecting…")
                    : row.modelData.connected ? (row.containsMouse ? I18n.tr("Disconnect") : I18n.trc("network", "Connected"))
                    : row.containsMouse ? I18n.tr("Connect") : Math.round(row.strength * 100) + "%"

                SequentialAnimation on opacity {
                    running: row.busy
                    loops: Animation.Infinite
                    alwaysRunToEnd: true
                    NumberAnimation { to: 0.4; duration: 450 }
                    NumberAnimation { to: 1; duration: 450 }
                }
            }
        }
    }
}
