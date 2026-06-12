import QtQuick
import QtQuick.Controls

Button {
    id: btn

    Typography {
        id: componentTypography
        scale: root.scale || 1.0
    }

    property color bgColor: "#1A4DB5"
    property color hoverColor: "#163E91"
    property color disabledColor: "#D1D5DB"

    property color textColor: "white"
    property color disabledTextColor: "#6B7280"

    property real radius: 10

    implicitWidth: 110
    implicitHeight: 50

    hoverEnabled: true

    background: Rectangle {
        radius: btn.radius

        color: !btn.enabled
               ? btn.disabledColor
               : (btn.down
                  ? btn.hoverColor
                  : (btn.hovered ? btn.hoverColor : btn.bgColor))

        opacity: btn.enabled ? 1.0 : 0.5

        Behavior on color {
            ColorAnimation { duration: 120 }
        }
    }

    contentItem: Text {
        text: btn.text
        anchors.centerIn: parent

        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter

        font: btn.font

        color: btn.enabled
               ? btn.textColor
               : btn.disabledTextColor
    }

    scale: !btn.enabled ? 1.0 : (btn.down ? 0.96 : 1.0)

    Behavior on scale {
        NumberAnimation {
            duration: 100
        }
    }
}
