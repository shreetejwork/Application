import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import AppState 1.0

import "../components"

Item {
    id: root

    property bool showTopBar: true
    property var globalTopBar

    property real baseHeight: 700
    property real scale: Math.max(0.9, Math.min(1.8, height / baseHeight))

    ListModel { id: histValues }

    Component.onCompleted: {
        var intervalMinutes = 30
        var readingsPerDay  = (24 * 60) / intervalMinutes
        var totalDays       = 30

        for (var day = 1; day <= totalDays; day++) {
            for (var r = 0; r < readingsPerDay; r++) {
                var totalMin = r * intervalMinutes
                var hh = Math.floor(totalMin / 60)
                var mm = totalMin % 60

                var dd   = day  < 10 ? "0" + day : "" + day
                var hhS  = hh   < 10 ? "0" + hh  : "" + hh
                var mmS  = mm   < 10 ? "0" + mm   : "" + mm

                histValues.append({
                    dd:   dd,
                    mon:  "01",
                    hhmm: hhS + ":" + mmS,
                    val:  Math.round(Math.random() * 10000)
                })
            }
        }
    }

    Rectangle {
        id: histogramCard

        anchors.fill: parent
        anchors.margins: 20 * root.scale

        radius: 22 * root.scale
        color: "#FFFFFF"
        border.width: 2
        border.color: "#6F95D6"
        clip: true

        // ── ZOOM ────────────────────────────────────────────
        property real zoomFactor:      0.4
        property real _pinchStartZoom: 0.4
        property real detailZoomThreshold: 1.2

        // ── SELECTED BAR INFO (for overlay tooltip) ─────────
        property int  selectedIndex: -1
        property real selectedBarVal: 0
        property real selectedBarX:   0   // absolute x inside histogramCard
        property real selectedBarY:   0   // absolute y (top of bar) inside histogramCard
        property real selectedBarW:   0

        PinchHandler {
            id: pinchHandler
            target: null
            onActiveChanged: {
                if (active)
                    histogramCard._pinchStartZoom = histogramCard.zoomFactor
            }
            onActiveScaleChanged: {
                // ── ZOOM-ANCHOR FIX ──────────────────────────
                // Anchor zoom to center of visible viewport
                var oldZoom    = histogramCard.zoomFactor
                var newZoom    = Math.max(0.4, Math.min(8.0,
                                     histogramCard._pinchStartZoom * activeScale))

                // Center of visible content in content-space
                var visibleCenterX = flickArea.contentX + flickArea.width / 2

                histogramCard.zoomFactor = newZoom

                // Reposition so the same content point stays centered
                var ratio = newZoom / oldZoom
                flickArea.contentX = Math.max(0,
                    visibleCenterX * ratio - flickArea.width / 2)
            }
        }

        // ── SIZING ──────────────────────────────────────────
        property real barWidth:   Math.round(Math.max(2, 44 * root.scale * zoomFactor))
        property real barSpacing: Math.round(Math.max(1,  6 * root.scale * zoomFactor))
        property real barStride:  barWidth + barSpacing
        property int  barCount:   histValues.count

        property bool isDetail:   zoomFactor >= detailZoomThreshold

        property real yAxisWidth:  10 * root.scale
        property real xAxisHeight: isDetail ? 64 * root.scale : 30 * root.scale
        property real titleH:      52 * root.scale
        property real padH:        20 * root.scale
        property real padV:        16 * root.scale

        property real yMin: 0
        property real yMax: 10000
        property int  ySteps: 5

        Behavior on xAxisHeight {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        // ── LAYOUT ──────────────────────────────────────────
        Column {
            anchors.fill: parent
            anchors.leftMargin:   histogramCard.padH
            anchors.rightMargin:  histogramCard.padH
            anchors.topMargin:    histogramCard.padV
            anchors.bottomMargin: histogramCard.padV
            spacing: 0

            // ── TITLE ────────────────────────────────────────
            Item {
                width:  parent.width
                height: histogramCard.titleH

                Text {
                    anchors.centerIn: parent
                    text: "Coil Output Histogram"
                    font.pixelSize: 24 * root.scale
                    font.bold: true
                    color: "#1A4DB5"
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: Math.round(histogramCard.zoomFactor * 100) + "%"
                    font.pixelSize: 13 * root.scale
                    color: "#8BA0CC"
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: 52 * root.scale
                    anchors.verticalCenter: parent.verticalCenter
                    width:  62 * root.scale
                    height: 26 * root.scale
                    radius: 7 * root.scale
                    visible: Math.abs(histogramCard.zoomFactor - 0.4) > 0.05
                    color: resetMouse.containsMouse ? "#E3EDFF" : "#EDF1FA"
                    border.color: "#1A4DB5"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Reset"
                        font.pixelSize: 12 * root.scale
                        color: "#1A4DB5"
                        font.bold: true
                    }

                    MouseArea {
                        id: resetMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            histogramCard.zoomFactor  = 0.4
                            histogramCard.selectedIndex = -1
                        }
                    }
                }
            }

            // ── GRAPH AREA ───────────────────────────────────
            Item {
                id: graphArea
                width:  parent.width
                height: parent.height - histogramCard.titleH

                property real plotW: width - histogramCard.yAxisWidth

                property real totalBarsW: Math.max(
                    plotW,
                    histogramCard.barCount * histogramCard.barStride
                    + histogramCard.barSpacing * 2
                )

                property real barAreaH: height - histogramCard.xAxisHeight

                // ── Y-AXIS SPINE ─────────────────────────────
                Item {
                    id: yAxisPanel
                    x: 0; y: 0
                    width:  histogramCard.yAxisWidth
                    height: graphArea.barAreaH

                    Rectangle {
                        anchors.right:  parent.right
                        anchors.top:    parent.top
                        anchors.bottom: parent.bottom
                        width: 2
                        color: "#4A5E8A"
                    }
                }

                // ── PINNED X-AXIS ─────────────────────────────
                Item {
                    id: xAxisPanel
                    x:      histogramCard.yAxisWidth
                    y:      graphArea.barAreaH
                    width:  graphArea.plotW
                    height: histogramCard.xAxisHeight
                    clip:   true

                    Rectangle {
                        anchors.top:   parent.top
                        anchors.left:  parent.left
                        anchors.right: parent.right
                        height: 2
                        color:  "#4A5E8A"
                    }

                    Item {
                        x:      -flickArea.contentX
                        y:      0
                        width:  graphArea.totalBarsW
                        height: parent.height

                        Repeater {
                            model: histValues

                            delegate: Item {
                                // Center this label item on the bar center
                                x: index * histogramCard.barStride
                                   + histogramCard.barSpacing
                                y: 0
                                width:  histogramCard.barStride
                                height: xAxisPanel.height

                                // Tick
                                Rectangle {
                                    x:      parent.width / 2 - width / 2
                                    y:      2
                                    width:  1
                                    height: 5 * root.scale
                                    color:  "#4A5E8A"
                                }

                                // Low zoom: show DD only on first bar of each day
                                Text {
                                    visible: !histogramCard.isDetail
                                             && model.hhmm === "00:30"
                                    anchors.top:              parent.top
                                    anchors.topMargin:        8 * root.scale
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text:  model.dd
                                    font.pixelSize: Math.max(9, 12 * root.scale)
                                    font.bold: true
                                    color: "#2A3550"
                                    horizontalAlignment: Text.AlignHCenter
                                }

                                // Detail zoom: 3-line label DD / MM / HH:MM
                                Column {
                                    visible: histogramCard.isDetail
                                    anchors.top:              parent.top
                                    anchors.topMargin:        4 * root.scale
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    spacing: 2 * root.scale

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text:  model.dd
                                        font.pixelSize: Math.max(10, 13 * root.scale)
                                        font.bold: true
                                        color: "#1A4DB5"
                                        horizontalAlignment: Text.AlignHCenter
                                    }

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text:  model.mon
                                        font.pixelSize: Math.max(9, 12 * root.scale)
                                        font.bold: false
                                        color: "#4A5E8A"
                                        horizontalAlignment: Text.AlignHCenter
                                    }

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text:  model.hhmm
                                        font.pixelSize: Math.max(8, 11 * root.scale)
                                        font.bold: false
                                        color: "#7B8FAD"
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                }
                            }
                        }
                    }
                }

                // ── SCROLLABLE BARS ───────────────────────────
                Flickable {
                    id: flickArea

                    x:      histogramCard.yAxisWidth
                    y:      0
                    width:  graphArea.plotW
                    height: graphArea.barAreaH

                    clip: true
                    boundsBehavior:     Flickable.StopAtBounds
                    interactive:        true
                    flickableDirection: Flickable.HorizontalFlick

                    contentWidth:  graphArea.totalBarsW
                    contentHeight: height

                    // ── MOUSE WHEEL ZOOM (anchor to cursor) ───
                    WheelHandler {
                        acceptedDevices: PointerDevice.Mouse
                        onWheel: function(event) {
                            var oldZoom = histogramCard.zoomFactor
                            var newZoom = Math.max(0.4, Math.min(8.0,
                                oldZoom * (event.angleDelta.y > 0 ? 1.12 : 0.9)))

                            // Anchor to mouse cursor x position
                            var mouseContentX = flickArea.contentX + event.x
                            histogramCard.zoomFactor = newZoom
                            flickArea.contentX = Math.max(0,
                                mouseContentX * (newZoom / oldZoom) - event.x)
                        }
                    }

                    Item {
                        id: plotItem
                        width:  flickArea.contentWidth
                        height: flickArea.height

                        // GRID LINES
                        Repeater {
                            model: histogramCard.ySteps + 1

                            delegate: Rectangle {
                                x:      0
                                y:      (index / histogramCard.ySteps) * plotItem.height
                                width:  plotItem.width
                                height: index === histogramCard.ySteps ? 2 : 1
                                color:  index === histogramCard.ySteps
                                        ? "#4A5E8A" : "#E1E8F5"
                            }
                        }

                        // BARS
                        Repeater {
                            id: barsRepeater
                            model: histValues

                            delegate: Item {
                                id: barSlot

                                x:      index * histogramCard.barStride + histogramCard.barSpacing
                                y:      0
                                width:  histogramCard.barWidth
                                height: plotItem.height

                                property bool isSelected: histogramCard.selectedIndex === index

                                Rectangle {
                                    id: bar

                                    property real fraction:
                                        (model.val - histogramCard.yMin) /
                                        (histogramCard.yMax - histogramCard.yMin)

                                    width:  parent.width
                                    height: Math.max(2, fraction * plotItem.height)

                                    anchors.bottom:           parent.bottom
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    radius: Math.min(6 * root.scale, width * 0.35)

                                    gradient: Gradient {
                                        GradientStop {
                                            position: 0.0
                                            color: barSlot.isSelected ? "#FFB74D" : "#58A6FF"
                                        }
                                        GradientStop {
                                            position: 1.0
                                            color: barSlot.isSelected ? "#F57C00" : "#1A4DB5"
                                        }
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: parent.radius
                                        color: barMouse.containsMouse ? "#33FFFFFF" : "transparent"
                                    }
                                }

                                MouseArea {
                                    id: barMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    propagateComposedEvents: true

                                    onClicked: {
                                        if (!histogramCard.isDetail) return

                                        if (histogramCard.selectedIndex === index) {
                                            histogramCard.selectedIndex = -1
                                            return
                                        }

                                        histogramCard.selectedIndex = index
                                        histogramCard.selectedBarVal = model.val

                                        // Convert bar's top-of-bar position to
                                        // histogramCard coordinate space for the overlay
                                        var fraction = (model.val - histogramCard.yMin)
                                                       / (histogramCard.yMax - histogramCard.yMin)
                                        var barH     = Math.max(2, fraction * plotItem.height)

                                        // bar top in plotItem space
                                        var barTopInPlot = plotItem.height - barH

                                        // map through flickArea → graphArea → histogramCard
                                        var pt = plotItem.mapToItem(histogramCard,
                                            barSlot.x + barSlot.width / 2,
                                            barTopInPlot)

                                        histogramCard.selectedBarX = pt.x
                                        histogramCard.selectedBarY = pt.y
                                        histogramCard.selectedBarW = barSlot.width
                                    }

                                    onPressed: {
                                        mouse.accepted = false
                                    }
                                }
                            }
                        }
                    }
                }

                // ── CORNER FILL ───────────────────────────────
                Rectangle {
                    x:      0
                    y:      graphArea.barAreaH
                    width:  histogramCard.yAxisWidth
                    height: histogramCard.xAxisHeight
                    color:  "#FFFFFF"

                    Rectangle {
                        anchors.top:   parent.top
                        anchors.left:  parent.left
                        anchors.right: parent.right
                        height: 2
                        color:  "#4A5E8A"
                    }
                }
            }
        }

        // ── TOOLTIP OVERLAY (above everything, inside card) ──
        // Rendered at histogramCard level so it's never clipped by plotItem
        Rectangle {
            id: tooltipOverlay

            visible: histogramCard.selectedIndex >= 0
                     && histogramCard.isDetail

            // Position: centered on bar, just above bar top
            x: Math.min(
                   Math.max(0, histogramCard.selectedBarX - width / 2),
                   histogramCard.width - width - 4 * root.scale)
            y: histogramCard.selectedBarY - height - 6 * root.scale

            width:  tooltipVal.implicitWidth + 18 * root.scale
            height: tooltipVal.implicitHeight + 10 * root.scale

            radius: 6 * root.scale
            color:  "#F57C00"
            z: 100

            // Small triangle pointer
            Canvas {
                id: tipArrow
                width:  12 * root.scale
                height:  6 * root.scale
                anchors.top:              parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    ctx.fillStyle = "#F57C00"
                    ctx.beginPath()
                    ctx.moveTo(0, 0)
                    ctx.lineTo(width / 2, height)
                    ctx.lineTo(width, 0)
                    ctx.closePath()
                    ctx.fill()
                }
            }

            Text {
                id: tooltipVal
                anchors.centerIn: parent
                text: histogramCard.selectedIndex >= 0
                      ? histValues.get(histogramCard.selectedIndex).val
                      : ""
                font.pixelSize: 14 * root.scale
                font.bold: true
                color: "#FFFFFF"
            }
        }
    }
}
