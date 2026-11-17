import QtQuick
import QtQuick.Effects
import QtQuick.Shapes

// Annabelle the sheep, after the RealPlayer visualization of the early 2000s,
// in a round window: she listens to the music with you and dances to it
// (Dancer), while the scene around her changes at random, with no set order
// (Scenery), her look changes with it, and now and then a visitor drops by:
// a UFO that lifts her in its beam, a beach ball bouncing on her back on the
// beats, a bird riding her back, a blimp with the spectrum on its side.
//
// A square item; everything inside is drawn at 400×400 units and scaled up,
// so it stays sharp at any size. Fed by the Visualizer: the spectrum, the
// beats (beat()) and whether a line of the lyrics is being sung.
Item {
    id: root

    // ── What is playing ───────────────────────────────────
    property var bars: []
    property real level: 0
    property real bass: 0
    property real kick: 0
    property real gain: 1
    property bool lyricLine: false
    property string track: ""
    property bool running: visible
    property bool manual: false       // stepped from outside instead of every frame

    // Her sense of the music (tempo, drive), for previews
    readonly property alias dancer: dancer

    function beat(strength) {
        dancer.beat(strength);
    }

    // ── What is on, picked at random ──────────────────────
    property string scene: "day"
    property string look: "classic"
    property var outfit: ({})
    property string visitor: ""
    property real flash: 0
    property real hue: 0.6
    property real flicker: 0
    property int frame: 0

    readonly property var looks: ({
        classic: {},
        techno: { glasses: true, tattoo: "peace" },
        anarchy: { tattoo: "anarchy" },
        showtime: { hat: true, mic: true },
        punk: { punk: true },
        beret: { beret: true }
    })

    // Visitors each scene may get, and how likely
    readonly property var visitors: ({
        day: { ufo: 1, ball: 1.3, bird: 1.1, blimp: 0.8 },
        night: { ufo: 1.6, ball: 0.4, blimp: 0.6 },
        disco: { ufo: 0.8, ball: 1.4, bird: 0.3 },
        psy: { ufo: 1, ball: 1, bird: 0.8, blimp: 0.8 },
        film: { ufo: 1, ball: 0.6, bird: 1, blimp: 1 }
    })

    property var dir: ({ sceneT: 0, dwell: 22, visitorIn: 7, lastBeat: 0 })

    function weighted(w) {
        let sum = 0;
        for (const k in w) sum += w[k];
        let r = Math.random() * sum;
        for (const k in w) {
            r -= w[k];
            if (r <= 0) return k;
        }
        return Object.keys(w)[0];
    }

    // Wardrobe: a look, sometimes with glasses or a tattoo on top
    function dress(name) {
        const o = Object.assign({}, looks[name] ?? {});
        if (!o.glasses && Math.random() < 0.2) o.glasses = true;
        if (!o.tattoo && Math.random() < 0.2) o.tattoo = Math.random() < 0.5 ? "anarchy" : "peace";
        look = name;
        outfit = o;
    }

    function changeScene(to) {
        const v = dancer.drive;
        const w = { day: 3, night: 1.4 + (1 - v) * 2, disco: 0.8 + v * 2.2, psy: 0.5 + v * 2, film: 1 };
        delete w[scene];
        scene = to ?? weighted(w);
        dir.sceneT = 0;
        dir.dwell = 16 + Math.random() * 20;
        flash = 1;
        if (Math.random() < 0.55) {
            const l = Object.assign({}, looks);
            delete l[look];
            const names = Object.keys(l);
            dress(names[Math.floor(Math.random() * names.length)]);
        }
    }

    function startVisitor(name) {
        visitor = name ?? weighted(visitors[scene]);
        if (visitor === "ufo") ufo.start();
        else if (visitor === "ball") ball.start((1 - (dancer.phase - Math.floor(dancer.phase))) * dancer.period, dancer.period);
        else if (visitor === "bird") bird.start(6 + Math.random() * 5);
        else blimp.start();
    }

    // Where something is, as a look direction for her eyes
    function lookAt(x, y) {
        const e = sheep.eyeAnchor.mapToItem(stage, 0, 0);
        dancer.lookX = Math.max(-1, Math.min(1, (x - e.x) / 60));
        dancer.lookY = Math.max(-1, Math.min(1, (y - e.y) / 60));
        dancer.watching = true;
    }

    function step(dt) {
        dt = Math.max(0.001, Math.min(dt, 0.05));
        frame++;
        const D = dir;

        // A new scene on a downbeat, once this one has had its time and
        // nobody is visiting
        D.sceneT += dt;
        const b = Math.floor(dancer.phase);
        const downbeat = b !== D.lastBeat && b % 4 === 0;
        D.lastBeat = b;
        if (D.sceneT > D.dwell && (visitor === "" || visitor === "blimp") && (downbeat || D.sceneT > D.dwell + 6))
            changeScene();

        if (visitor === "") {
            D.visitorIn -= dt;
            if (D.visitorIn <= 0) startVisitor();
        }
        ufo.step(dt);
        ball.step(dt);
        blimp.step(dt);
        if (visitor !== "" && !ufo.active && !ball.active && !bird.active && !blimp.active) {
            visitor = "";
            D.visitorIn = 8 + Math.random() * 14;
        }

        // Her eyes follow whoever is visiting
        dancer.watching = false;
        if (ufo.active && ufo.t < 7.8) lookAt(ufo.ux, ufo.uy);
        else if (ball.active) lookAt(ball.bx, ball.by);
        else if (bird.active && (!bird.perched || bird.t < bird.arrive + 1.2)) lookAt(bird.bx, bird.by);
        else if (blimp.active && blimp.bx > 60 && blimp.bx < 340 && Math.sin(blimp.t * 0.9) > 0) lookAt(blimp.bx, blimp.by);
        dancer.abduct = ufo.lift;

        dancer.step(dt);

        const back = sheep.backAnchor.mapToItem(stage, 0, 0);
        ball.backX = back.x;
        ball.backY = back.y;
        bird.perchX = back.x;
        bird.perchY = back.y;
        bird.step(dt);

        hue = (hue + dt * (0.04 + kick * 0.25)) % 1;
        scenery.step(dt);
        notes.step(dt);
        flash *= Math.exp(-dt * 5);
        flicker = (Math.random() - 0.5) * 0.12;
    }

    // Only while her clock runs, so the frames she counts match the time she keeps
    onBarsChanged: if (running || manual) dancer.listen(bars)
    onTrackChanged: if (track !== "") dancer.surprise()
    Component.onCompleted: {
        changeScene(["day", "day", "night", "disco"][Math.floor(Math.random() * 4)]);
        flash = 0;
        const names = Object.keys(looks);
        dress(names[Math.floor(Math.random() * names.length)]);
    }

    FrameAnimation {
        running: root.running && !root.manual
        onTriggered: root.step(frameTime)
    }

    Dancer {
        id: dancer
        bars: root.bars
        level: root.level * Math.min(1.4, 0.6 + 0.4 * root.gain)
        lyricLine: root.lyricLine
        mic: root.outfit.mic ?? false
        punk: root.outfit.punk ?? false
        onSang: {
            const p = sheep.mouthAnchor.mapToItem(stage, 0, 0);
            notes.spawn(p.x - 6, p.y - 8);
        }
    }

    // ── The scene, drawn at 400×400 and scaled to the item ──
    // Drawn only through the round mask below. (hideSource rather than
    // visible: false, which would freeze items that show up later.)
    Item {
        id: view
        anchors.fill: parent

        Item {
            id: stage
            width: 400
            height: 400
            scale: root.width / 400
            transformOrigin: Item.TopLeft

            Scenery {
                id: scenery
                scene: root.scene
                phase: dancer.phase
                kick: root.kick
                bass: root.bass
                high: root.bars.length >= 64 ? (root.bars[40] + root.bars[48] + root.bars[56]) / 3 : 0
                air: dancer.air
                hue: root.hue
            }
            Blimp {
                id: blimp
                bars: root.bars
                night: root.scene === "night"
            }
            Sheep {
                id: sheep
                x: 78
                y: 96
                scale: 1.12
                transformOrigin: Item.Bottom
                air: dancer.air
                bob: dancer.bob
                sway: dancer.sway
                tilt: dancer.tilt
                squash: dancer.squash
                nod: dancer.nod
                earBack: dancer.earBack
                earFront: dancer.earFront
                lidL: dancer.lidL
                lidR: dancer.lidR
                eyeScale: dancer.eyeScale
                pupilX: dancer.pupilX
                pupilY: dancer.pupilY
                cross: dancer.cross
                mouth: dancer.mouth
                mouthRound: dancer.mouthRound
                tongue: dancer.tongue
                tap0: dancer.tap0
                tap1: dancer.tap1
                tap2: dancer.tap2
                tap3: dancer.tap3
                dangle: dancer.dangle
                hair: dancer.hair
                glasses: root.outfit.glasses ?? false
                hat: root.outfit.hat ?? false
                mic: root.outfit.mic ?? false
                punk: root.outfit.punk ?? false
                beret: root.outfit.beret ?? false
                tattoo: root.outfit.tattoo ?? ""
            }
            DiscoLights {
                amount: scenery.discoAmt
                phase: amount > 0.01 ? dancer.phase : 0
                kick: amount > 0.01 ? root.kick : 0
                drive: dancer.drive
            }
            Ufo {
                id: ufo
                phase: dancer.phase
            }
            BeachBall {
                id: ball
                onHit: dancer.bonk()
            }
            Bird {
                id: bird
                phase: dancer.phase
                onChirp: (x, y) => notes.spawn(x, y)
            }
            Notes {
                id: notes
            }
            FilmGrain {
                amount: scenery.filmAmt
                seed: amount > 0.01 ? root.frame : 0
            }

            // A darker rim, like looking through a porthole
            Shape {
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeColor: "transparent"
                    fillGradient: RadialGradient {
                        centerX: 200; centerY: 200; centerRadius: 200
                        focalX: 200; focalY: 200
                        GradientStop { position: 0.72; color: "transparent" }
                        GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0.32 + scenery.filmAmt * 0.3) }
                    }
                    PathSvg { path: "M 0 0 L 400 0 L 400 400 L 0 400 Z" }
                }
            }

            // A flash hides the change of scene and of clothes
            Rectangle {
                anchors.fill: parent
                color: "white"
                opacity: root.flash * 0.75
                visible: opacity > 0.01
            }
        }
    }

    ShaderEffectSource {
        id: viewTexture
        anchors.fill: parent
        sourceItem: view
        hideSource: true
        live: true
        visible: false
    }

    Rectangle {
        id: mask
        anchors.fill: parent
        radius: width / 2
        visible: false
        layer.enabled: true
        antialiasing: true
    }

    MultiEffect {
        anchors.fill: parent
        source: viewTexture
        maskEnabled: true
        maskSource: mask
        maskThresholdMin: 0.3
        maskSpreadAtMin: 0.4
        saturation: -scenery.filmAmt
        brightness: scenery.filmAmt * root.flicker
    }
}
