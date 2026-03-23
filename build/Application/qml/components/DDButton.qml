import QtQuick
import QtQuick.Controls

Rectangle {
    id: root

    // ================= RESPONSIVE  =================
    property real minScale: 0.75
    property real maxScale: 1.0
    property real s: Math.max(minScale, Math.min(maxScale, Math.min(width, height) / 200))

    width: 160
    height: 60
    radius: 16

    property bool toggled: false
    property bool hovered: false
    property bool pressed: false

    // ================= BACKGROUND =================
    color: toggled ? "#1A4DB5" : "#F3F4F6"
    border.color: toggled ? "#1A4DB5" : "#E5E7EB"
    border.width: 1

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: "transparent"
        border.color: "#00000010"
    }

    // ================= KNOB =================
    Rectangle {
        id: knob
        width: 52
        height: 52
        radius: 16

        y: (parent.height - height) / 2
        x: toggled ? parent.width - width - 6 : 6

        color: "white"
        border.color: "#E5E7EB"

        Behavior on x {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        Text {
            anchors.centerIn: parent
            text: toggled ? "ON" : "OFF"
            font.pixelSize: 12
            font.bold: true
            color: toggled ? "#1A4DB5" : "#6B7280"
        }
    }

    // ================= INTERACTION =================
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true

        onEntered: root.hovered = true
        onExited: root.hovered = false
        onPressed: root.pressed = true
        onReleased: root.pressed = false

        onClicked: root.toggled = !root.toggled
    }

    // ================= ANIMATIONS =================
    scale: pressed ? 0.96 : 1.0
    Behavior on scale { NumberAnimation { duration: 120 } }

    Behavior on color { ColorAnimation { duration: 180 } }
    Behavior on border.color { ColorAnimation { duration: 180 } }
}
