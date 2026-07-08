import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    Typography {
        id: componentTypography
        scale: root.scale || 1.0
    }
    id: root

    property int value: 2208
    property int maxValue: 10000
    property string label: "Coil Output"

    property color trackColor: "#D9D9D9"

    property real ratio: Math.min(1, Math.max(0, value / maxValue))

    width: 500
    height: 140

    Behavior on value {
        NumberAnimation { duration: 150 }
    }

    Column {
        anchors.centerIn: parent
        width: parent.width
        spacing: 12

        // ================= TRACK =================
        Item {
            id: track
            width: parent.width
            height: 24

            // ===== BACKGROUND =====
            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: root.trackColor
            }

            // ===== COLOR BARS =====
            Item {
                anchors.fill: parent
                clip: true

                // GREEN
                Rectangle {
                    x: 0
                    height: parent.height
                    color: "#3FAE6A"
                    width: Math.min(root.value, 2800) / root.maxValue * parent.width
                    radius: width > 0 ? height / 2 : 0
                }

                // GREEN → YELLOW
                Rectangle {
                    height: parent.height
                    x: (2600 / root.maxValue) * parent.width - 1

                    width: root.value <= 2600 ? 0 :
                           Math.min(root.value - 2600, 1600) / root.maxValue * parent.width + 1

                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "#3FAE6A" }
                        GradientStop { position: 1.0; color: "#F5C242" }
                    }
                }

                // YELLOW → ORANGE
                Rectangle {
                    height: parent.height
                    x: (4200 / root.maxValue) * parent.width - 1

                    width: root.value <= 4200 ? 0 :
                           Math.min(root.value - 4200, 1000) / root.maxValue * parent.width + 1

                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "#F5C242" }
                        GradientStop { position: 1.0; color: "#F39C34" }
                    }
                }

                // ORANGE
                Rectangle {
                    height: parent.height
                    color: "#F39C34"

                    x: (5200 / root.maxValue) * parent.width - 1

                    width: root.value <= 5200 ? 0 :
                           Math.min(root.value - 5200, 2000) / root.maxValue * parent.width + 1
                }

                // ================= ORANGE → RED =================
                Rectangle {
                    height: parent.height

                    // Start gradient at 5500
                    x: (5500 / root.maxValue) * parent.width - 1

                    width: root.value <= 5500 ? 0 :
                           Math.min(root.value - 5500, 3300) / root.maxValue * parent.width + 2

                    gradient: Gradient {
                        orientation: Gradient.Horizontal

                        GradientStop { position: 0.0;  color: "#F39C34" } // Orange
                        GradientStop { position: 0.25; color: "#F07F2F" } // Orange-Red
                        GradientStop { position: 0.50; color: "#EC5E2B" } // Deep Orange
                        GradientStop { position: 0.75; color: "#E84A2F" } // Near Red
                        GradientStop { position: 1.0;  color: "#E53935" } // Red
                    }

                    Behavior on width {
                        NumberAnimation { duration: 150 }
                    }
                }

                // ================= SOLID RED =================
                Rectangle {
                    height: parent.height
                    color: "#E53935"

                    // Start solid red after gradient ends
                    x: (8800 / root.maxValue) * parent.width - 1

                    width: root.value <= 8800 ? 0 :
                           (root.value - 8800) / root.maxValue * parent.width + 1

                    radius: root.value >= root.maxValue ? height / 2 : 0
                }
            }

            // ===== BORDER =====
            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: "transparent"
                border.color: "black"
                border.width: 2
                z: 10
            }

            // ===== NEEDLE =====
            Rectangle {
                id: needle
                width: 5
                height: track.height + 8
                radius: 6
                color: "black"
                border.color: "#0D3BA8"
                border.width: 1
                anchors.verticalCenter: parent.verticalCenter

                x: Math.min(track.width - width,
                            Math.max(0, track.width * root.ratio - width / 2))

                Behavior on x { NumberAnimation { duration: 150 } }
                z: 20
            }

            // ===== CLICK INTERACTION =====
            MouseArea {
                anchors.fill: parent

                onClicked: function(mouse) {
                    var xPos = Math.min(Math.max(mouse.x, 0), track.width)
                    root.value = Math.round((xPos / track.width) * root.maxValue)
                }

                onPositionChanged: function(mouse) {
                    if (!(mouse.buttons & Qt.LeftButton)) return
                    var xPos = Math.min(Math.max(mouse.x, 0), track.width)
                    root.value = Math.round((xPos / track.width) * root.maxValue)
                }
            }
        }

        // ===== LABEL =====
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8

            Text {
                text: root.label
                font.pixelSize: componentTypography.body

                color: "#1A4DB5"
            }

            Text {
                text: ":"
                font.pixelSize: componentTypography.body

            }

            Text {
                text: root.value
                font.pixelSize: componentTypography.body

            }
        }

        // ================= SLIDER (LIVE TEST) =================
        // Slider {
        //     id: testSlider
        //     width: parent.width
        //     from: 0
        //     to: root.maxValue
        //     value: root.value

        //     onValueChanged: {
        //         root.value = Math.round(value)
        //     }
        // }
    }
}
