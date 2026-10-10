import QtQuick
import QtQuick.Controls

Button {
    id: control

    property color accent: "#1A4DB5"
    property bool selected: false

    implicitWidth: label.implicitWidth + 20
    implicitHeight: 30
    padding: 0
    hoverEnabled: true

    contentItem: Text {
        id: label
        text: control.text
        color: control.down || control.selected
               ? "#FFFFFF" : control.enabled ? "#334155" : "#9AA5B5"
        font.pixelSize: 12
        font.weight: Font.Medium
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle {
        radius: 6
        color: !control.enabled ? "#F1F3F7"
              : control.selected ? control.accent
              : control.down ? control.accent
              : control.hovered ? "#EEF4FF" : "#FFFFFF"
        border.width: 1
        border.color: !control.enabled ? "#E1E5EC"
                     : control.selected ? control.accent
                     : control.down || control.hovered ? control.accent : "#C8D2E1"
    }
}
