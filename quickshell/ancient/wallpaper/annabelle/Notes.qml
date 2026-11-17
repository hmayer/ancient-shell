import QtQuick

// Musical notes floating up from whoever sings: Annabelle, or the bird.
// 400×400 units.
Item {
    id: root
    width: 400
    height: 400

    readonly property real life: 1.6

    function spawn(x, y) {
        for (let i = 0; i < rep.count; i++) {
            const n = rep.itemAt(i);
            if (n.age < 0) {
                n.x0 = x;
                n.y0 = y;
                n.drift = -10 - Math.random() * 14;
                n.text = Math.random() < 0.5 ? "♪" : "♫";
                n.age = 0;
                return;
            }
        }
    }

    function step(dt) {
        for (let i = 0; i < rep.count; i++) {
            const n = rep.itemAt(i);
            if (n.age < 0) continue;
            n.age += dt;
            if (n.age > life) n.age = -1;
        }
    }

    Repeater {
        id: rep
        model: 8
        Text {
            property real age: -1
            property real x0: 0
            property real y0: 0
            property real drift: -12
            visible: age >= 0
            x: x0 + drift * age + Math.sin(age * 6) * 3 - width / 2
            y: y0 - 30 * age - height / 2
            opacity: age < 0 ? 0 : Math.min(1, (root.life - age) / 0.5)
            scale: 0.6 + Math.min(0.4, age * 1.5)
            font.pixelSize: 17
            font.bold: true
            color: "#ffffff"
            style: Text.Outline
            styleColor: "#14141c"
        }
    }
}
