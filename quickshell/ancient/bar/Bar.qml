import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.drawers
import qs.services
import qs.theme
import qs.widgets

// The top bar: a chamfered stone plate floating under the screen edge.
PanelWindow {
    id: root
    required property ShellScreen modelData
    screen: modelData

    WlrLayershell.namespace: "ancient-bar"
    WlrLayershell.layer: WlrLayer.Top
    anchors { top: true; left: true; right: true }
    implicitHeight: Theme.barHeight + Theme.gap
    exclusiveZone: Theme.barHeight + Theme.gap
    color: "transparent"

    readonly property string screenName: modelData.name

    ChamferPanel {
        id: plate
        x: Theme.gap
        y: Theme.gap
        width: parent.width - Theme.gap * 2
        height: Theme.barHeight
        cut: Theme.cut
        accentEdge: "bottom"
        accentLength: 0.22
        accentColor: ShellState.drawer !== "" && ShellState.drawerScreen === root.screenName ? Theme.cyan : Theme.alpha(Theme.cyan, 0.45)

        // ── Left ───────────────────────────────────────
        Row {
            id: left
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            BarButton {
                id: originBtn
                active: ShellState.launcherOpen
                onClicked: ShellState.toggleLauncher()
                OriginGlyph {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 16; height: 19
                    glow: originBtn.containsMouse || originBtn.active ? 0.9 : 0.45
                }
            }

            Separator {}

            Workspaces {
                anchors.verticalCenter: parent.verticalCenter
                screen: root.modelData
            }

            Separator {}

            ActiveWindow {
                anchors.verticalCenter: parent.verticalCenter
                maxWidth: plate.width / 2 - left.anchors.leftMargin - x - 150
            }
        }

        // ── Centre ─────────────────────────────────────
        Clock {
            anchors.centerIn: parent
            screenName: root.screenName
        }

        // ── Right ──────────────────────────────────────
        Row {
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Media {
                anchors.verticalCenter: parent.verticalCenter
                screenName: root.screenName
            }
            Tray {
                anchors.verticalCenter: parent.verticalCenter
                barWindow: root
            }
            Separator {}
            UpgradeIndicator {
                anchors.verticalCenter: parent.verticalCenter
                screenName: root.screenName
            }
            Status {
                anchors.verticalCenter: parent.verticalCenter
                screenName: root.screenName
            }
            BarButton {
                id: powerBtn
                anchors.verticalCenter: parent.verticalCenter
                active: ShellState.drawer === "session" && ShellState.drawerScreen === root.screenName
                activeColor: Theme.dome
                onClicked: ShellState.toggleDrawer("session", root.screenName)
                MIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "power_settings_new"
                    size: 18
                    color: powerBtn.containsMouse || powerBtn.active ? Theme.dome : Theme.textDim
                }
            }
        }
    }

    IdleInhibitor {
        window: root
        enabled: ShellState.caffeine
    }

    Dashboard { modelData: root.modelData; barWindow: root }
    MediaPanel { modelData: root.modelData; barWindow: root }
    ControlCenter { modelData: root.modelData; barWindow: root }
    SessionMenu { modelData: root.modelData; barWindow: root }
    UpgradesPanel { modelData: root.modelData; barWindow: root }
    UpgradeConsole { modelData: root.modelData }

    component Separator: Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 1
        height: Theme.barHeight - 18
        color: Theme.line
    }
}
