import QtQuick
import QtQuick.Controls

Button {
    Typography {
        id: componentTypography
        scale: root.scale || 1.0
    }
    id: btn

    property color bgColor: "#EEF2FF"
    property color accent: "#4A6CF7"

    implicitWidth: 80
    implicitHeight: 80   //  equal = perfect circle

    hoverEnabled: true

    background: Rectangle {
        width: btn.width
        height: btn.height
        radius: width / 2   //  makes it round

        color: btn.down ? btn.accent : (btn.hovered ? "#E0E7FF" : btn.bgColor)
        border.color: btn.accent
        border.width: 2

        Behavior on color { ColorAnimation { duration: 150 } }
    }

    contentItem: Text {
        text: btn.text
        anchors.centerIn: parent
        font.pixelSize: 14

        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter

        color: btn.down ? "white" : btn.accent

        Behavior on color { ColorAnimation { duration: 150 } }
    }

    // Press animation
    scale: btn.down ? 0.92 : 1.0
    Behavior on scale { NumberAnimation { duration: 120 } }
}
