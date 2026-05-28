import QtQuick
import QtQuick.Controls
import AppState 1.0

Item {
    Typography {
        id: componentTypography
        scale: root.scale || 1.0
    }
    id: root

    // ===== OPTIONAL TRACKING =====
    property real trackingPhase: -1
    property string trackingCountLabel: "Tracking Phase"

    property real baseHeight: 400
    property real scale: Math.max(0.6, height / baseHeight)

    // LOCAL STATE (SYNCED WITH GLOBAL)
    property real productPhase: 0
    property real machinePhase: 0

    property real minValue: 0
    property real maxValue: 180
    readonly property real valueRange: maxValue - minValue

    property color needleColor: "#1A4DB5"
    property color tickColor: "#2A2A4A"

    signal machinePhaseClicked()

    function valueToAngleDeg(v) {
        var startDeg = -90
        var sweepDeg = 180
        return startDeg + (v / valueRange) * sweepDeg
    }

    // ================= CANVAS =================
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

            var fontSize = componentTypography.tiny
            var labelOffset = radius * 0.14

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

                    // =========================================
                    // DYNAMIC LABEL POSITIONING
                    // FOR ROBOTO CONDENSED
                    // =========================================

                    var dynamicFontSize = componentTypography.tiny

                    ctx.font = "bold " + dynamicFontSize + "px 'Roboto Condensed'"

                    // Measure actual text width
                    var textMetrics = ctx.measureText(v.toString())
                    var textWidth = textMetrics.width

                    // Dynamic inward spacing based on text width
                    var labelR = radius - tLen - labelOffset - (textWidth * 0.12)

                    // Extra inward compensation near crowded region
                    if (v >= 140)
                        labelR -= radius * 0.03

                    var lx = cx + labelR * Math.cos(angleRad)
                    var ly = cy + labelR * Math.sin(angleRad)

                    ctx.fillStyle = root.tickColor
                    ctx.textAlign = "center"
                    ctx.textBaseline = "middle"

                    ctx.fillText(v.toString(), lx, ly)
                }
            }

            // PRODUCT MARKER
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

            // MACHINE NEEDLE
            var nAngleRad = root.valueToAngleDeg(root.machinePhase) * Math.PI / 180
            var startOffset = radius * 0.60
            var needleLen = radius * 0.15
            var baseOffset = radius * 0.025

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

    //  SAFE CONNECTION
    Connections {
        target: (typeof GlobalState !== "undefined" && GlobalState) ? GlobalState : null

        function onProductPhaseChanged() {
            root.productPhase = GlobalState.productPhase
            canvas.requestPaint()
        }

        function onMachinePhaseChanged() {
            root.machinePhase = GlobalState.machinePhase
            canvas.requestPaint()
        }
    }

    //  INITIAL LOAD (CRITICAL)
    Component.onCompleted: {
        if (typeof GlobalState !== "undefined" && GlobalState) {
            root.productPhase = GlobalState.productPhase
            root.machinePhase = GlobalState.machinePhase
        }
        canvas.requestPaint()
    }

    // ================= LEFT PANEL =================
    Column {
        anchors.left: parent.left
        anchors.leftMargin: parent.width * 0.08
        anchors.verticalCenter: parent.verticalCenter

        spacing: root.trackingPhase >= 0
                 ? Math.max(6, root.height * 0.02)
                 : Math.max(10, root.height * 0.03)

        Column {
            spacing: 2

            Text {
                text: root.productPhase
                font.pixelSize: root.trackingPhase >= 0
                                ? componentTypography.small
                                : componentTypography.body
                font.bold: true
                color: "#1A4DB5"
            }

            Text {
                text: "Product Phase"
                font.pixelSize: root.trackingPhase >= 0
                                ? componentTypography.tiny
                                : componentTypography.small
                font.bold: true
            }
        }

        Rectangle {
            visible: root.trackingPhase < 0
            width: 40
            height: 2
            color: "#90CAF9"
        }

        Column {
            spacing: 2

            Text {
                text: root.machinePhase
                font.pixelSize: root.trackingPhase >= 0
                                ? componentTypography.small
                                : componentTypography.body
                font.bold: true
                color: "#1A4DB5"
            }

            Item {
                width: machineLabel.width
                height: machineLabel.height

                Text {
                    id: machineLabel
                    text: "Machine Phase"
                    font.pixelSize: root.trackingPhase >= 0
                                    ? componentTypography.tiny
                                    : componentTypography.small
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.machinePhaseClicked()
                }
            }
        }

        Column {
            visible: root.trackingPhase >= 0
            spacing: 2

            Text {
                text: root.trackingPhase
                font.pixelSize: root.trackingPhase >= 0
                                ? componentTypography.small
                                : componentTypography.body
                font.bold: true
                color: "#1A4DB5"
            }

            Text {
                text: root.trackingCountLabel
                font.pixelSize: root.trackingPhase >= 0
                                ? componentTypography.tiny
                                : componentTypography.small
                font.bold: true
            }
        }
    }
}
