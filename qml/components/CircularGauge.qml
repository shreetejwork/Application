import QtQuick
import QtQuick.Controls

Item {
    Typography {
        id: componentTypography
        scale: root.scale || 1.0
    }
    id: root

    property real sizeRef: Math.min(width, height)
    
    // =========================================================
    // TYPOGRAPHY FOR CIRCULAR GAUGE
    // =========================================================
    
    Typography {
        id: gaugeTypography
        scale: Math.min(root.width / 200, root.height / 200)
    }

    property real value: 950
    property real threshold: 500
    property real maxValue: 1200

    property string label: "Signal"
    property string thresholdLabel: "Thr-S"

    property color signalColor: "#F39AAC"
    property color thresholdColor: "#6D5BD0"
    property color overColor: "#FF4D4D"
    property color bgColor: "#EEF1F6"

    readonly property real startAngle: 0
    readonly property real span: 260
    readonly property real colorSpan: 340

    // Signal when threshold text is clicked
    signal thresholdClicked()

    function toDeg(v) {
        return startAngle + (v / maxValue) * colorSpan
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()

            var cx = width / 2
            var cy = height / 2

            var radius = sizeRef * 0.42
            var widthArc = Math.max(6, sizeRef * 0.06)

            // Rounded cap compensation
            var capOffsetDeg =
                    (widthArc / radius)
                    * (180 / Math.PI)
                    * 0.5

            function rad(d) {
                return (d - 90) * Math.PI / 180
            }

            // =====================================================
            // CONSTANT THRESHOLD POSITION
            // =====================================================

            var fixedThresholdDeg = 110

            // =====================================================
            // VALUE MAPPING LOGIC
            // =====================================================

            // -----------------------------------------------------
            // VISUAL ZONES
            // -----------------------------------------------------

            // Zone 1:
            // 0° -> 110°
            var zone1EndDeg = fixedThresholdDeg

            // Zone 2:
            // 110° -> 180°
            var zone2EndDeg = 250

            // Zone 3:
            // 180° -> 360°
            var zone3EndDeg = 360

            // -----------------------------------------------------
            // VALUE ZONES
            // -----------------------------------------------------

            // Zone 1:
            // 0 -> threshold
            var zone1Limit = root.threshold

            // Zone 2:
            // threshold -> 3000
            var zone2Limit = 3000

            // Zone 3:
            // 3000 -> 65000
            var zone3Limit = 65000

            // -----------------------------------------------------
            // CLAMP VALUE
            // -----------------------------------------------------

            var valueClamped =
                    Math.max(0,
                             Math.min(root.value,
                                      zone3Limit))

            var signalDeg = 0
            var overDeg = 0

            // =====================================================
            // ZONE 1
            // 0 -> threshold
            // =====================================================

            if (valueClamped <= zone1Limit) {

                signalDeg =
                        (valueClamped / zone1Limit)
                        * zone1EndDeg
            }

            // =====================================================
            // ZONE 2
            // threshold -> 3000
            // =====================================================

            else if (valueClamped <= zone2Limit) {

                // Pink fixed till threshold
                signalDeg = zone1EndDeg

                var zone2Value =
                        valueClamped - zone1Limit

                var zone2Range =
                        zone2Limit - zone1Limit

                overDeg =
                        (zone2Value / zone2Range)
                        * (zone2EndDeg - zone1EndDeg)
            }

            // =====================================================
            // ZONE 3
            // 3000 -> 65000
            // =====================================================

            else {

                // Pink fixed
                signalDeg = zone1EndDeg

                // Fill full zone 2 first
                overDeg = zone2EndDeg - zone1EndDeg

                var zone3Value =
                        valueClamped - zone2Limit

                var zone3Range =
                        zone3Limit - zone2Limit

                overDeg +=
                        (zone3Value / zone3Range)
                        * (zone3EndDeg - zone2EndDeg)
            }

            // =====================================================
            // BACKGROUND CIRCLE
            // =====================================================

            ctx.beginPath()

            ctx.arc(
                cx,
                cy,
                radius + widthArc * 1.5,
                0,
                Math.PI * 2
            )

            ctx.fillStyle = bgColor
            ctx.fill()

            // =====================================================
            // FULL GREY BASE ARC
            // =====================================================

            ctx.beginPath()
            ctx.lineWidth = widthArc
            ctx.strokeStyle = "#E3E6EE"
            ctx.lineCap = "round"

            ctx.arc(
                cx,
                cy,
                radius,
                0,
                Math.PI * 2
            )

            ctx.stroke()

            // =====================================================
            // FIXED THRESHOLD ARC
            // =====================================================

            ctx.beginPath()
            ctx.lineWidth = widthArc
            ctx.strokeStyle = thresholdColor
            ctx.lineCap = "round"

            ctx.arc(
                cx,
                cy,
                radius - widthArc * 0.6,
                rad(0),
                rad(fixedThresholdDeg)
            )

            ctx.stroke()

            // =====================================================
            // SIGNAL ARC
            // =====================================================

            ctx.beginPath()
            ctx.lineWidth = widthArc
            ctx.strokeStyle = signalColor
            ctx.lineCap = "round"

            ctx.arc(
                cx,
                cy,
                radius,
                rad(0),
                rad(signalDeg)
            )

            ctx.stroke()

            // =====================================================
            // OVER ARC
            // =====================================================

            if (valueClamped > root.threshold) {

                ctx.beginPath()
                ctx.lineWidth = widthArc
                ctx.strokeStyle = overColor
                ctx.lineCap = "round"

                var redStartDeg =
                        signalDeg + capOffsetDeg

                var redEndDeg =
                        signalDeg + overDeg + capOffsetDeg

                ctx.arc(
                    cx,
                    cy,
                    radius,
                    rad(redStartDeg),
                    rad(redEndDeg)
                )

                ctx.stroke()
            }
        }
    }
    Column {
        anchors.centerIn: parent
        spacing: Math.max(6, sizeRef * 0.03)

        Text {
            text: root.value
            font.pixelSize: gaugeTypography.heading
            // font.bold: true
            color: "#2446B8"
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: root.label
            font.pixelSize: gaugeTypography.small
            font.bold: true
            color: "#333"
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Rectangle {
            width: sizeRef * 0.35
            height: Math.max(1, sizeRef * 0.01)
            color: "#9BB8E8"
            anchors.horizontalCenter: parent.horizontalCenter
        }

        // CLICKABLE THRESHOLD AREA
        Item {
            width: parent.width
            height: thresholdColumn.height
            anchors.horizontalCenter: parent.horizontalCenter

            Column {
                id: thresholdColumn
                anchors.centerIn: parent
                spacing: Math.max(3, sizeRef * 0.02)

                Text {
                    text: root.threshold
                    font.pixelSize: gaugeTypography.heading
                    color: "#444"
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: root.thresholdLabel
                    font.pixelSize: gaugeTypography.small
                    font.bold: true
                    color: "#2446B8"
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.thresholdClicked()
            }
        }

    }

    onValueChanged: canvas.requestPaint()
    onThresholdChanged: canvas.requestPaint()
    onWidthChanged: canvas.requestPaint()
    onHeightChanged: canvas.requestPaint()

    Component.onCompleted: canvas.requestPaint()
}
