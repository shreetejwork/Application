import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import AppState 1.0

import "../components"

Item {
    id: root

    property bool showTopBar: true
    property var globalTopBar



    property real baseHeight: 700
    property real scale: Math.max(0.9, Math.min(1.8, height / baseHeight))

    property var sysDetails: [
        { label: "User", value: "..............."},
        { label: "Location", value: "..............."},
        { label: "Machine Id", value: "PHMX"},
        { label: "Version", value: "v4.0.1"}
    ]

    Rectangle {
        anchors.fill: parent
        color: "#F5F7FC"

        // ===== CENTER WRAPPER =====
        Item {
            anchors.centerIn: parent
            width: Math.min(parent.width * 0.92, 900 * root.scale)
            height: contentColumn.implicitHeight

            Column {
                id: contentColumn
                width: parent.width
                spacing: 24 * root.scale

                // ===== COIL OUTPUT =====
                CoilProgressBar {
                    id: coilOut
                    anchors.horizontalCenter: parent.horizontalCenter

                    width: Math.min(parent.width * 0.8, 540 * root.scale)
                    height: 72 * root.scale

                    label: "Coil Output"
                    value: 2208
                    maxValue: 10000
                }

                // ===== CARD =====
                Rectangle {
                    id: card
                    anchors.horizontalCenter: parent.horizontalCenter

                    width: Math.min(parent.width * 0.85, 600 * root.scale)
                    height: contentInner.implicitHeight + (66 * root.scale)

                    radius: 24 * root.scale
                    color: "white"
                    border.width: 2
                    border.color: "#6F95D6"

                    Column {
                        id: contentInner
                        anchors.centerIn: parent
                        width: parent.width * 0.75
                        spacing: 20 * root.scale

                        // ===== TITLE =====
                        Column {
                            spacing: 10 * root.scale
                            anchors.horizontalCenter: parent.horizontalCenter

                            Text {
                                text: "About Machine"
                                font.pixelSize: 20 * root.scale
                                font.bold: true
                                color: "#1A4DB5"
                            }
                        }

                        // ===== DETAILS =====
                        Column {
                            width: parent.width
                            spacing: 10 * root.scale

                            Repeater {
                                model: root.sysDetails

                                delegate: Row {
                                    width: parent.width
                                    height: 34 * root.scale

                                    property real labelW: parent.width * 0.42
                                    property real colonW: 20 * root.scale
                                    property real valueW: parent.width * 0.48

                                    Text {
                                        text: modelData.label
                                        width: parent.labelW
                                        font.pixelSize: 18 * root.scale
                                        font.bold: true
                                        color: "#000000"
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    Text {
                                        text: ":"
                                        width: parent.colonW
                                        font.pixelSize: 18 * root.scale
                                        font.bold: true
                                        color: "#000000"
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    Text {
                                        text: modelData.value
                                        width: parent.valueW
                                        font.pixelSize: 18 * root.scale
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
}
