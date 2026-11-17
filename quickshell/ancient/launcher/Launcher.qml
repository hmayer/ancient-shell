import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import qs.services
import qs.theme
import qs.widgets

// Application launcher styled as the SGC dialing computer.
// Typing dials: each character encodes a chevron and spins the glyph track.
// Enter locks the seventh chevron, opens the wormhole and launches.
// A query starting with ">" dials a shell command instead.
PanelWindow {
    id: root

    readonly property bool open: ShellState.launcherOpen
    property real progress: open ? 1 : 0
    Behavior on progress { NumberAnimation { duration: Theme.animMid; easing.type: Easing.OutCubic } }

    screen: Quickshell.screens.find(s => s.name === ShellState.overlayScreen) ?? Quickshell.screens[0]
    visible: progress > 0.001
    color: "transparent"

    WlrLayershell.namespace: "ancient-launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: 1120
    implicitHeight: 672

    property bool launching: false
    property string authCode: ""

    onOpenChanged: {
        if (open) {
            launching = false;
            search.text = ShellState.launcherText;
            ShellState.launcherText = "";
            list.currentIndex = 0;
            authCode = randDigits(6) + "-" + randDigits(8);
            search.forceActiveFocus();
        }
    }

    function randDigits(n) {
        let s = "";
        for (let i = 0; i < n; i++) s += Math.floor(Math.random() * 10);
        return s;
    }

    HyprlandFocusGrab {
        active: root.open
        windows: [root]
        onCleared: ShellState.launcherOpen = false
    }

    // ── Search ───────────────────────────────────────────────
    readonly property bool commandMode: search.text.startsWith(">")
    readonly property string query: (commandMode ? search.text.slice(1) : search.text).trim().toLowerCase()

    function score(e, q) {
        const name = (e.name || "").toLowerCase();
        if (name.startsWith(q)) return 100 - name.length / 100;
        const words = name.split(/[\s\-_.]+/);
        if (words.some(w => w.startsWith(q))) return 80;
        if (name.includes(q)) return 60;
        const extra = ((e.genericName || "") + " " + [].concat(e.keywords || []).join(" ") + " " + (e.comment || "")).toLowerCase();
        if (extra.includes(q)) return 30;
        // Subsequence match ("ffx" → firefox)
        let i = 0;
        for (const c of name) if (c === q[i]) i++;
        return i === q.length ? 10 : -1;
    }

    readonly property var results: {
        const apps = DesktopEntries.applications.values.filter(e => !e.noDisplay);
        if (commandMode) return [];
        if (query === "") return apps.slice().sort((a, b) => a.name.localeCompare(b.name));
        return apps.map(e => ({ e, s: score(e, query) }))
            .filter(x => x.s >= 0)
            .sort((a, b) => b.s - a.s || a.e.name.localeCompare(b.e.name))
            .map(x => x.e);
    }

    readonly property var current: results[list.currentIndex] ?? null
    readonly property bool valid: commandMode ? query !== "" : results.length > 0
    readonly property int encoded: valid ? Math.min(6, query.length) : 0

    // Status line of the dialing computer
    readonly property var status: {
        if (launching) return { text: I18n.tr("WORMHOLE ESTABLISHED"), color: Theme.cyanBright };
        if (commandMode) return query === "" ? { text: I18n.tr("MANUAL DIALING"), color: Theme.amber }
            : { text: I18n.tr("COMMAND ENCODED"), color: Theme.amber };
        if (query === "") return { text: I18n.tr("AWAITING ADDRESS"), color: Theme.textDim };
        if (!valid) return { text: I18n.tr("INVALID ADDRESS"), color: Theme.dome };
        return { text: I18n.tr("CHEVRON %1 ENCODED", encoded), color: Theme.cyan };
    }

    function dial() {
        if (launching || !valid) return;
        launching = true;
        launchTimer.restart();
    }

    Timer {
        id: launchTimer
        interval: gate.openDuration + 150   // let the wormhole finish opening
        onTriggered: {
            const cmd = search.text.slice(1).trim();
            const entry = root.current;
            const cmdMode = root.commandMode;
            ShellState.launcherOpen = false;
            if (cmdMode) {
                if (cmd) Hypr.exec(cmd);
            } else if (entry) {
                // Through Hyprland, like any other launch: the app gets the
                // session's environment, not the shell's
                let line = Hypr.quote(entry.runInTerminal ? [Config.terminal, "-e", ...entry.command] : entry.command);
                if (entry.workingDirectory) line = "cd " + Hypr.quote([entry.workingDirectory]) + " && " + line;
                Hypr.exec(line);
            }
        }
    }

    // ── Console ──────────────────────────────────────────────
    ChamferPanel {
        id: plate
        anchors.fill: parent
        opacity: root.progress
        scale: 0.97 + 0.03 * root.progress
        cut: 18
        fillColor: Theme.alpha(Theme.stone0, 0.94)
        borderColor: Theme.alpha(Theme.cyan, 0.45)
        accentEdge: "top"
        accentLength: 0.6

        // Circuit traces from the gate to the registry
        Canvas {
            id: traces
            anchors.fill: parent
            onWidthChanged: requestPaint()
            Connections {
                target: list
                function onCurrentIndexChanged() { traces.requestPaint(); }
                function onContentYChanged() { traces.requestPaint(); }
            }
            onPaint: {
                const c = getContext("2d");
                c.reset();
                const gx = gate.x + gate.cx, gy = gate.y + gate.cy, R = gate.r + 22;
                const top = list.mapToItem(plate, 0, 0).y;
                const firstVisible = list.indexAt(10, list.contentY + 2);
                const angles = [58, 76, 94, 112, 130];
                for (let i = 0; i < angles.length; i++) {
                    const a = angles[i] * Math.PI / 180;
                    const sx = gx + Math.sin(a) * R, sy = gy - Math.cos(a) * R;
                    const ty = top + i * 62 + 31;
                    const midX = right.x - 18 - i * 7;
                    const lit = list.count > 0 && firstVisible >= 0 && firstVisible + i === list.currentIndex;
                    c.strokeStyle = lit ? Theme.amber : Theme.alpha(Theme.cyan, 0.28);
                    c.lineWidth = lit ? 1.6 : 1;
                    c.beginPath();
                    c.moveTo(sx, sy);
                    c.lineTo(midX, sy);
                    c.lineTo(midX, ty);
                    c.lineTo(right.x + 2, ty);
                    c.stroke();
                }
            }
        }

        // ── Header ───────────────────────────────────────
        Item {
            id: header
            x: 18; y: 14
            width: parent.width - 36
            height: 34

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10
                OriginGlyph { width: 16; height: 20; glow: 0.7; anchors.verticalCenter: parent.verticalCenter }
                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    display: true
                    size: 12
                    font.letterSpacing: 2.6
                    color: Theme.cyan
                    text: I18n.tr("DIALING COMPUTER")
                }
                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    size: 12
                    color: Theme.textMute
                    text: I18n.tr("SGC · %1", (Quickshell.env("HOSTNAME") || I18n.tr("EARTH")).toUpperCase())
                }
            }

            // Address cells: the typed characters
            Row {
                anchors.centerIn: parent
                spacing: 4
                Repeater {
                    model: 7
                    Rectangle {
                        required property int index
                        readonly property string ch: root.query.charAt(index).toUpperCase()
                        readonly property bool filled: index < 6 ? ch !== "" : root.launching
                        width: 26; height: 26
                        color: filled ? Theme.alpha(index === 6 ? Theme.amber : Theme.cyan, 0.16) : Theme.stone1
                        border.width: 1
                        border.color: filled ? (index === 6 ? Theme.amber : Theme.cyan) : Theme.line
                        Label {
                            anchors.centerIn: parent
                            display: true
                            size: 12
                            color: index === 6 ? Theme.amberBright : Theme.cyanBright
                            text: index < 6 ? parent.ch : (root.launching ? "Λ" : "")
                        }
                    }
                }
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10
                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    display: true
                    size: 10
                    font.letterSpacing: 2.2
                    color: Theme.textMute
                    text: I18n.tr("DESTINATION:")
                }
                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, 260)
                    display: true
                    size: 13
                    font.letterSpacing: 1.6
                    color: root.commandMode ? Theme.amber : Theme.text
                    text: root.commandMode ? (root.query || "—").toUpperCase()
                        : (root.current?.name ?? "—").toUpperCase()
                }
            }
        }

        Rectangle {
            x: 18; y: header.y + header.height + 6
            width: parent.width - 36; height: 1
            color: Theme.line
        }

        // ── Left: data stream + chevron status ───────────
        Column {
            id: left
            x: 18
            y: header.y + header.height + 18
            width: 206
            spacing: 10

            Item {
                width: parent.width
                height: 268
                ChamferPanel {
                    anchors.fill: parent
                    cut: 8
                    fillColor: Theme.stone1
                    borderColor: Theme.line
                }
                BinaryStream {
                    anchors.fill: parent
                    anchors.margins: 4
                    running: root.open
                    lines: 17
                    speed: root.launching ? 6 : root.query !== "" ? 2.5 : 1
                }
            }

            Row {
                spacing: 6
                Label { size: 12; display: true; font.letterSpacing: 1.6; color: Theme.textMute; text: I18n.tr("STATUS:") }
                Label {
                    size: 12; display: true; font.letterSpacing: 1.6
                    color: root.launching ? Theme.cyanBright : root.query !== "" ? Theme.amber : Theme.crystal
                    text: root.launching ? I18n.tr("LOCKED") : root.query !== "" ? I18n.tr("DIALING") : I18n.tr("ACTIVE")
                }
            }

            ChamferPanel {
                width: parent.width
                height: 7 * 26 + 16
                cut: 8
                fillColor: Theme.stone1
                borderColor: Theme.line

                Column {
                    x: 12; y: 8
                    spacing: 4
                    Repeater {
                        model: 7
                        Row {
                            id: chevRow
                            required property int index
                            readonly property bool lit: index < 6 ? index < root.encoded : root.launching
                            spacing: 10
                            height: 22
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 70; height: 10
                                color: Theme.stone0
                                border.width: 1
                                border.color: Theme.line
                                Rectangle {
                                    anchors.right: parent.right
                                    anchors.margins: 2
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: chevRow.lit ? parent.width - 4 : 14
                                    height: parent.height - 4
                                    color: chevRow.lit ? (chevRow.index === 6 ? Theme.amber : Theme.cyan) : Theme.stone3
                                    Behavior on width { NumberAnimation { duration: Theme.animMid; easing.type: Easing.OutCubic } }
                                }
                            }
                            Label {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 14
                                display: true
                                size: 12
                                color: chevRow.lit ? Theme.text : Theme.textMute
                                text: chevRow.index + 1
                            }
                            Label {
                                anchors.verticalCenter: parent.verticalCenter
                                display: true
                                size: 11
                                font.letterSpacing: 1.4
                                color: Theme.crystal
                                opacity: chevRow.lit ? 1 : 0
                                text: I18n.tr("OK")
                                Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                            }
                        }
                    }
                }
            }
        }

        // ── Centre: the gate ─────────────────────────────
        Item {
            id: centre
            x: left.x + left.width + 18
            y: left.y
            width: right.x - x - 26
            height: footer.y - y - 10

            GateRing {
                id: gate
                anchors.horizontalCenter: parent.horizontalCenter
                y: -6
                width: 400; height: 400
                encoded: root.encoded
                locked: root.launching
                active: root.valid
                commandMode: root.commandMode
                iconSource: root.current ? Quickshell.iconPath(root.current.icon, "application-x-executable") : ""
                spin: {
                    // The track turns one way for odd chevrons, the other for even ones
                    let s = 0;
                    for (let i = 1; i <= root.query.length; i++) s += (i % 2 ? 1 : -1) * (37 + (root.query.charCodeAt(i - 1) % 9) * 9.23);
                    return s;
                }
            }

            Label {
                anchors.left: status.left
                anchors.bottom: status.top
                anchors.bottomMargin: 4
                display: true; size: 9; font.letterSpacing: 2; color: Theme.textMute
                text: "LST CODE #1"
            }
            Label {
                anchors.right: status.right
                anchors.bottom: status.top
                anchors.bottomMargin: 4
                display: true; size: 9; font.letterSpacing: 2; color: Theme.textMute
                text: "LST CODE #2"
            }

            // Status readout ("SUCCESS" / "ACTIVE" box)
            ChamferPanel {
                id: status
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: field.top
                anchors.bottomMargin: 10
                width: parent.width - 40
                height: 52
                cut: 8
                fillColor: Theme.alpha(root.status.color, 0.07)
                borderColor: Theme.alpha(root.status.color, 0.65)

                Label {
                    id: statusText
                    anchors.centerIn: parent
                    display: true
                    size: 22
                    font.weight: Font.Bold
                    font.letterSpacing: 5
                    color: root.status.color
                    text: root.status.text
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: root.status.color
                        shadowBlur: 0.6
                        shadowHorizontalOffset: 0
                        shadowVerticalOffset: 0
                    }
                    SequentialAnimation on opacity {
                        running: root.launching
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.35; duration: 110 }
                        NumberAnimation { to: 1; duration: 110 }
                    }
                }
            }

            // Destination input
            Item {
                id: field
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 40
                height: 44

                ChamferPanel {
                    anchors.fill: parent
                    cut: 8
                    cutTopRight: false
                    cutBottomLeft: false
                    fillColor: Theme.stone0
                    borderColor: search.activeFocus ? Theme.alpha(root.commandMode ? Theme.amber : Theme.cyan, 0.7) : Theme.line
                }
                Label {
                    id: prompt
                    x: 14
                    anchors.verticalCenter: parent.verticalCenter
                    display: true
                    size: 11
                    font.letterSpacing: 2
                    color: root.commandMode ? Theme.amber : Theme.cyan
                    text: root.commandMode ? I18n.tr("CMD ▸") : I18n.tr("DIAL ▸")
                }
                TextInput {
                    id: search
                    anchors.left: prompt.right
                    anchors.leftMargin: 12
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: Theme.fontUi
                    font.pixelSize: 20
                    font.weight: Font.DemiBold
                    color: Theme.text
                    selectionColor: Theme.cyanDeep
                    selectedTextColor: Theme.cyanBright
                    clip: true
                    focus: true
                    readOnly: root.launching

                    Label {
                        visible: search.text === ""
                        anchors.verticalCenter: parent.verticalCenter
                        size: 18
                        color: Theme.textMute
                        // i18n: input placeholder; ">" is the literal prefix that switches to command mode
                        text: I18n.tr("destination name…   ( > dials a command )")
                    }

                    Keys.onEscapePressed: ShellState.launcherOpen = false
                    Keys.onDownPressed: list.incrementCurrentIndex()
                    Keys.onUpPressed: list.decrementCurrentIndex()
                    Keys.onTabPressed: list.incrementCurrentIndex()
                    Keys.onBacktabPressed: list.decrementCurrentIndex()
                    Keys.onReturnPressed: root.dial()
                    Keys.onEnterPressed: root.dial()
                    onTextChanged: list.currentIndex = 0
                }
            }
        }

        // ── Right: destination registry ──────────────────
        Item {
            id: right
            x: parent.width - width - 18
            y: left.y
            width: 300
            height: footer.y - y - 10

            Row {
                id: regHead
                spacing: 8
                Label { display: true; size: 10; font.letterSpacing: 2.2; color: Theme.amber; text: I18n.tr("DESTINATION LOG") }
                Label { size: 13; color: Theme.textMute; text: root.commandMode ? "—" : I18n.trn("%1 address", "%1 addresses", root.results.length) }
            }

            ListView {
                id: list
                anchors.top: regHead.bottom
                anchors.topMargin: 10
                anchors.bottom: parent.bottom
                width: parent.width
                clip: true
                model: root.results
                spacing: 0
                highlightMoveDuration: 120
                boundsBehavior: Flickable.StopAtBounds
                keyNavigationWraps: true
                snapMode: ListView.SnapToItem

                delegate: MouseArea {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool cur: ListView.isCurrentItem
                    width: ListView.view.width
                    height: 62
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: if (!root.launching) list.currentIndex = index
                    onClicked: { list.currentIndex = index; root.dial(); }

                    Label {
                        id: num
                        width: 28
                        anchors.verticalCenter: parent.verticalCenter
                        horizontalAlignment: Text.AlignRight
                        display: true
                        size: 14
                        color: row.cur ? Theme.amber : Theme.textMute
                        text: row.index + 1
                    }

                    ChamferPanel {
                        id: cell
                        anchors.left: num.right
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        width: 54; height: 52
                        cut: 7
                        fillColor: row.cur ? Theme.alpha(Theme.amber, 0.12) : Theme.stone1
                        borderColor: row.cur ? Theme.amber : row.containsMouse ? Theme.lineBright : Theme.line
                        IconImage {
                            anchors.centerIn: parent
                            implicitSize: 30
                            source: Quickshell.iconPath(row.modelData.icon, "application-x-executable")
                        }
                    }

                    Column {
                        anchors.left: cell.right
                        anchors.leftMargin: 12
                        anchors.right: parent.right
                        anchors.rightMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: -2
                        Label {
                            width: parent.width
                            size: 16
                            color: row.cur ? Theme.text : Theme.textDim
                            text: row.modelData.name
                        }
                        Label {
                            width: parent.width
                            size: 12
                            visible: text !== ""
                            color: Theme.textMute
                            text: row.modelData.genericName || row.modelData.comment || ""
                        }
                    }
                }

                Label {
                    anchors.centerIn: parent
                    visible: list.count === 0
                    width: parent.width - 20
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    size: 15
                    color: root.commandMode ? Theme.amber : Theme.dome
                    // i18n: shown when the query starts with ">"; %1 is the shell command, on its own line
                    text: root.commandMode ? I18n.tr("Enter dials:\n%1", search.text.slice(1).trim()) : I18n.tr("No address matches")
                }
            }
        }

        // ── Footer ───────────────────────────────────────
        Item {
            id: footer
            x: 18
            y: parent.height - height - 12
            width: parent.width - 36
            height: 30

            Rectangle { width: parent.width; height: 1; color: Theme.line }

            Row {
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 3
                spacing: 10
                Label { display: true; size: 9; font.letterSpacing: 2; color: Theme.textMute; text: I18n.tr("AUTHORIZATION CODE") }
                Label { font.family: Theme.fontMono; size: 13; font.letterSpacing: 3; color: Theme.cyan; text: root.authCode }
            }
            Row {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 3
                spacing: 18
                Repeater {
                    model: [["↑↓", I18n.tr("destination")], ["Enter", I18n.tr("dial")], ["> ", I18n.tr("command")], ["Esc", I18n.tr("abort")]]
                    Row {
                        required property var modelData
                        spacing: 6
                        Label { size: 11; display: true; color: Theme.amber; text: parent.modelData[0] }
                        Label { size: 13; color: Theme.textMute; text: parent.modelData[1] }
                    }
                }
            }
            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 3
                spacing: 14
                Label { display: true; size: 9; font.letterSpacing: 2; color: Theme.textMute; text: I18n.tr("USER: %1", (Quickshell.env("USER") || "").toUpperCase()) }
                Label { display: true; size: 9; font.letterSpacing: 2; color: Theme.textMute; text: I18n.tr("SYS:") }
                Label { display: true; size: 9; font.letterSpacing: 2; color: Theme.crystal; text: I18n.tr("NOMINAL") }
            }
        }
    }
}
