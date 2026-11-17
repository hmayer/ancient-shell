import QtQuick
import QtQuick.Effects
import Quickshell
import qs.services
import qs.theme
import qs.widgets

// Session menu laid out like a dialing device: a row of glyph keys
// and, in the middle, the red dome that commits the choice.
Drawer {
    id: root
    name: "session"
    align: "right"
    contentWidth: 470
    contentHeight: 200

    property int selected: -1

    readonly property var actions: [
        { icon: "lock", label: "Bloquear", run: () => Hypr.exec(Config.lockCommand) },
        { icon: "bedtime", label: "Suspender", run: () => Hypr.exec("systemctl suspend") },
        { icon: "logout", label: "Sair", run: () => Hypr.exit() },
        { icon: "restart_alt", label: "Reiniciar", run: () => Hypr.exec("systemctl reboot") },
        { icon: "power_settings_new", label: "Desligar", run: () => Hypr.exec("systemctl poweroff") }
    ]

    function commit() {
        if (selected < 0) return;
        const a = actions[selected];
        ShellState.closeAll();
        selected = -1;
        a.run();
    }

    onOpenChanged: if (!open) selected = -1

    Item {
        anchors.fill: parent
        focus: root.open
        Keys.onLeftPressed: root.selected = root.selected <= 0 ? root.actions.length - 1 : root.selected - 1
        Keys.onRightPressed: root.selected = (root.selected + 1) % root.actions.length
        Keys.onReturnPressed: root.commit()
        Keys.onEnterPressed: root.commit()
        Keys.onEscapePressed: ShellState.closeDrawer()

        SectionTitle {
            id: title
            width: parent.width
            text: root.selected >= 0 ? root.actions[root.selected].label + " — confirme no domo" : "Sessão"
            color: root.selected >= 0 ? Theme.dome : Theme.amber
        }

        Row {
            anchors.top: title.bottom
            anchors.topMargin: 18
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10

            Repeater {
                model: root.actions
                MouseArea {
                    id: key
                    required property var modelData
                    required property int index
                    readonly property bool sel: root.selected === index
                    width: 76; height: 82
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.selected = sel ? -1 : index
                    onDoubleClicked: { root.selected = index; root.commit(); }

                    ChamferPanel {
                        anchors.fill: parent
                        cut: 12
                        fillColor: key.sel ? Theme.alpha(Theme.amber, 0.22) : key.containsMouse ? Theme.stone3 : Theme.stone2
                        borderColor: key.sel ? Theme.amber : key.containsMouse ? Theme.lineBright : Theme.line
                        Behavior on fillColor { ColorAnimation { duration: Theme.animFast } }
                    }
                    MIcon {
                        id: ic
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 16
                        text: key.modelData.icon
                        size: 28
                        filled: key.sel
                        color: key.sel ? Theme.amberBright : key.containsMouse ? Theme.text : Theme.textDim
                        layer.enabled: key.sel
                        layer.effect: MultiEffect {
                            shadowEnabled: true; shadowColor: Theme.amber; shadowBlur: 0.7
                            shadowHorizontalOffset: 0; shadowVerticalOffset: 0
                        }
                    }
                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 10
                        size: 13
                        color: key.sel ? Theme.amberBright : Theme.textDim
                        text: key.modelData.label
                    }
                }
            }
        }

        // The dome
        MouseArea {
            id: dome
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            width: 150; height: 34
            enabled: root.selected >= 0
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: root.commit()

            Rectangle {
                id: domeShape
                anchors.fill: parent
                radius: height / 2
                color: dome.enabled ? (dome.containsMouse ? "#ff6a4f" : Theme.dome) : Theme.stone2
                border.color: dome.enabled ? "#ffb39f" : Theme.line
                border.width: 1
                Behavior on color { ColorAnimation { duration: Theme.animMid } }
                layer.enabled: dome.enabled
                layer.effect: MultiEffect {
                    shadowEnabled: true; shadowColor: Theme.dome; shadowBlur: 1.0
                    shadowHorizontalOffset: 0; shadowVerticalOffset: 0
                }
            }
            Label {
                anchors.centerIn: parent
                display: true
                size: 11
                font.letterSpacing: 2.5
                color: dome.enabled ? "#1a0905" : Theme.textMute
                text: "CONFIRMAR"
            }
        }
    }
}
