import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    anchors.fill: parent

    property real baseWidth: 1024
    property real baseHeight: 600
    property real scale: Math.max(0.75, Math.min(width / baseWidth, height / baseHeight))

    Rectangle {
        anchors.fill: parent
        color: "#F5F7FC"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20 * root.scale
            spacing: 12 * root.scale

            // ===== PAGE TITLE =====
            Column {
                spacing: 6 * root.scale

                Text {
                    text: "Product Library"
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

            // ===== TOP BAR =====
            Rectangle {
                Layout.fillWidth: true
                height: 48 * root.scale
                radius: 8 * root.scale
                color: "#E9EEF8"
                border.color: "#D0D8EC"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8 * root.scale

                    Rectangle {
                        width: 160 * root.scale
                        height: 32 * root.scale
                        radius: 6 * root.scale
                        color: "#FFFFFF"
                        border.color: "#B0BEE0"

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 6 * root.scale

                            Text {
                                text: "GROUP: 01"
                                font.pixelSize: 16 * root.scale
                                Layout.fillWidth: true
                            }

                            Text { text: "▼"; font.pixelSize: 14 * root.scale }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Repeater {
                        model: ["LOAD", "ADD", "EDIT", "DELETE"]

                        delegate: Rectangle {
                            width: 90 * root.scale
                            height: 32 * root.scale
                            radius: 6 * root.scale
                            color: "#FFFFFF"
                            border.color: "#1A4DB5"

                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                font.pixelSize: 16 * root.scale
                                color: "#1A4DB5"
                                font.weight: Font.Medium
                            }
                        }
                    }
                }
            }

            // ===== MAIN CONTENT =====
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 10 * root.scale

                // ===== TABLE =====
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 10 * root.scale
                    color: "#FFFFFF"
                    border.color: "#D0D8EC"
                    border.width: 1
                    clip: true

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0

                        // ===== HEADER =====
                        Rectangle {
                            Layout.fillWidth: true
                            height: 44 * root.scale
                            color: "#1A4DB5"
                            radius: 10 * root.scale

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10 * root.scale

                                Text { text: "Active"; Layout.preferredWidth: 70 * root.scale; color: "white"; font.bold: true; font.pixelSize: 18 * root.scale }
                                Text { text: "Gr"; Layout.preferredWidth: 60 * root.scale; color: "white"; font.bold: true; font.pixelSize: 18 * root.scale }
                                Text { text: "Sr"; Layout.preferredWidth: 60 * root.scale; color: "white"; font.bold: true; font.pixelSize: 18 * root.scale }
                                Text { text: "Product Name"; Layout.preferredWidth: 220 * root.scale; color: "white"; font.bold: true; font.pixelSize: 18 * root.scale }
                                Text { text: "Product Code"; Layout.preferredWidth: 200 * root.scale; color: "white"; font.bold: true; font.pixelSize: 18 * root.scale }
                            }
                        }

                        // ===== DATA =====
                        ListView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            model: ListModel {
                                ListElement { active: "A"; gr: "01"; sr: "1"; name: "default name"; code: "default code" }
                                ListElement { active: "A"; gr: "01"; sr: "1"; name: "default name"; code: "default code" }
                                ListElement { active: "A"; gr: "01"; sr: "1"; name: "default name"; code: "default code" }
                            }

                            delegate: Rectangle {
                                width: ListView.view.width
                                height: 42 * root.scale
                                color: index % 2 === 0 ? "#FFFFFF" : "#F4F7FF"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10 * root.scale

                                    Text { text: active; Layout.preferredWidth: 70 * root.scale; font.pixelSize: 18 * root.scale }
                                    Text { text: gr; Layout.preferredWidth: 60 * root.scale; font.pixelSize: 18 * root.scale }
                                    Text { text: sr; Layout.preferredWidth: 60 * root.scale; font.pixelSize: 18 * root.scale }
                                    Text { text: name; Layout.preferredWidth: 220 * root.scale; font.pixelSize: 18 * root.scale }
                                    Text { text: code; Layout.preferredWidth: 200 * root.scale; font.pixelSize: 18 * root.scale }
                                }
                            }
                        }
                    }
                }

                // ===== SIDE PANEL =====
                Rectangle {
                    Layout.preferredWidth: 260 * root.scale
                    Layout.fillHeight: true
                    radius: 10 * root.scale
                    color: "#FFFFFF"
                    border.color: "#D0D8EC"

                    Column {
                        anchors.fill: parent
                        anchors.margins: 14 * root.scale
                        spacing: 10 * root.scale

                        Text {
                            text: "Details"
                            font.pixelSize: 20 * root.scale
                            font.bold: true
                            color: "#1A4DB5"
                        }

                        Rectangle { width: parent.width; height: 2; color: "#E4EAF5" }

                        Text { text: "Phase: 110"; font.pixelSize: 20 * root.scale }
                        Text { text: "Signal: 500"; font.pixelSize: 20 * root.scale }
                        Text { text: "Amplitude : 14000"; font.pixelSize: 20 * root.scale }
                        Text { text: "Digital Gain : 1"; font.pixelSize: 20 * root.scale }
                        Text { text: "Analog Gain : 1"; font.pixelSize: 20 * root.scale }
                        Text { text: "DD Frequency : 18"; font.pixelSize: 20 * root.scale }
                        Text { text: "DD Power : 50"; font.pixelSize: 20 * root.scale }
                    }
                }
            }
        }
    }
}
