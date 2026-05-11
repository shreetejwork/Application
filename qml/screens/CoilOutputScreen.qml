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

    // ── GENERATE DUMMY DATA (30 days × 288 readings per day at 5-min gap) ──
    // We keep it manageable: 30 days × 48 readings (every 30 min) = 1440 points
    // For demo: 5-minute gap as requested but capped at a reasonable count

    ListModel {
        id: histValues
    }

    Component.onCompleted: {
        // Generate 30 days of data with 5-minute intervals
        // 30 days × 24 hours × 12 readings/hour = 8640 points
        // For performance we use every 30 min = 1440 points
        var intervalMinutes = 30
        var readingsPerDay  = (24 * 60) / intervalMinutes  // 48
        var totalDays       = 30

        for (var day = 1; day <= totalDays; day++) {
            for (var r = 0; r < readingsPerDay; r++) {
                var totalMin = r * intervalMinutes
                var hh       = Math.floor(totalMin / 60)
                var mm       = totalMin % 60

                var dd  = String(day).length < 2 ? "0" + day : "" + day
                var mmS = String(hh).length  < 2 ? "0" + hh  : "" + hh
                var ssS = String(mm).length  < 2 ? "0" + mm  : "" + mm

                // Month cycles: days 1-30 mapped across Jan(01)
                var month = "01"

                // Random value 0-10000
                var yVal = Math.round(Math.random() * 10000)

                histValues.append({
                    dd:    dd,
                    mon:   month,
                    hhmm:  mmS + ":" + ssS,
                    val:   yVal
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

        // ── ZOOM ────────────────────────────────────────────
        // Initial zoom = 0.4 so 8 days fit on screen at start
        property real zoomFactor:      0.4
        property real _pinchStartZoom: 0.4

        // Threshold above which we show full DD/MM/HH:MM labels
        property real detailZoomThreshold: 1.2

        PinchHandler {
            id: pinchHandler
            target: null
            onActiveChanged: {
                if (active)
                    histogramCard._pinchStartZoom = histogramCard.zoomFactor
            }
            onActiveScaleChanged: {
                histogramCard.zoomFactor = Math.max(
                    0.4, Math.min(8.0,
                        histogramCard._pinchStartZoom * activeScale)
                )
            }
        }

        // ── SIZING ──────────────────────────────────────────
        property real barWidth:   Math.round(Math.max(2, 44 * root.scale * zoomFactor))
        property real barSpacing: Math.round(Math.max(1,  6 * root.scale * zoomFactor))
        property real barStride:  barWidth + barSpacing
        property int  barCount:   histValues.count

        property real yAxisWidth:   10 * root.scale   // very thin — no labels shown
        property real xAxisHeight:  histogramCard.zoomFactor >= histogramCard.detailZoomThreshold
                                    ? 58 * root.scale   // 3 lines: DD / MM / HH:MM
                                    : 28 * root.scale   // 1 line: DD only

        property real titleH: 52 * root.scale
        property real padH:   20 * root.scale
        property real padV:   16 * root.scale

        property real yMin: 0
        property real yMax: 10000
        property int  ySteps: 5

        // Animate xAxisHeight change
        Behavior on xAxisHeight {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        // ── MAIN LAYOUT ─────────────────────────────────────
        Column {
            anchors.fill: parent
            anchors.leftMargin:   histogramCard.padH
            anchors.rightMargin:  histogramCard.padH
            anchors.topMargin:    histogramCard.padV
            anchors.bottomMargin: histogramCard.padV
            spacing: 0

            // ── TITLE ROW ────────────────────────────────────
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

                // Zoom % indicator
                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: Math.round(histogramCard.zoomFactor * 100) + "%"
                    font.pixelSize: 13 * root.scale
                    color: "#8BA0CC"
                }

                // Reset button — only shows when not at default zoom
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
                        onClicked: histogramCard.zoomFactor = 0.4
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

                // ── THIN Y-AXIS SPINE (no labels) ────────────
                Item {
                    id: yAxisPanel
                    x: 0
                    y: 0
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

                    // X-axis spine line
                    Rectangle {
                        anchors.top:   parent.top
                        anchors.left:  parent.left
                        anchors.right: parent.right
                        height: 2
                        color:  "#4A5E8A"
                    }

                    // Sliding strip — tracks flickArea scroll
                    Item {
                        x:      -flickArea.contentX
                        y:      0
                        width:  graphArea.totalBarsW
                        height: parent.height

                        Repeater {
                            model: histValues

                            delegate: Item {
                                x: index * histogramCard.barStride
                                   + histogramCard.barSpacing
                                   + histogramCard.barWidth / 2
                                   - width / 2
                                y: 0
                                width:  Math.max(histogramCard.barWidth, 1)
                                height: xAxisPanel.height

                                // Tick
                                Rectangle {
                                    anchors.top:              parent.top
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width:  1
                                    height: 4 * root.scale
                                    color:  "#4A5E8A"
                                }

                                // ── LABEL: DD only at low zoom ──
                                // ── LABEL: DD / MM / HH:MM at detail zoom ──
                                Column {
                                    anchors.top:              parent.top
                                    anchors.topMargin:        5 * root.scale
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    spacing: 1

                                    // Always show: DD
                                    // Only show first reading of each day to avoid clutter
                                    Text {
                                        visible: model.hhmm === "00:00"
                                                 || histogramCard.zoomFactor >= histogramCard.detailZoomThreshold
                                        text: model.dd
                                        font.pixelSize: Math.max(8, 11 * root.scale)
                                        font.bold: true
                                        color: "#2A3550"
                                        horizontalAlignment: Text.AlignHCenter
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }

                                    // Detail lines: MM and HH:MM
                                    Text {
                                        visible: histogramCard.zoomFactor >= histogramCard.detailZoomThreshold
                                        text: model.mon
                                        font.pixelSize: Math.max(7, 10 * root.scale)
                                        color: "#5B6B8C"
                                        horizontalAlignment: Text.AlignHCenter
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }

                                    Text {
                                        visible: histogramCard.zoomFactor >= histogramCard.detailZoomThreshold
                                        text: model.hhmm
                                        font.pixelSize: Math.max(7, 10 * root.scale)
                                        color: "#8BA0CC"
                                        horizontalAlignment: Text.AlignHCenter
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                }
                            }
                        }
                    }
                }

                // ── SCROLLABLE BAR PLOT ───────────────────────
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

                    // Mouse-wheel zoom
                    WheelHandler {
                        acceptedDevices: PointerDevice.Mouse
                        onWheel: function(event) {
                            histogramCard.zoomFactor = Math.max(
                                0.4, Math.min(8.0,
                                    histogramCard.zoomFactor *
                                    (event.angleDelta.y > 0 ? 1.12 : 0.9))
                            )
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
                            model: histValues

                            delegate: Item {
                                id: barSlot

                                x:      index * histogramCard.barStride
                                        + histogramCard.barSpacing
                                y:      0
                                width:  histogramCard.barWidth
                                height: plotItem.height

                                // Track which bar is selected
                                property bool isSelected: false

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

                                    // Hover highlight
                                    Rectangle {
                                        anchors.fill: parent
                                        radius: parent.radius
                                        color: barMouse.containsMouse
                                               ? "#33FFFFFF" : "transparent"
                                    }

                                    // ── VALUE TOOLTIP ─────────────────────
                                    // Visible only when:
                                    //   (a) zoom >= detailThreshold AND
                                    //   (b) bar is selected (tapped/clicked)
                                    Rectangle {
                                        visible: barSlot.isSelected
                                                 && histogramCard.zoomFactor
                                                    >= histogramCard.detailZoomThreshold

                                        anchors.bottom:           parent.top
                                        anchors.bottomMargin:     5 * root.scale
                                        anchors.horizontalCenter: parent.horizontalCenter

                                        width:  tipText.implicitWidth + 14 * root.scale
                                        height: tipText.implicitHeight + 8 * root.scale
                                        radius: 5 * root.scale
                                        color:  "#F57C00"
                                        z: 20

                                        Text {
                                            id: tipText
                                            anchors.centerIn: parent
                                            text: model.val
                                            font.pixelSize: 12 * root.scale
                                            font.bold: true
                                            color: "#FFFFFF"
                                        }
                                    }
                                }

                                // Tap / click handler
                                MouseArea {
                                    id: barMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    propagateComposedEvents: true

                                    onClicked: {
                                        // Deselect all others by toggling this one
                                        var wasSelected = barSlot.isSelected
                                        // Reset all — walk siblings via plotItem
                                        for (var i = 0; i < plotItem.children.length; i++) {
                                            var child = plotItem.children[i]
                                            if (typeof child.isSelected !== "undefined")
                                                child.isSelected = false
                                        }
                                        barSlot.isSelected = !wasSelected
                                    }

                                    onPressed: {
                                        if (!contains(Qt.point(mouse.x, mouse.y)))
                                            return
                                        // Allow Flickable to handle drag
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
    }
}
