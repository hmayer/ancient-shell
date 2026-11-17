pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

// Synced lyrics of the track playing, from LRCLIB (lrclib.net, free and open,
// no account). Only looked up while desktop lyrics are on; each track is
// asked for once per session.
Singleton {
    id: root

    readonly property MprisPlayer player: Players.active
    readonly property bool enabled: MusicFx.settings.lyrics
    readonly property string key: player && player.trackTitle ? (player.trackArtist ?? "") + "\u0001" + player.trackTitle : ""

    property var lines: []          // [{ t: seconds, text }]
    property string status: ""      // "", "loading", "none", "ok", "error"
    property real position: 0       // seconds, ticked while shown

    property var _cache: ({})

    // The line being sung, -1 before the first one
    readonly property int index: {
        let lo = -1;
        for (let i = 0; i < lines.length && lines[i].t <= position; i++) lo = i;
        return lo;
    }
    readonly property string current: index >= 0 ? lines[index].text : ""
    readonly property string next: index + 1 < lines.length ? lines[index + 1].text : ""
    // How far into the current line, 0..1, assuming words are evenly spread
    readonly property real progress: {
        if (index < 0) return 0;
        const t0 = lines[index].t;
        const t1 = index + 1 < lines.length ? lines[index + 1].t : t0 + 4;
        const words = Math.max(1, current.split(/\s+/).length);
        const span = Math.max(0.6, Math.min(t1 - t0, words * 0.55));
        return Math.max(0, Math.min(1, (position - t0) / span));
    }

    onKeyChanged: lookup()
    onEnabledChanged: lookup()

    function lookup() {
        fetcher.running = false;
        if (!enabled || key === "") {
            lines = [];
            status = "";
            return;
        }
        if (_cache[key] !== undefined) {
            lines = _cache[key];
            status = lines.length ? "ok" : "none";
            return;
        }
        lines = [];
        status = "loading";
        debounce.restart();
    }

    // Tracks skipped through quickly are not looked up
    Timer {
        id: debounce
        interval: 500
        onTriggered: {
            const p = root.player;
            if (!p) return;
            fetcher.wanted = root.key;
            fetcher.length = p.lengthSupported ? p.length : 0;
            fetcher.command = ["curl", "-sf", "-m", "10", "-G", "https://lrclib.net/api/search",
                "-H", "User-Agent: ancient-shell",
                "--data-urlencode", "track_name=" + p.trackTitle,
                "--data-urlencode", "artist_name=" + (p.trackArtist ?? "")];
            fetcher.running = true;
        }
    }

    Process {
        id: fetcher
        property string wanted: ""
        property real length: 0
        stdout: StdioCollector {
            onStreamFinished: {
                if (fetcher.wanted !== root.key) return;
                let found = [];
                try {
                    // The synced entry closest in length to the track
                    const hits = JSON.parse(text).filter(h => h.syncedLyrics);
                    if (fetcher.length > 0)
                        hits.sort((a, b) => Math.abs(a.duration - fetcher.length) - Math.abs(b.duration - fetcher.length));
                    if (hits.length) found = root.parse(hits[0].syncedLyrics);
                } catch (e) {
                    root.status = "error";
                    return;
                }
                root._cache[fetcher.wanted] = found;
                root.lines = found;
                root.status = found.length ? "ok" : "none";
            }
        }
        onExited: (code, status) => {
            if (code !== 0 && fetcher.wanted === root.key) root.status = "error";
        }
    }

    // LRC: "[mm:ss.xx]text", a line may carry several times
    function parse(lrc) {
        const out = [];
        for (const raw of lrc.split("\n")) {
            const text = raw.replace(/\[[^\]]*\]/g, "").trim();
            const stamp = /\[(\d+):(\d+(?:\.\d+)?)\]/g;
            let m;
            while ((m = stamp.exec(raw)) !== null) out.push({ t: parseInt(m[1]) * 60 + parseFloat(m[2]), text });
        }
        return out.sort((a, b) => a.t - b.t);
    }

    // The player's position only updates on demand
    Timer {
        running: root.status === "ok" && (root.player?.isPlaying ?? false)
        interval: 80
        repeat: true
        onTriggered: root.position = root.player?.position ?? 0
    }
}
