import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    property int value: 10

    // ✅ THIS IS REQUIRED
    signal saveClicked(int value)

    RowLayout {
        spacing: 24

        Rectangle {
            width: 90
            height: 70
            radius: 16
            color: "#F9FAFB"
            border.color: "#E5E7EB"

            Text {
                anchors.centerIn: parent
                text: root.value
                font.pixelSize: 20
                font.bold: true
            }
        }

        Column {
            spacing: 10

            Button {
                text: "+"
                width: 40
                height: 30
                onClicked: root.value++
            }

            Button {
                text: "-"
                width: 40
                height: 30
                onClicked: root.value--
            }
        }

        Button {
            text: "Save"
            onClicked: root.saveClicked(root.value)   // ✅ emit signal
        }
    }
}
