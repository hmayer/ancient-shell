import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import qs.launcher
import qs.theme
import qs.widgets

// One screen of the boot splash: the gate dialing over dark stone.
// `ctl` is the splash root (../splash.qml), which owns the dialing state.
PanelWindow {
    id: win

    required property ShellScreen modelData
    property var ctl

    screen: modelData
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "ancient-splash"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }

    readonly property real gateSize: Math.round(Math.min(height * 0.52, width * 0.42, 540))
    readonly property real horizonSize: (gateSize / 2 - 34 - 50) * 2   // as drawn by GateRing

    property bool shown: false
    Component.onCompleted: shown = true

    MouseArea {
        anchors.fill: parent
        onClicked: win.ctl.leave()
    }

    // ── Stone, with a faint glow behind the gate ─────────────
    Item {
        anchors.fill: parent
        opacity: win.ctl.leaving ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: win.ctl.leaveDuration; easing.type: Easing.InCubic } }

        Rectangle {
            anchors.fill: parent
            color: Theme.void_
        }
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeWidth: 0
                strokeColor: "transparent"
                fillGradient: RadialGradient {
                    centerX: win.width / 2; centerY: gate.y + gate.height / 2
                    centerRadius: win.gateSize * 1.1
                    focalX: centerX; focalY: centerY
                    GradientStop { position: 0.0; color: Theme.alpha(Theme.cyanDeep, 0.55) }
                    GradientStop { position: 1.0; color: "transparent" }
                }
                PathLine { x: win.width; y: 0 }
                PathLine { x: win.width; y: win.height }
                PathLine { x: 0; y: win.height }
                PathLine { x: 0; y: 0 }
            }
        }
        // Flash when the wormhole bursts open
        Rectangle {
            id: flash
            anchors.fill: parent
            color: Theme.cyanBright
            opacity: 0
        }
    }

    // ── Console: dives into the horizon when leaving ─────────
    Item {
        id: stage
        anchors.fill: parent
        transformOrigin: Item.TopLeft
        opacity: !win.shown ? 0 : win.ctl.leaving ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: win.ctl.leaving ? win.ctl.leaveDuration : 400; easing.type: Easing.InOutQuad } }

        // Zoom about the centre of the gate
        transform: Scale {
            origin.x: gate.x + gate.width / 2
            origin.y: gate.y + gate.height / 2
            xScale: win.ctl.leaving ? 3.4 : 1
            yScale: xScale
            Behavior on xScale { NumberAnimation { duration: win.ctl.leaveDuration; easing.type: Easing.InCubic } }
        }

        // Header
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            y: gate.y - 58
            spacing: 12
            OriginGlyph { width: 16; height: 20; glow: 0.7; anchors.verticalCenter: parent.verticalCenter }
            Label {
                anchors.verticalCenter: parent.verticalCenter
                display: true
                size: 13
                font.letterSpacing: 3.2
                color: Theme.cyan
                text: "ANCIENT SHELL"
            }
            Label {
                anchors.verticalCenter: parent.verticalCenter
                size: 13
                color: Theme.textMute
                text: "SGC · " + (Quickshell.env("HOSTNAME") || "TERRA").toUpperCase()
            }
        }

        // Data streams on both sides of the gate
        Repeater {
            model: win.width > win.gateSize + 520 ? 2 : 0
            BinaryStream {
                required property int index
                width: 170
                height: win.gateSize * 0.7
                x: index === 0 ? gate.x - width - 60 : gate.x + gate.width + 60
                y: gate.y + (gate.height - height) / 2
                opacity: 0.55
                running: !win.ctl.leaving
                lines: Math.floor(height / 13)
                speed: win.ctl.locked ? 6 : win.ctl.encoded > 0 ? 2.5 : 1
            }
        }

        GateRing {
            id: gate
            x: (win.width - width) / 2
            y: (win.height - height) / 2 - win.gateSize * 0.08
            width: win.gateSize
            height: win.gateSize
            openDuration: win.ctl.openDuration
            encoded: win.ctl.encoded
            locked: win.ctl.locked
            active: true
            spin: win.ctl.spin
        }

        // Kawoosh: the unstable vortex bursts out of the horizon and falls back
        Shape {
            id: kawoosh
            width: win.horizonSize
            height: width
            x: gate.x + (gate.width - width) / 2
            y: gate.y + (gate.height - height) / 2
            opacity: 0
            scale: 0.2
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeWidth: 0
                strokeColor: "transparent"
                fillGradient: RadialGradient {
                    centerX: kawoosh.width / 2; centerY: kawoosh.height / 2
                    centerRadius: kawoosh.width / 2
                    focalX: centerX; focalY: centerY
                    GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.95) }
                    GradientStop { position: 0.35; color: Theme.alpha(Theme.cyanBright, 0.85) }
                    GradientStop { position: 0.75; color: Theme.alpha(Theme.cyan, 0.45) }
                    GradientStop { position: 1.0; color: "transparent" }
                }
                PathAngleArc {
                    centerX: kawoosh.width / 2; centerY: kawoosh.height / 2
                    radiusX: kawoosh.width / 2; radiusY: kawoosh.height / 2
                    startAngle: 0; sweepAngle: 360
                }
            }
        }

        SequentialAnimation {
            id: burst
            PauseAnimation { duration: 140 }
            ParallelAnimation {
                NumberAnimation { target: kawoosh; property: "scale"; from: 0.2; to: 1.6; duration: 380; easing.type: Easing.OutQuad }
                NumberAnimation { target: kawoosh; property: "opacity"; from: 0; to: 1; duration: 160 }
                SequentialAnimation {
                    NumberAnimation { target: flash; property: "opacity"; to: 0.14; duration: 140 }
                    NumberAnimation { target: flash; property: "opacity"; to: 0; duration: 520; easing.type: Easing.OutQuad }
                }
            }
            ParallelAnimation {
                NumberAnimation { target: kawoosh; property: "scale"; to: 0.94; duration: 620; easing.type: Easing.InOutQuad }
                NumberAnimation { target: kawoosh; property: "opacity"; to: 0; duration: 760; easing.type: Easing.InQuad }
            }
        }
        Connections {
            target: win.ctl
            function onLockedChanged() { if (win.ctl.locked) burst.restart(); }
        }

        // Status readout
        ChamferPanel {
            id: status
            anchors.horizontalCenter: parent.horizontalCenter
            y: gate.y + gate.height + 22
            width: Math.min(720, win.width - 80)
            height: 52
            cut: 8
            fillColor: Theme.alpha(win.ctl.status.color, 0.07)
            borderColor: Theme.alpha(win.ctl.status.color, 0.65)

            Label {
                anchors.centerIn: parent
                display: true
                size: 20
                font.weight: Font.Bold
                font.letterSpacing: 5
                color: win.ctl.status.color
                text: win.ctl.status.text
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: win.ctl.status.color
                    shadowBlur: 0.6
                    shadowHorizontalOffset: 0
                    shadowVerticalOffset: 0
                }
                // Fast blink while the 7th chevron locks, slow pulse while waiting
                SequentialAnimation on opacity {
                    running: win.ctl.locked && !win.ctl.opened
                        || win.ctl.encoded === 6 && !win.ctl.shellReady && !win.ctl.failed
                    loops: Animation.Infinite
                    alwaysRunToEnd: true
                    NumberAnimation { to: 0.35; duration: win.ctl.locked ? 110 : 650 }
                    NumberAnimation { to: 1; duration: win.ctl.locked ? 110 : 650 }
                }
            }
        }

        // Address: one cell per chevron, the 7th is the point of origin
        Row {
            id: cells
            anchors.horizontalCenter: parent.horizontalCenter
            y: status.y + status.height + 14
            spacing: 5
            Repeater {
                model: 7
                Rectangle {
                    id: cell
                    required property int index
                    readonly property bool last: index === 6
                    readonly property bool lit: last ? win.ctl.locked : index < win.ctl.encoded
                    readonly property color tint: last ? Theme.amber : Theme.cyan
                    width: 30; height: 30
                    color: lit ? Theme.alpha(tint, 0.16) : Theme.stone1
                    border.width: 1
                    border.color: lit ? tint : Theme.line
                    Behavior on color { ColorAnimation { duration: Theme.animMid } }

                    Label {
                        anchors.centerIn: parent
                        visible: !cell.last
                        display: true
                        size: 12
                        color: cell.lit ? Theme.cyanBright : Theme.textMute
                        text: cell.index + 1
                    }
                    OriginGlyph {
                        anchors.centerIn: parent
                        visible: cell.last
                        width: 13; height: 16
                        glow: cell.lit ? 0.7 : 0
                        color: cell.lit ? Theme.amberBright : Theme.textMute
                    }
                }
            }
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            y: cells.y + cells.height + 14
            display: true
            size: 10
            font.letterSpacing: 2.4
            color: win.ctl.opened ? Theme.cyanBright : Theme.textMute
            text: (win.ctl.opened ? "DESTINO: " + win.ctl.destination.name.toUpperCase()
                    : win.ctl.shellReady ? "SHELL CARREGADO" : "CARREGANDO O SHELL")
                + "  ·  T+" + String(Math.floor(win.ctl.elapsed / 60)).padStart(2, "0")
                + ":" + String(win.ctl.elapsed % 60).padStart(2, "0")
        }
    }
}
