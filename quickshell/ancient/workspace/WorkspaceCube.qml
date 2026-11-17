import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.services
import qs.theme

// Workspace switch on one screen, shown as a cube turning about the
// horizontal axis: the current workspace on one face, the next one on the
// face below it (or above, going back).
//
// The screen cannot be captured while the cube covers it, so the switch runs
// in steps:
//   capture  the screen, as it is, becomes the front face (layer still clear)
//   cover    the cube shows it, frozen; once that is on screen, Hyprland
//            switches behind it
//   turn     the cube backs away, turns and comes close again; the new face
//            (WorkspaceFace, rebuilt from its parts) fills in when Hyprland
//            reports the workspace. If it never does, the cube comes close
//            again without turning
//   leave    the cube fades onto the real workspace underneath
// The area of the bar is left out, so the bar stays still.
PanelWindow {
    id: root

    required property ShellScreen modelData
    screen: modelData

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
    readonly property var reserved: monitor?.lastIpcObject?.reserved ?? [0, 0, 0, 0]

    property string phase: "idle"
    property string dispatchExpr: ""
    property int direction: 1
    property int fromId: -1
    property HyprlandWorkspace target: null
    property var pending: null            // { kind, target } asked for while busy
    property var snapshots: ({})          // workspace id → ItemGrabResult, kept alive

    readonly property int zoomDuration: 240
    readonly property int turnDuration: 520
    readonly property int leaveDuration: 120

    visible: phase !== "idle"
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "ancient-cube"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Normal   // below the bar, not over it
    anchors { top: true; bottom: true; left: true; right: true }
    mask: Region {}                       // never takes input

    Connections {
        target: WorkspaceNav
        function onTransition(screenName, kind, target, expr, dir) {
            if (screenName === root.screen.name) root.start(kind, target, expr, dir);
        }
    }

    function start(kind, target, expr, dir) {
        // One request waits; it is asked again once the cube is done, so its
        // direction is worked out from the workspace the cube landed on
        if (phase !== "idle") {
            pending = { kind, target };
            return;
        }
        dispatchExpr = expr;
        direction = dir;
        fromId = monitor?.activeWorkspace?.id ?? -1;
        root.target = null;
        cube.progress = 0;
        cube.zoom = 0;
        stage.opacity = 0;
        phase = "capture";
        watchdog.restart();
        // Fresh bar height and window places; the replies come during capture
        Hyprland.refreshMonitors();
        Hyprland.refreshToplevels();
    }

    // The screen is captured: show it frozen
    function covered() {
        if (phase !== "capture") return;
        stage.opacity = 1;
        coverFrames = 0;
        phase = "cover";
        watchdog.restart();
    }

    // The frozen screen is up: switch behind it, back away, and keep a copy of
    // this screen for later turns to this workspace
    function switchNow() {
        if (phase !== "cover") return;
        watchdog.stop();
        phase = "turn";
        Hyprland.dispatch(dispatchExpr);
        zoomOut.restart();
        const id = fromId;
        before.item.grabToImage(result => { root.snapshots[id] = result; },
            Qt.size(Math.round(screen.width * 0.75), Math.round(screen.height * 0.75)));
    }

    function idle() {
        phase = "idle";
        target = null;
        // Forget pictures of workspaces that are gone
        const alive = Hyprland.workspaces.values.map(w => String(w.id));
        for (const id of Object.keys(snapshots))
            if (!alive.includes(id)) delete snapshots[id];
        if (pending) {
            const p = pending;
            pending = null;
            WorkspaceNav.request(p.kind, p.target);
        }
    }

    Connections {
        target: root.monitor
        function onActiveWorkspaceChanged() {
            const ws = root.monitor.activeWorkspace;
            if (root.phase === "turn" && !root.target && ws && ws.id !== root.fromId) {
                Hyprland.refreshToplevels();
                root.target = ws;
            }
        }
    }

    // Switch once a frame with the cube up has surely gone to the compositor:
    // the first frame reported may have started before the cube showed, so
    // ask for one more and switch after that
    property int coverFrames: 0
    Connections {
        target: root.phase === "cover" ? stage.Window.window : null
        function onFrameSwapped() {
            if (++root.coverFrames >= 2) root.switchNow();
            else stage.Window.window.update();
        }
    }

    // A step that stalls: no capture came (switch without the cube), or no
    // frame was reported (switch anyway)
    Timer {
        id: watchdog
        interval: 300
        onTriggered: {
            if (root.phase === "capture") {
                Hyprland.dispatch(root.dispatchExpr);
                root.idle();
            } else if (root.phase === "cover") {
                root.switchNow();
            }
        }
    }

    // Back away until the whole face shows as one side of the cube, turn,
    // then come close again until the new face fills the screen. Without a
    // new workspace by then (the switch went elsewhere), skip the turn.
    NumberAnimation {
        id: zoomOut
        target: cube
        property: "zoom"
        from: 0
        to: 1
        duration: root.zoomDuration
        easing.type: Easing.InOutQuad
        onFinished: root.target ? turnAnim.restart() : zoomIn.restart()
    }
    NumberAnimation {
        id: turnAnim
        target: cube
        property: "progress"
        from: 0
        to: 1
        duration: root.turnDuration
        easing.type: Easing.InOutCubic
        onFinished: zoomIn.restart()
    }
    NumberAnimation {
        id: zoomIn
        target: cube
        property: "zoom"
        from: 1
        to: 0
        duration: root.zoomDuration
        easing.type: Easing.InOutQuad
        onFinished: {
            root.phase = "leave";
            leaveAnim.restart();
        }
    }
    NumberAnimation {
        id: leaveAnim
        target: stage
        property: "opacity"
        to: 0
        duration: root.leaveDuration
        easing.type: Easing.OutQuad
        onFinished: root.idle()
    }

    // The wallpaper of the new face, decoded ahead of time: decoding it when the
    // turn starts would stall the first frames
    Image {
        visible: false
        asynchronous: true
        source: Wallpapers.current ? "file://" + Wallpapers.current : ""
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: root.screen.width
        sourceSize.height: root.screen.height
    }

    Item {
        id: stage
        anchors.fill: parent
        opacity: 0

        Rectangle {
            anchors.fill: parent
            color: Theme.void_
        }
        Cube {
            id: cube
            anchors.fill: parent
            direction: root.direction

            from: Loader {
                id: before
                active: root.phase !== "idle"
                sourceComponent: ScreencopyView {
                    x: -root.reserved[0]
                    y: -root.reserved[1]
                    width: root.screen.width
                    height: root.screen.height
                    captureSource: root.screen
                    live: false
                    paintCursor: false
                    onHasContentChanged: if (hasContent) root.covered()
                }
            }

            to: Loader {
                anchors.fill: parent
                active: root.phase === "turn" || root.phase === "leave"
                sourceComponent: WorkspaceFace {
                    screen: root.screen
                    workspace: root.target
                    snapshot: root.target ? (root.snapshots[root.target.id]?.url ?? "") : ""
                    offsetX: root.reserved[0]
                    offsetY: root.reserved[1]
                }
            }
        }
    }
}
