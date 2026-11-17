import QtQuick
import QtQuick.Shapes
import qs.theme
import qs.widgets

// A small animated picture of the weather: sun or moon, white clouds, grey
// clouds with rain or snow, dark clouds with lightning, fog. `animate` stops
// the motion when nobody can see it.
Item {
    id: root

    property string kind: "clear"   // clear, partly, cloudy, fog, drizzle, rain, snow, storm
    property bool day: true
    property bool animate: true

    implicitWidth: 120
    implicitHeight: 96

    readonly property color white: "#eef3f4"
    readonly property color light: "#c3cdd0"
    readonly property color grey: "#8b989d"
    readonly property color dark: "#55636a"
    readonly property color darker: "#3b454a"

    Loader {
        anchors.fill: parent
        sourceComponent: ({
            clear: clearScene, partly: partlyScene, cloudy: cloudyScene, fog: fogScene,
            drizzle: drizzleScene, rain: rainScene, snow: snowScene, storm: stormScene
        })[root.kind] ?? cloudyScene
    }

    // ── Scenes ───────────────────────────────────────
    Component {
        id: clearScene
        Item {
            Sun { visible: root.day; anchors.centerIn: parent }
            Moon { visible: !root.day; anchors.centerIn: parent }
        }
    }
    Component {
        id: partlyScene
        Item {
            Sun { visible: root.day; x: 8; y: 2; scale: 0.8 }
            Moon { visible: !root.day; x: 12; y: 4; scale: 0.8 }
            Cloud { x: 32; y: 40; color: root.white; drift: 5 }
        }
    }
    Component {
        id: cloudyScene
        Item {
            Cloud { x: 6; y: 14; scale: 0.8; color: root.light; drift: 4; period: 5200 }
            Cloud { x: 34; y: 36; color: root.white; drift: 6 }
        }
    }
    Component {
        id: fogScene
        Item {
            Cloud { x: 20; y: 6; color: root.grey; drift: 3 }
            Repeater {
                model: 3
                Rectangle {
                    required property int index
                    x: 14 + index * 6
                    y: 60 + index * 11
                    width: 92 - index * 12
                    height: 6
                    radius: 3
                    color: Theme.alpha(root.light, 0.55 - index * 0.1)
                    SequentialAnimation on x {
                        running: root.animate
                        loops: Animation.Infinite
                        NumberAnimation { to: 22 + index * 6; duration: 2600 + index * 700; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 6 + index * 6; duration: 2600 + index * 700; easing.type: Easing.InOutSine }
                    }
                }
            }
        }
    }
    Component {
        id: drizzleScene
        Item {
            Drops { x: 34; y: 50; count: 5; length: 6; speed: 1100; color: Theme.alpha(Theme.cyanBright, 0.7) }
            Cloud { x: 20; y: 8; color: root.grey; drift: 4 }
        }
    }
    Component {
        id: rainScene
        Item {
            Drops { x: 26; y: 50; count: 9; length: 11; speed: 650 }
            Cloud { x: 4; y: 10; scale: 0.8; color: root.dark; drift: 3; period: 5400 }
            Cloud { x: 24; y: 18; color: root.grey; drift: 5 }
        }
    }
    Component {
        id: snowScene
        Item {
            Flakes { x: 26; y: 48 }
            Cloud { x: 20; y: 8; color: root.light; drift: 4 }
        }
    }
    Component {
        id: stormScene
        Item {
            Drops { x: 24; y: 50; count: 8; length: 12; speed: 520 }
            Bolt { x: 52; y: 42 }
            Cloud { x: 2; y: 8; scale: 0.85; color: root.darker; drift: 3; period: 4800 }
            Cloud { x: 26; y: 16; color: root.dark; drift: 5 }
        }
    }

    // ── Parts ────────────────────────────────────────
    // Sun: an amber disc in a breathing halo, rays turning slowly
    component Sun: Item {
        width: 64; height: 64
        Rectangle {
            id: halo
            anchors.centerIn: parent
            width: 48; height: 48; radius: 24
            color: Theme.alpha(Theme.amber, 0.22)
            SequentialAnimation on scale {
                running: root.animate
                loops: Animation.Infinite
                NumberAnimation { to: 1.18; duration: 1800; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.92; duration: 1800; easing.type: Easing.InOutSine }
            }
        }
        Item {
            anchors.fill: parent
            RotationAnimation on rotation {
                running: root.animate
                loops: Animation.Infinite
                from: 0; to: 360
                duration: 24000
            }
            Repeater {
                model: 8
                Rectangle {
                    required property int index
                    x: parent.width / 2 - width / 2
                    y: 1
                    width: 3; height: 9; radius: 1.5
                    color: Theme.amberBright
                    transform: Rotation { origin.x: 1.5; origin.y: 31; angle: index * 45 }
                }
            }
        }
        Rectangle {
            anchors.centerIn: parent
            width: 30; height: 30; radius: 15
            gradient: Gradient {
                GradientStop { position: 0; color: Theme.amberBright }
                GradientStop { position: 1; color: Theme.amber }
            }
        }
    }

    // Moon: a pale crescent with stars blinking around it
    component Moon: Item {
        width: 64; height: 64
        MIcon {
            anchors.centerIn: parent
            text: "dark_mode"
            filled: true
            size: 42
            color: "#dfe8ea"
            rotation: -20
        }
        Repeater {
            model: [[6, 10, 2400], [52, 6, 3100], [56, 44, 2000], [10, 50, 2800]]
            Rectangle {
                required property var modelData
                x: modelData[0]; y: modelData[1]
                width: 4; height: 4
                rotation: 45
                color: Theme.cyanBright
                SequentialAnimation on opacity {
                    running: root.animate
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.15; duration: modelData[2] / 2; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1; duration: modelData[2] / 2; easing.type: Easing.InOutSine }
                }
            }
        }
    }

    // Cloud: a few puffs on a rounded base, swaying sideways
    component Cloud: Item {
        id: cloud
        property color color: root.white
        property real drift: 5
        property int period: 4200
        width: 80; height: 48
        transform: Translate { id: sway }
        SequentialAnimation {
            running: root.animate
            loops: Animation.Infinite
            NumberAnimation { target: sway; property: "x"; to: cloud.drift; duration: cloud.period; easing.type: Easing.InOutSine }
            NumberAnimation { target: sway; property: "x"; to: -cloud.drift; duration: cloud.period; easing.type: Easing.InOutSine }
        }
        Rectangle { x: 6; y: 24; width: 68; height: 24; radius: 12; color: cloud.color }
        Rectangle { x: 10; y: 12; width: 30; height: 30; radius: 15; color: cloud.color }
        Rectangle { x: 26; y: 0; width: 38; height: 38; radius: 19; color: cloud.color }
        Rectangle { x: 46; y: 10; width: 28; height: 28; radius: 14; color: cloud.color }
    }

    // Rain: slanted streaks falling from under the cloud
    component Drops: Item {
        id: drops
        property int count: 8
        property real length: 10
        property int speed: 700
        property color color: Theme.alpha(Theme.cyanBright, 0.85)
        width: 70; height: 46
        Repeater {
            model: drops.count
            Rectangle {
                id: drop
                required property int index
                x: (index * 37) % drops.width
                width: 2; height: drops.length; radius: 1
                rotation: 14
                color: drops.color
                opacity: 0
                SequentialAnimation {
                    running: root.animate
                    loops: Animation.Infinite
                    PauseAnimation { duration: (drop.index * 173) % drops.speed }
                    ParallelAnimation {
                        NumberAnimation { target: drop; property: "y"; from: 0; to: drops.height - drops.length; duration: drops.speed }
                        SequentialAnimation {
                            NumberAnimation { target: drop; property: "opacity"; from: 0; to: 1; duration: drops.speed * 0.2 }
                            PauseAnimation { duration: drops.speed * 0.5 }
                            NumberAnimation { target: drop; property: "opacity"; to: 0; duration: drops.speed * 0.3 }
                        }
                    }
                }
            }
        }
    }

    // Snow: flakes drifting down, swaying
    component Flakes: Item {
        id: flakes
        width: 70; height: 48
        Repeater {
            model: 8
            Rectangle {
                id: flake
                required property int index
                x: (index * 29) % flakes.width
                width: 5; height: 5; radius: 2.5
                color: root.white
                opacity: 0
                transform: Translate { id: swing }
                SequentialAnimation {
                    running: root.animate
                    loops: Animation.Infinite
                    PauseAnimation { duration: (flake.index * 311) % 2400 }
                    ParallelAnimation {
                        NumberAnimation { target: flake; property: "y"; from: 0; to: flakes.height - 5; duration: 2400 }
                        SequentialAnimation {
                            NumberAnimation { target: swing; property: "x"; to: 4; duration: 600; easing.type: Easing.InOutSine }
                            NumberAnimation { target: swing; property: "x"; to: -4; duration: 1200; easing.type: Easing.InOutSine }
                            NumberAnimation { target: swing; property: "x"; to: 0; duration: 600; easing.type: Easing.InOutSine }
                        }
                        SequentialAnimation {
                            NumberAnimation { target: flake; property: "opacity"; from: 0; to: 1; duration: 400 }
                            PauseAnimation { duration: 1400 }
                            NumberAnimation { target: flake; property: "opacity"; to: 0; duration: 600 }
                        }
                    }
                }
            }
        }
    }

    // Lightning: a bolt that strikes now and then, twice in a row
    component Bolt: Item {
        id: bolt
        width: 24; height: 40
        opacity: 0
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                fillColor: Theme.amberBright
                strokeColor: "white"
                strokeWidth: 1
                PathPolyline {
                    path: [Qt.point(14, 0), Qt.point(2, 22), Qt.point(11, 22), Qt.point(6, 40),
                        Qt.point(22, 14), Qt.point(13, 14), Qt.point(19, 0), Qt.point(14, 0)]
                }
            }
        }
        SequentialAnimation {
            running: root.animate
            loops: Animation.Infinite
            PauseAnimation { duration: 2600 }
            NumberAnimation { target: bolt; property: "opacity"; to: 1; duration: 40 }
            NumberAnimation { target: bolt; property: "opacity"; to: 0.2; duration: 80 }
            NumberAnimation { target: bolt; property: "opacity"; to: 1; duration: 40 }
            NumberAnimation { target: bolt; property: "opacity"; to: 0; duration: 260 }
            PauseAnimation { duration: 1700 }
            NumberAnimation { target: bolt; property: "opacity"; to: 1; duration: 40 }
            NumberAnimation { target: bolt; property: "opacity"; to: 0; duration: 300 }
        }
    }
}
