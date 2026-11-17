import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.splash
import qs.theme

// Boot splash, run as its own instance next to the shell:
//     qs -p ~/.config/quickshell/ancient/splash.qml -d
// It dials the gate while the shell loads, locks the seventh chevron and opens
// the wormhole once the shell answers on IPC, then dives into it and quits.
// A click (or `ipc call splash skip`) closes it early.
ShellRoot {
    id: root

    property int encoded: 0          // chevrons 1–6
    property real spin: 0            // glyph track rotation
    property bool shellReady: false
    property bool locked: false      // 7th chevron
    property bool opened: false      // wormhole fully open
    property bool failed: false      // the shell never answered
    property bool leaving: false     // diving into the horizon
    property int elapsed: 0          // seconds since the splash appeared

    readonly property int openDuration: 1600
    readonly property int leaveDuration: 950
    readonly property int giveUpAfter: 90   // seconds

    readonly property var status: {
        if (failed) return { text: I18n.tr("DIALING FAILED"), color: Theme.dome };
        if (opened) return { text: I18n.tr("WORMHOLE ESTABLISHED"), color: Theme.cyanBright };
        if (locked) return { text: I18n.tr("CHEVRON 7 LOCKED"), color: Theme.amber };
        if (encoded === 0) return { text: I18n.tr("INITIATING DIALING"), color: Theme.textDim };
        if (encoded === 6 && !shellReady) return { text: I18n.tr("CHEVRON 7 · WAITING"), color: Theme.amber };
        return { text: I18n.tr("CHEVRON %1 ENCODED", encoded), color: Theme.cyan };
    }

    // Where the wormhole connects, drawn when the splash starts. Names that
    // languages spell differently go through I18n.
    readonly property var destinations: [
        { name: "Abydos", note: I18n.tr("The desert world where it all began.") },
        { name: "Chulak", note: I18n.tr("Teal'c's homeworld.") },
        { name: "Dakara", note: I18n.tr("The sacred temple of the Jaffa.") },
        { name: "Cimmeria", note: I18n.tr("Protected by Thor's Hammer.") },
        { name: "Tollana", note: I18n.tr("Home of the Tollan.") },
        { name: "Langara", note: I18n.tr("Kelowna and its naquadria.") },
        { name: I18n.tr("Heliopolis"), note: I18n.tr("The meeting hall of the four races.") },
        { name: "Kheb", note: I18n.tr("Where Oma Desala taught ascension.") },
        { name: "Edora", note: I18n.tr("Beware of the meteor shower.") },
        { name: "Argos", note: I18n.tr("The nanites speed up aging: do not linger.") },
        { name: "Netu", note: I18n.tr("Sokar's prison moon.") },
        { name: "P3X-888", note: I18n.tr("Homeworld of the Unas and cradle of the Goa'uld.") },
        { name: I18n.tr("Atlantis"), note: I18n.tr("The city of the Ancients, in the Pegasus galaxy.") }
    ]
    readonly property var destination: destinations[Math.floor(Math.random() * destinations.length)]

    // System notification naming the destination. Only once the shell is up:
    // with no notification server on the bus, notify-send would D-Bus-activate
    // swaync and it would keep org.freedesktop.Notifications from the shell.
    property bool announced: false
    function announce() {
        if (announced || !shellReady || failed) return;
        announced = true;
        Quickshell.execDetached(["notify-send",
            "-a", I18n.tr("Stargate Command"),
            "-h", "string:image-path:" + Quickshell.shellPath("assets/origin.svg"),
            I18n.tr("Wormhole established"),
            I18n.tr("Destination: %1 · %2", destination.name, destination.note)]);
    }

    function leave() {
        if (leaving) return;
        leaving = true;
        announce();
        quitTimer.start();
    }

    Variants {
        model: Quickshell.screens
        SplashWindow { ctl: root }
    }

    // Each tick encodes a chevron; the track turns the other way for the next
    // one. With all six encoded it keeps turning until the shell answers.
    Timer {
        running: !root.locked && !root.failed
        interval: root.shellReady ? 240 : 620
        repeat: true
        onTriggered: {
            if (root.encoded < 6) {
                root.encoded++;
                root.spin += (root.encoded % 2 ? 1 : -1) * (70 + Math.random() * 60);
            } else if (root.shellReady) {
                root.locked = true;
                openTimer.start();
            } else {
                root.spin += 40;
            }
        }
    }

    Timer {
        id: openTimer
        interval: root.openDuration
        onTriggered: {
            root.opened = true;
            root.announce();
            leaveTimer.start();
        }
    }
    Timer {
        id: leaveTimer
        interval: 450
        onTriggered: root.leave()
    }
    Timer {
        id: quitTimer
        interval: root.leaveDuration + 50
        onTriggered: Qt.quit()
    }

    Timer {
        running: !root.leaving
        interval: 1000
        repeat: true
        onTriggered: {
            root.elapsed++;
            if (root.elapsed >= root.giveUpAfter && !root.shellReady && !root.failed) {
                root.failed = true;
                leaveTimer.interval = 2500;
                leaveTimer.start();
            }
        }
    }

    // The shell is ready once its IPC targets exist, which happens when its
    // config has loaded and the bar is being mapped.
    Timer {
        running: !root.shellReady && !root.failed
        interval: root.elapsed < 10 ? 400 : 1500
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!probe.running) probe.running = true
    }
    Process {
        id: probe
        command: ["qs", "-p", Quickshell.shellPath("shell.qml"), "ipc", "show"]
        stdout: StdioCollector {
            onStreamFinished: if (text.includes("target shell")) root.shellReady = true
        }
    }

    // `qs -p ~/.config/quickshell/ancient/splash.qml ipc call splash <function>`
    IpcHandler {
        target: "splash"

        function ready(): void { root.shellReady = true; }
        function skip(): void { root.leave(); }
    }
}
