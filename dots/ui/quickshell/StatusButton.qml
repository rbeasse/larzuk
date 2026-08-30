// StatusButton.qml
//
// Small clickable/scrollable label used for every module in the bar.

import QtQuick

Item {
    id: root

    property string text: ""
    property color textColor: "white"
    property color hoverColor: textColor
    property string fontFamily: "sans-serif"
    property int fontSize: 14
    property bool bold: false

    signal clicked
    signal wheelUp
    signal wheelDown

    width: label.implicitWidth + 16
    height: 26

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: mouse.containsMouse ? root.hoverColor : root.textColor
        font.family: root.fontFamily
        font.pixelSize: root.fontSize
        font.bold: root.bold
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
        onWheel: wheel => {
            if (wheel.angleDelta.y > 0)
                root.wheelUp();
            else if (wheel.angleDelta.y < 0)
                root.wheelDown();
        }
    }
}
