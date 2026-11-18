pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Pending package upgrades, counted per package manager by
// scripts/upgrades.py, and the topgrade run that applies them. The run goes
// on in the background if the shell restarts (its output is appended to the
// log in Config.upgradesLog), and the shell picks it up again when it starts.
Singleton {
    id: root

    // Every manager, in order; `id` is the name scripts/upgrades.py knows
    readonly property var allManagers: [
        { id: "system", name: I18n.tr("System") },
        { id: "omz", name: "Oh My Zsh" },
        { id: "cargo", name: "Rust" },
        { id: "vscode", name: "VS Code Extensions" },
        { id: "nvim", name: "NeoVim" },
        { id: "node", name: "Node" },
        { id: "docker", name: I18n.tr("Docker images") },
        { id: "composer", name: "PHP Composer" },
        { id: "github", name: "GitHub" },
        { id: "claude", name: "Claude Code" },
        { id: "uv", name: "Python UV" }
    ]
    // The rows of the table: the managers not in Config.upgradesDisabled
    readonly property var managers: allManagers.filter(m => !Config.upgradesDisabled.includes(m.id))

    // id → { count } | { note } (not checked, why) | { error } | { missing }
    property var results: ({})
    property var fresh: ({})            // ids already answered by the check going on
    property bool checking: false
    property date lastCheck: new Date(0)
    readonly property bool checked: lastCheck.getTime() > 0
    readonly property var pending: managers.filter(m => (results[m.id]?.count ?? 0) > 0)
    readonly property int total: pending.reduce((n, m) => n + results[m.id].count, 0)

    // The upgrade run
    property bool running: false
    property bool queued: false         // asked for during a check: starts when the check ends
    readonly property bool active: running || queued
    property var runNames: []           // the managers it upgrades
    property int lastExit: 0
    property bool consoleOpen: false
    property string consoleScreen: ""
    property alias output: lines            // { line }
    readonly property int maxLines: 4000

    readonly property string script: Quickshell.shellPath("scripts/upgrades.py")
    readonly property var env: ({
        ANCIENT_NODE_BIN: Config.upgradesNodeBin,
        ANCIENT_UPGRADE_LOG: Config.upgradesLog,
        ANCIENT_EXTRA_PATH: Config.upgradesPath.join(":")
    })

    function check() {
        if (checking || active) return;
        fresh = {};
        if (managers.length === 0) {
            // upgrades.py checks every manager when given none
            lastCheck = new Date();
            return;
        }
        _checkCode = -1;
        checking = true;
        checker.command = ["python3", script, "check", ...managers.map(m => m.id)];
        checker.running = true;
    }

    function upgrade(screenName) {
        if (active || (!checking && pending.length === 0)) return;
        lines.clear();
        consoleScreen = screenName || ShellState.focusedScreen;
        consoleOpen = true;
        ShellState.closeDrawer();
        if (checking) {
            // The check's git fetches and dry runs would race topgrade's steps
            queued = true;
            // i18n: shown in the upgrade console while a check is still running
            lines.append({ line: I18n.tr("Waiting for the check to finish…") });
        } else {
            _start();
        }
    }

    function _start() {
        queued = false;
        if (pending.length === 0) {
            consoleOpen = false;
            return;
        }
        lines.clear();
        runNames = pending.map(m => m.name);
        _runCode = -1;
        running = true;
        runner.command = ["python3", script, "run", ...pending.map(m => m.id)];
        runner.running = true;
    }

    function toggleConsole(screenName) {
        const scr = screenName || ShellState.focusedScreen;
        if (consoleOpen && consoleScreen === scr) {
            consoleOpen = false;
        } else {
            consoleScreen = scr;
            consoleOpen = true;
        }
    }

    // A minute after login, then every 3 hours
    Timer {
        running: true
        repeat: true
        interval: root.checked ? 3 * 60 * 60 * 1000 : 60 * 1000
        onTriggered: root.check()
    }

    Process {
        id: checker
        environment: root.env
        stdout: SplitParser {
            onRead: data => {
                let r;
                try { r = JSON.parse(data); } catch (e) { return; }
                if (!r.id) return;
                root.results = Object.assign({}, root.results, { [r.id]: r });
                root.fresh = Object.assign({}, root.fresh, { [r.id]: true });
            }
        }
        onExited: code => root._checkCode = code
        // Also when python3 could not start, which emits no `exited`
        onRunningChanged: if (!running) Qt.callLater(root._checked)
    }

    property int _checkCode: -1
    function _checked() {
        if (!checking) return;
        checking = false;
        if (_checkCode === 0) lastCheck = new Date();   // a failed check is retried in a minute
        if (queued) _start();
    }

    ListModel { id: lines }

    Process {
        id: runner
        environment: root.env
        stdout: SplitParser {
            onRead: data => {
                // A run picked up on start tells what it upgrades in its header
                const head = data.match(/^━━━━ .* · upgrade: (.*) ━━━━$/);
                if (head) {
                    const ids = head[1].split(" ");
                    root.runNames = root.allManagers.filter(m => ids.includes(m.id)).map(m => m.name);
                }
                root.running = true;
                lines.append({ line: data });
                if (lines.count > root.maxLines) lines.remove(0, lines.count - root.maxLines);
            }
        }
        onExited: code => root._runCode = code
        onRunningChanged: if (!running) Qt.callLater(root._ran)
    }

    property int _runCode: -1
    function _ran() {
        if (!running) return;   // `follow` found no run going on
        running = false;
        lastExit = _runCode;
        consoleOpen = false;    // a failure is told by topgrade's notification and the drawer
        check();
    }

    // A run that outlived the previous shell
    Component.onCompleted: {
        runner.command = ["python3", script, "follow"];
        runner.running = true;
    }
}
