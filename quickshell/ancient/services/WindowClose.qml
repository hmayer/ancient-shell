pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Closing the active window through the shell, so it can be sucked into a
// stargate (windowfx/GateClose). Hyprland's close key reaches it as the
// global shortcut "ancient:close-window" (see hypr/init.lua). Windows closed
// any other way (their own button, the app quitting) keep Hyprland's
// animation.
Singleton {
    id: root

    readonly property bool gate: Config.gateClose

    // Asks the overlay on `screenName` to swallow `win`:
    // { address, x, y, width, height } with x, y relative to that screen
    signal closing(string screenName, var win)

    function close() {
        if (!gate) {
            Hyprland.dispatch(expr(""));
            return;
        }
        probe.running = true;
    }

    // Close a window by address (the active one when empty)
    function expr(address) {
        if (Hyprland.usingLua)
            return address ? `hl.dsp.window.close({ window = "address:${address}" })` : "hl.dsp.window.close()";
        return address ? `closewindow address:${address}` : "killactive";
    }

    // Turn Hyprland's own close animation off or back on for one window
    function quiet(address, on) {
        if (Hyprland.usingLua)
            Hyprland.dispatch(`hl.dsp.window.set_prop({ window = "address:${address}", prop = "no_anim", value = "${on}" })`);
        else
            Hyprland.dispatch(`setprop address:${address} noanim ${on ? 1 : 0}`);
    }

    // Where the active window is, exactly, right now
    Process {
        id: probe
        command: ["hyprctl", "activewindow", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                let w = null;
                try { w = JSON.parse(text); } catch (e) {}
                if (!w?.address) return;
                const mon = Hyprland.monitors.values.find(m => m.id === w.monitor);
                const scr = Quickshell.screens.find(s => s.name === mon?.name);
                if (!scr) {
                    Hyprland.dispatch(root.expr(w.address));
                    return;
                }
                root.closing(scr.name, {
                    address: w.address,
                    x: w.at[0] - scr.x, y: w.at[1] - scr.y,
                    width: w.size[0], height: w.size[1]
                });
            }
        }
        onExited: (code, status) => { if (code !== 0) Hyprland.dispatch(root.expr("")); }
    }

    GlobalShortcut {
        appid: "ancient"
        name: "close-window"
        description: "Close the active window through a stargate"
        onPressed: root.close()
    }
}
