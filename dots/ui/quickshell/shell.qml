// shell.qml
//
// Entry point. Spawns one Bar per connected screen.

import Quickshell
import QtQuick

ShellRoot {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData

            screen: modelData
            color: "#11111b"

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: 34

            Bar {
                anchors.fill: parent
            }
        }
    }
}
