pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Notification daemon (replaces swaync). Keeps a history and a popup queue.
Singleton {
    id: root

    // Newest first
    property list<QtObject> history: []
    readonly property var popups: history.filter(w => w.popup)
    readonly property int count: history.length

    function dismiss(wrapper) {
        wrapper.popup = false;
        wrapper.notification?.dismiss();
    }

    function clearAll() {
        for (const w of history.slice()) w.notification?.dismiss();
        history = [];
    }

    function _remove(wrapper) {
        history = history.filter(w => w !== wrapper);
        wrapper.destroy();
    }

    NotificationServer {
        id: server
        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        actionsSupported: true
        imageSupported: true

        onNotification: n => {
            n.tracked = true;
            const w = wrapperComp.createObject(root, {
                notification: n,
                popup: !ShellState.dnd || n.urgency === NotificationUrgency.Critical
            });
            root.history = [w, ...root.history];
        }
    }

    component Wrapper: QtObject {
        id: wrapper
        required property Notification notification
        property bool popup: true
        readonly property date time: new Date()
        readonly property string summary: notification?.summary ?? ""
        readonly property string body: notification?.body ?? ""
        readonly property string appName: notification?.appName ?? ""
        readonly property string appIcon: notification?.appIcon ?? ""
        readonly property string image: notification?.image ?? ""
        readonly property bool critical: notification?.urgency === NotificationUrgency.Critical

        readonly property Timer timer: Timer {
            running: wrapper.popup && !wrapper.critical
            interval: (wrapper.notification?.expireTimeout ?? -1) > 0 ? wrapper.notification.expireTimeout : 6000
            onTriggered: wrapper.popup = false
        }

        readonly property Connections conn: Connections {
            target: wrapper.notification
            function onClosed() { root._remove(wrapper); }
        }
    }

    Component {
        id: wrapperComp
        Wrapper {}
    }
}
