pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// CPU, memory, temperature and disk readings. Polls only while `active`.
Singleton {
    id: root

    property bool active: false
    property real cpu: 0        // 0..1
    property real mem: 0        // 0..1
    property real memUsedGb: 0
    property real memTotalGb: 0
    property real temp: 0       // °C
    property real disk: 0       // 0..1
    property string diskLabel: ""
    property string uptime: ""

    property var _lastCpu: null

    Timer {
        interval: 2000
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload();
            meminfo.reload();
            uptimeFile.reload();
            tempProc.running = true;
            diskProc.running = true;
        }
    }

    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: {
            const f = text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
            const idle = f[3] + (f[4] || 0);
            const total = f.reduce((a, b) => a + b, 0);
            if (root._lastCpu) {
                const dt = total - root._lastCpu.total;
                const di = idle - root._lastCpu.idle;
                if (dt > 0) root.cpu = Math.max(0, Math.min(1, 1 - di / dt));
            }
            root._lastCpu = { total, idle };
        }
    }

    FileView {
        id: meminfo
        path: "/proc/meminfo"
        onLoaded: {
            const m = {};
            for (const line of text().split("\n")) {
                const p = line.split(/:\s+/);
                if (p.length === 2) m[p[0]] = parseInt(p[1]);
            }
            const total = m.MemTotal || 1;
            const used = total - (m.MemAvailable || 0);
            root.mem = used / total;
            root.memUsedGb = used / 1048576;
            root.memTotalGb = total / 1048576;
        }
    }

    FileView {
        id: uptimeFile
        path: "/proc/uptime"
        onLoaded: {
            const s = Math.floor(parseFloat(text()));
            const d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60);
            root.uptime = (d > 0 ? d + "d " : "") + h + "h " + m + "m";
        }
    }

    // Highest CPU package/core temperature among the usual hwmon drivers
    Process {
        id: tempProc
        command: ["sh", "-c", "for h in /sys/class/hwmon/hwmon*; do n=$(cat $h/name 2>/dev/null); case $n in coretemp|k10temp|zenpower|cpu_thermal|acpitz) cat $h/temp*_input 2>/dev/null;; esac; done | sort -n | tail -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseInt(text);
                if (!isNaN(v)) root.temp = v / 1000;
            }
        }
    }

    Process {
        id: diskProc
        command: ["df", "-B1", "--output=used,size", "/"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.trim().split("\n");
                if (l.length < 2) return;
                const [used, size] = l[1].trim().split(/\s+/).map(Number);
                root.disk = used / size;
                root.diskLabel = Math.round(used / 1e9) + " / " + Math.round(size / 1e9) + " GB";
            }
        }
    }
}
