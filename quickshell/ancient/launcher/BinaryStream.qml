import QtQuick
import qs.theme

// Columns of binary scrolling up, as on the dialing computer's left panel.
Item {
    id: root
    property bool running: false
    property int lines: 14
    property real speed: 1           // >1 while dialing

    clip: true

    function randomLine() {
        let s = "";
        const n = 10 + Math.floor(Math.random() * 7);
        for (let i = 0; i < n; i++) s += Math.random() > 0.5 ? "1" : "0";
        return s;
    }

    property var buffer: {
        const b = [];
        for (let i = 0; i < 40; i++) b.push(randomLine());
        return b;
    }

    Timer {
        interval: Math.max(40, 160 / root.speed)
        running: root.running
        repeat: true
        onTriggered: root.buffer = [...root.buffer.slice(1), root.randomLine()]
    }

    // Glow band, like the teal highlight on the SGC screen
    Rectangle {
        y: parent.height * 0.42
        width: parent.width
        height: parent.height * 0.28
        gradient: Gradient {
            GradientStop { position: 0; color: "transparent" }
            GradientStop { position: 0.5; color: Theme.alpha(Theme.cyan, 0.10) }
            GradientStop { position: 1; color: "transparent" }
        }
    }

    Text {
        anchors.fill: parent
        anchors.margins: 6
        font.family: Theme.fontMono
        font.pixelSize: 11
        lineHeight: 1.15
        color: Theme.alpha(Theme.cyan, 0.7)
        text: root.buffer.slice(0, root.lines).join("\n")
    }
}
