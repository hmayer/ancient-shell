pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

// Hyprland actions. With a Lua config, `hyprctl dispatch` takes a Lua expression
// (hl.dsp.*); with a hyprlang config it takes the classic "dispatcher args" form.
Singleton {
    id: root

    readonly property bool lua: Hyprland.usingLua

    function dispatch(luaExpr, legacy) {
        Quickshell.execDetached(["hyprctl", "dispatch", lua ? luaExpr : legacy]);
    }

    // Through WorkspaceNav, so the switch turns the cube when it is on
    function workspace(id) {
        WorkspaceNav.go(String(id));
    }

    function exit() {
        dispatch("hl.dsp.exit()", "exit");
    }

    // Run a command through Hyprland, so it gets the session's environment
    // (the shell's own may differ, e.g. the GPU it renders on)
    function exec(cmd) {
        if (lua) {
            // A Lua long string takes the command as is
            let eq = "=";
            while (cmd.includes("]" + eq + "]")) eq += "=";
            Hyprland.dispatch(`hl.dsp.exec_cmd([${eq}[${cmd}]${eq}])`);
        } else {
            Hyprland.dispatch("exec " + cmd);
        }
    }

    // A command line from an argument list, each argument shell-quoted
    function quote(args) {
        return args.map(a => "'" + String(a).replace(/'/g, "'\\''") + "'").join(" ");
    }
}
