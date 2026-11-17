pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

// Music effects on the desktop: their settings (changed from the media
// player's panel) and the live spectrum of what is playing, read from cava
// while the player plays and some effect wants it.
Singleton {
    id: root

    readonly property alias settings: opts

    readonly property MprisPlayer player: Players.active
    readonly property bool playing: player?.isPlaying ?? false
    readonly property bool wallpaperFx: opts.wallpaperFx && (opts.glow || opts.blur || opts.zoom || opts.shake)
    // Something on screen is driven by the music right now
    readonly property bool live: playing && (opts.visualizer || wallpaperFx)

    // Spectrum, low to high: `count` values in 0..1
    readonly property int count: 64
    property var bars: zeros()
    property real level: 0         // mean of all bands
    property real bass: 0          // mean of the lowest bands
    property real kick: 0          // jumps on a beat, then fades
    signal beat(real strength)

    property real _bassAvg: 0
    property double _lastBeat: 0

    function zeros() {
        return new Array(count).fill(0);
    }

    // One cava frame: "v;v;v;...;" with v in 0..1000
    function frame(line) {
        const parts = line.split(";");
        if (parts.length < count) return;
        const v = new Array(count);
        let sum = 0, low = 0;
        for (let i = 0; i < count; i++) {
            v[i] = Math.min(1, (parseInt(parts[i]) || 0) / 1000);
            sum += v[i];
            if (i < 6) low += v[i];
        }
        low /= 6;
        bars = v;
        level = sum / count;
        bass = low;
        _bassAvg = _bassAvg * 0.94 + low * 0.06;
        const now = Date.now();
        if (low > 0.22 && low > _bassAvg * 1.25 && now - _lastBeat > 170) {
            _lastBeat = now;
            kick = Math.min(1, 0.45 + (low - _bassAvg) * 2.5);
            beat(kick);
        } else {
            kick *= 0.86;
        }
    }

    function reset() {
        bars = zeros();
        level = 0;
        bass = 0;
        kick = 0;
        _bassAvg = 0;
    }

    onLiveChanged: if (!live) reset()

    Process {
        id: cava
        running: root.live
        // The config is written next to the shell's state on each start
        command: ["sh", "-c", 'printf "%s" "$1" > "$2" && exec cava -p "$2"', "sh", root.cavaConfig,
            Quickshell.statePath("cava.conf")]
        stdout: SplitParser {
            onRead: data => root.frame(data)
        }
        onExited: (code, status) => {
            if (code !== 0 && root.live) console.warn("MusicFx: cava exited with", code);
        }
    }

    readonly property string cavaConfig: [
        "[general]", "framerate = 60", "bars = " + count, "autosens = 1",
        "[input]", "method = pipewire", "source = auto",
        "[output]", "method = raw", "raw_target = /dev/stdout", "data_format = ascii",
        "ascii_max_range = 1000", "bar_delimiter = 59", "frame_delimiter = 10", "channels = mono",
        "[smoothing]", "noise_reduction = 70", ""
    ].join("\n")

    FileView {
        path: Quickshell.statePath("music-fx.json")
        onAdapterUpdated: writeAdapter()
        onLoadFailed: writeAdapter()
        JsonAdapter {
            id: opts
            property real intensity: 1.0          // 0.1 .. 2.0
            property bool visualizer: true
            property string mode: "ring"          // bars, wave, mirror, ring, halo, sheep
            property bool particles: false        // star streaks over any mode
            property bool lyrics: true
            property bool wallpaperFx: true
            property bool glow: true
            property bool blur: false
            property bool zoom: true
            property bool shake: false
        }
    }
}
