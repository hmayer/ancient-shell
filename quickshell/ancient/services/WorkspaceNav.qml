pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Workspace switching through the shell, so the switch can be animated as a
// turning cube (workspace/WorkspaceCube). Hyprland's key bindings reach it as
// global shortcuts "ancient:go-<target>" and "ancient:move-<target>" (see
// hypr/init.lua), where target is a workspace number or a relative one such as
// "m+1" or "e-1". Anything the cube cannot animate is dispatched directly.
Singleton {
    id: root

    readonly property bool cube: Config.workspaceCube

    // Asks the cube on `screenName` to cover the screen, run `dispatch` and
    // turn towards `direction` (+1 next, -1 previous). kind and target are
    // the request itself, for the cube to ask again if it has to wait.
    signal transition(string screenName, string kind, string target, string dispatch, int direction)

    function go(target) {
        request("go", target);
    }

    // Move the active window there and follow it
    function move(target) {
        request("move", target);
    }

    // What `hyprctl dispatch` takes: a Lua dispatcher with a Lua config,
    // "dispatcher args" with a hyprlang one
    function expr(kind, target) {
        if (kind === "move")
            return Hyprland.usingLua ? `hl.dsp.window.move({ workspace = "${target}", follow = true })`
                : `movetoworkspace ${target}`;
        return Hyprland.usingLua ? `hl.dsp.focus({ workspace = "${target}" })` : `workspace ${target}`;
    }

    function request(kind, target) {
        target = String(target);
        const dispatch = expr(kind, target);
        const plan = cube && (kind !== "move" || Hyprland.activeToplevel !== null) ? planFor(target) : null;
        if (plan) transition(plan.monitor.name, kind, target, dispatch, plan.direction);
        else Hyprland.dispatch(dispatch);
    }

    // The screen the switch happens on and which way the cube turns there
    // (+1 the target lies after the workspace it shows, -1 before it). null
    // when the cube has nothing to turn to: the workspace is already shown
    // (on this screen, or on another one, where Hyprland just moves the
    // focus), or it is named or special
    function planFor(target) {
        const focused = Hyprland.focusedMonitor;
        const here = focused?.activeWorkspace?.id ?? 0;
        if (here <= 0) return null;
        const id = resolve(target, focused, here);
        if (id === null || id <= 0) return null;
        const mon = monitorOf(id) ?? focused;
        const current = mon.activeWorkspace?.id ?? 0;
        if (current <= 0 || id === current) return null;
        const rel = mon === focused ? /^[mer]([+-])/.exec(target) : null;
        return { monitor: mon, direction: rel ? (rel[1] === "+" ? 1 : -1) : Math.sign(id - current) };
    }

    // The screen a workspace shows on: where it is open, else the one a
    // workspace rule binds it to (Hyprland creates it there), else null for
    // the focused one
    function monitorOf(id) {
        const ws = Hyprland.workspaces.values.find(w => w.id === id);
        if (ws?.monitor) return ws.monitor;
        const bound = boundTo[id];
        if (!bound) return null;
        return Hyprland.monitors.values.find(m => bound.startsWith("desc:")
            ? (m.lastIpcObject?.description ?? "").startsWith(bound.slice(5))
            : m.name === bound) ?? null;
    }

    // The workspace id a target names: a number, r±n (relative id), m±n (open
    // workspaces of this screen) or e±n (open workspaces of all screens), the
    // last two wrapping around like Hyprland's
    function resolve(target, mon, current) {
        const id = parseInt(target);
        if (String(id) === target) return id;
        const rel = /^([mer])([+-]\d+)$/.exec(target);
        if (!rel) return null;
        const step = parseInt(rel[2]);
        if (rel[1] === "r") return current + step;
        const open = Hyprland.workspaces.values
            .filter(w => w.id > 0 && (rel[1] === "e" || w.monitor === mon))
            .map(w => w.id)
            .sort((a, b) => a - b);
        const at = open.indexOf(current);
        if (at < 0 || open.length < 2) return null;
        return open[((at + step) % open.length + open.length) % open.length];
    }

    // Workspace id → monitor, from Hyprland's workspace rules ("workspace 8
    // goes to DP-1"); read at start and again whenever the config reloads
    property var boundTo: ({})

    Process {
        id: rules
        command: ["hyprctl", "workspacerules", "-j"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const map = {};
                try {
                    for (const r of JSON.parse(text)) {
                        const id = parseInt(r.workspaceString);
                        if (String(id) === r.workspaceString && r.monitor) map[id] = r.monitor;
                    }
                } catch (e) {
                    console.warn("WorkspaceNav: cannot read workspace rules:", e);
                }
                root.boundTo = map;
            }
        }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "configreloaded") rules.running = true;
        }
    }

    readonly property var targets: ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10",
        "m+1", "m-1", "e+1", "e-1"]

    Variants {
        model: root.targets
        GlobalShortcut {
            required property string modelData
            appid: "ancient"
            name: "go-" + modelData
            description: "Go to workspace " + modelData
            onPressed: root.go(modelData)
        }
    }
    Variants {
        model: root.targets
        GlobalShortcut {
            required property string modelData
            appid: "ancient"
            name: "move-" + modelData
            description: "Move the active window to workspace " + modelData
            onPressed: root.move(modelData)
        }
    }
}
