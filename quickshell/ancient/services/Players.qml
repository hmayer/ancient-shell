pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// The MPRIS player the shell shows: the one playing, else the last one touched.
Singleton {
    id: root

    property MprisPlayer manual: null
    readonly property list<MprisPlayer> all: Mpris.players.values
    readonly property MprisPlayer active: {
        if (manual && all.includes(manual)) return manual;
        return all.find(p => p.isPlaying) ?? all[0] ?? null;
    }

    function cycle() {
        if (all.length < 2) return;
        const i = all.indexOf(active);
        manual = all[(i + 1) % all.length];
    }

    function fmt(sec) {
        if (!isFinite(sec) || sec < 0) return "0:00";
        sec = Math.floor(sec);
        return Math.floor(sec / 60) + ":" + String(sec % 60).padStart(2, "0");
    }
}
