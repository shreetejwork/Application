import QtQuick
import QtQuick.Controls

Item {
    id: root

    // =========================================================
    // PROPERTIES
    // =========================================================

    property int totalSeconds: 1800  // 30 minutes
    property int remainingSeconds: totalSeconds
    property real size: 60
    property bool showLabel: true

    // =========================================================
    // SIGNALS
    // =========================================================

    signal longPressed()
    signal clicked()

    // =========================================================
    // STYLING
    // =========================================================

    property color backgroundColor: "#E8F0FE"
    property color progressColor: "#1A4DB5"
    property color textColor: "#1A4DB5"

    width: size
    height: size

    // =========================================================
    // CALCULATE PROGRESS
    // =========================================================

    readonly property real progress: Math.max(0, Math.min(1, remainingSeconds / totalSeconds))
    readonly property int minutes: Math.floor(remainingSeconds / 60)
    readonly property int seconds: remainingSeconds % 60

    // =========================================================
    // MAIN CIRCLE
    // =========================================================

    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d")
            var centerX = width / 2
            var centerY = height / 2
            var radius = Math.min(width, height) / 2 - 2

            // Clear canvas
            ctx.clearRect(0, 0, width, height)

            // Background circle
            ctx.fillStyle = root.backgroundColor
            ctx.beginPath()
            ctx.arc(centerX, centerY, radius, 0, Math.PI * 2)
            ctx.fill()

            // Progress arc
            ctx.strokeStyle = root.progressColor
            ctx.lineWidth = 4
            ctx.lineCap = "round"

            // Draw arc from top, going clockwise for progress
            var startAngle = -Math.PI / 2  // Top
            var endAngle = startAngle + (Math.PI * 2 * root.progress)

            ctx.beginPath()
            ctx.arc(centerX, centerY, radius, startAngle, endAngle)
            ctx.stroke()

            // Border circle
            ctx.strokeStyle = root.progressColor
            ctx.lineWidth = 1
            ctx.globalAlpha = 0.3
            ctx.beginPath()
            ctx.arc(centerX, centerY, radius, 0, Math.PI * 2)
            ctx.stroke()
        }
    }

    // =========================================================
    // TIME TEXT
    // =========================================================

    Text {
        anchors.centerIn: parent
        visible: root.showLabel

        text: {
            var m = root.minutes.toString().padStart(2, '0')
            var s = root.seconds.toString().padStart(2, '0')
            return m + ":" + s
        }

        font.pixelSize: Math.max(10, root.size * 0.35)
        font.bold: true
        color: root.textColor

        // Animation when time runs low (< 5 minutes)
        NumberAnimation on opacity {
            id: blinkAnimation
            from: 1.0
            to: 0.5
            duration: 500
            running: root.remainingSeconds < 300 && root.remainingSeconds > 0
            loops: Animation.Infinite
            alternatingDirection: true
        }
    }

    // =========================================================
    // LONG PRESS HANDLING
    // =========================================================

    MouseArea {
        id: mouseArea
        anchors.fill: parent

        property bool isLongPressing: false
        property int pressStartTime: 0

        onPressed: {
            isLongPressing = true
            pressStartTime = new Date().getTime()
        }

        onReleased: {
            var pressDuration = new Date().getTime() - pressStartTime
            isLongPressing = false

            // Long press threshold: 500ms
            if (pressDuration >= 500) {
                root.longPressed()
            } else {
                root.clicked()
            }
        }

        onCanceled: {
            isLongPressing = false
        }
    }

    // =========================================================
    // UPDATE CANVAS
    // =========================================================

    onRemainingSecondsChanged: {
        canvas.requestPaint()
    }

    onProgressChanged: {
        canvas.requestPaint()
    }

    // =========================================================
    // COLOR CHANGE BASED ON TIME
    // =========================================================

    onRemainingSecondsChanged: {
        // Change color to warning when < 5 minutes
        if (root.remainingSeconds < 300 && root.remainingSeconds > 0) {
            root.progressColor = "#FF6B6B"  // Red
        } else if (root.remainingSeconds > 0) {
            root.progressColor = "#1A4DB5"  // Blue
        }
    }
}
