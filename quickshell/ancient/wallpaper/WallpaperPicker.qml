import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.services
import qs.theme
import qs.widgets

// Wallpaper selector: a carousel of slanted plates along the bottom of the screen.
// ←/→ or wheel to browse, Enter or click to apply, R for random, Esc to close.
PanelWindow {
    id: root

    readonly property bool open: ShellState.wallpaperPickerOpen
    property real progress: open ? 1 : 0
    Behavior on progress { NumberAnimation { duration: Theme.animSlow; easing.type: Easing.OutExpo } }

    screen: Quickshell.screens.find(s => s.name === ShellState.overlayScreen) ?? Quickshell.screens[0]
    visible: progress > 0.001
    color: "transparent"

    WlrLayershell.namespace: "ancient-wallpicker"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { bottom: true; left: true; right: true }
    implicitHeight: 360

    readonly property int cardW: 300
    readonly property int cardH: 190
    readonly property int slant: 36

    onOpenChanged: {
        if (!open) return;
        for (let i = 0; i < Wallpapers.model.count; i++) {
            if (Wallpapers.model.get(i, "filePath") === Wallpapers.current) {
                carousel.currentIndex = i;
                carousel.positionViewAtIndex(i, ListView.Center);
                break;
            }
        }
        carousel.forceActiveFocus();
    }

    HyprlandFocusGrab {
        active: root.open
        windows: [root]
        onCleared: ShellState.wallpaperPickerOpen = false
    }

    function apply(i) {
        const p = Wallpapers.model.get(i, "filePath");
        if (p) Wallpapers.set(p);
    }

    // Fade band behind the carousel
    Rectangle {
        anchors.fill: parent
        opacity: root.progress
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.alpha(Theme.void_, 0.0) }
            GradientStop { position: 0.12; color: Theme.alpha(Theme.void_, 0.82) }
            GradientStop { position: 1.0; color: Theme.alpha(Theme.void_, 0.96) }
        }
    }

    Item {
        anchors.fill: parent
        opacity: root.progress
        transform: Translate { y: (1 - root.progress) * 80 }

        // Title + current file
        Row {
            id: header
            x: 40
            y: 26
            spacing: 14
            OriginGlyph { width: 16; height: 20; glow: 0.7; anchors.verticalCenter: parent.verticalCenter }
            Label {
                anchors.verticalCenter: parent.verticalCenter
                display: true
                size: 13
                font.letterSpacing: 2.5
                color: Theme.cyan
                text: I18n.tr("VISUAL ADDRESS")
            }
            Label {
                anchors.verticalCenter: parent.verticalCenter
                size: 15
                color: Theme.textDim
                text: (Wallpapers.model.get(carousel.currentIndex, "fileName") ?? "")
                    + "   ·   " + (carousel.currentIndex + 1) + " / " + carousel.count
            }
        }
        Row {
            anchors.right: parent.right
            anchors.rightMargin: 40
            y: 26
            spacing: 18
            Repeater {
                model: [["← →", I18n.tr("navigate")], ["Enter", I18n.tr("apply")], ["R", I18n.tr("random")], ["Esc", I18n.tr("close")]]
                Row {
                    required property var modelData
                    spacing: 6
                    Label { size: 12; display: true; color: Theme.amber; text: parent.modelData[0] }
                    Label { size: 13; color: Theme.textMute; text: parent.modelData[1] }
                }
            }
        }

        ListView {
            id: carousel
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 46
            height: root.cardH + 60
            orientation: ListView.Horizontal
            spacing: -root.slant + 18
            model: Wallpapers.model
            focus: true
            clip: false
            highlightRangeMode: ListView.StrictlyEnforceRange
            preferredHighlightBegin: width / 2 - root.cardW / 2
            preferredHighlightEnd: width / 2 + root.cardW / 2
            highlightMoveDuration: 260
            cacheBuffer: root.cardW * 4
            boundsBehavior: Flickable.StopAtBounds

            Keys.onEscapePressed: ShellState.wallpaperPickerOpen = false
            Keys.onReturnPressed: root.apply(currentIndex)
            Keys.onEnterPressed: root.apply(currentIndex)
            Keys.onPressed: event => {
                if (event.key === Qt.Key_R) { Wallpapers.random(); event.accepted = true; }
            }

            WheelHandler {
                onWheel: event => {
                    if (event.angleDelta.y < 0 || event.angleDelta.x < 0) carousel.incrementCurrentIndex();
                    else carousel.decrementCurrentIndex();
                }
            }

            delegate: Item {
                id: card
                required property int index
                required property string filePath
                readonly property bool isCurrent: ListView.isCurrentItem
                readonly property bool isApplied: filePath === Wallpapers.current

                width: root.cardW
                height: carousel.height
                z: isCurrent ? 10 : 0
                scale: isCurrent ? 1.0 : 0.82
                opacity: isCurrent ? 1 : 0.55
                Behavior on scale { NumberAnimation { duration: Theme.animMid; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: Theme.animMid } }

                Item {
                    id: frame
                    width: root.cardW
                    height: root.cardH
                    anchors.centerIn: parent

                    Image {
                        id: thumb
                        anchors.fill: parent
                        source: "file://" + card.filePath
                        sourceSize: Qt.size(root.cardW * 1.5, root.cardH * 1.5)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: false
                    }
                    Shape {
                        id: mask
                        anchors.fill: parent
                        visible: false
                        layer.enabled: true
                        preferredRendererType: Shape.CurveRenderer
                        ShapePath {
                            fillColor: "white"
                            strokeWidth: 0
                            startX: root.slant; startY: 0
                            PathLine { x: root.cardW; y: 0 }
                            PathLine { x: root.cardW - root.slant; y: root.cardH }
                            PathLine { x: 0; y: root.cardH }
                            PathLine { x: root.slant; y: 0 }
                        }
                    }
                    MultiEffect {
                        anchors.fill: parent
                        source: thumb
                        maskEnabled: true
                        maskSource: mask
                        brightness: card.isCurrent ? 0 : -0.15
                    }
                    // Outline
                    Shape {
                        anchors.fill: parent
                        preferredRendererType: Shape.CurveRenderer
                        layer.enabled: card.isCurrent
                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            shadowColor: card.isApplied ? Theme.amber : Theme.cyan
                            shadowBlur: 0.8
                            shadowHorizontalOffset: 0
                            shadowVerticalOffset: 0
                        }
                        ShapePath {
                            fillColor: "transparent"
                            strokeColor: card.isApplied ? Theme.amber : card.isCurrent ? Theme.cyan : Theme.lineBright
                            strokeWidth: card.isCurrent ? 2 : 1
                            joinStyle: ShapePath.MiterJoin
                            startX: root.slant; startY: 0
                            PathLine { x: root.cardW; y: 0 }
                            PathLine { x: root.cardW - root.slant; y: root.cardH }
                            PathLine { x: 0; y: root.cardH }
                            PathLine { x: root.slant; y: 0 }
                        }
                    }
                    // "Applied" marker
                    Rectangle {
                        visible: card.isApplied
                        x: root.cardW - root.slant - 30
                        y: root.cardH - 18
                        width: 8; height: 8; rotation: 45
                        color: Theme.amber
                    }
                }

                MouseArea {
                    anchors.fill: frame
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (card.isCurrent) root.apply(card.index);
                        else carousel.currentIndex = card.index;
                    }
                }
            }
        }
    }
}
