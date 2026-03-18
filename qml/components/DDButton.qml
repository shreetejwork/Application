import QtQuick

Item {
    id: root

    // ✅ SAFE SCALE (no layout change)
    property real baseSize: 120
    property real scale: Math.max(0.6, Math.min(width, height) / baseSize)

    property bool isOn: true
    property string label: "DD"
    property color onColor: "#4CAF50"
    property color offColor: "#F44336"

    signal clicked()

    readonly property color ringColor: root.isOn ? root.onColor : root.offColor
    property real pressScale: 1.0

    Rectangle {
        id: outerRing
        anchors.centerIn: parent

        width: Math.min(parent.width, parent.height) * root.pressScale
        height: width
        radius: width / 2

        color: "transparent"
        border.color: root.ringColor

        // ✅ SCALE SAFE BORDER
        border.width: Math.max(2, width * 0.055)

        Behavior on width {
            NumberAnimation { duration: 80; easing.type: Easing.OutQuad }
        }

        Rectangle {
            anchors.centerIn: parent
            width: parent.width + parent.border.width * 2
            height: width
            radius: width / 2
            color: "transparent"
            border.color: root.ringColor

            // ✅ SAFE MIN BORDER
            border.width: Math.max(1, 1 * root.scale)
            opacity: 0.35
        }

        Rectangle {
            anchors.centerIn: parent
            width: parent.width * 0.80
            height: width
            radius: width / 2

            gradient: Gradient {
                GradientStop { position: 0.0; color: "#FFFFFF" }
                GradientStop { position: 1.0; color: "#E0E0E0" }
            }

            Column {
                anchors.centerIn: parent

                // ✅ SAFE SPACING
                spacing: Math.max(4, parent.height * 0.04)

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.label

                    // ✅ SAME DESIGN + MIN CLAMP
                    font.pixelSize: Math.max(10, parent.parent.width * 0.22)
                    font.bold: true
                    color: "#222"
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.isOn ? "ON" : "OFF"

                    // ✅ SAME DESIGN + MIN CLAMP
                    font.pixelSize: Math.max(8, parent.parent.width * 0.13)
                    font.bold: true
                    color: root.ringColor
                }
            }
        }
    }

    MultiPointTouchArea {
        anchors.fill: parent
        maximumTouchPoints: 1

        onPressed: {
            root.pressScale = 0.93
        }

        onReleased: {
            root.pressScale = 1.0
            root.clicked()
        }

        onCanceled: {
            root.pressScale = 1.0
        }
    }
}
