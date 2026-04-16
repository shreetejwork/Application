import QtQuick

Item {
    id: root

    property real sizeRef: Math.min(width, height)

    property real value: 950
    property real threshold: 500
    property real maxValue: 1200

    property string label: "Signal"
    property string thresholdLabel: "Thr-S"

    property color signalColor: "#6D5BD0"
    property color thresholdColor: "#F39AAC"
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
            var capOffsetDeg = (widthArc / radius) * (180 / Math.PI) * 0.5
            function rad(d) { return (d - 90) * Math.PI / 180 }

            // BACKGROUND CIRCLE
            ctx.beginPath()
            ctx.arc(cx, cy, radius + widthArc * 1.5, 0, Math.PI * 2)
            ctx.fillStyle = bgColor
            ctx.fill()

            // GREY BASE ARC
            ctx.beginPath()
            ctx.lineWidth = widthArc
            ctx.strokeStyle = "#E3E6EE"
            ctx.lineCap = "round"
            ctx.arc(cx, cy, radius,
                    rad(startAngle),
                    rad(startAngle + span))
            ctx.stroke()

            // THRESHOLD ARC
            var thresholdClamped = Math.max(0, Math.min(root.threshold, root.maxValue))
            ctx.beginPath()
            ctx.lineWidth = widthArc
            ctx.strokeStyle = thresholdColor
            ctx.lineCap = "round"
            ctx.arc(cx, cy, radius - widthArc * 0.6,
                    rad(startAngle),
                    rad(toDeg(thresholdClamped) - capOffsetDeg))
            ctx.stroke()

            // SIGNAL ARC (limited by threshold)
            var valueClamped = Math.max(0, Math.min(root.value, root.maxValue))
            var signalEnd = Math.min(valueClamped, thresholdClamped)
            ctx.beginPath()
            ctx.lineWidth = widthArc
            ctx.strokeStyle = signalColor
            ctx.lineCap = "round"
            ctx.arc(cx, cy, radius,
                    rad(startAngle),
                    rad(toDeg(signalEnd)))
            ctx.stroke()

            // OVER ARC if value > threshold
            if (valueClamped > thresholdClamped) {
                ctx.beginPath()
                ctx.lineWidth = widthArc
                ctx.strokeStyle = overColor
                ctx.lineCap = "round"
                ctx.arc(cx, cy, radius,
                        rad(toDeg(thresholdClamped) + capOffsetDeg),
                        rad(toDeg(valueClamped)))
                ctx.stroke()
            }
        }
    }
    Column {
        anchors.centerIn: parent
        spacing: Math.max(6, sizeRef * 0.03)

        Text {
            text: root.value
            font.pixelSize: Math.max(14, sizeRef * 0.12)
            font.bold: true
            color: "#2446B8"
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: root.label
            font.pixelSize: Math.max(12, sizeRef * 0.08)
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
                    font.pixelSize: Math.max(13, sizeRef * 0.09)
                    color: "#444"
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: root.thresholdLabel
                    font.pixelSize: Math.max(12, sizeRef * 0.08)
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
