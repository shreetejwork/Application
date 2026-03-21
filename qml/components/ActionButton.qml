import QtQuick
import QtQuick.Controls

Button {
    id: btn

    property color bgColor: "#1A4DB5"
    property color hoverColor: "#163E91"

    property real minScale: 0.75
    property real maxScale: 1.0
    property real s: Math.max(minScale, Math.min(maxScale, Math.min(width, height) / 200))

    implicitWidth: btn.width > 0 ? btn.width : 180
    implicitHeight: btn.height > 0 ? btn.height : 48

    hoverEnabled: true

    background: Rectangle {
        radius: 10

        color: !btn.enabled
               ? "#D1D5DB"
               : (btn.down
                  ? btn.hoverColor
                  : (btn.hovered ? btn.hoverColor : btn.bgColor))

        opacity: btn.enabled ? 1.0 : 0.5

        Behavior on color { ColorAnimation { duration: 120 } }
    }

    contentItem: Text {
        text: btn.text
        anchors.centerIn: parent
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter

        font.pixelSize: 14
        font.bold: true
        color: btn.enabled ? "white" : "#6B7280"
    }

    // IMPORTANT: DO NOT FORCE enabled here
    // enabled is controlled from outside now

    scale: !btn.enabled ? 1.0 : (btn.down ? 0.96 : 1.0)
    Behavior on scale { NumberAnimation { duration: 100 } }
}
