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
                id: centerColumn

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter

                width: Math.min(parent.width * 0.9, 720 * root.scale)
                spacing: 24 * root.scale

                // ===== HEADER =====
                Column {
                    spacing: 6 * root.scale

                    Text {
                        text: "About Machine"
                        font.pixelSize: 26 * root.scale
                        font.bold: true
                        color: "#1A4DB5"
                    }

                    Rectangle {
                        width: 80 * root.scale
                        height: 4 * root.scale
                        radius: 2 * root.scale
                        color: "#1A4DB5"
                    }
                }

                // ================= CARD =================
                Rectangle {
                    width: parent.width
                    height: gridContent.implicitHeight + (80 * root.scale)

                    radius: 24 * root.scale
                    color: "#FFFFFF"

                    border.width: 2
                    border.color: "#6F95D6"

                    anchors.horizontalCenter: parent.horizontalCenter

                    Column {
                        id: gridContent

                        anchors.centerIn: parent
                        width: parent.width * 0.9

                        spacing: 20 * root.scale

                        GridLayout {
                            width: parent.width
                            columns: 2

                            rowSpacing: 18 * root.scale
                            columnSpacing: 18 * root.scale

                            Repeater {
                                model: root.sysDetails

                                delegate: Rectangle {

                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 80 * root.scale

                                    radius: 14 * root.scale
                                    color: "#F7F9FF"

                                    border.width: 1
                                    border.color: "#D7E2F5"

                                    Column {
                                        anchors.fill: parent
                                        anchors.margins: 14 * root.scale
                                        spacing: 6 * root.scale

                                        Text {
                                            text: modelData.label
                                            font.pixelSize: 15 * root.scale
                                            font.bold: true
                                            color: "#5B6B8C"
                                        }

                                        Text {
                                            text: modelData.value
                                            font.pixelSize: 19 * root.scale
                                            font.bold: true
                                            color: "#1A4DB5"
                                            elide: Text.ElideRight
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
}
