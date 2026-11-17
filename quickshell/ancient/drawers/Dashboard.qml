import QtQuick
import Quickshell
import qs.services
import qs.theme
import qs.widgets

// Dashboard: time, calendar and system readings. The media player has its own
// drawer, under the now-playing module of the bar.
Drawer {
    id: root
    name: "dashboard"
    align: "center"
    contentWidth: 980
    contentHeight: 400

    onOpenChanged: SysStats.active = open

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    Row {
        anchors.fill: parent
        anchors.leftMargin: 4
        spacing: 28

        // ── Time + calendar ──────────────────────────
        Column {
            width: 330
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            Row {
                spacing: 8
                Label {
                    display: true
                    size: 60
                    font.weight: Font.Bold
                    color: Theme.text
                    text: Qt.formatDateTime(clock.date, Config.clock24h ? "HH:mm" : "hh:mm")
                }
                Label {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 13
                    display: true
                    size: 21
                    color: Theme.cyan
                    text: Qt.formatDateTime(clock.date, "ss")
                }
            }
            Label {
                width: parent.width
                size: 17
                color: Theme.amber
                font.letterSpacing: 1.2
                // i18n: Qt date format (QLocale::toString): weekday, month, day
                text: Config.locale.toString(clock.date, I18n.tr("dddd, MMMM d")).toUpperCase()
            }
            Calendar {
                width: parent.width
                today: clock.date
                cellHeight: 28
                textSize: 16
            }
        }

        Rectangle { width: 1; height: parent.height; color: Theme.line }

        // ── System ───────────────────────────────────
        Column {
            width: 210
            anchors.verticalCenter: parent.verticalCenter
            spacing: 18

            SectionTitle { width: parent.width; text: I18n.tr("System"); color: Theme.cyan }
            Repeater {
                model: [
                    // i18n: title of the uptime (how long since the system started)
                    ["schedule", I18n.tr("Up"), SysStats.uptime],
                    ["memory", I18n.tr("Memory"), SysStats.memUsedGb.toFixed(1) + " / " + SysStats.memTotalGb.toFixed(0) + " GB"],
                    ["hard_drive", I18n.tr("Disk %1", Config.tilde(Config.diskPath)), SysStats.diskLabel],
                    ["person", I18n.tr("User"), Quickshell.env("USER")]
                ]
                Row {
                    required property var modelData
                    spacing: 12
                    MIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        text: parent.modelData[0]
                        size: 26
                        color: Theme.cyan
                    }
                    Column {
                        spacing: -2
                        Label { text: parent.parent.modelData[1]; size: 13; color: Theme.textMute }
                        Label { text: parent.parent.modelData[2]; size: 18; color: Theme.textDim; width: 172 }
                    }
                }
            }
        }

        Rectangle { width: 1; height: parent.height; color: Theme.line }

        // ── Gauges ───────────────────────────────────
        Grid {
            anchors.verticalCenter: parent.verticalCenter
            columns: 2
            spacing: 18
            RingGauge { width: 132; height: 132; thickness: 7; value: SysStats.cpu; label: "CPU" }
            RingGauge { width: 132; height: 132; thickness: 7; value: SysStats.mem; label: I18n.tr("MEM") }
            RingGauge {
                width: 132; height: 132; thickness: 7
                value: Math.min(1, SysStats.temp / 100)
                valueText: Math.round(SysStats.temp) + "°"
                label: I18n.tr("TEMP")
            }
            RingGauge { width: 132; height: 132; thickness: 7; value: SysStats.disk; label: I18n.tr("DISK") }
        }
    }
}
