import QtQuick
import QtQuick.VirtualKeyboard

InputPanel {
    id: keyboard
    width: parent.width
    height: 260   // global fixed size
    anchors.bottom: parent.bottom
    visible: Qt.inputMethod.visible
}
