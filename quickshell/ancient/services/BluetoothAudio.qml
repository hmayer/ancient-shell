pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Audio profiles of Bluetooth devices, read from PipeWire's Bluetooth cards
// through pactl (Quickshell's PipeWire service has no card profiles).
// PipeWire exposes each codec as a card profile, e.g. "a2dp-sink-aac" is
// "High Fidelity Playback (A2DP Sink, codec AAC)", so switching codec is
// switching profile.
//
// cards[address] = {
//     card: "bluez_card.XX_XX…", active: "<profile name>",
//     modes: [{ id: "a2dp"|"hfp"|"bap", label, profiles: [{ name, codec }] }]
// }
Singleton {
    id: root

    property var cards: ({})
    property string pending: ""       // profile being switched to
    property bool watching: false     // follow card changes (drawer open)

    readonly property var modeInfo: ({
        a2dp: { label: I18n.tr("Music"), hint: "A2DP" },
        bap: { label: "LE Audio", hint: "BAP" },
        hfp: { label: I18n.tr("Call"), hint: "HFP" }
    })

    // A refresh asked for while a read runs is redone after it, so a read that
    // started before a profile switch never leaves stale data behind
    property bool dirty: false
    function refresh() {
        if (lister.running) dirty = true;
        else lister.running = true;
    }

    function setProfile(card, profile) {
        if (setter.running) return;
        pending = profile;
        setter.command = ["pactl", "set-card-profile", card, profile];
        setter.running = true;
    }

    function modeOf(name) {
        if (name.startsWith("a2dp")) return "a2dp";
        if (name.startsWith("bap")) return "bap";
        if (/^(headset|hfp|hsp)/.test(name)) return "hfp";
        return "";
    }

    function parse(text) {
        const out = {};
        let list = [];
        try { list = JSON.parse(text); } catch (e) { return out; }
        for (const c of list) {
            const address = c.properties?.["api.bluez5.address"];
            if (!address) continue;
            const modes = {};
            const entries = Object.entries(c.profiles ?? {})
                .filter(([name, p]) => p.available && modeOf(name) !== "")
                .sort((a, b) => b[1].priority - a[1].priority);
            for (const [name, p] of entries) {
                const id = modeOf(name);
                const m = (p.description ?? "").match(/codec ([^),]+)/i);
                const codec = m ? m[1].trim() : I18n.tr("Auto");
                if (!modes[id]) modes[id] = { id, label: modeInfo[id].label, hint: modeInfo[id].hint, profiles: [] };
                const same = modes[id].profiles.findIndex(x => x.codec === codec);
                // The base profile ("a2dp-sink") often repeats a codec profile;
                // keep the one that is active, if either is
                if (same < 0) modes[id].profiles.push({ name, codec });
                else if (name === c.active_profile) modes[id].profiles[same] = { name, codec };
            }
            out[address] = {
                card: c.name,
                active: c.active_profile,
                modes: ["a2dp", "bap", "hfp"].filter(id => modes[id]).map(id => modes[id])
            };
        }
        return out;
    }

    Process {
        id: lister
        command: ["pactl", "-f", "json", "list", "cards"]
        stdout: StdioCollector {
            onStreamFinished: {
                // Keep the old object when nothing changed, so the chips are not rebuilt
                const next = root.parse(text);
                if (JSON.stringify(next) !== JSON.stringify(root.cards)) root.cards = next;
            }
        }
        onExited: if (root.dirty) {
            root.dirty = false;
            root.refresh();
        }
    }

    Process {
        id: setter
        onExited: (code, status) => {
            if (code !== 0) console.warn("pactl set-card-profile failed:", setter.command.join(" "));
            root.pending = "";
            root.refresh();
        }
    }

    // While watched, re-read the cards whenever PipeWire reports a card change
    // (a device connecting, or the profile changed elsewhere)
    Process {
        running: root.watching
        command: ["pactl", "subscribe"]
        stdout: SplitParser {
            onRead: line => { if (line.includes(" on card ")) debounce.restart(); }
        }
    }
    Timer {
        id: debounce
        interval: 250
        onTriggered: root.refresh()
    }
    onWatchingChanged: if (watching) refresh()
}
