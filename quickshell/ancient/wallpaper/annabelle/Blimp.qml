import QtQuick

// A blimp drifting across the sky, its side screen showing the live spectrum.
// 400×400 units.
Item {
    id: root
    width: 400
    height: 400

    property var bars: []
    property real t: -1
    property bool night: false
    readonly property real duration: 17
    readonly property bool active: t >= 0 && t < duration
    readonly property real bx: 460 - t * (580 / duration)
    readonly property real by: 64 + Math.sin(t * 0.8) * 3

    visible: active

    function start() {
        t = 0;
    }
    function step(dt) {
        if (t >= 0) t = t < duration ? t + dt : -1;
    }

    Item {
        x: root.bx
        y: root.by

        // Tail fins
        Rectangle { x: 34; y: -20; width: 16; height: 12; radius: 3; rotation: -20; color: "#c3c9d4"; border.color: "#454b56"; border.width: 1.2; antialiasing: true }
        Rectangle { x: 34; y: 8; width: 16; height: 12; radius: 3; rotation: 20; color: "#aab1be"; border.color: "#454b56"; border.width: 1.2; antialiasing: true }
        // Envelope
        Rectangle {
            x: -50; y: -17
            width: 100; height: 34
            radius: 17
            antialiasing: true
            border.color: "#454b56"
            border.width: 1.4
            gradient: Gradient {
                GradientStop { position: 0; color: "#f6f7fa" }
                GradientStop { position: 0.6; color: "#c9ced8" }
                GradientStop { position: 1; color: "#8d95a3" }
            }
        }
        // Gondola
        Rectangle { x: -14; y: 15; width: 26; height: 8; radius: 3; color: "#5d6472"; border.color: "#353a44"; border.width: 1; antialiasing: true }
        // Screen with the spectrum
        Rectangle {
            x: -22; y: -9
            width: 40; height: 18
            radius: 2
            color: "#101418"
            border.color: "#353a44"
            border.width: 1
            Row {
                x: 3
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 2
                spacing: 1
                Repeater {
                    model: 8
                    Rectangle {
                        required property int index
                        readonly property real v: root.bars.length >= 64 ? root.bars[2 + index * 7] : 0
                        anchors.bottom: parent.bottom
                        width: 3.5
                        height: 1 + Math.min(1, v * 1.3) * 13
                        color: v > 0.7 ? "#ff4a3d" : v > 0.45 ? "#ffd23a" : "#3ee05a"
                    }
                }
            }
        }
        // Nose light, blinking at night
        Rectangle {
            x: -54; y: -3
            width: 6; height: 6
            radius: 3
            color: "#ff5b4a"
            visible: root.night && Math.floor(root.t * 2) % 2 === 0
            antialiasing: true
        }
    }
}
