import QtQuick
import QtQuick.Controls

Rectangle {
    id: root
    width: 200
    height: 64
    radius: 32

    property bool toggled: false

    color: toggled ? "#22C55E" : "#EF4444"

    Text {
        anchors.centerIn: parent
        text: toggled ? "DD ON" : "DD OFF"
        color: "white"
        font.bold: true
        font.pixelSize: 16
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.toggled = !root.toggled
    }

    scale: pressed ? 0.96 : 1
    property bool pressed: false

    MouseArea {
        anchors.fill: parent
        onPressed: root.pressed = true
        onReleased: root.pressed = false
        onClicked: root.toggled = !root.toggled
    }

    Behavior on color { ColorAnimation { duration: 200 } }
    Behavior on scale { NumberAnimation { duration: 120 } }
}
