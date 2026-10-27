import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Backend 1.0

Item {
    id: root
    anchors.fill: parent

    property real scale: Math.max(0.85, Math.min(width / 1024, height / 600))

    Rectangle {
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.78, 700 * root.scale)
        height: 230 * root.scale
        radius: 22 * root.scale
        color: "#FFFFFF"
        border.width: 2
        border.color: "#6F95D6"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 28 * root.scale
            spacing: 22 * root.scale

            ColumnLayout {
                spacing: 4 * root.scale

                Text {
                    text: "Versions"
                    font.pixelSize: 26 * root.scale
                    color: "#1A4DB5"
                }

                Rectangle {
                    width: 40 * root.scale
                    height: 3 * root.scale
                    radius: 2 * root.scale
                    color: "#1A4DB5"
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 16 * root.scale

                Repeater {
                    model: [
                        { label: "App Version", value: "v" + Qt.application.version },
                        {
                            label: "CPU Version",
                            value: SerialManager.cpuVersion.length
                                   ? SerialManager.cpuVersion : "----"
                        }
                    ]

                    delegate: Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 14 * root.scale
                        color: "#F5F8FF"
                        border.width: 1
                        border.color: "#D7E2F5"

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 18 * root.scale
                            spacing: 8 * root.scale

                            Text {
                                text: modelData.label
                                font.pixelSize: 20 * root.scale
                                color: "#5B6B8C"
                            }

                            Text {
                                text: modelData.value
                                font.pixelSize: 28 * root.scale
                                color: "#1A4DB5"
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
            }
        }
    }
}
