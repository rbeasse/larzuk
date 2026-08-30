// Notifications.qml
//
// Notification popups, top-right stack, replacing dunst. Only one process
// can own org.freedesktop.Notifications, so unlike Bar.qml this is a single
// instance pinned to one screen (dunst's config here was also pinned to
// monitor 0, not "follow mouse" across outputs).

pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

PanelWindow {
    id: root

    readonly property color bgColor: "#181825"
    readonly property color textColor: "#cdd6f4"
    readonly property color lowColor: "#a6e3a1"
    readonly property color normalColor: "#89b4fa"
    readonly property color criticalColor: "#f38ba8"
    readonly property string fontFamily: "CaskaydiaMono Nerd Font"
    readonly property int cardWidth: 360

    function colorFor(urgency) {
        if (urgency === NotificationUrgency.Low)
            return lowColor;
        if (urgency === NotificationUrgency.Critical)
            return criticalColor;
        return normalColor;
    }

    // Matches dunst's per-urgency timeout config (4s/6s/never).
    function defaultTimeout(urgency) {
        if (urgency === NotificationUrgency.Low)
            return 4000;
        if (urgency === NotificationUrgency.Critical)
            return 0;
        return 6000;
    }

    screen: Quickshell.screens[0]
    color: "transparent"
    focusable: false
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    // Full-surface, click-through except over the visible card column —
    // avoids resizing the wayland surface every time a toast appears.
    mask: Region {
        item: column
    }

    NotificationServer {
        id: server

        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        actionsSupported: true
        persistenceSupported: false

        onNotification: notif => {
            notif.tracked = true;

            // Matches dunst's notification_limit = 5: drop the oldest once
            // over the cap.
            var tracked = server.trackedNotifications.values;
            for (var i = 0; i < tracked.length - 5; i++) {
                tracked[i].tracked = false;
            }
        }
    }

    Column {
        id: column
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 40
        anchors.rightMargin: 6
        width: root.cardWidth
        spacing: 8

        Repeater {
            // Bound directly to the server's own object model (not a plain
            // JS array) so adding/removing one notification only touches
            // that one delegate — a plain-array rebind would recreate every
            // delegate on each change and reset every other card's timer.
            model: server.trackedNotifications

            Rectangle {
                id: card
                required property var modelData

                width: root.cardWidth
                implicitHeight: cardColumn.implicitHeight + 28
                radius: 5
                color: root.bgColor
                border.width: 1
                border.color: root.colorFor(card.modelData.urgency)

                Connections {
                    target: card.modelData
                    function onClosed() {
                        card.modelData.tracked = false;
                    }
                }

                Timer {
                    running: true
                    repeat: false
                    interval: card.modelData.expireTimeout > 0 ? card.modelData.expireTimeout : root.defaultTimeout(card.modelData.urgency)
                    onTriggered: {
                        if (interval > 0) {
                            card.modelData.expire();
                            card.modelData.tracked = false;
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        card.modelData.dismiss();
                        card.modelData.tracked = false;
                    }
                }

                Column {
                    id: cardColumn
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 6

                    Row {
                        width: parent.width
                        spacing: 10

                        Image {
                            readonly property string iconSource: card.modelData.image || (card.modelData.appIcon ? Quickshell.iconPath(card.modelData.appIcon, "") : "")
                            visible: iconSource !== "" && status !== Image.Error
                            source: iconSource
                            width: 32
                            height: 32
                            fillMode: Image.PreserveAspectFit
                        }

                        Column {
                            width: parent.width - 42
                            spacing: 2

                            Text {
                                width: parent.width
                                text: card.modelData.summary
                                color: root.textColor
                                font.family: root.fontFamily
                                font.bold: true
                                font.pixelSize: 13
                                wrapMode: Text.Wrap
                            }

                            Text {
                                width: parent.width
                                visible: text !== ""
                                text: card.modelData.body
                                textFormat: Text.RichText
                                color: root.textColor
                                font.family: root.fontFamily
                                font.pixelSize: 12
                                wrapMode: Text.Wrap
                            }
                        }
                    }

                    Rectangle {
                        visible: card.modelData.hints.value !== undefined
                        width: parent.width
                        height: 6
                        radius: 3
                        color: "#313244"

                        Rectangle {
                            height: parent.height
                            radius: 3
                            color: root.colorFor(card.modelData.urgency)
                            width: parent.width * Math.max(0, Math.min(100, card.modelData.hints.value ?? 0)) / 100
                        }
                    }

                    Row {
                        visible: card.modelData.actions.length > 0
                        spacing: 6

                        Repeater {
                            model: card.modelData.actions

                            Rectangle {
                                id: actionBtn
                                required property var modelData

                                width: actionLabel.implicitWidth + 16
                                height: 22
                                radius: 4
                                color: "#313244"

                                Text {
                                    id: actionLabel
                                    anchors.centerIn: parent
                                    text: actionBtn.modelData.text
                                    color: root.textColor
                                    font.family: root.fontFamily
                                    font.pixelSize: 11
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: actionBtn.modelData.invoke()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
