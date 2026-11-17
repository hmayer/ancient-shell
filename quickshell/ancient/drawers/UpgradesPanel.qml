import QtQuick
import QtQuick.Effects
import qs.services
import qs.theme
import qs.widgets

// Package upgrades, unrolled under the upgrades icon of the bar: how many
// packages each package manager has to upgrade, and the key that upgrades
// them with topgrade.
Drawer {
    id: root
    name: "upgrades"
    align: "right"
    contentWidth: 360
    contentHeight: body.implicitHeight + 2 * (Theme.pad + 2)

    // Opened before the first scheduled check
    onOpenChanged: if (open && !Upgrades.checked) Upgrades.check()

    Column {
        id: body
        width: parent.width
        spacing: 12

        Item {
            width: parent.width
            height: 22
            SectionTitle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - refresh.width - 12
                text: I18n.tr("Upgrades")
            }
            MouseArea {
                id: refresh
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: refreshRow.width + 12
                height: 24
                enabled: !Upgrades.checking && !Upgrades.active
                hoverEnabled: true
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: Upgrades.check()
                Row {
                    id: refreshRow
                    anchors.centerIn: parent
                    spacing: 4
                    Spinner {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "refresh"
                        size: 18
                        spinning: Upgrades.checking
                        color: refresh.containsMouse ? Theme.amberBright : Theme.amber
                    }
                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Upgrades.checking ? I18n.tr("Checking") : I18n.tr("Check")
                        size: 13
                        color: refresh.containsMouse ? Theme.text : Theme.textDim
                    }
                }
            }
        }

        // The table: no rules, no borders
        Column {
            width: parent.width

            Item {
                width: parent.width
                height: 20
                Label {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    display: true
                    size: 9
                    font.letterSpacing: 2
                    color: Theme.textMute
                    text: I18n.tr("MANAGER")
                }
                Label {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    display: true
                    size: 9
                    font.letterSpacing: 2
                    color: Theme.textMute
                    text: I18n.tr("PACKAGES")
                }
            }

            Repeater {
                // Fixed rows, so a check does not rebuild them as answers come in
                model: Upgrades.managers

                Item {
                    id: row
                    required property var modelData
                    readonly property var result: Upgrades.results[modelData.id] ?? null
                    visible: !(result?.missing ?? false)   // not installed
                    readonly property bool waiting: Upgrades.checking && !(Upgrades.fresh[modelData.id] ?? false)
                    readonly property int count: result?.count ?? 0
                    readonly property string detail: result?.error ?? result?.note ?? ""

                    width: parent.width
                    height: !visible ? 0 : detail !== "" ? 40 : 28

                    Column {
                        anchors.left: parent.left
                        anchors.right: cell.left
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: -2
                        Label {
                            width: parent.width
                            size: 15
                            color: row.count > 0 ? Theme.text : Theme.textDim
                            text: row.modelData.name
                        }
                        Label {
                            width: parent.width
                            visible: row.detail !== ""
                            size: 12
                            color: row.result?.error ? Theme.alpha(Theme.dome, 0.85) : Theme.textMute
                            text: row.detail
                        }
                    }

                    Item {
                        id: cell
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 60
                        height: 20
                        Spinner {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            visible: row.waiting
                            spinning: visible
                            text: "progress_activity"
                            size: 15
                            color: Theme.textMute
                        }
                        Label {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            visible: !row.waiting
                            size: 16
                            color: row.count > 0 ? Theme.yellow : row.result?.error ? Theme.dome : Theme.textMute
                            text: row.result?.count !== undefined ? String(row.result.count)
                                : row.result?.error ? I18n.tr("error") : "—"
                        }
                    }
                }
            }
        }

        Label {
            width: parent.width
            size: 13
            color: Theme.textMute
            text: Upgrades.active ? I18n.tr("Upgrade in progress")
                : Upgrades.checking ? I18n.tr("Querying the managers…")
                : !Upgrades.checked ? I18n.tr("Not checked yet")
                : Upgrades.total > 0 ? I18n.trn("%1 package · checked at %2", "%1 packages · checked at %2", Upgrades.total, Qt.formatTime(Upgrades.lastCheck, "HH:mm"))
                : I18n.tr("All up to date · checked at %1", Qt.formatTime(Upgrades.lastCheck, "HH:mm"))
        }
        Label {
            width: parent.width
            visible: Upgrades.lastExit !== 0 && !Upgrades.active
            size: 13
            color: Theme.alpha(Theme.dome, 0.85)
            text: I18n.tr("The last upgrade ended with failures · %1", Config.tilde(Config.upgradesLog))
        }

        // The key: amber, like the Atlantis consoles
        MouseArea {
            id: go
            anchors.horizontalCenter: parent.horizontalCenter
            visible: Upgrades.total > 0 && !Upgrades.active
            width: 170
            height: 36
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Upgrades.upgrade(root.modelData.name)

            ChamferPanel {
                anchors.fill: parent
                cut: Theme.cutSmall
                fillColor: go.pressed ? Theme.amber : go.containsMouse ? Theme.amberBright : Theme.amber
                borderColor: Theme.amberBright
                Behavior on fillColor { ColorAnimation { duration: Theme.animFast } }
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true; shadowColor: Theme.amber; shadowBlur: 0.8
                    shadowHorizontalOffset: 0; shadowVerticalOffset: 0
                }
            }
            Row {
                anchors.centerIn: parent
                spacing: 8
                MIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "download"
                    size: 18
                    color: Theme.amberDeep
                }
                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    display: true
                    size: 12
                    font.letterSpacing: 2.5
                    color: Theme.amberDeep
                    text: I18n.tr("UPGRADE")
                }
            }
        }
    }

    component Spinner: MIcon {
        id: spinner
        property bool spinning: false
        NumberAnimation on rotation {
            running: spinner.spinning
            from: 0
            to: 360
            duration: 1000
            loops: Animation.Infinite
            onRunningChanged: if (!running) spinner.rotation = 0
        }
    }
}
