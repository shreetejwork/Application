import QtQuick
import QtQuick.Controls

Button {
    id: btn

    property color bgColor: "#EEF2FF"
    property color accent: "#4A6CF7"

    implicitHeight: 48
    implicitWidth: 180

    background: Rectangle {
        radius: 14
        color: btn.down ? accent : btn.bgColor
        border.color: accent

        Behavior on color { ColorAnimation { duration: 150 } }
    }

    contentItem: Text {
        text: btn.text
        anchors.centerIn: parent
        font.pixelSize: 15
        font.bold: true
        color: btn.down ? "white" : accent
    }

    scale: btn.down ? 0.96 : 1.0
    Behavior on scale { NumberAnimation { duration: 120 } }
}
