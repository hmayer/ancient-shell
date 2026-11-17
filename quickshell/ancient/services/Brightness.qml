pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Laptop panel brightness through brightnessctl.
Singleton {
    id: root

    property real value: 0      // 0..1
    property bool available: false
    signal touched()

    function set(v) {
        v = Math.max(0.01, Math.min(1, v));
        value = v;
        setter.command = ["brightnessctl", "-q", "s", Math.round(v * 100) + "%"];
        setter.running = true;
    }
    function step(delta) { set(value + delta); touched(); }
    function refresh() { reader.running = true; }

    Process {
        id: reader
        command: ["brightnessctl", "-m", "-c", "backlight"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                // name,class,current,percent%,max
                const parts = text.trim().split("\n")[0].split(",");
                if (parts.length >= 5) {
                    root.value = Number(parts[2]) / Number(parts[4]);
                    root.available = true;
                }
            }
        }
    }

    Process { id: setter }

    // Pick up changes made outside the shell
    Timer {
        interval: 5000
        running: root.available
        repeat: true
        onTriggered: reader.running = true
    }
}
