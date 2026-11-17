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
                text: "Atualizações"
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
                        text: Upgrades.checking ? "Verificando" : "Verificar"
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
                    text: "GERENCIADOR"
                }
                Label {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    display: true
                    size: 9
                    font.letterSpacing: 2
                    color: Theme.textMute
                    text: "PACOTES"
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
                                : row.result?.error ? "erro" : "—"
                        }
                    }
                }
            }
        }

        Label {
            width: parent.width
            size: 13
            color: Theme.textMute
            text: Upgrades.active ? "Upgrade em andamento"
                : Upgrades.checking ? "Consultando os gerenciadores…"
                : !Upgrades.checked ? "Ainda não verificado"
                : (Upgrades.total > 0 ? Upgrades.total + (Upgrades.total === 1 ? " pacote" : " pacotes") : "Tudo em dia")
                    + " · verificado às " + Qt.formatTime(Upgrades.lastCheck, "HH:mm")
        }
        Label {
            width: parent.width
            visible: Upgrades.lastExit !== 0 && !Upgrades.active
            size: 13
            color: Theme.alpha(Theme.dome, 0.85)
            text: "O último upgrade terminou com falhas · ~/upgrade.log"
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
                    text: "UPGRADE"
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
