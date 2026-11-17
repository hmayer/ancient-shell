import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.theme
import qs.widgets

// Volume / brightness indicator near the bottom of the focused screen.
PanelWindow {
    id: root

    property string kind: "volume"
    property bool shown: false
    property bool armed: false   // ignore the burst of changes at startup

    screen: Quickshell.screens.find(s => s.name === ShellState.focusedScreen) ?? Quickshell.screens[0]
    visible: opacityAnim.running || shown
    color: "transparent"

    WlrLayershell.namespace: "ancient-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore
    anchors.bottom: true
    margins.bottom: 90
    implicitWidth: 340
    implicitHeight: 58

    function show(k) {
        if (!armed) return;
        kind = k;
        shown = true;
        hide.restart();
    }

    Timer { interval: 2500; running: true; onTriggered: root.armed = true }
    Timer { id: hide; interval: 1500; onTriggered: root.shown = false }

    Connections {
        target: Audio
        function onVolumeChanged() { root.show("volume"); }
        function onMutedChanged() { root.show("volume"); }
        function onVolumeTouched() { root.show("volume"); }
    }
    Connections {
        target: Brightness
        function onTouched() { root.show("brightness"); }
    }

    ChamferPanel {
        id: plate
        anchors.fill: parent
        opacity: root.shown ? 1 : 0
        scale: root.shown ? 1 : 0.94
        Behavior on opacity { NumberAnimation { id: opacityAnim; duration: Theme.animMid } }
        Behavior on scale { NumberAnimation { duration: Theme.animMid; easing.type: Easing.OutBack } }
        accentEdge: "bottom"
        accentColor: root.kind === "volume" ? Theme.cyan : Theme.amber

        GlyphSlider {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 16
            segments: 20
            icon: root.kind === "volume" ? Audio.icon : "light_mode"
            color: root.kind === "volume" ? (Audio.muted ? Theme.textMute : Theme.cyan) : Theme.amber
            value: root.kind === "volume" ? (Audio.muted ? 0 : Audio.volume) : Brightness.value
            onMoved: v => root.kind === "volume" ? Audio.setVolume(v) : Brightness.set(v)
        }
    }
}
