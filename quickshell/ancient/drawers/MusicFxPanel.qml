import QtQuick
import qs.services
import qs.theme
import qs.widgets

// Music effects, the back of the media player: how strongly the desktop moves
// with the music, which visualizer it draws, the lyrics and the wallpaper
// effects. Settings live in MusicFx and are kept between sessions.
Column {
    id: root

    readonly property var opts: MusicFx.settings
    signal back()

    spacing: 12

    // ── Header ───────────────────────────────────────
    Item {
        width: parent.width
        height: 22
        SectionTitle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - trackName.width - backBtn.width - 24
            text: I18n.tr("Music effects")
        }
        Label {
            id: trackName
            anchors.right: backBtn.left
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, 160)
            size: 13
            color: Theme.textMute
            text: MusicFx.player?.trackTitle ?? ""
        }
        MouseArea {
            id: backBtn
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 26; height: 26
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.back()
            MIcon {
                anchors.centerIn: parent
                text: "arrow_back"
                size: 20
                color: parent.containsMouse ? Theme.amberBright : Theme.textDim
            }
        }
    }

    GlyphSlider {
        width: parent.width
        icon: "music_note"
        color: Theme.amber
        segments: 20
        value: root.opts.intensity / 2
        label: Math.round(root.opts.intensity * 100) + "%"
        onMoved: v => root.opts.intensity = Math.round(Math.max(0.1, v * 2) * 20) / 20
    }

    Rule {}

    // ── Desktop visualizer ───────────────────────────
    SwitchRow {
        title: I18n.tr("Desktop visualizer")
        checked: root.opts.visualizer
        onToggled: c => root.opts.visualizer = c
    }
    Grid {
        width: parent.width
        columns: 3
        spacing: 8
        opacity: root.opts.visualizer ? 1 : 0.4
        enabled: root.opts.visualizer
        Repeater {
            model: [
                ["bars", "graphic_eq", I18n.tr("Bars")],
                ["wave", "airwave", I18n.tr("Wave")],
                ["mirror", "align_vertical_center", I18n.tr("Mirror")],
                ["ring", "donut_large", I18n.tr("Ring")],
                ["halo", "adjust", I18n.tr("Halo")],
                ["sheep", "pets", "Annabelle"]
            ]
            ModeKey {
                required property var modelData
                width: (parent.width - 16) / 3
                icon: modelData[1]
                title: modelData[2]
                selected: root.opts.mode === modelData[0]
                onClicked: root.opts.mode = modelData[0]
            }
        }
        // Not a shape of its own: streaks behind whichever is chosen
        ModeKey {
            width: (parent.width - 16) / 3
            icon: "auto_awesome"
            title: I18n.tr("Particles")
            selected: root.opts.particles
            selectedColor: Theme.cyan
            onClicked: root.opts.particles = !root.opts.particles
        }
    }

    Rule {}

    // ── Lyrics ───────────────────────────────────────
    SwitchRow {
        title: I18n.tr("Desktop lyrics")
        subtitle: !root.opts.lyrics ? "" : ({
            loading: I18n.tr("Fetching lyrics…"),
            none: I18n.tr("No synced lyrics for this track"),
            error: I18n.tr("LRCLIB unreachable"),
            ok: I18n.tr("Synced lyrics from LRCLIB")
        })[Lyrics.status] ?? ""
        checked: root.opts.lyrics
        onToggled: c => root.opts.lyrics = c
    }

    Rule {}

    // ── Wallpaper effects ────────────────────────────
    SwitchRow {
        title: I18n.tr("Wallpaper effects")
        checked: root.opts.wallpaperFx
        onToggled: c => root.opts.wallpaperFx = c
    }
    Grid {
        width: parent.width
        columns: 2
        spacing: 8
        opacity: root.opts.wallpaperFx ? 1 : 0.4
        enabled: root.opts.wallpaperFx
        Repeater {
            model: [
                ["glow", "flare", I18n.tr("Glow")],
                ["blur", "blur_on", I18n.tr("Blur")],
                ["zoom", "zoom_out_map", I18n.tr("Zoom")],
                ["shake", "vibration", I18n.tr("Shake")]
            ]
            QuickToggle {
                required property var modelData
                width: (parent.width - 8) / 2
                implicitHeight: 42
                icon: modelData[1]
                title: modelData[2]
                checked: root.opts[modelData[0]]
                onClicked: root.opts[modelData[0]] = !root.opts[modelData[0]]
            }
        }
    }

    Rule {}

    MouseArea {
        width: parent.width
        height: 40
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: ShellState.toggleWallpaperPicker()
        ChamferPanel {
            anchors.fill: parent
            cut: Theme.cutSmall
            fillColor: parent.containsMouse ? Theme.stone3 : Theme.stone2
            borderColor: parent.containsMouse ? Theme.lineBright : Theme.line
        }
        Row {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10
            MIcon { text: "wallpaper"; size: 20; color: Theme.cyan; anchors.verticalCenter: parent.verticalCenter }
            Label { text: I18n.tr("Customize desktop"); size: 15; color: Theme.text; anchors.verticalCenter: parent.verticalCenter }
        }
        MIcon {
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: "chevron_right"
            size: 20
            color: Theme.textDim
        }
    }

    component Rule: Rectangle {
        width: parent.width
        height: 1
        color: Theme.line
    }

    component SwitchRow: Item {
        id: row
        property string title: ""
        property string subtitle: ""
        property bool checked: false
        signal toggled(bool checked)
        width: parent.width
        height: Math.max(24, texts.implicitHeight)
        Column {
            id: texts
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 60
            spacing: -2
            Label { width: parent.width; text: row.title; size: 15; color: Theme.text }
            Label { width: parent.width; text: row.subtitle; size: 12; color: Theme.textMute; visible: text !== "" }
        }
        GlyphSwitch {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            checked: row.checked
            onToggled: c => row.toggled(c)
        }
    }

    // A visualizer shape: the chosen one lights amber like the play key
    component ModeKey: MouseArea {
        id: key
        property string icon: ""
        property string title: ""
        property bool selected: false
        property color selectedColor: Theme.amber
        height: 52
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        ChamferPanel {
            anchors.fill: parent
            cut: Theme.cutSmall
            cutTopRight: false
            cutBottomLeft: false
            fillColor: key.selected ? Theme.alpha(key.selectedColor, key.containsMouse ? 0.3 : 0.2)
                : key.containsMouse ? Theme.stone3 : Theme.stone2
            borderColor: key.selected ? Theme.alpha(key.selectedColor, 0.8) : Theme.line
            Behavior on fillColor { ColorAnimation { duration: Theme.animFast } }
        }
        Column {
            anchors.centerIn: parent
            spacing: 0
            MIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                text: key.icon
                size: 20
                filled: key.selected
                color: key.selected ? Qt.lighter(key.selectedColor, 1.3) : Theme.textDim
            }
            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: key.title
                size: 13
                color: key.selected ? Theme.text : Theme.textDim
            }
        }
    }
}
