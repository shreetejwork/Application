import QtQuick
import QtQuick.Controls

Rectangle {
    id: root
    width: 160
    height: 60
    radius: 16

    property bool toggled: false
    property bool hovered: false
    property bool pressed: false

    // Background
    color: toggled ? "#4A6CF7" : "#F3F4F6"
    border.color: toggled ? "#4A6CF7" : "#E5E7EB"
    border.width: 1

    // Shadow
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: "transparent"
        border.color: "#00000010"
    }

    //  Sliding Circle
    Rectangle {
        id: knob
        width: 52
        height: 52
        radius: 26
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

        //  TEXT INSIDE CIRCLE
        Text {
            anchors.centerIn: parent
            text: toggled ? "ON" : "OFF"
            font.pixelSize: 12
            font.bold: true
            color: toggled ? "#4A6CF7" : "#6B7280"
        }
    }

    // Interaction
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true

        onEntered: root.hovered = true
        onExited: root.hovered = false
        onPressed: root.pressed = true
        onReleased: root.pressed = false

        onClicked: root.toggled = !root.toggled
    }

    // Press animation
    scale: pressed ? 0.96 : 1.0
    Behavior on scale { NumberAnimation { duration: 120 } }

    // Smooth transitions
    Behavior on color { ColorAnimation { duration: 180 } }
    Behavior on border.color { ColorAnimation { duration: 180 } }

    // Hover effect
    states: [
        State {
            name: "hovered"
            when: hovered && !pressed
            PropertyChanges {
                target: root
                color: toggled ? "#3B5BDB" : "#E5E7EB"
            }
        }
    ]
}
