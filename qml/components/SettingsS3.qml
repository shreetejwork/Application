import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    anchors.fill: parent

    property real baseWidth: 1024
    property real baseHeight: 600
    property real scale: Math.min(width / baseWidth, height / baseHeight)

    Rectangle {
        anchors.fill: parent
        color: "#F5F7FC"
    }

    // ===== MODEL =====
    ListModel {
        id: timeModel
        ListElement { time: "11:15"; enabled: false }
        ListElement { time: "11:30"; enabled: true }
        ListElement { time: "11:45"; enabled: false }
        ListElement { time: "11:00"; enabled: true }
    }

    // ===== MAIN CARD =====
    Rectangle {
        anchors.centerIn: parent
        width: 600 * root.scale
        height: 420 * root.scale
        radius: 16 * root.scale
        color: "#FFFFFF"
        border.color: "#E5E7EB"

        // ===== CONTENT =====
        Column {
            anchors.centerIn: parent
            width: parent.width - (40 * root.scale)
            spacing: 14 * root.scale

            // ===== TITLE =====
            Text {
                text: "Time Scheduler"
                font.pixelSize: 20 * root.scale
                font.bold: true
                color: "#1A4DB5"
            }

            Rectangle {
                width: 50 * root.scale
                height: 3 * root.scale
                color: "#1A4DB5"
                radius: 2
            }

            // ===== HEADER =====
            Row {
                width: parent.width
                spacing: 60 * root.scale

                Text { text: "Time"; font.bold: true; width: 120 * root.scale }
                Text { text: "Edit"; font.bold: true; width: 100 * root.scale }
                Text { text: "Enable"; font.bold: true }
            }

            Rectangle {
                height: 1
                width: parent.width
                color: "#E5E7EB"
            }

            // ===== LIST =====
            Repeater {
                model: timeModel

                Row {
                    width: parent.width
                    spacing: 60 * root.scale
                    height: 40 * root.scale

                    // Time
                    Rectangle {
                        width: 120 * root.scale
                        height: 30 * root.scale
                        radius: 6
                        color: "#EEF3FF"

                        Text {
                            anchors.centerIn: parent
                            text: model.time
                            color: "#1A4DB5"
                            font.bold: true
                        }
                    }

                    // Edit Button
                    Rectangle {
                        width: 80 * root.scale
                        height: 30 * root.scale
                        radius: 6
                        color: "#1A4DB5"

                        Text {
                            anchors.centerIn: parent
                            text: "Edit"
                            color: "#FFFFFF"
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                // Demo edit logic
                                timeModel.setProperty(index, "time", "12:00")
                            }
                        }
                    }

                    // Toggle
                    Rectangle {
                        width: 26 * root.scale
                        height: 26 * root.scale
                        radius: 4
                        border.color: "#1A4DB5"
                        color: model.enabled ? "#1A4DB5" : "#FFFFFF"

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                timeModel.setProperty(index, "enabled", !model.enabled)
                            }
                        }
                    }
                }
            }

            // Spacer to push buttons down
            Item {
                width: 1
                height: 10 * root.scale
            }
        }

        // ===== ACTION BUTTONS =====
        Row {
            spacing: 20 * root.scale
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: 20 * root.scale
            anchors.bottomMargin: 15 * root.scale

            Rectangle {
                width: 100 * root.scale
                height: 40 * root.scale
                radius: 8
                color: "#1A4DB5"

                Text {
                    anchors.centerIn: parent
                    text: "SAVE"
                    color: "#FFFFFF"
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        console.log("Saved:", JSON.stringify(timeModel))
                    }
                }
            }

            Rectangle {
                width: 100 * root.scale
                height: 40 * root.scale
                radius: 8
                color: "#D1D5DB"

                Text {
                    anchors.centerIn: parent
                    text: "ESC"
                    color: "#111827"
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        console.log("Exit clicked")
                    }
                }
            }
        }
    }
}
