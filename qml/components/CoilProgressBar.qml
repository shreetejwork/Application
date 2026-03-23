import QtQuick

Item {
    id: root

    // ================= INPUT =================
    property int value: 1500
    property int maxValue: 3000
    property string label: "Coil"

    // ================= COLORS (BACKWARD SAFE) =================
    property color fillColor: "#4CAF50"     // OLD SUPPORT (DO NOT REMOVE)
    property color baseColor: fillColor     // NEW SYSTEM USES THIS
    // Gradient middle (yellow) and end (red) colors
    property color gradientMidColor: "#F5C242"
    property color gradientEndColor: "#E53935"
    property color trackColor: "#E6E6E6"
    property color handleColor: "#2E2E2E"

    // ================= RATIO =================
    property real ratio: Math.min(1, Math.max(0, value / maxValue))

    // smooth value animation
    Behavior on value {
        NumberAnimation { duration: 120 }
    }

    Column {
        anchors.fill: parent
        spacing: Math.max(10, height * 0.08)

        // ================= TRACK =================
        Item {
            id: trackArea
            width: parent.width
            // Taller bar area so the pill matches the reference screenshot.
            height: Math.max(48, parent.height * 0.70)

            // BACK TRACK
            Rectangle {
                id: bgTrack
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: parent.height * 0.80
                radius: height / 2
                color: root.trackColor
                border.color: "#6F95D6"
                border.width: 2
            }

            // ================= FILLED BAR =================
            Rectangle {
                id: fillBar
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width * root.ratio
                height: bgTrack.height
                radius: height / 2

                // Horizontal left->right color change
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: root.baseColor }
                    GradientStop { position: 0.55; color: root.gradientMidColor }
                    GradientStop { position: 1.0; color: root.gradientEndColor }
                }
            }

            // ================= NEEDLE MARKER =================
            // Teardrop/needle marker at the current value position.
            Item {
                id: needle
                width: Math.max(14, bgTrack.height * 0.35)
                height: bgTrack.height * 1.08

                // Place the bottom tip at the top of the pill (slightly overlapping).
                anchors.bottom: bgTrack.top
                anchors.bottomMargin: -2

                x: Math.min(
                    parent.width - width,
                    Math.max(0, parent.width * root.ratio - width / 2)
                )

                Canvas {
                    anchors.fill: parent
                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)

                        var w = width
                        var h = height

                        // Teardrop path (point down)
                        ctx.beginPath()
                        ctx.moveTo(w / 2, h) // bottom tip
                        ctx.quadraticCurveTo(w * 0.95, h * 0.78, w * 0.82, h * 0.55)
                        ctx.quadraticCurveTo(w * 0.68, h * 0.28, w / 2, 0)
                        ctx.quadraticCurveTo(w * 0.32, h * 0.28, w * 0.18, h * 0.55)
                        ctx.quadraticCurveTo(w * 0.05, h * 0.78, w / 2, h)
                        ctx.closePath()

                        ctx.fillStyle = "#1A4DB5"
                        ctx.strokeStyle = "#0D3BA8"
                        ctx.lineWidth = 2
                        ctx.fill()
                        ctx.stroke()

                        // small highlight near the top
                        ctx.beginPath()
                        ctx.arc(w / 2, h * 0.18, Math.max(2, w * 0.16), 0, Math.PI * 2)
                        ctx.fillStyle = "white"
                        ctx.globalAlpha = 0.25
                        ctx.fill()
                        ctx.globalAlpha = 1.0
                    }
                }
            }

            // ================= TOUCH =================
            MultiPointTouchArea {
                anchors.fill: parent
                maximumTouchPoints: 1

                onUpdated: {
                    var tp = touchPoints[0]
                    var ratio = Math.min(1.0, Math.max(0.0, tp.x / width))
                    root.value = Math.round(ratio * root.maxValue)
                }
            }
        }

        // ================= LABEL + VALUE =================
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 28

            Text {
                text: root.label
                font.pixelSize: Math.max(16, root.height * 0.18)
                color: "#1A4DB5"
            }

            Text {
                text: root.value
                font.pixelSize: Math.max(16, root.height * 0.18)
                font.bold: true
                color: "#111827"
                font.family: "monospace"
            }
        }
    }
}
