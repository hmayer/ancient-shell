pragma Singleton

import QtQuick
import Quickshell

// Ancient console palette.
// Base: the charcoal stone of the Earth point-of-origin wallpaper.
// Primary: the cyan light of a dialed glyph / control crystal.
// Accent: the amber and bronze of the Atlantis consoles.
Singleton {
    id: root

    // ── Stone (backgrounds) ───────────────────────────────
    readonly property color void_:     "#07090a"
    readonly property color stone0:    "#0b0f11"   // deepest panel
    readonly property color stone1:    "#11171a"   // panel
    readonly property color stone2:    "#182125"   // raised element
    readonly property color stone3:    "#212c31"   // hover
    readonly property color panel:     Qt.rgba(0.043, 0.059, 0.067, 0.84)
    readonly property color panelSolid: stone0

    // ── Lines (engraved hairlines) ────────────────────────
    readonly property color line:      "#26343a"
    readonly property color lineBright: "#3a4d55"

    // ── Glyph light (primary) ─────────────────────────────
    readonly property color cyan:       "#30c6de"
    readonly property color cyanBright: "#8ceaf7"
    readonly property color cyanMid:    "#2093ae"
    readonly property color cyanDeep:   "#133849"
    readonly property color cyanGlow:   Qt.rgba(0.188, 0.776, 0.871, 0.55)

    // ── Atlantis console (accent) ─────────────────────────
    readonly property color amber:       "#e8a33d"
    readonly property color amberBright: "#ffd08a"
    readonly property color bronze:      "#9a7348"
    readonly property color amberDeep:   "#3d2a10"
    readonly property color amberGlow:   Qt.rgba(0.91, 0.64, 0.24, 0.5)

    // ── States ────────────────────────────────────────────
    readonly property color dome:     "#e5533d"   // DHD centre dome, critical
    readonly property color crystal:  "#5fd3a1"   // control crystal green, success
    readonly property color yellow:   "#f3c74a"   // something waits for you (upgrades)

    // ── Text ──────────────────────────────────────────────
    readonly property color text:     "#d5e3e7"
    readonly property color textDim:  "#8ea2a9"
    readonly property color textMute: "#55676e"

    // ── Fonts ─────────────────────────────────────────────
    readonly property string fontDisplay: orbitron.status === FontLoader.Ready ? orbitron.name : "sans-serif"
    readonly property string fontUi: rajdhani.status === FontLoader.Ready ? rajdhani.name : "sans-serif"
    readonly property string fontMono: "FiraCode Nerd Font"
    readonly property string fontIcon: "Material Symbols Rounded"

    // ── Metrics ───────────────────────────────────────────
    readonly property int barHeight: 40
    readonly property int gap: 8          // distance from screen edge
    readonly property int cut: 10         // chamfer size of panels
    readonly property int cutSmall: 6
    readonly property int pad: 14
    readonly property int radius: 4

    // ── Motion ────────────────────────────────────────────
    readonly property int animFast: 140
    readonly property int animMid: 260
    readonly property int animSlow: 420

    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    FontLoader { id: orbitron; source: Qt.resolvedUrl("../assets/fonts/Orbitron-Variable.ttf") }
    FontLoader { id: rajdhani; source: Qt.resolvedUrl("../assets/fonts/Rajdhani-SemiBold.ttf") }
    FontLoader { source: Qt.resolvedUrl("../assets/fonts/Rajdhani-Medium.ttf") }
    FontLoader { source: Qt.resolvedUrl("../assets/fonts/Rajdhani-Bold.ttf") }
}
