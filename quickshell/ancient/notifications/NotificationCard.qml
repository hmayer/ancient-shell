import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.services
import qs.theme
import qs.widgets

// One notification on a console plate. Used for popups and in the history.
MouseArea {
    id: root
    required property var wrapper        // Notifs.Wrapper
    property bool compact: false

    readonly property color tone: wrapper.critical ? Theme.dome : Theme.cyan

    implicitHeight: Math.max(64, col.implicitHeight + 22)
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
    onClicked: mouse => {
        const n = wrapper.notification;
        if (mouse.button === Qt.LeftButton && n?.actions?.length > 0) {
            const def = n.actions.find(a => a.identifier === "default") ?? null;
            if (def) { def.invoke(); return; }
        }
        Notifs.dismiss(wrapper);
    }

    // Hovering pauses the popup timer
    onContainsMouseChanged: if (wrapper.timer) wrapper.timer.running = !containsMouse && wrapper.popup && !wrapper.critical

    ChamferPanel {
        anchors.fill: parent
        cutTopRight: false
        cutBottomLeft: false
        cut: Theme.cutSmall + 2
        fillColor: root.compact ? (root.containsMouse ? Theme.stone3 : Theme.stone2) : Theme.panel
        borderColor: root.containsMouse ? Theme.alpha(root.tone, 0.7) : Theme.line
    }
    // Glyph strip on the left edge
    Rectangle {
        x: 0; y: 8
        width: 2
        height: parent.height - 16
        color: root.tone
    }

    Item {
        id: iconBox
        x: 14; y: 12
        width: 36; height: 36
        readonly property string src: root.wrapper.image !== "" ? root.wrapper.image
            : root.wrapper.appIcon !== "" ? Quickshell.iconPath(root.wrapper.appIcon, true) : ""
        Image {
            id: img
            anchors.fill: parent
            source: iconBox.src
            fillMode: Image.PreserveAspectFit
            sourceSize: Qt.size(72, 72)
            asynchronous: true
            visible: status === Image.Ready
        }
        MIcon {
            anchors.centerIn: parent
            visible: img.status !== Image.Ready
            text: root.wrapper.critical ? "warning" : "notifications"
            size: 24
            color: root.tone
        }
    }

    Column {
        id: col
        x: iconBox.x + iconBox.width + 12
        y: 10
        width: root.width - x - 34
        spacing: 2

        Row {
            width: parent.width
            spacing: 8
            Label {
                id: app
                size: 11
                font.letterSpacing: 1.4
                color: root.wrapper.critical ? Theme.dome : Theme.amber
                text: (root.wrapper.appName || I18n.tr("System")).toUpperCase()
                width: Math.min(implicitWidth, parent.width - when.width - 8)
            }
            Label {
                id: when
                size: 11
                color: Theme.textMute
                text: Qt.formatTime(root.wrapper.time, "HH:mm")
            }
        }
        Label {
            width: parent.width
            size: 16
            color: Theme.text
            text: root.wrapper.summary
            wrapMode: Text.Wrap
            maximumLineCount: 2
        }
        Text {
            width: parent.width
            visible: text !== ""
            font.family: Theme.fontUi
            font.pixelSize: 14
            font.weight: Font.Medium
            color: Theme.textDim
            text: root.wrapper.body
            textFormat: Text.StyledText
            wrapMode: Text.Wrap
            maximumLineCount: root.compact ? 2 : 5
            elide: Text.ElideRight
            linkColor: Theme.cyan
            onLinkActivated: link => Qt.openUrlExternally(link)
        }
        Flow {
            width: parent.width
            spacing: 6
            topPadding: 4
            visible: !root.compact && (root.wrapper.notification?.actions?.length ?? 0) > 0
            Repeater {
                model: root.wrapper.notification?.actions ?? []
                MouseArea {
                    id: act
                    required property var modelData
                    visible: modelData.identifier !== "default"
                    width: actLabel.implicitWidth + 20
                    height: 26
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: modelData.invoke()
                    ChamferPanel {
                        anchors.fill: parent
                        cut: 5
                        fillColor: act.containsMouse ? Theme.alpha(root.tone, 0.22) : Theme.stone2
                        borderColor: Theme.alpha(root.tone, 0.5)
                    }
                    Label {
                        id: actLabel
                        anchors.centerIn: parent
                        size: 13
                        text: act.modelData.text
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 6
        width: 22; height: 22
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        visible: root.containsMouse
        onClicked: Notifs.dismiss(root.wrapper)
        MIcon {
            anchors.centerIn: parent
            text: "close"
            size: 16
            color: parent.containsMouse ? Theme.dome : Theme.textDim
        }
    }
}
