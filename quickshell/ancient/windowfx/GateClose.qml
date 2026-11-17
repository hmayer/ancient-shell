import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.services
import qs.theme

// A closing window sucked into a stargate, on one screen. The window cannot
// be drawn once it is gone, so the close runs in steps:
//   capture  the screen, as it is, while this layer is still clear
//   cover    the window's part of it is shown frozen over the window; once
//            that is on screen, Hyprland's own animation is turned off for
//            the window and it is asked to close
//   wait     until Hyprland reports it closed. An app that asks first (unsaved
//            work) keeps its window: the cover fades and nothing else happens
//   run      the gate opens over the window, swallows it and collapses
//            (shaders/gate.frag)
PanelWindow {
    id: root

    required property ShellScreen modelData
    screen: modelData

    property string phase: "idle"
    property var win: null
    readonly property int duration: 1150

    visible: phase !== "idle"
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "ancient-gate"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    mask: Region {}

    Connections {
        target: WindowClose
        function onClosing(screenName, w) {
            if (screenName === root.screen.name) root.start(w);
        }
    }

    function start(w) {
        // One at a time; another close meanwhile goes through plainly
        if (phase !== "idle") {
            Hyprland.dispatch(WindowClose.expr(w.address));
            return;
        }
        win = w;
        fx.t = 0;
        fx.time = 0;
        stage.opacity = 0;
        phase = "capture";
        watchdog.interval = 300;
        watchdog.restart();
    }

    function covered() {
        if (phase !== "capture") return;
        stage.opacity = 1;
        coverFrames = 0;
        phase = "cover";
        watchdog.restart();
    }

    function closeNow() {
        if (phase !== "cover") return;
        phase = "wait";
        WindowClose.quiet(win.address, true);
        Hyprland.dispatch(WindowClose.expr(win.address));
        watchdog.interval = 700;
        watchdog.restart();
    }

    function run() {
        watchdog.stop();
        phase = "run";
        swallow.restart();
    }

    // The window stayed (the app asked first): give it back its animation
    function abort() {
        WindowClose.quiet(win.address, false);
        phase = "abort";
        fade.restart();
    }

    function idle() {
        watchdog.stop();
        phase = "idle";
        win = null;
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (root.phase === "wait" && event.name === "closewindow"
                    && root.win && root.win.address === "0x" + event.data)
                root.run();
        }
    }

    // Close once a frame with the cover has surely reached the compositor
    property int coverFrames: 0
    Connections {
        target: root.phase === "cover" ? stage.Window.window : null
        function onFrameSwapped() {
            if (++root.coverFrames >= 3) root.closeNow();
            else stage.Window.window.update();
        }
    }

    Timer {
        id: watchdog
        onTriggered: {
            if (root.phase === "capture") {
                // No capture: close without the gate
                Hyprland.dispatch(WindowClose.expr(root.win.address));
                root.idle();
            } else if (root.phase === "cover") {
                root.closeNow();
            } else if (root.phase === "wait") {
                root.abort();
            }
        }
    }

    NumberAnimation {
        id: swallow
        target: fx
        property: "t"
        from: 0
        to: 1
        duration: root.duration
        onFinished: root.idle()
    }
    NumberAnimation {
        id: fade
        target: stage
        property: "opacity"
        to: 0
        duration: 150
        onFinished: root.idle()
    }
    FrameAnimation {
        running: root.phase === "run"
        onTriggered: fx.time += frameTime
    }

    // The screen before the close, kept as a texture for the shader
    Loader {
        id: shot
        active: root.phase !== "idle"
        sourceComponent: ScreencopyView {
            width: root.screen.width
            height: root.screen.height
            captureSource: root.screen
            live: false
            paintCursor: false
            onHasContentChanged: if (hasContent) root.covered()
        }
    }
    ShaderEffectSource {
        id: frozen
        sourceItem: shot.item
        hideSource: true
        // Kept current while in use: the capture's texture may arrive a
        // frame after it reports content
        live: root.phase !== "idle"
        width: 1
        height: 1
        visible: false
    }

    Item {
        id: stage
        anchors.fill: parent
        opacity: 0

        ShaderEffect {
            id: fx
            anchors.fill: parent
            fragmentShader: Qt.resolvedUrl("shaders/gate.frag.qsb")

            property var source: frozen
            property vector2d size: Qt.vector2d(width, height)
            property vector4d rect: root.win
                ? Qt.vector4d(root.win.x, root.win.y, root.win.width, root.win.height)
                : Qt.vector4d(0, 0, 0, 0)
            property real t: 0
            property real time: 0
            property color horizon: "#0f3f9e"
            property color rim: Theme.cyanBright
            property color stone: "#6a7378"     // steel
            property color chevron: "#ff4a14"   // chevron lamps
        }
    }
}
