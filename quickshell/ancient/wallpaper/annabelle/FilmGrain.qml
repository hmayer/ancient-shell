import QtQuick

// Old film over the scene: dust, scratches and a dark edge that flicker each
// frame. The grey comes from Annabelle's effect. 400×400 units.
Item {
    id: root
    width: 400
    height: 400

    property real amount: 0
    property int seed: 0             // a new speckle pattern each frame

    visible: amount > 0.01
    opacity: amount

    function hash(n) {
        const x = Math.sin(n * 12.9898 + 78.233) * 43758.5453;
        return x - Math.floor(x);
    }

    Repeater {
        model: 26
        Rectangle {
            required property int index
            readonly property real h: root.hash(index * 7.13 + root.seed * 1.37)
            x: root.hash(index * 3.7 + root.seed * 0.71) * 400
            y: root.hash(index * 5.1 + root.seed * 0.53) * 400
            width: 1 + h * 2.5
            height: width
            radius: width / 2
            color: index % 3 ? "#000000" : "#ffffff"
            opacity: 0.25 + h * 0.5
        }
    }
    Repeater {
        model: 2
        Rectangle {
            required property int index
            readonly property real h: root.hash(index * 11.3 + Math.floor(root.seed / 3) * 2.1)
            visible: h > 0.45
            x: h * 400
            width: 1.2
            height: 400
            color: index ? "#ffffff" : "#1a1a1a"
            opacity: 0.35
        }
    }
}
