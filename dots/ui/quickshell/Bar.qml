// Bar.qml
//
// Content of the top bar: logo/menu (left), workspaces (center),
// status modules + clock (right). One instance per screen, hosted by
// the PanelWindow in shell.qml.

pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Bluetooth

Item {
    id: root

    readonly property color textColor: "#cdd6f4"
    readonly property color dimColor: "#585b70"
    readonly property color accentColor: "#89b4fa"
    readonly property color hoverColor: "#7287fd"
    readonly property color warnColor: "#f9e2af"
    readonly property color critColor: "#eba0ac"
    readonly property string fontFamily: "CaskaydiaMono Nerd Font"

    // Bottom accent border, matching the previous waybar look.
    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: 1
        color: root.accentColor
    }

    // Fire-and-forget launcher for hyprctl dispatch exec_cmd, used by the
    // status modules below to open floating terminal tools. Hyprland's Lua
    // config evaluates dispatch arguments as Lua, so this needs the
    // hl.dsp.exec_cmd(cmd, rules) form rather than the old bracket-prefix
    // exec syntax.
    Process {
        id: launcher
    }

    function launchFloating(cmd) {
        var escaped = cmd.replace(/"/g, '\\"');
        launcher.command = ["hyprctl", "dispatch", 'hl.dsp.exec_cmd("ghostty -e ' + escaped + '", { float = true, center = true, size = "900 600" })'];
        launcher.running = true;
    }

    // ---- Left: menu/launcher ----

    StatusButton {
        id: logo
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: "\uEEED"
        textColor: root.textColor
        hoverColor: root.hoverColor
        fontFamily: root.fontFamily
        fontSize: 16
        onClicked: menuProc.running = true
    }

    Process {
        id: menuProc
        command: ["walker"]
    }

    // ---- Center: workspaces ----

    Row {
        id: wsRow
        anchors.centerIn: parent
        spacing: 6

        function workspaceIds() {
            var ids = [1, 2, 3, 4];
            var values = Hyprland.workspaces.values;
            for (var i = 0; i < values.length; i++) {
                var id = values[i].id;
                if (id > 0 && ids.indexOf(id) === -1)
                    ids.push(id);
            }
            ids.sort(function (a, b) {
                return a - b;
            });
            return ids;
        }

        Repeater {
            model: wsRow.workspaceIds()

            Rectangle {
                id: wsButton
                required property int modelData

                readonly property var workspace: {
                    var values = Hyprland.workspaces.values;
                    for (var i = 0; i < values.length; i++) {
                        if (values[i].id === modelData)
                            return values[i];
                    }
                    return null;
                }
                readonly property bool occupied: workspace !== null && workspace.toplevels.values.length > 0
                readonly property bool focused: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === modelData

                width: label.implicitWidth + 16
                height: 24
                radius: 0
                color: "transparent"
                border.width: 1
                border.color: focused ? root.accentColor : root.dimColor
                opacity: occupied || focused ? 1 : 0.4

                Text {
                    id: label
                    anchors.centerIn: parent
                    text: wsButton.modelData
                    color: wsButton.focused ? root.accentColor : root.dimColor
                    font.family: root.fontFamily
                    font.pixelSize: 14
                    font.bold: wsButton.focused
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch('hl.dsp.focus({ workspace = "' + wsButton.modelData + '" })')
                }
            }
        }
    }

    // ---- Right: status modules + clock ----

    Row {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        // Pending package updates (yay)
        StatusButton {
            id: updates
            visible: count > 0
            property int count: 0
            text: "󰚰"
            textColor: root.warnColor
            hoverColor: root.hoverColor
            fontFamily: root.fontFamily
            onClicked: root.launchFloating("yay -Syu")

            Process {
                id: updatesProc
                command: ["bash", "-c", "yay -Qu 2>/dev/null | wc -l"]
                stdout: SplitParser {
                    onRead: data => updates.count = parseInt(data, 10) || 0
                }
            }

            Timer {
                interval: 300000
                running: true
                repeat: true
                triggeredOnStart: true
                onTriggered: if (!updatesProc.running) updatesProc.running = true
            }
        }

        // Running docker containers
        StatusButton {
            id: docker
            property int count: 0
            text: "󰡨"
            textColor: root.textColor
            hoverColor: root.hoverColor
            fontFamily: root.fontFamily
            onClicked: root.launchFloating("lazydocker")

            Process {
                id: dockerProc
                command: ["bash", "-c", "docker ps -q 2>/dev/null | wc -l"]
                stdout: SplitParser {
                    onRead: data => docker.count = parseInt(data, 10) || 0
                }
            }

            Timer {
                interval: 10000
                running: true
                repeat: true
                triggeredOnStart: true
                onTriggered: if (!dockerProc.running) dockerProc.running = true
            }
        }

        // Bluetooth
        StatusButton {
            id: bluetooth

            readonly property bool powered: !!Bluetooth.defaultAdapter?.enabled
            readonly property int connectedCount: {
                var devices = Bluetooth.devices ? Bluetooth.devices.values : [];
                var n = 0;
                for (var i = 0; i < devices.length; i++) {
                    if (devices[i].connected)
                        n++;
                }
                return n;
            }

            text: !powered ? "󰂲" : (connectedCount > 0 ? "󰂱" : "󰂯")
            textColor: root.textColor
            hoverColor: root.hoverColor
            fontFamily: root.fontFamily
            onClicked: root.launchFloating("bluetui")
        }

        // Network
        StatusButton {
            id: network
            property string kind: "down"
            text: kind === "wifi" ? "󰖩" : (kind === "eth" ? "ETH" : "X")
            textColor: kind === "down" ? root.critColor : root.textColor
            hoverColor: root.hoverColor
            fontFamily: root.fontFamily
            onClicked: root.launchFloating("impala")

            Process {
                id: netProc
                command: ["bash", "-c", "ip route get 1.1.1.1 2>/dev/null | head -1"]
                stdout: SplitParser {
                    onRead: data => {
                        var match = data.match(/ dev (\S+)/);
                        if (!match)
                            network.kind = "down";
                        else if (match[1].startsWith("wl"))
                            network.kind = "wifi";
                        else
                            network.kind = "eth";
                    }
                }
            }

            Timer {
                interval: 3000
                running: true
                repeat: true
                triggeredOnStart: true
                onTriggered: if (!netProc.running) netProc.running = true
            }
        }

        // Volume (default pipewire sink)
        StatusButton {
            id: volume

            readonly property var sink: Pipewire.defaultAudioSink
            readonly property bool muted: !!sink?.audio?.muted
            readonly property real level: sink?.audio?.volume ?? 0

            text: muted ? "󰝟" : (level > 0.66 ? "󰕾" : (level > 0.33 ? "󰖀" : "󰕿"))
            textColor: root.textColor
            hoverColor: root.hoverColor
            fontFamily: root.fontFamily
            onClicked: root.launchFloating("wiremix")
            onWheelUp: if (sink?.ready && sink?.audio) sink.audio.volume = Math.min(1, level + 0.05)
            onWheelDown: if (sink?.ready && sink?.audio) sink.audio.volume = Math.max(0, level - 0.05)

            PwObjectTracker {
                objects: volume.sink ? [volume.sink] : []
            }
        }

        // Battery
        StatusButton {
            id: battery

            readonly property var device: UPower.displayDevice
            readonly property bool present: !!device?.isPresent
            readonly property real pct: device ? device.percentage * 100 : 0
            readonly property bool charging: device?.state === UPowerDeviceState.Charging
            readonly property int step: Math.max(0, Math.min(9, Math.floor(pct / 10)))
            readonly property var defaultIcons: ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
            readonly property var chargingIcons: ["󰢜", "󰂆", "󰂇", "󰂈", "󰢝", "󰂉", "󰢞", "󰂊", "󰂋", "󰂅"]

            visible: present
            text: charging ? chargingIcons[step] : defaultIcons[step]
            textColor: pct <= 10 ? root.critColor : (pct <= 20 ? root.warnColor : root.textColor)
            hoverColor: root.hoverColor
            fontFamily: root.fontFamily
        }

        // Clock
        StatusButton {
            id: clock
            property date now: new Date()
            text: Qt.formatDateTime(now, "hh:mm AP")
            bold: true
            textColor: root.textColor
            hoverColor: root.textColor
            fontFamily: root.fontFamily

            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: clock.now = new Date()
            }
        }
    }
}
