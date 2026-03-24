import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import AppState 1.0

import "../components"

Item {
    id: root

    property bool showTopBar: true
    property var globalTopBar

    property var sysDetails: [
        { label: "User", value: "..............."},
        { label: "Location", value: "..............."},
        { label: "Machine Id", value: "PHMX"},
        { label: "Version", value: "v4.0.1"}
    ]

    Rectangle {
        anchors.fill: parent
        color: "#F5F7FC"

        Column {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 24
            anchors.topMargin: 60

            // ===== COIL OUTPUT =====
            CoilProgressBar {
                id: coilOut
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.min(parent.width * 0.60, 540)
                height: 72

                label: "Coil Output"
                value: 2208
                maxValue: 10000
            }

            // ===== CARD =====
            Rectangle {
                id: card
                anchors.horizontalCenter: parent.horizontalCenter

                width: Math.min(parent.width * 0.6, 500)
                height: contentColumn.implicitHeight + 56

                radius: 24
                color: "white"
                border.width: 2
                border.color: "#6F95D6"

                Column {
                    id: contentColumn

                    anchors.centerIn: parent

                    width: parent.width * 0.75
                    spacing: 20

                    // ===== TITLE =====
                    Column {
                        spacing: 10
                        anchors.horizontalCenter: parent.horizontalCenter

                        Text {
                            id: titleText
                            text: "About Machine"
                            font.pixelSize: 20
                            font.bold: true
                            color: "#1A4DB5"
                        }
                    }

                    // ===== DETAILS CONTAINER =====
                    Column {
                        width: parent.width
                        spacing: 10   // spacing between rows

                        Repeater {
                            model: root.sysDetails

                            delegate: Row {
                                width: parent.width
                                height: 34

                                property real labelW: parent.width * 0.42
                                property real colonW: 20
                                property real valueW: parent.width * 0.48

                                Text {
                                    text: modelData.label
                                    width: parent.labelW
                                    font.pixelSize: 18
                                    font.bold: true
                                    color: "#000000"
                                    horizontalAlignment: Text.AlignLeft
                                    verticalAlignment: Text.AlignVCenter
                                }

                                Text {
                                    text: ":"
                                    width: parent.colonW
                                    font.pixelSize: 18
                                    font.bold: true
                                    color: "#000000"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                Text {
                                    text: modelData.value
                                    width: parent.valueW
                                    font.pixelSize: 18
                                    font.bold: true
                                    color: "#1A4DB5"
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
