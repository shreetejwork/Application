import QtQuick

Item {
    id: root

    // ✅ SAFE SCALE
    property real baseHeight: 120
    property real scale: Math.max(0.6, height / baseHeight)

    property int value: 1500
    property int maxValue: 3000
    property string label: "Coil"
    property color fillColor: "#4CAF50"
    property color trackColor: "#E0E0E0"

    readonly property real fillRatio: Math.min(1.0, Math.max(0.0, value / maxValue))

    Column {
        anchors.fill: parent

        // ✅ SAFE SPACING
        spacing: Math.max(6, parent.height * 0.08)

        Item {
            id: trackArea
            width: parent.width

            // ✅ MIN HEIGHT SAFETY
            height: Math.max(48, root.height * 0.50)

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: parent.height * 0.38
                radius: height / 2
                color: root.trackColor

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    width: parent.width * root.fillRatio
                    height: parent.height
                    radius: height / 2
                    color: root.fillColor
                }
            }

            // 🔘 HANDLE
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter

                x: Math.min(
                    parent.width - width,
                    Math.max(0, (parent.width * root.fillRatio) - width / 2)
                )

                // ✅ SIZE SAFETY
                width: Math.max(48, parent.height * 0.85)
                height: Math.max(48, parent.height * 0.85)

                radius: Math.max(4, width * 0.08)
                color: "#888888"
                opacity: 0.85

                Column {
                    anchors.centerIn: parent

                    // ✅ SAFE SPACING
                    spacing: Math.max(2, parent.height * 0.05)

                    Repeater {
                        model: 3
                        Rectangle {
                            width: parent.parent.width * 0.45

                            // ✅ LINE VISIBILITY FIX
                            height: Math.max(2, parent.parent.height * 0.08)

                            color: "white"
                            opacity: 0.8
                        }
                    }
                }
            }

            MultiPointTouchArea {
                anchors.fill: parent
                maximumTouchPoints: 1

                onUpdated: {
                    var tp = touchPoints[0]
                    var ratio = Math.min(1.0, Math.max(0.0, tp.x / trackArea.width))
                    root.value = Math.round(ratio * root.maxValue)
                }
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter

            // ✅ SAFE SPACING
            spacing: Math.max(6, root.width * 0.015)

            Text {
                text: root.label + " :"

                // ✅ FONT CLAMP (NO DESIGN CHANGE)
                font.pixelSize: Math.max(12, root.height * 0.22)
                color: "#222"
            }

            Text {
                text: root.value

                // ✅ FONT CLAMP
                font.pixelSize: Math.max(12, root.height * 0.22)
                font.bold: true
                color: "#1A4DB5"
            }
        }
    }
}
