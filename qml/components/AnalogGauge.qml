import QtQuick
import QtQuick.Controls

Item {
    id: root

    // KEEP FLEXIBLE SIZE (parent controlled)
    // width: 500
    // height: 400


    property real baseHeight: 400
    property real scale: Math.max(0.6, height / baseHeight)

    property real productPhase: 40
    property real machinePhase: 60

    property real minValue: 0
    property real maxValue: 180
    readonly property real valueRange: maxValue - minValue

    property color needleColor: "#1A4DB5"
    property color tickColor: "#2A2A4A"

    function valueToAngleDeg(v) {
        var startDeg = -90
        var sweepDeg = 180
        return startDeg + (v / valueRange) * sweepDeg
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()

            var cx = width * 0.15
            var cy = height * 0.50
            var radius = height * 0.45

            var tickMajorLen = radius * 0.07
            var tickMinorLen = radius * 0.04

            var fontSize = Math.max(7 * root.scale, radius * 0.075)
            var labelOffset = radius * 0.14

            // --- TICKS AND LABELS ---
            for (var v = root.minValue; v <= root.maxValue; v += 5) {
                var isMajor = (v % 10 === 0)
                var tLen = isMajor ? tickMajorLen : tickMinorLen
                var angleRad = root.valueToAngleDeg(v) * Math.PI / 180

                var ox = cx + radius * Math.cos(angleRad)
                var oy = cy + radius * Math.sin(angleRad)
                var ix = cx + (radius - tLen) * Math.cos(angleRad)
                var iy = cy + (radius - tLen) * Math.sin(angleRad)

                ctx.beginPath()
                ctx.moveTo(ox, oy)
                ctx.lineTo(ix, iy)
                ctx.strokeStyle = root.tickColor
                ctx.lineWidth = (isMajor ? 4 : 2) * root.scale
                ctx.stroke()

                if (isMajor) {
                    var labelR = radius - tLen - labelOffset
                    var lx = cx + labelR * Math.cos(angleRad)
                    var ly = cy + labelR * Math.sin(angleRad)

                    ctx.font = "bold " + fontSize + "px sans-serif"
                    ctx.fillStyle = root.tickColor
                    ctx.textAlign = "center"
                    ctx.textBaseline = "middle"
                    ctx.fillText(v.toString(), lx, ly)
                }
            }

            // --- PRODUCT PHASE MARKER (RED DASH) ---
            var mAngleRad = root.valueToAngleDeg(root.productPhase) * Math.PI / 180
            var outerR = radius
            var innerR = radius - radius * 0.10
            var thickness = radius * 0.035
            var perp = mAngleRad + Math.PI / 2

            var ox = cx + outerR * Math.cos(mAngleRad)
            var oy = cy + outerR * Math.sin(mAngleRad)
            var ix = cx + innerR * Math.cos(mAngleRad)
            var iy = cy + innerR * Math.sin(mAngleRad)

            ctx.beginPath()
            ctx.moveTo(ox + thickness * Math.cos(perp), oy + thickness * Math.sin(perp))
            ctx.lineTo(ox - thickness * Math.cos(perp), oy - thickness * Math.sin(perp))
            ctx.lineTo(ix - thickness * Math.cos(perp), iy - thickness * Math.sin(perp))
            ctx.lineTo(ix + thickness * Math.cos(perp), iy + thickness * Math.sin(perp))
            ctx.closePath()
            ctx.fillStyle = "rgba(255, 0, 0, 0.6)"
            ctx.fill()

            // -------- NEEDLE FOR MACHINE PHASE --------
            var nAngleRad = root.valueToAngleDeg(root.machinePhase) * Math.PI / 180
            var startOffset = radius * 0.60   // distance from center
            var needleLen = radius * 0.15     // short needle
            var baseOffset = radius * 0.025   // width of needle

            var startX = cx + startOffset * Math.cos(nAngleRad)
            var startY = cy + startOffset * Math.sin(nAngleRad)
            var tipX = cx + (startOffset + needleLen) * Math.cos(nAngleRad)
            var tipY = cy + (startOffset + needleLen) * Math.sin(nAngleRad)

            var perpNeedle = nAngleRad + Math.PI / 2

            ctx.beginPath()
            ctx.moveTo(tipX, tipY)
            ctx.lineTo(startX + baseOffset * Math.cos(perpNeedle), startY + baseOffset * Math.sin(perpNeedle))
            ctx.lineTo(startX - baseOffset * Math.cos(perpNeedle), startY - baseOffset * Math.sin(perpNeedle))
            ctx.closePath()
            ctx.fillStyle = root.needleColor
            ctx.fill()
        }
    }

    onProductPhaseChanged: canvas.requestPaint()
    onMachinePhaseChanged: canvas.requestPaint()
    Component.onCompleted: canvas.requestPaint()

    Column {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: parent.width * 0.10


        spacing: Math.max(6, height * 0.035)

        Text {
            text: root.productPhase
            font.pixelSize: Math.max(12, root.height * 0.07)
            font.bold: true
            color: "#1A4DB5"
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            text: "Product Phase"
            font.pixelSize: Math.max(10, root.height * 0.035)
            font.bold: true
            color: "#111"
            horizontalAlignment: Text.AlignHCenter
        }

        Rectangle {
            width: parent.width * 0.4
            height: Math.max(1, 2 * root.scale)
            color: "#90CAF9"
        }

        Text {
            text: root.machinePhase
            font.pixelSize: Math.max(12, root.height * 0.055)
            color: "#111"
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            text: "Machine Phase"
            font.pixelSize: Math.max(10, root.height * 0.035)
            font.bold: true
            color: "#1A4DB5"
            horizontalAlignment: Text.AlignHCenter
        }
    }

    Text {
        anchors.bottom: machineSlider.top
        anchors.horizontalCenter: machineSlider.horizontalCenter
        anchors.bottomMargin: 6

        text: "Product Phase: " + Math.round(machineSlider.value)


        font.pixelSize: Math.max(12, 16 * root.scale)
        color: "#333"
    }

    Slider {
        id: machineSlider
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 20

        width: parent.width * 0.6

        from: root.minValue
        to: root.maxValue
        stepSize: 1
        value: root.productPhase

        onValueChanged: root.productPhase = value
    }
}
