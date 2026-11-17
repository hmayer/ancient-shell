import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.services
import qs.theme
import qs.widgets

// Weather on the desktop: a console plate under the windows that can be
// dragged anywhere on its screen. It shows the weather as a small animation,
// the temperature, how it feels and the wind; a click unrolls the next 6
// hours. The gear picks the city (typed in, never guessed) and the screen.
//
// The window covers the whole screen but only takes input on the plate, so
// the plate moves inside it while dragging: moving a small layer surface
// instead lags behind the pointer.
PanelWindow {
    id: root

    // Made for one screen only (shell.qml); moving to another makes a new
    // window there, since changing a window's screen crashes Quickshell 0.3
    required property ShellScreen modelData
    screen: modelData
    visible: Weather.saved.shown
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "ancient-weather"
    WlrLayershell.keyboardFocus: editing ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    mask: Region { x: card.x; y: card.y; width: card.width; height: card.height }

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
    // Tiled windows hide the desktop: then nobody sees the animation
    readonly property bool covered: (monitor?.activeWorkspace?.toplevels?.values ?? [])
        .some(t => t.lastIpcObject?.floating !== true)

    readonly property bool expanded: Weather.expanded
    property bool editing: !Weather.hasPlace
    readonly property var now: Weather.current

    // Where the plate sits: saved, or top right under the bar the first time
    readonly property real minY: Theme.barHeight + Theme.gap
    function clampX(x) { return Math.max(0, Math.min(width - card.width, x)); }
    function clampY(y) { return Math.max(minY, Math.min(height - card.height, y)); }
    readonly property real savedX: Weather.saved.x < 0 ? width - card.width - 32 : Weather.saved.x
    readonly property real savedY: Weather.saved.y < 0 ? minY + 24 : Weather.saved.y

    function round(v) { return v === undefined || v === null ? "—" : Math.round(v) + "°"; }

    ChamferPanel {
        id: card
        width: 340
        height: body.implicitHeight + 2 * Theme.pad
        x: mover.dragging ? mover.dragX : root.clampX(root.savedX)
        y: mover.dragging ? mover.dragY : root.clampY(root.savedY)
        fillColor: Theme.panel
        borderColor: mover.containsMouse || mover.dragging ? Theme.lineBright : Theme.line
        accentEdge: "bottom"
        accentLength: 0.4
        accentColor: Theme.alpha(Theme.amber, 0.6)

        Behavior on height { NumberAnimation { duration: Theme.animMid; easing.type: Easing.OutCubic } }

        // Drag anywhere on the plate; a click without moving shows the hours
        MouseArea {
            id: mover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: dragging ? Qt.ClosedHandCursor : Qt.PointingHandCursor
            property bool dragging: false
            property real dragX: 0
            property real dragY: 0
            property point grab
            onPressed: mouse => {
                grab = Qt.point(mouse.x, mouse.y);
                dragX = card.x;
                dragY = card.y;
            }
            onPositionChanged: mouse => {
                if (!pressed) return;
                const dx = mouse.x - grab.x, dy = mouse.y - grab.y;
                if (!dragging && Math.hypot(dx, dy) < 5) return;
                dragging = true;
                // mouse is relative to the plate, which follows it
                dragX = root.clampX(dragX + dx);
                dragY = root.clampY(dragY + dy);
            }
            onReleased: {
                if (dragging) {
                    Weather.saved.x = dragX;
                    Weather.saved.y = dragY;
                    dragging = false;
                } else if (!root.editing && Weather.hasPlace) {
                    Weather.expanded = !Weather.expanded;
                }
            }
        }

        Column {
            id: body
            x: Theme.pad
            y: Theme.pad
            width: parent.width - 2 * Theme.pad
            spacing: 10

            // ── Now ──────────────────────────────────
            Item {
                visible: !root.editing
                width: parent.width
                height: 96

                WeatherScene {
                    id: scene
                    width: 120; height: 96
                    kind: root.now?.kind ?? "cloudy"
                    day: root.now?.day ?? true
                    animate: root.visible && !root.covered && root.now !== null
                    opacity: root.now ? 1 : 0.35
                }
                Column {
                    anchors.left: scene.right
                    anchors.leftMargin: 10
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 0
                    Label {
                        display: true
                        size: 40
                        font.weight: Font.Bold
                        color: Theme.text
                        text: root.round(root.now?.temp)
                    }
                    Label {
                        size: 14
                        color: Theme.textDim
                        text: "Sensação " + root.round(root.now?.feels)
                    }
                    Label {
                        width: parent.width
                        size: 14
                        color: Theme.cyan
                        text: root.now ? Weather.describe(root.now.code)
                            : Weather.status === "error" ? "Sem conexão" : "Consultando…"
                    }
                }
                IconButton {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.topMargin: -4
                    icon: "settings"
                    onClicked: root.editing = true
                }
            }

            Item {
                visible: !root.editing
                width: parent.width
                height: 20
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 5; height: 5; rotation: 45
                        color: Theme.amber
                    }
                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.min(implicitWidth, body.width - windNow.width - 24)
                        display: true
                        size: 10
                        font.letterSpacing: 1.8
                        color: Theme.amber
                        text: Weather.placeLabel.toUpperCase()
                    }
                }
                Wind {
                    id: windNow
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.now !== null
                    dir: root.now?.windDir ?? 0
                    speed: root.now?.windSpeed ?? 0
                    size: 14
                }
            }

            // ── Next 6 hours ─────────────────────────
            Column {
                visible: root.expanded && !root.editing
                width: parent.width
                spacing: 6

                Rectangle { width: parent.width; height: 1; color: Theme.line }

                Grid {
                    id: table
                    width: parent.width
                    columns: 6
                    rowSpacing: 5
                    columnSpacing: 0
                    readonly property var widths: [50, 34, 46, 50, 52, width - 232]
                    readonly property var heads: ["Hora", "", "Temp", "Sens.", "Chuva", "Vento"]

                    Repeater {
                        model: 6
                        Label {
                            required property int index
                            width: table.widths[index]
                            size: 11
                            font.letterSpacing: 1
                            color: Theme.textMute
                            horizontalAlignment: index === 0 || index === 5 ? Text.AlignLeft : Text.AlignHCenter
                            text: table.heads[index].toUpperCase()
                        }
                    }
                    Repeater {
                        model: Weather.hours
                        delegate: Repeater {
                            id: hourRow
                            required property var modelData
                            readonly property var hour: modelData
                            model: 6
                            Item {
                                required property int index
                                width: table.widths[index]
                                height: 22
                                Label {
                                    visible: index === 0
                                    anchors.verticalCenter: parent.verticalCenter
                                    size: 14
                                    color: Theme.textDim
                                    text: hourRow.hour.time
                                }
                                MIcon {
                                    visible: index === 1
                                    anchors.centerIn: parent
                                    size: 18
                                    filled: true
                                    color: ["clear", "partly"].includes(hourRow.hour.kind) && hourRow.hour.day ? Theme.amber : Theme.textDim
                                    text: Weather.icon(hourRow.hour.kind, hourRow.hour.day)
                                }
                                Label {
                                    visible: index === 2 || index === 3 || index === 4
                                    anchors.centerIn: parent
                                    size: 14
                                    color: index === 2 ? Theme.text : index === 4 && hourRow.hour.rain >= 50 ? Theme.cyan : Theme.textDim
                                    text: index === 2 ? root.round(hourRow.hour.temp)
                                        : index === 3 ? root.round(hourRow.hour.feels)
                                        : hourRow.hour.rain + "%"
                                }
                                Wind {
                                    visible: index === 5
                                    anchors.verticalCenter: parent.verticalCenter
                                    dir: hourRow.hour.windDir
                                    speed: hourRow.hour.windSpeed
                                    size: 13
                                }
                            }
                        }
                    }
                }

                Label {
                    width: parent.width
                    horizontalAlignment: Text.AlignRight
                    size: 11
                    color: Theme.textMute
                    text: (Weather.status === "error" ? "Sem conexão · dados de " : "Open-Meteo · ")
                        + Qt.formatTime(Weather.updated, "HH:mm")
                }
            }

            // ── City and screen ──────────────────────
            Column {
                visible: root.editing
                width: parent.width
                spacing: 10

                Item {
                    width: parent.width
                    height: 22
                    SectionTitle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 34
                        text: "Cidade"
                    }
                    IconButton {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        visible: Weather.hasPlace
                        icon: "close"
                        onClicked: root.editing = false
                    }
                }

                Item {
                    width: parent.width
                    height: 36
                    ChamferPanel {
                        anchors.fill: parent
                        cut: Theme.cutSmall
                        fillColor: Theme.stone2
                        borderColor: field.activeFocus ? Theme.alpha(Theme.cyan, 0.7) : Theme.line
                    }
                    MIcon {
                        id: searchIcon
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: "search"
                        size: 18
                        color: Theme.textDim
                    }
                    TextInput {
                        id: field
                        anchors.left: searchIcon.right
                        anchors.leftMargin: 8
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: Theme.fontUi
                        font.pixelSize: 16
                        color: Theme.text
                        selectionColor: Theme.cyanMid
                        clip: true
                        onAccepted: Weather.search(text)
                        Keys.onEscapePressed: if (Weather.hasPlace) root.editing = false
                        Label {
                            visible: field.text === ""
                            anchors.verticalCenter: parent.verticalCenter
                            size: 15
                            color: Theme.textMute
                            text: "Digite a cidade e tecle Enter"
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.IBeamCursor
                        onPressed: mouse => { field.forceActiveFocus(); mouse.accepted = false; }
                    }
                }

                Label {
                    visible: text !== ""
                    width: parent.width
                    size: 13
                    color: Theme.textMute
                    text: ({ loading: "Procurando…", none: "Nenhuma cidade com esse nome", error: "Sem conexão com o Open-Meteo" })[Weather.searchStatus] ?? ""
                }

                Column {
                    width: parent.width
                    spacing: 4
                    Repeater {
                        model: Weather.results
                        MouseArea {
                            id: hit
                            required property var modelData
                            width: parent.width
                            height: 40
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Weather.choose(modelData);
                                field.text = "";
                                root.editing = false;
                            }
                            ChamferPanel {
                                anchors.fill: parent
                                visible: hit.containsMouse
                                cut: Theme.cutSmall
                                fillColor: Theme.stone3
                                borderColor: Theme.lineBright
                            }
                            Column {
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: -2
                                Label { width: parent.width; size: 15; color: Theme.text; text: hit.modelData.name }
                                Label {
                                    width: parent.width
                                    size: 12
                                    color: Theme.textMute
                                    text: [hit.modelData.region, hit.modelData.country].filter(s => s).join(" · ")
                                }
                            }
                        }
                    }
                }

                // The screen the plate lives on
                Row {
                    visible: Quickshell.screens.length > 1
                    spacing: 6
                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        size: 13
                        color: Theme.textMute
                        text: "Monitor"
                    }
                    Repeater {
                        model: Quickshell.screens
                        MouseArea {
                            id: scr
                            required property ShellScreen modelData
                            readonly property bool current: modelData === root.screen
                            width: scrLabel.implicitWidth + 16
                            height: 26
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (current) return;
                                Weather.saved.screen = modelData.name;
                                Weather.saved.x = -1;
                                Weather.saved.y = -1;
                            }
                            ChamferPanel {
                                anchors.fill: parent
                                cut: 4
                                fillColor: scr.current ? Theme.alpha(Theme.cyan, 0.18) : scr.containsMouse ? Theme.stone3 : Theme.stone2
                                borderColor: scr.current ? Theme.alpha(Theme.cyan, 0.7) : Theme.line
                            }
                            Label {
                                id: scrLabel
                                anchors.centerIn: parent
                                size: 12
                                color: scr.current ? Theme.text : Theme.textDim
                                text: scr.modelData.name
                            }
                        }
                    }
                }
            }
        }
    }

    onEditingChanged: if (editing) field.forceActiveFocus()
    Component.onCompleted: if (editing) field.forceActiveFocus()

    // Wind: an arrow along the flow, where it comes from and how fast
    component Wind: Row {
        property real dir: 0
        property real speed: 0
        property int size: 14
        spacing: 4
        MIcon {
            anchors.verticalCenter: parent.verticalCenter
            text: "navigation"
            filled: true
            size: parent.size + 2
            color: Theme.cyan
            rotation: parent.dir + 180
        }
        Label {
            anchors.verticalCenter: parent.verticalCenter
            size: parent.size
            color: Theme.textDim
            text: Weather.compass(parent.dir) + " " + Math.round(parent.speed) + " km/h"
        }
    }

    component IconButton: MouseArea {
        id: btn
        property string icon: ""
        width: 26; height: 26
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        MIcon {
            anchors.centerIn: parent
            text: btn.icon
            size: 18
            color: btn.containsMouse ? Theme.cyanBright : Theme.textMute
        }
    }
}
