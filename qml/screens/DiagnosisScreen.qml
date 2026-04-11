import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Item {
    id: root
    anchors.fill: parent

    property real baseWidth: 1024
    property real baseHeight: 600
    property real scale: Math.min(width / baseWidth, height / baseHeight)
    property var navigateTo

    Rectangle {
        anchors.fill: parent
        color: "#F5F7FC"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 30 * root.scale
            spacing: 20 * root.scale

            // ===== HEADER =====
            RowLayout {
                Layout.fillWidth: true
                spacing: 16 * root.scale

                Column {
                    spacing: 6 * root.scale

                    Text {
                        text: "System Diagnosis"
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

                Item { Layout.fillWidth: true }

                Rectangle {
                    width: 110 * root.scale
                    height: 38 * root.scale
                    radius: 8 * root.scale
                    color: "#1A4DB5"

                    Text {
                        anchors.centerIn: parent
                        text: "Run All"
                        color: "#FFFFFF"
                        font.pixelSize: 18 * root.scale
                        font.weight: Font.Medium
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            cpuStatus.status  = "Checking..."
                            memStatus.status  = "Checking..."
                            netStatus.status  = "Checking..."
                            tempStatus.status = "Checking..."
                            runTimer.restart()
                        }
                    }
                }
            }

            // ===== DIVIDER =====
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#DDDDDD"
            }

            // ===== CARDS GRID =====
            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 2
                rowSpacing: 16 * root.scale
                columnSpacing: 16 * root.scale

                DiagCard {
                    id: cpuStatus
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    title: "CPU"
                    status: "OK"
                    detail: "Usage: 24%"
                    scale: root.scale
                }

                DiagCard {
                    id: memStatus
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    title: "Memory"
                    status: "OK"
                    detail: "Used: 1.2 GB / 4 GB"
                    scale: root.scale
                }

                DiagCard {
                    id: netStatus
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    title: "Network"
                    status: "OK"
                    detail: "Ping: 12 ms"
                    scale: root.scale
                }

                DiagCard {
                    id: tempStatus
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    title: "Temperature"
                    status: "OK"
                    detail: "Core: 42°C"
                    scale: root.scale
                }
            }
        }
    }

    // ===== TIMER =====
    Timer {
        id: runTimer
        interval: 1500
        repeat: false
        onTriggered: {
            cpuStatus.status  = "OK"
            memStatus.status  = "OK"
            netStatus.status  = "OK"
            tempStatus.status = "Warning"
        }
    }
}
