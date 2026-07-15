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

    property var pendingCoilGrab: null

    property int statAvg: 0
    property int statMin: 0
    property int statMax: 0
    property int visualMax: 100

    property int totalDays: 0

    // Full dataset — never mutated after loadData()
    property var rawValues: []


    property var dayBoundaries: []

    // ─── Windowed-render state ────────────────────────────────────────────────
    property int windowStart: 0
    property int windowEnd:   0
    property int windowSize:  0


    property int windowStep: 1


    readonly property int renderBuffer: 80


    readonly property int maxRenderBars: 1200

    // ─── Tooltip cache ───────────────────────────────────────────────────────
    property var  tooltipItem: null   // cached object from rawValues
    property real tooltipBarX: 0
    property real tooltipBarY: 0

    // ─── Helpers ─────────────────────────────────────────────────────────────
    function monthName(m)
    {
        var months = [
            "", "Jan", "Feb", "Mar", "Apr", "May",
            "Jun", "Jul", "Aug","Sep", "Oct", "Nov","Dec"
        ]

        return months[m]
    }


    function formatAxisValue(v)
    {
        v = Math.round(v)

        if (v >= 1000000) {
            var m  = v / 1000000
            var rm = Math.round(m * 10) / 10
            return (rm % 1 === 0 ? rm.toFixed(0) : rm.toFixed(1)) + "M"
        }

        if (v >= 1000) {
            var k  = v / 1000
            var rk = Math.round(k * 10) / 10
            return (rk % 1 === 0 ? rk.toFixed(0) : rk.toFixed(1)) + "k"
        }

        return v.toString()
    }

    // ─── Initialisation ──────────────────────────────────────────────────────
    Component.onCompleted:
    {
        loadData()

        Qt.callLater(function(){

            Qt.callLater(function(){

                histogramCard.setInitialZoom()

            })

        })
    }

    function exportCoilPdf()
    {
        if (typeof PdfExporter === "undefined" || !PdfExporter) {
            console.log("ERROR: PdfExporter is not available")
            return
        }


        // Capture only graph area
        pendingCoilGrab = graphArea.grabToImage(
            function(result){

                if (!result) {
                    console.log("Coil graph capture failed")
                    pendingCoilGrab = null
                    return
                }


                var tempImage =
                        StandardPaths.writableLocation(
                            StandardPaths.TempLocation
                        )
                        + "/coil_output_tmp.png"


                var ok = result.saveToFile(tempImage)


                console.log(
                    "Coil graph image saved:",
                    ok,
                    tempImage
                )


                if(!ok)
                {
                    pendingCoilGrab = null
                    return
                }


                try
                {
                    var sessionInfo = {
                        "loggedInUserName":
                            GlobalState.loggedInUserName,

                        "loggedInUserRole":
                            GlobalState.loggedInUserRole
                    }


                    var savedPath =
                            PdfExporter.exportCoilOutputToPdf(
                                tempImage,
                                statAvg.toString(),
                                statMin.toString(),
                                statMax.toString(),
                                sessionInfo
                            )


                    console.log(
                        "Coil Output PDF saved:",
                        savedPath
                    )


                    if(notify)
                        notify("PDF saved: " + savedPath)

                }
                catch(e)
                {
                    console.log(
                        "EXCEPTION exportCoilOutputToPdf:",
                        e
                    )
                }


                pendingCoilGrab = null


            },
            Qt.size(
                graphArea.width * 2,
                graphArea.height * 2
            )
        )
    }

    function loadData()
    {

        var dbData =
                databaseManager.getCoilOutputHistory()


        var arr = []


        var sum = 0

        var mn = 999999999

        var mx = 0



        for(var i = 0; i < dbData.length; i++)
        {

            var item = dbData[i]


            var value =
                    item.value


            sum += value


            if(value < mn)
                mn = value


            if(value > mx)
                mx = value



            var axisDateStr = item.date  !== undefined ? item.date  : ""
            var axisTimeStr = item.time  !== undefined ? item.time  : ""


            var sortKey  = item.created_date !== undefined
                                ? item.created_date
                                : axisDateStr

            var dayStr   = "01"
            var monStr   = "Jan"
            var yearNum  = 1970

            if (item.created_date !== undefined) {
                var cdParts = ("" + item.created_date).split("-")
                if (cdParts.length === 3) {
                    yearNum = parseInt(cdParts[0])
                    monStr  = root.monthName(parseInt(cdParts[1]))
                    dayStr  = cdParts[2]
                }
            }

            var dayKey = sortKey


            arr.push({

                date: dayStr + " " + monStr + " " + yearNum,

                time: axisTimeStr,

                day: dayStr,

                month: monStr,

                hhmm: axisTimeStr,

                axisDate: axisDateStr,

                axisTime: axisTimeStr,

                dayKey: dayKey,

                isDayStart: false, // computed below once sorted

                val: value

            })

        }



        arr.sort(function(a, b) {
            if (a.dayKey === b.dayKey)
                return a.hhmm < b.hhmm ? -1 : (a.hhmm > b.hhmm ? 1 : 0)
            return a.dayKey < b.dayKey ? -1 : 1
        })



        var boundaries = []
        var lastDayKey = null

        for (var j = 0; j < arr.length; j++) {
            if (arr[j].dayKey !== lastDayKey) {
                arr[j].isDayStart = true
                boundaries.push({
                    index:    j,
                    axisDate: arr[j].axisDate,
                    dayKey:   arr[j].dayKey
                })
                lastDayKey = arr[j].dayKey
            }
        }


        rawValues = arr

        dayBoundaries = boundaries

        totalDays = boundaries.length



        if(arr.length > 0)
        {

            statAvg =
                    Math.round(sum / arr.length)


            statMin =
                    mn


            statMax =
                    mx



            visualMax =
                    Math.ceil((statMax * 1.12) / 100) * 100

        }
        else
        {

            statAvg = 0
            statMin = 0
            statMax = 0
            visualMax = 100

        }



        windowStart = 0

        windowEnd = 0

        windowSize = 0

        windowStep = 1

        tooltipItem = null


        updateVisibleWindow()

    }


    function jumpToDay(dayNumber)
    {
        if (!flickArea || !histogramCard) return
        if (dayNumber < 1 || dayNumber > dayBoundaries.length) return

        var boundary = dayBoundaries[dayNumber - 1]
        var stride = histogramCard.barStride

        if (stride <= 0) return

        var targetX = boundary.index * stride

        targetX = Math.max(
                    0,
                    Math.min(targetX, flickArea.contentWidth - flickArea.width)
                    )

        flickArea.contentX = targetX

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

        // Guard against an out-of-range start (e.g. stray contentX values)
        newStart = Math.min(newStart, total - 1)
        newEnd   = Math.max(newEnd, newStart)

        var rangeSize = newEnd - newStart + 1
        var newStep = 1
        var newSize = rangeSize


        if (rangeSize > maxRenderBars) {
            newStep = Math.ceil(rangeSize / maxRenderBars)
            newSize = Math.ceil(rangeSize / newStep)
        }

        // Only update properties that actually changed to avoid binding churn
        if (newStart !== windowStart) windowStart = newStart
        if (newEnd   !== windowEnd)   windowEnd   = newEnd
        if (newSize  !== windowSize)  windowSize  = newSize
        if (newStep  !== windowStep)  windowStep  = newStep
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
        tooltipItem  = item   // carries date, time, axisDate, axisTime, val

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

        function setInitialZoom()
        {
            if (plotW <= 0)
                return



            var daysToShow = 15

            var totalBarsForRange


            if (root.dayBoundaries.length > daysToShow) {


                totalBarsForRange = root.dayBoundaries[daysToShow].index

            } else {


                totalBarsForRange = root.rawValues.length

            }


            if (totalBarsForRange <= 0)
                totalBarsForRange = 100


            var availableWidth =
                    plotW


            // required pixel distance per bar
            var targetStride =
                    availableWidth / totalBarsForRange


            var defaultStride =
                    (44 + 6) * root.scale


            var initialZoom =
                    targetStride / defaultStride


            zoomFactor = Math.max(
                        minZoomFactor,
                        Math.min(
                            2.0,
                            initialZoom
                            )
                        )


            Qt.callLater(function(){

                flickArea.contentX = 0

                root.updateVisibleWindow()

            })
        }

        // ─── Zoom state ──────────────────────────────────────────────────────
        property real minZoomFactor: 0.003
        property real zoomFactor: 0.003
        property real _pinchZoom:    minZoomFactor

        property real detailThresh: 0.5
        property bool isDetail:     zoomFactor >= detailThresh

        // ─── Bar geometry ────────────────────────────────────────────────────

        property real barWidth: Math.max(0.15 * root.scale, 44 * root.scale * zoomFactor)
        property real barSpacing: Math.max(0.05 * root.scale, 6 * root.scale * zoomFactor)
        property real barStride: barWidth + barSpacing

        // ─── Y range ─────────────────────────────────────────────────────────
        property real yMin: 0

        property real yMax: root.visualMax > 0
                            ? root.visualMax
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

        // Which day (1-based, indexed into root.dayBoundaries) the first
        // visible bar currently belongs to.
        property int visibleDay: {
            var firstBar = Math.floor(flickArea.contentX / histogramCard.barStride)
            var boundaries = root.dayBoundaries

            if (boundaries.length === 0)
                return 1

            var dayNum = 1
            for (var i = 0; i < boundaries.length; i++) {
                if (boundaries[i].index <= firstBar)
                    dayNum = i + 1
                else
                    break
            }

            return Math.max(1, Math.min(root.totalDays, dayNum))
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
        onBarStrideChanged: {
            Qt.callLater(root.updateVisibleWindow)
        }


        function applyZoom(newZoom, centerX)
        {
            var oldZoom = zoomFactor

            newZoom = Math.max(
                        minZoomFactor,
                        Math.min(2.0, newZoom)
                        )

            if (Math.abs(oldZoom - newZoom) < 0.00001)
                return


            // Keep mouse/center position fixed while zooming
            var contentPos = flickArea.contentX + centerX

            zoomFactor = newZoom


            Qt.callLater(function(){

                flickArea.contentX = Math.max(
                            0,
                            Math.min(
                                contentPos * (newZoom / oldZoom) - centerX,
                                flickArea.contentWidth - flickArea.width
                                )
                            )

                root.updateVisibleWindow()

            })
        }

        // ─── Pinch zoom ───────────────────────────────────────────────────────
        PinchHandler {

            enabled: histogramCard.interactionUnlocked

            target: null

            onActiveChanged: {
                if (active) histogramCard._pinchZoom = histogramCard.zoomFactor
            }

            onActiveScaleChanged: {

                var oldZ = histogramCard.zoomFactor

                var newZ = Math.max(
                            histogramCard.minZoomFactor,
                            Math.min(2.0,
                                     histogramCard._pinchZoom * activeScale))

                if (Math.abs(newZ - oldZ) < 0.005)
                    return

                var cx = flickArea.contentX + flickArea.width / 2

                histogramCard.applyZoom(
                            newZ,
                            flickArea.width / 2
                            )
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

                                function doZoomOut()
                                {
                                    histogramCard.applyZoom(
                                                histogramCard.zoomFactor * 0.85,
                                                flickArea.width / 2
                                                )
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
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    text: Math.round(
                                              Math.log(histogramCard.zoomFactor /
                                                       histogramCard.minZoomFactor)
                                              /
                                              Math.log(2.0 /
                                                       histogramCard.minZoomFactor)
                                              * 100
                                              ) + "%"

                                    font.pixelSize: 15
                                    color: "#1A4DB5"
                                }
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

                                function zoomInStep()
                                {
                                    histogramCard.applyZoom(
                                                histogramCard.zoomFactor * 1.15,
                                                flickArea.width / 2
                                                )
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
                Button {
                    id: savePdfButton

                    text: "Save PDF"

                    Layout.preferredWidth: 140 * root.scale
                    Layout.preferredHeight: 55 * root.scale

                    onClicked: {
                        var path = exportCoilPdf()

                        if (path !== "") {
                            if (globalTopBar && globalTopBar.showNotification) {
                                globalTopBar.showNotification("✓ PDF saved successfully")
                            }
                        }
                    }

                    contentItem: Text {
                        text: savePdfButton.text
                        font.pixelSize: 18 * root.scale
                        color: "#FFFFFF"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        radius: 10 * root.scale
                        color: savePdfButton.pressed ? "#153F94" : "#1A4DB5"
                        border.width: 1
                        border.color: "#DCE5F5"
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

        Item {
            id: graphArea

            width: histogramCard.width
            height:
                histogramCard.graphTop +
                histogramCard.topPad +
                histogramCard.barAreaH +
                histogramCard.xAxisH +
                histogramCard.padV

            clip: false

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
                            text: root.formatAxisValue(labelVal)
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

                    onWheel: function(ev)
                    {
                        var factor =
                                ev.angleDelta.y > 0 ? 1.12 : 0.88

                        histogramCard.applyZoom(
                                    histogramCard.zoomFactor * factor,
                                    ev.x
                                    )
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

                            readonly property int  globalIdx: root.windowStart + index * root.windowStep
                            // Guard against rawValues not yet populated
                            readonly property bool dataValid: globalIdx < root.rawValues.length

                            readonly property var  barData:   dataValid ? root.rawValues[globalIdx] : null

                            readonly property real fraction:  dataValid
                                                              ? (barData.val - histogramCard.yMin) / (histogramCard.yMax - histogramCard.yMin)
                                                              : 0


                            readonly property real barH: Math.max(
                                                             6 * root.scale,
                                                             fraction * (plotItem.height * 0.90)
                                                             )

                            x: globalIdx * histogramCard.barStride + histogramCard.barSpacing
                            width:  histogramCard.barWidth
                            height: plotItem.height

                            // Bar
                            Rectangle {
                                anchors.bottom: parent.bottom
                                width:  Math.max(1.2 * root.scale, parent.width)
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

                x: histogramCard.padH + histogramCard.yAxisW

                y:
                    histogramCard.topPad +
                    histogramCard.graphTop +
                    histogramCard.barAreaH

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
                            readonly property int  globalIdx: root.windowStart + index * root.windowStep
                            readonly property bool dataValid: globalIdx < root.rawValues.length
                            readonly property var  axisData: dataValid ? root.rawValues[globalIdx] : null

                            x:      dataValid ? globalIdx * histogramCard.barStride + histogramCard.barSpacing : 0
                            width:  histogramCard.barStride
                            height: xAxisItem.height
                            visible: dataValid

                            // Tick mark
                            Rectangle { x: parent.width / 2; y: 2; width: 1; height: 5 * root.scale; color: "#4A5E8A" }


                            Column {
                                visible: !histogramCard.isDetail && dataValid && axisData.isDayStart
                                anchors.top: parent.top
                                anchors.topMargin: 9 * root.scale
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 1 * root.scale

                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: dataValid ? axisData.axisDate.split(" ")[0] : ""; font.pixelSize: 11; font.bold: true; color: "#1A4DB5" }
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: dataValid ? axisData.axisDate.split(" ")[1] : ""; font.pixelSize: 10; color: "#1A4DB5" }
                            }


                            Column {
                                visible: histogramCard.isDetail && dataValid
                                anchors.top: parent.top
                                anchors.topMargin: 9 * root.scale
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 1 * root.scale

                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: dataValid ? axisData.day : ""; font.pixelSize: 11; font.bold: true; color: "#1A4DB5" }
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: dataValid ? axisData.month : ""; font.pixelSize: 10; color: "#1A4DB5" }
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: dataValid ? axisData.axisTime : ""; font.pixelSize: 8; color: "#7B8FAD" }
                            }
                        }
                    }
                }
            }
        }
    }
}
