import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: powerPopup

    property real baseWidth: 1024
    property real baseHeight: 600


    modal: true
    focus: true
    closePolicy: Popup.CloseOnPressOutside

    width: 520 * scale
    height: 360 * scale

    x: (Overlay.overlay.width - width) / 2
    y: (Overlay.overlay.height - height) / 2

    background: Rectangle {
        color: "#EBEBEB"
        radius: 20 * scale
        border.color: "#C8C8C8"
        border.width: 1
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24 * scale
        spacing: 18 * scale

        // TITLE
        Text {
            text: "Power Off"
            font.pixelSize: Math.max(16, 26 * scale)
            font.bold: true
            color: "#1A4DB5"
            Layout.alignment: Qt.AlignHCenter
        }

        // MESSAGE BOX (like input fields style)
        Rectangle {
            Layout.fillWidth: true
            height: 80 * scale
            radius: 10 * scale
            color: "#F2F2F2"
            border.color: "#1A4DB5"

            Text {
                anchors.centerIn: parent
                text: "This will turn off the system. Continue?"
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                width: parent.width * 0.9
                font.pixelSize: Math.max(12, 18 * scale)
                font.bold: true
                color: "#1A1A2E"
            }
        }

        // BUTTONS (same style as login)
        Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: 20 * scale

            // CANCEL
            Rectangle {
                width: 140 * scale
                height: 50 * scale
                radius: 10 * scale
                border.color: "#1A4DB5"
                border.width: 2
                color: "white"

                Text {
                    anchors.centerIn: parent
                    text: "Cancel"
                    color: "#1A4DB5"
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: powerPopup.close()
                }
            }

            // POWER OFF
            Rectangle {
                width: 140 * scale
                height: 50 * scale
                radius: 10 * scale
                color: "#1A4DB5"

                Text {
                    anchors.centerIn: parent
                    text: "Power Off"
                    color: "white"
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        powerPopup.close()

                        // 👉 Your shutdown logic
                        console.log("Powering off...")

                        // Example:
                        // Qt.quit()
                        // OR call C++ backend
                    }
                }
            }
        }
    }
}
