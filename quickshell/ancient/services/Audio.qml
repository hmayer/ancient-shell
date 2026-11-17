pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    readonly property bool ready: sink?.ready ?? false
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property real micVolume: source?.audio?.volume ?? 0
    readonly property bool micMuted: source?.audio?.muted ?? false

    readonly property string icon: muted || volume <= 0.001 ? "volume_off"
        : volume < 0.34 ? "volume_mute"
        : volume < 0.67 ? "volume_down" : "volume_up"

    signal volumeTouched()

    function setVolume(v) {
        if (sink?.ready && sink.audio) {
            sink.audio.muted = false;
            sink.audio.volume = Math.max(0, Math.min(1, v));
        }
    }
    function step(delta) { setVolume(volume + delta); volumeTouched(); }
    function toggleMute() {
        if (sink?.ready && sink.audio) sink.audio.muted = !sink.audio.muted;
        volumeTouched();
    }
    function setMicVolume(v) {
        if (source?.ready && source.audio) source.audio.volume = Math.max(0, Math.min(1, v));
    }
    function toggleMic() {
        if (source?.ready && source.audio) source.audio.muted = !source.audio.muted;
    }

    // Binds the default nodes so their audio properties stay live
    PwObjectTracker {
        objects: [root.sink, root.source]
    }
}
