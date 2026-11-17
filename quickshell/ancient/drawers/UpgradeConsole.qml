import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.theme
import qs.widgets

// The upgrade's output, on a plate that rises from the bottom edge of the
// screen the way the drawers unroll from the bar: 90% of the screen wide and
// a third of it tall. It closes by itself when the run ends. Esc or "Ocultar"
// hide it while the run goes on; the bar icon brings it back.
PanelWindow {
    id: root

    required property ShellScreen modelData

    readonly property bool open: Upgrades.consoleOpen && Upgrades.consoleScreen === modelData.name
    readonly property int contentHeight: Math.round(modelData.height * 0.33)
    property real progress: open ? 1 : 0
    Behavior on progress {
        NumberAnimation { duration: Theme.animSlow; easing.type: root.open ? Easing.OutExpo : Easing.InCubic }
    }

    screen: modelData
    visible: progress > 0.001
    color: "transparent"

    WlrLayershell.namespace: "ancient-upgrade"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    exclusiveZone: 0
    anchors.bottom: true
    implicitWidth: Math.round(modelData.width * 0.9)
    implicitHeight: contentHeight

    FocusScope {
        id: clipper
        anchors.bottom: parent.bottom
        width: parent.width
        height: Math.max(1, root.contentHeight * root.progress)
        clip: true
        focus: root.open
        Keys.onEscapePressed: Upgrades.consoleOpen = false

        ChamferPanel {
            y: root.contentHeight * (1 - root.progress) * 0.35
            width: parent.width
            height: root.contentHeight
            fillColor: Theme.panel
            cutBottomLeft: false
            cutBottomRight: false
            accentEdge: "top"
            accentLength: 0.5
            accentColor: Theme.alpha(Theme.amber, 0.7)

            Item {
                anchors.fill: parent
                anchors.margins: Theme.pad + 2
                anchors.bottomMargin: Theme.pad
                opacity: Math.max(0, root.progress * 1.6 - 0.6)

                Item {
                    id: header
                    width: parent.width
                    height: 22

                    SectionTitle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - tools.width - 16
                        text: "Upgrade" + (Upgrades.runNames.length > 0 ? " · " + Upgrades.runNames.join(", ") : "")
                    }
                    Row {
                        id: tools
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 14

                        MIcon {
                            id: spin
                            anchors.verticalCenter: parent.verticalCenter
                            text: "sync"
                            size: 17
                            color: Theme.amber
                            NumberAnimation on rotation {
                                running: Upgrades.active && root.visible
                                from: 0
                                to: -360
                                duration: 1600
                                loops: Animation.Infinite
                            }
                        }
                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            size: 13
                            color: Theme.textMute
                            text: "~/upgrade.log"
                        }
                        MouseArea {
                            id: hide
                            anchors.verticalCenter: parent.verticalCenter
                            width: hideLabel.implicitWidth + 4
                            height: 22
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Upgrades.consoleOpen = false
                            Label {
                                id: hideLabel
                                anchors.centerIn: parent
                                size: 13
                                color: hide.containsMouse ? Theme.text : Theme.textDim
                                text: "Ocultar"
                            }
                        }
                    }
                }

                ListView {
                    id: log
                    anchors.top: header.bottom
                    anchors.topMargin: 10
                    anchors.bottom: parent.bottom
                    width: parent.width
                    clip: true
                    model: Upgrades.output
                    boundsBehavior: Flickable.StopAtBounds

                    // Follow new lines, unless scrolled up to read
                    property bool stick: true
                    onMovementEnded: stick = atYEnd
                    onCountChanged: {
                        if (count === 0) stick = true;   // a new run
                        else if (stick) Qt.callLater(positionViewAtEnd);
                    }

                    delegate: Text {
                        required property string line
                        width: ListView.view.width
                        text: line
                        textFormat: Text.PlainText
                        wrapMode: Text.WrapAnywhere
                        font.family: Theme.fontMono
                        font.pixelSize: 12
                        renderType: Text.NativeRendering
                        // topgrade's step separators and the run's header and footer
                        color: /^(――|━━━━)/.test(line) ? Theme.cyan : Theme.textDim
                    }
                }
            }
        }

        // The seam where the plate leaves the screen edge
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width * (0.4 + 0.6 * root.progress)
            height: 2
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.5; color: Theme.cyan }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }
    }
}
