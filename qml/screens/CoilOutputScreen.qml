import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtCore
import AppState 1.0

import "../components"

Item {
    id: root

    property bool showTopBar: true
    property var globalTopBar

    property real baseHeight: 700
    property real scale: Math.max(0.9, Math.min(1.8, height / baseHeight))

    property int statAvg: 0
    property int statMin: 0
    property int statMax: 0
    property int visualMax: 100

    property int readingsPerDay: 288
    property int totalDays: 30

    // Full dataset — never mutated after loadData()
    property var rawValues: []

    // ─── Windowed-render state ────────────────────────────────────────────────
    property int windowStart: 0
    property int windowEnd:   0
    property int windowSize:  0


    readonly property int renderBuffer: 80

    // ─── Tooltip cache ───────────────────────────────────────────────────────
    property var  tooltipItem: null   // cached object from rawValues
    property real tooltipBarX: 0
    property real tooltipBarY: 0

    // ─── Helpers ─────────────────────────────────────────────────────────────
    function monthName(m) {
        var names = ["JAN","FEB","MAR","APR","MAY","JUN",
                     "JUL","AUG","SEP","OCT","NOV","DEC"]
        return names[m - 1]
    }

    function jumpToDay(day) {
        var idx     = (day - 1) * root.readingsPerDay
        var targetX = idx * histogramCard.barStride + histogramCard.barSpacing
        flickArea.contentX = Math.max(
            0,
            Math.min(targetX, flickArea.contentWidth - flickArea.width))
    }

    // ─── Initialisation ──────────────────────────────────────────────────────
    Component.onCompleted: { loadData() }

    function loadData() {

        var arr = []
        var sum = 0
        var mn  = 999999999
        var mx  = 0

        for (var day = 1; day <= totalDays; day++) {

            for (var r = 0; r < readingsPerDay; r++) {

                var totalMin = r * 5

                var hh = Math.floor(totalMin / 60)
                var mm = totalMin % 60

                var hhS = hh < 10 ? "0" + hh : "" + hh
                var mmS = mm < 10 ? "0" + mm : "" + mm
                var dd  = day < 10 ? "0" + day : "" + day

                // -------------------------------------------------
                // REALISTIC LIVE-LIKE VALUES (0 → 2k)
                // -------------------------------------------------

                var rand = Math.random()

                var baseMax = 0

                // 80% → low range
                if (rand < 0.80) {

                    baseMax = 300 + Math.random() * 900
                    // 300 → 1200
                }

                // 18% → medium range
                else if (rand < 0.98) {

                    baseMax = 1200 + Math.random() * 500
                    // 1200 → 1700
                }

                // 2% → high spikes
                else {

                    baseMax = 1700 + Math.random() * 300
                    // 1700 → 2000
                }

                // smooth movement
                var wave =
                        (Math.sin(r / 10) * 0.35) +
                        (Math.sin(r / 22) * 0.22) +
                        0.50

                // random noise
                var noise = Math.random() * 0.25

                // final factor
                var factor = Math.max(0.05, wave + noise)

                // raw value
                var base = factor * baseMax

                // occasional dips
                if (Math.random() < 0.05)
                    base *= 0.15

                // tiny spikes
                if (Math.random() < 0.01)
                    base *= 1.15

                // final clamp
                var v = Math.max(
                            0,
                            Math.min(2000, Math.round(base))
                            )

                sum += v

                if (v < mn)
                    mn = v

                if (v > mx)
                    mx = v

                arr.push({
                    dd: dd,
                    mon: 1,
                    hhmm: hhS + ":" + mmS,
                    val: v,
                    dayIndex: day - 1
                })
            }
        }

        rawValues = arr

        statAvg = Math.round(sum / arr.length)
        statMin = mn
        statMax = mx

        // -------------------------------------------------
        // SMART VISUAL MAX
        // -------------------------------------------------

        function nextNiceStep(v) {

            if (v <= 500)
                return 500

            return Math.ceil(v / 500) * 500
        }

        visualMax = nextNiceStep(statMax)

        // Reset window
        windowStart = 0
        windowEnd   = 0
        windowSize  = 0
        tooltipItem = null

        updateVisibleWindow()
    }

    // ─── Core virtualization ─────────────────────────────────────────────────

    function updateVisibleWindow() {
        if (!flickArea || !histogramCard) return

        var stride = histogramCard.barStride
        if (stride <= 0) return

        var total = rawValues.length
        if (total === 0) return

        var firstVisible = Math.floor(flickArea.contentX / stride)
        var lastVisible  = Math.ceil((flickArea.contentX + flickArea.width) / stride)

        var newStart = Math.max(0, firstVisible - renderBuffer)
        var newEnd   = Math.min(total - 1, lastVisible + renderBuffer)
        var newSize  = newEnd - newStart + 1

        // Only update properties that actually changed to avoid binding churn
        if (newStart !== windowStart) windowStart = newStart
        if (newEnd   !== windowEnd)   windowEnd   = newEnd
        if (newSize  !== windowSize)  windowSize  = newSize
    }

    // ─── Tooltip helper ──────────────────────────────────────────────────────
    function updateTooltip(mouseX) {
        var stride = histogramCard.barStride
        var globalIdx = Math.floor(
            (mouseX - histogramCard.barSpacing) / stride)

        if (globalIdx < 0 || globalIdx >= rawValues.length) {
            tooltipItem = null
            return
        }

        var item     = rawValues[globalIdx]
        tooltipItem  = item

        var fraction = (item.val - histogramCard.yMin)
                     / (histogramCard.yMax - histogramCard.yMin)

        tooltipBarX = globalIdx * stride + histogramCard.barWidth / 2
        tooltipBarY = flickArea.height - Math.max(2, fraction * flickArea.height)
    }

    // =========================================================================
    // CARD
    // =========================================================================
    Rectangle {
        id: histogramCard

        anchors.fill:    parent
        anchors.margins: 20 * root.scale

        radius:       22 * root.scale
        color:        "#FFFFFF"
        border.width: 2
        border.color: "#6F95D6"
        clip:         true

        // ─── Zoom state ──────────────────────────────────────────────────────
        property real minZoomFactor: 0.01
        property real zoomFactor:    minZoomFactor
        property real _pinchZoom:    minZoomFactor

        property real detailThresh: 0.5
        property bool isDetail:     zoomFactor >= detailThresh

        // ─── Bar geometry ────────────────────────────────────────────────────
        property real barWidth:   Math.max(1, 44 * root.scale * zoomFactor)
        property real barSpacing: Math.max(0.5, 6 * root.scale * zoomFactor)
        property real barStride:  barWidth + barSpacing

        // ─── Y range ─────────────────────────────────────────────────────────
        property real yMin: 0
        property real yMax: root.visualMax > 0
                             ? root.visualMax * 0.92
                             : 100
        property int  ySteps: 5

        // ─── Layout constants ─────────────────────────────────────────────────
        property real padH:    20 * root.scale
        property real padV:    16 * root.scale
        property real headerH: 78 * root.scale
        property real yAxisW:  62 * root.scale
        property real xAxisH:  52 * root.scale
        property real navRowH: 54 * root.scale
        property real topPad:  28 * root.scale

        property bool needsNav: {
            var totalW = rawValues.length * barStride + barSpacing * 2
            var plotW  = histogramCard.width - padH * 2 - yAxisW
            return totalW > plotW + 10
        }

        property int visibleDay: {
            var firstBar = Math.floor(flickArea.contentX / histogramCard.barStride)
            return Math.max(1, Math.min(root.totalDays,
                Math.floor(firstBar / root.readingsPerDay) + 1))
        }

        property real graphTop: {
            var t = padV + headerH + 1
            if (needsNav) t += navRowH + 1
            t += 10 * root.scale
            return t
        }

        property real graphH:     height - graphTop - padV
        property real plotW:      width - padH * 2 - yAxisW
        property real barAreaH:   Math.max(80 * root.scale, graphH - xAxisH - topPad)
        property real totalBarsW: Math.max(plotW,
            rawValues.length * barStride + barSpacing * 2)

        // ─── Zoom changed → rebuild window ────────────────────────────────────
        onBarStrideChanged: Qt.callLater(root.updateVisibleWindow)

        // ─── Pinch zoom ───────────────────────────────────────────────────────
        PinchHandler {

            enabled: histogramCard.interactionUnlocked

            target: null

            onActiveChanged: {
                if (active) histogramCard._pinchZoom = histogramCard.zoomFactor
            }

            onActiveScaleChanged: {
                var oldZ = histogramCard.zoomFactor
                var newZ = Math.max(histogramCard.minZoomFactor,
                           Math.min(2.0, histogramCard._pinchZoom * activeScale))
                if (Math.abs(newZ - oldZ) < 0.005) return

                var cx = flickArea.contentX + flickArea.width / 2
                histogramCard.zoomFactor = newZ
                flickArea.contentX = Math.max(0,
                    cx * (newZ / oldZ) - flickArea.width / 2)
            }
        }

        // =====================================================================
        // HEADER
        // =====================================================================
        Item {
            id: headerItem

            x: histogramCard.padH
            y: histogramCard.padV
            width:  histogramCard.width - histogramCard.padH * 2
            height: histogramCard.headerH

            RowLayout {
                anchors.fill: parent
                spacing: 20 * root.scale

                // Stats pill
                Rectangle {
                    Layout.preferredWidth:  320 * root.scale
                    Layout.preferredHeight: 64  * root.scale
                    radius: 18 * root.scale
                    color:  "#F7F9FD"
                    border.width: 1
                    border.color: "#DCE5F5"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin:  18 * root.scale
                        anchors.rightMargin: 18 * root.scale
                        spacing: 14 * root.scale

                        ColumnLayout {
                            Layout.fillWidth: true
                            Text { Layout.alignment: Qt.AlignHCenter; text: "AVG"; font.pixelSize: 10; color: "#8EA2C8" }
                            Text { Layout.alignment: Qt.AlignHCenter; text: root.statAvg.toLocaleString(); font.pixelSize: 17; color: "#1A4DB5" }
                        }
                        Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 34 * root.scale; color: "#DCE5F5" }
                        ColumnLayout {
                            Layout.fillWidth: true
                            Text { Layout.alignment: Qt.AlignHCenter; text: "MIN"; font.pixelSize: 10; color: "#8EA2C8" }
                            Text { Layout.alignment: Qt.AlignHCenter; text: root.statMin.toLocaleString(); font.pixelSize: 17; color: "#0F8A60" }
                        }
                        Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 34 * root.scale; color: "#DCE5F5" }
                        ColumnLayout {
                            Layout.fillWidth: true
                            Text { Layout.alignment: Qt.AlignHCenter; text: "MAX"; font.pixelSize: 10; color: "#8EA2C8" }
                            Text { Layout.alignment: Qt.AlignHCenter; text: root.statMax.toLocaleString(); font.pixelSize: 17; color: "#D64545" }
                        }
                    }
                }

                // Title
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Text {
                        anchors.centerIn: parent
                        text: "Coil Output"
                        font.pixelSize: 30

                        color: "#0E4AB8"
                    }
                }

                // Zoom controls
                Rectangle {
                    Layout.preferredWidth:  250 * root.scale
                    Layout.preferredHeight: 64  * root.scale
                    Layout.alignment: Qt.AlignVCenter
                    radius: 18 * root.scale
                    color:  "#F7F9FD"
                    border.width: 1
                    border.color: "#DCE5F5"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin:  10 * root.scale
                        anchors.rightMargin: 10 * root.scale
                        spacing: 10 * root.scale

                        // Zoom out
                        Rectangle {
                            Layout.preferredWidth:  46 * root.scale
                            Layout.preferredHeight: 46 * root.scale
                            radius: 14 * root.scale
                            color: zoomOutMa.pressed ? "#CFE1FF"
                                 : zoomOutMa.containsMouse ? "#E3EEFF" : "#FFFFFF"
                            border.width: 1; border.color: "#6F95D6"
                            scale: zoomOutMa.pressed ? 0.92 : 1.0
                            Behavior on scale { NumberAnimation { duration: 80 } }

                            Text { anchors.centerIn: parent; text: "−"; font.pixelSize: 26; color: "#1A4DB5" }

                            MouseArea {
                                id: zoomOutMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                property bool holdActive: false

                                function doZoomOut() {
                                    var oldZ = histogramCard.zoomFactor
                                    var newZ = Math.max(histogramCard.minZoomFactor, oldZ * 0.85)
                                    if (Math.abs(newZ - oldZ) < 0.001) return
                                    var cx = flickArea.contentX + flickArea.width / 2
                                    histogramCard.zoomFactor = newZ
                                    flickArea.contentX = Math.max(0, cx * (newZ / oldZ) - flickArea.width / 2)
                                }

                                onClicked:      { if (!holdActive) doZoomOut() }
                                onPressAndHold: { holdActive = true; zoomOutTimer.start() }
                                onReleased:     { holdActive = false; zoomOutTimer.stop() }
                                onCanceled:     { holdActive = false; zoomOutTimer.stop() }
                            }
                            Timer {
                                id: zoomOutTimer; interval: 120; repeat: true
                                onTriggered: {
                                    if (histogramCard.zoomFactor <= histogramCard.minZoomFactor + 0.001) stop()
                                    else zoomOutMa.doZoomOut()
                                }
                            }
                        }

                        // Zoom label
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 46 * root.scale
                            radius: 14 * root.scale; color: "#FFFFFF"
                            border.width: 1; border.color: "#DCE5F5"
                            Column {
                                anchors.centerIn: parent; spacing: 0
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "ZOOM"; font.pixelSize: 9; color: "#8EA2C8" }
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: Math.round(histogramCard.zoomFactor * 100) + "%"; font.pixelSize: 15; color: "#1A4DB5" }
                            }
                        }

                        // Zoom in
                        Rectangle {
                            Layout.preferredWidth:  46 * root.scale
                            Layout.preferredHeight: 46 * root.scale
                            radius: 14 * root.scale
                            color: zoomInMa.pressed ? "#CFE1FF"
                                 : zoomInMa.containsMouse ? "#E3EEFF" : "#FFFFFF"
                            border.width: 1; border.color: "#6F95D6"
                            scale: zoomInMa.pressed ? 0.92 : 1.0
                            Behavior on scale { NumberAnimation { duration: 80 } }

                            Text { anchors.centerIn: parent; text: "+"; font.pixelSize: 24; color: "#1A4DB5" }

                            MouseArea {
                                id: zoomInMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor

                                function zoomInStep() {
                                    var oldZ = histogramCard.zoomFactor
                                    var newZ = Math.min(2.0, oldZ * 1.15)
                                    if (Math.abs(newZ - oldZ) < 0.001) return
                                    var cx = flickArea.contentX + flickArea.width / 2
                                    histogramCard.zoomFactor = newZ
                                    flickArea.contentX = Math.max(0, cx * (newZ / oldZ) - flickArea.width / 2)
                                }

                                onClicked:  { zoomInStep() }
                                onPressed:  { zoomInTimer.start() }
                                onReleased: { zoomInTimer.stop() }
                                onCanceled: { zoomInTimer.stop() }

                                Timer {
                                    id: zoomInTimer; interval: 90; repeat: true; running: false
                                    onTriggered: zoomInMa.zoomInStep()
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle { x: 0; y: histogramCard.padV + histogramCard.headerH; width: histogramCard.width; height: 1; color: "#E1E8F5" }

        // =====================================================================
        // DAY NAVIGATION
        // =====================================================================
        Item {
            id: navRow
            x: histogramCard.padH
            y: histogramCard.padV + histogramCard.headerH + 1
            width:   histogramCard.width - histogramCard.padH * 2
            height:  histogramCard.needsNav ? histogramCard.navRowH : 0
            visible: histogramCard.needsNav
            clip:    true

            Rectangle {
                id: prevBtn
                anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                width: 46 * root.scale; height: 46 * root.scale; radius: 14 * root.scale
                color: prevMa.pressed ? "#BFD7FF" : prevMa.containsMouse ? "#DCEBFF" : "#EDF4FF"
                border.width: 1; border.color: "#6F95D6"
                scale: prevMa.pressed ? 0.94 : 1.0
                Behavior on scale { NumberAnimation { duration: 80 } }
                Text { anchors.centerIn: parent; text: "‹"; font.pixelSize: 24; color: "#1A4DB5" }
                MouseArea {
                    id: prevMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    property bool holdActive: false
                    onClicked:      { if (!holdActive && histogramCard.visibleDay > 1) root.jumpToDay(histogramCard.visibleDay - 1) }
                    onPressAndHold: { holdActive = true; prevHoldTimer.start() }
                    onReleased:     { holdActive = false; prevHoldTimer.stop() }
                    onCanceled:     { holdActive = false; prevHoldTimer.stop() }
                }
                Timer {
                    id: prevHoldTimer; interval: 120; repeat: true
                    onTriggered: {
                        if (histogramCard.visibleDay > 1) root.jumpToDay(histogramCard.visibleDay - 1)
                        else stop()
                    }
                }
            }

            Rectangle {
                id: nextBtn
                anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                width: 46 * root.scale; height: 46 * root.scale; radius: 14 * root.scale
                color: nextMa.pressed ? "#BFD7FF" : nextMa.containsMouse ? "#DCEBFF" : "#EDF4FF"
                border.width: 1; border.color: "#6F95D6"
                scale: nextMa.pressed ? 0.94 : 1.0
                Behavior on scale { NumberAnimation { duration: 80 } }
                Text { anchors.centerIn: parent; text: "›"; font.pixelSize: 24; color: "#1A4DB5" }
                MouseArea {
                    id: nextMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    property bool holdActive: false
                    onClicked:      { if (!holdActive && histogramCard.visibleDay < root.totalDays) root.jumpToDay(histogramCard.visibleDay + 1) }
                    onPressAndHold: { holdActive = true; nextHoldTimer.start() }
                    onReleased:     { holdActive = false; nextHoldTimer.stop() }
                    onCanceled:     { holdActive = false; nextHoldTimer.stop() }
                }
                Timer {
                    id: nextHoldTimer; interval: 120; repeat: true
                    onTriggered: {
                        if (histogramCard.visibleDay < root.totalDays) root.jumpToDay(histogramCard.visibleDay + 1)
                        else stop()
                    }
                }
            }

            Flickable {
                id: dayPillFlick
                anchors.left: prevBtn.right; anchors.right: nextBtn.left
                anchors.leftMargin: 10 * root.scale; anchors.rightMargin: 10 * root.scale
                anchors.verticalCenter: parent.verticalCenter
                height: 40 * root.scale
                clip: true
                flickableDirection: Flickable.HorizontalFlick
                boundsBehavior: Flickable.StopAtBounds
                contentWidth: pillRow.width; contentHeight: height

                Behavior on contentX { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                Item {
                    id: pillBg
                    width: pillRow.width; height: parent.height

                    Rectangle {
                        id: selHighlight
                        width: 44 * root.scale; height: 34 * root.scale
                        radius: 9 * root.scale; color: "#1A4DB5"; border.width: 1; border.color: "#6F95D6"; z: 0
                        y: (pillBg.height - height) / 2
                        x: (histogramCard.visibleDay - 1) * ((44 * root.scale) + (7 * root.scale))
                        Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    }

                    Row {
                        id: pillRow; spacing: 7 * root.scale; anchors.verticalCenter: parent.verticalCenter

                        Repeater {
                            model: root.totalDays
                            delegate: Item {
                                width: 44 * root.scale; height: 34 * root.scale
                                property bool active: histogramCard.visibleDay === index + 1
                                Text {
                                    anchors.centerIn: parent
                                    text: (index + 1) < 10 ? "0" + (index + 1) : "" + (index + 1)
                                    color: active ? "#FFFFFF" : pma.containsMouse ? "#1A4DB5" : "#3562B8"
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                }
                                MouseArea { id: pma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.jumpToDay(index + 1) }
                            }
                        }
                    }
                }

                Connections {
                    target: histogramCard
                    function onVisibleDayChanged() {
                        var itemWidth = (44 * root.scale) + (7 * root.scale)
                        var targetX   = (histogramCard.visibleDay - 1) * itemWidth
                                      - dayPillFlick.width / 2 + itemWidth / 2
                        dayPillFlick.contentX = Math.max(0,
                            Math.min(targetX, dayPillFlick.contentWidth - dayPillFlick.width))
                    }
                }
            }
        }

        Rectangle { x: 0; y: navRow.y + navRow.height; width: histogramCard.width; height: histogramCard.needsNav ? 1 : 0; color: "#E1E8F5" }

        // =====================================================================
        // Y AXIS
        // =====================================================================
        Item {
            id: yAxisItem
            x: histogramCard.padH
            y: histogramCard.graphTop + histogramCard.topPad
            width: histogramCard.yAxisW; height: histogramCard.barAreaH

            Rectangle { anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom; width: 2; color: "#4A5E8A" }

            Repeater {
                model: histogramCard.ySteps + 1
                delegate: Item {
                    width: histogramCard.yAxisW - 4 * root.scale; height: 18 * root.scale
                    y: (index / histogramCard.ySteps) * yAxisItem.height - height / 2
                    Text {
                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                        anchors.rightMargin: 6 * root.scale
                        property real frac:     1.0 - index / histogramCard.ySteps
                        property real labelVal: histogramCard.yMin + frac * (histogramCard.yMax - histogramCard.yMin)
                        text: {

                            var v = Math.round(labelVal)

                            if (v >= 1000000)
                                return Math.round(v / 1000000) + "M"

                            if (v >= 1000)
                                return Math.round(v / 1000) + "k"

                            return v.toString()
                        }
                        font.pixelSize: 10; color: "#4A5E8A"
                    }
                }
            }
        }

        // =====================================================================
        // GRAPH AREA
        // =====================================================================
        Flickable {
            id: flickArea

            interactive: histogramCard.interactionUnlocked

            x: histogramCard.padH + histogramCard.yAxisW
            y: histogramCard.graphTop + histogramCard.topPad
            width:  histogramCard.plotW
            height: histogramCard.barAreaH
            clip:   true



            boundsBehavior:    Flickable.StopAtBounds
            flickableDirection: Flickable.HorizontalFlick

            contentWidth:  histogramCard.totalBarsW
            contentHeight: height

            ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AlwaysOff }

            onContentXChanged: Qt.callLater(root.updateVisibleWindow)
            onWidthChanged:    Qt.callLater(root.updateVisibleWindow)

            WheelHandler {
                acceptedDevices: PointerDevice.Mouse
                onWheel: function(ev) {
                    var oldZ   = histogramCard.zoomFactor
                    var factor = ev.angleDelta.y > 0 ? 1.08 : 0.92
                    var newZ   = Math.max(histogramCard.minZoomFactor, Math.min(2.0, oldZ * factor))
                    var mouseX = flickArea.contentX + ev.x
                    histogramCard.zoomFactor = newZ
                    flickArea.contentX = Math.max(0, mouseX * (newZ / oldZ) - ev.x)
                }
            }

            Item {
                id: plotItem
                width:  flickArea.contentWidth
                height: flickArea.height

                // ── Single hover handler covers the whole plot area ───────────
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    // Absolute x relative to plotItem origin
                    onPositionChanged: function(mouse) { root.updateTooltip(mouse.x) }
                    onExited:          { root.tooltipItem = null }
                }

                // ── Virtualized bar Repeater ──────────────────────────────────
                Repeater {
                    id: barRepeater
                    model: root.windowSize

                    delegate: Item {
                        id: barSlot

                        readonly property int  globalIdx: root.windowStart + index
                        // Guard against rawValues not yet populated
                        readonly property bool dataValid: globalIdx < root.rawValues.length

                        readonly property var  barData:   dataValid ? root.rawValues[globalIdx] : null

                        readonly property real fraction:  dataValid
                            ? (barData.val - histogramCard.yMin) / (histogramCard.yMax - histogramCard.yMin)
                            : 0

                        readonly property real barH: Math.max(
                            6 * root.scale,
                            fraction * (plotItem.height * 0.96)
                        )

                        x: globalIdx * histogramCard.barStride + histogramCard.barSpacing
                        width:  histogramCard.barWidth
                        height: plotItem.height

                        // Bar
                        Rectangle {
                            anchors.bottom: parent.bottom
                            width:  parent.width
                            height: parent.barH
                            radius: Math.min(4 * root.scale, width * 0.4)
                            color:  "#1A4DB5"
                        }

                        // Value label (detail mode only)
                        Text {
                            visible: histogramCard.isDetail && barSlot.dataValid
                            anchors.bottom:           parent.bottom
                            anchors.bottomMargin:     parent.barH + (4 * root.scale)
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: barSlot.dataValid ? barData.val.toLocaleString() : ""
                            font.pixelSize: 9

                            color: "#1A4DB5"
                            renderType: Text.NativeRendering
                        }
                    }
                }
            }
        }

        // =====================================================================
        // X AXIS  — uses same window as bars, no separate model needed
        // =====================================================================
        Item {
            id: xAxisItem
            x:      histogramCard.padH + histogramCard.yAxisW
            y:      histogramCard.graphTop + histogramCard.topPad + histogramCard.barAreaH
            width:  histogramCard.plotW
            height: histogramCard.xAxisH
            clip:   true

            Rectangle { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; height: 2; color: "#4A5E8A" }

            // Offset layer follows scroll without any model
            Item {
                x:      -flickArea.contentX
                width:  histogramCard.totalBarsW
                height: parent.height

                Repeater {
                    model: root.windowSize   // mirrors bar window exactly

                    delegate: Item {
                        readonly property int  globalIdx: root.windowStart + index
                        readonly property bool dataValid: globalIdx < root.rawValues.length
                        readonly property var  axisData: dataValid ? root.rawValues[globalIdx] : null

                        x:      dataValid ? globalIdx * histogramCard.barStride + histogramCard.barSpacing : 0
                        width:  histogramCard.barStride
                        height: xAxisItem.height
                        visible: dataValid

                        // Tick mark
                        Rectangle { x: parent.width / 2; y: 2; width: 1; height: 5 * root.scale; color: "#4A5E8A" }

                        // Overview label (one per day, at first reading)
                        Column {
                            visible: !histogramCard.isDetail && dataValid && axisData.hhmm === "00:05"
                            anchors.top:              parent.top
                            anchors.topMargin:        9 * root.scale
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 2 * root.scale
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: dataValid ? axisData.dd : ""; font.pixelSize: 11; color: "#1A4DB5" }
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: dataValid ? root.monthName(axisData.mon) : ""; font.pixelSize: 9; color: "#4A5E8A" }
                        }

                        // Detail label (day + time)
                        Column {
                            visible: histogramCard.isDetail && dataValid
                            anchors.top:              parent.top
                            anchors.topMargin:        9 * root.scale
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 4 * root.scale
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: dataValid ? axisData.dd : ""; font.pixelSize: 11; color: "#1A4DB5" }
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: dataValid ? root.monthName(axisData.mon) : ""; font.pixelSize: 9; color: "#4A5E8A" }
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: dataValid ? axisData.hhmm : ""; font.pixelSize: 8; color: "#7B8FAD" }
                        }
                    }
                }
            }
        }

        // Y-axis / X-axis corner cover
        Rectangle {
            x:      histogramCard.padH
            y:      histogramCard.graphTop + histogramCard.topPad + histogramCard.barAreaH
            width:  histogramCard.yAxisW
            height: histogramCard.xAxisH
            color:  "#FFFFFF"
            Rectangle { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; height: 2; color: "#4A5E8A" }
        }

        // ==========================================================
        // INTERACTION LOCK
        // ==========================================================

        property bool interactionUnlocked: false

        // Smooth unlock animation
        Behavior on opacity {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutCubic
            }
        }

        // ==========================================================
        // DISABLED OVERLAY
        // ==========================================================

        Rectangle {
            id: lockOverlay

            anchors.fill: parent

            z: 999999

            visible: !histogramCard.interactionUnlocked

            color: "#F5F7FC"

            opacity: overlayTap.pressed ? 0.92 : 0.96

            radius: histogramCard.radius

            border.width: 2
            border.color: "#6F95D6"

            // Smooth fade
            Behavior on opacity {
                NumberAnimation {
                    duration: 160
                }
            }

            // ======================================================
            // BACKGROUND GLOW
            // ======================================================

            Rectangle {
                width: 220 * root.scale
                height: 220 * root.scale

                radius: width / 2

                anchors.centerIn: parent

                color: "#DCE9FF"

                opacity: pulseAnim.running ? 0.48 : 0.38

                scale: pulseAnim.running ? 1.08 : 0.95

                SequentialAnimation on scale {
                    id: pulseAnim

                    running: true
                    loops: Animation.Infinite

                    NumberAnimation {
                        to: 1.08
                        duration: 1200
                        easing.type: Easing.OutQuad
                    }

                    NumberAnimation {
                        to: 0.95
                        duration: 1200
                        easing.type: Easing.InOutQuad
                    }
                }

                Behavior on opacity {
                    NumberAnimation { duration: 300 }
                }
            }

            // ======================================================
            // CENTER CONTENT
            // ======================================================

            Column {
                anchors.centerIn: parent

                spacing: 18 * root.scale

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter

                    text: "Coil Output Window"

                    font.pixelSize: 26


                    color: "#1A4DB5"
                }

                // Lock Icon Circle
                Rectangle {
                    width: 90 * root.scale
                    height: 90 * root.scale

                    radius: width / 2

                    anchors.horizontalCenter: parent.horizontalCenter

                    color: "#FFFFFF"

                    border.width: 2
                    border.color: "#6F95D6"

                    scale: overlayTap.pressed ? 0.94 : 1.0

                    Behavior on scale {
                        NumberAnimation {
                            duration: 120
                            easing.type: Easing.OutQuad
                        }
                    }

                    Text {
                        anchors.centerIn: parent

                        text: "🔒"

                        font.pixelSize: 38
                    }
                }

                // Main Text
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter

                    text: "Tap Here to Unlock"

                    font.pixelSize: 26


                    color: "#1A4DB5"
                }

                // Subtitle
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter

                    text: "Enable zoom, scroll & interaction"

                    font.pixelSize: 18

                    color: "#6B7A99"
                }
            }

            // ======================================================
            // TAP AREA
            // ======================================================

            MouseArea {
                id: overlayTap

                anchors.fill: parent

                hoverEnabled: true

                cursorShape: Qt.PointingHandCursor

                onClicked: {

                    unlockAnim.start()
                }
            }

            // ======================================================
            // UNLOCK ANIMATION
            // ======================================================

            SequentialAnimation {
                id: unlockAnim

                PropertyAnimation {
                    target: lockOverlay
                    property: "scale"

                    from: 1.0
                    to: 0.96

                    duration: 100
                }

                PropertyAnimation {
                    target: lockOverlay
                    property: "scale"

                    from: 0.96
                    to: 1.04

                    duration: 140
                }

                ParallelAnimation {

                    PropertyAnimation {
                        target: lockOverlay
                        property: "opacity"

                        to: 0.0

                        duration: 260
                        easing.type: Easing.OutQuad
                    }

                    PropertyAnimation {
                        target: lockOverlay
                        property: "scale"

                        to: 1.08

                        duration: 260
                        easing.type: Easing.OutQuad
                    }
                }

                ScriptAction {
                    script: {
                        histogramCard.interactionUnlocked = true
                    }
                }
            }
        }
    }
}
