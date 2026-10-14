import QtQuick
import QtQuick.Layouts
import "."

Rectangle {
    id: chartCard

    property real scale: 1
    property string title: "X"
    property string valueKey: "x"
    property color traceColor: "#1A4DB5"
    property string displayMode: "Both"
    property var samples: []
    property bool cursorEnabled: false
    property int hoverSampleIndex: -1
    property int firstCursorIndex: -1
    property int secondCursorIndex: -1

    property int visibleSamples: 10000
    property int windowStart: Math.max(0, samples.length - visibleSamples)
    property int previousSampleCount: samples.length
    property int zoomInLevel: 0

    readonly property int minVisibleSamples: 20
    readonly property int maxVisibleSamples: 10000
    readonly property real valueLimit: 32768

    function moveWindow(amount) {
        windowStart = Math.max(0,
                               Math.min(samples.length - visibleSamples,
                                        windowStart + amount))
    }

    function zoomIn() {
        var count = Math.min(visibleSamples,
                             Math.max(0, samples.length - windowStart))
        if (count === 0)
            return

        var keys = displayMode === "Both"
                ? ["x", "y"] : [displayMode.toLowerCase()]
        var peakIndex = windowStart
        var peakMagnitude = -1
        for (var i = windowStart; i < windowStart + count; ++i) {
            for (var keyIndex = 0; keyIndex < keys.length; ++keyIndex) {
                var magnitude = Math.abs(Number(samples[i][keys[keyIndex]]))
                if (magnitude > peakMagnitude) {
                    peakMagnitude = magnitude
                    peakIndex = i
                }
            }
        }

        var newVisibleSamples = Math.max(minVisibleSamples,
                                         Math.floor(visibleSamples / 1.5))
        if (newVisibleSamples === visibleSamples)
            return
        visibleSamples = newVisibleSamples
        zoomInLevel += 1
        windowStart = Math.max(0,
                               Math.min(samples.length - visibleSamples,
                                        Math.round(peakIndex - visibleSamples / 2)))
    }

    function zoomOut() {
        var center = windowStart + visibleSamples / 2
        visibleSamples = Math.min(maxVisibleSamples,
                                  Math.ceil(visibleSamples * 1.5))
        zoomInLevel = Math.max(0, zoomInLevel - 1)
        windowStart = Math.max(0,
                               Math.min(samples.length - visibleSamples,
                                        Math.round(center - visibleSamples / 2)))
    }

    function resetView() {
        visibleSamples = maxVisibleSamples
        windowStart = Math.max(0, samples.length - visibleSamples)
        zoomInLevel = 0
    }

    function clearCursorSelection() {
        hoverSampleIndex = -1
        firstCursorIndex = -1
        secondCursorIndex = -1
    }

    function sampleIndexAt(x, y) {
        var left = 76 * scale
        var right = 26 * scale
        var top = 18 * scale
        var bottom = 8 * scale
        var plotWidth = Math.max(1, plot.width - left - right)
        var plotHeight = Math.max(1, plot.height - top - bottom)
        var count = Math.min(visibleSamples,
                             Math.max(0, samples.length - windowStart))

        if (count === 0 || x < left || x > left + plotWidth
                || y < top || y > top + plotHeight)
            return -1

        if (count === 1)
            return windowStart

        return windowStart + Math.round((x - left) * (count - 1) / plotWidth)
    }

    function pointDescription(index) {
        var point = samples[index]
        return "(" + Number(point.x).toFixed(2)
                + ", " + Number(point.y).toFixed(2) + ")"
    }

    function sampleTimeMilliseconds(index) {
        if (samples.length <= 1)
            return 0
        return index * 10000 / (samples.length - 1)
    }

    function formatSampleTime(milliseconds) {
        return (milliseconds / 1000).toFixed(3) + " s ("
                + milliseconds.toFixed(0) + " ms)"
    }

    function currentAxisLimit() {
        var maxMagnitude = 0
        var keys = displayMode === "Both" ? ["x", "y"] : [displayMode.toLowerCase()]
        for (var i = 0; i < samples.length; ++i) {
            for (var keyIndex = 0; keyIndex < keys.length; ++keyIndex)
                maxMagnitude = Math.max(maxMagnitude,
                                        Math.abs(Number(samples[i][keys[keyIndex]])))
        }

        if (maxMagnitude === 0)
            return 1000

        maxMagnitude = Math.min(valueLimit, maxMagnitude)
        var power = Math.pow(10, Math.floor(Math.log(maxMagnitude) / Math.LN10))
        var normalized = maxMagnitude / power
        var rounded = normalized <= 1 ? 1
                    : normalized <= 2 ? 2
                    : normalized <= 5 ? 5 : 10
        return Math.min(valueLimit, rounded * power)
    }

    Layout.minimumWidth: 0
    radius: 8 * scale
    color: "#FFFFFF"
    border.width: 1
    border.color: "#DCE5F5"

    Canvas {
        id: plot

        anchors.fill: parent
        anchors.margins: 7 * chartCard.scale

        onPaint: {
                var ctx = getContext("2d")
                var w = width
                var h = height
                ctx.clearRect(0, 0, w, h)
                ctx.fillStyle = "#FFFFFF"
                ctx.fillRect(0, 0, w, h)

                var left = 76 * chartCard.scale
                var right = 26 * chartCard.scale
                var top = 18 * chartCard.scale
                var bottom = 8 * chartCard.scale
                var plotWidth = Math.max(1, w - left - right)
                var plotHeight = Math.max(1, h - top - bottom)
                var centerY = top + plotHeight / 2
                var samples = chartCard.samples
                var count = Math.min(chartCard.visibleSamples,
                                     Math.max(0, samples.length - chartCard.windowStart))
                var showSamplePoints = count <= plotWidth / 6
                var end = chartCard.windowStart + count
                var axisLimit = chartCard.currentAxisLimit()

                ctx.font = Math.max(12, 14 * chartCard.scale) + "px sans-serif"
                ctx.strokeStyle = "#E6ECF5"
                ctx.lineWidth = 1

                for (var tick = 0; tick <= 4; ++tick) {
                    var fraction = tick / 4
                    var y = top + plotHeight * fraction
                    ctx.beginPath()
                    ctx.moveTo(left, y)
                    ctx.lineTo(left + plotWidth, y)
                    ctx.stroke()
                    ctx.fillStyle = "#526174"
                    ctx.textAlign = "right"
                    ctx.textBaseline = "middle"
                    var value = Math.round(axisLimit - 2 * axisLimit * fraction)
                    ctx.fillText(value > 0 ? "+" + value : String(value),
                                 left - 8 * chartCard.scale, y)
                }

                for (var gridIndex = 0; gridIndex <= 10; ++gridIndex) {
                    var gridX = left + plotWidth * gridIndex / 10
                    ctx.beginPath()
                    ctx.moveTo(gridX, top)
                    ctx.lineTo(gridX, top + plotHeight)
                    ctx.stroke()
                }

                ctx.strokeStyle = "#526174"
                ctx.lineWidth = 1.4
                ctx.beginPath()
                ctx.moveTo(left, top + plotHeight)
                ctx.lineTo(left, top)
                ctx.lineTo(left - 4 * chartCard.scale, top + 7 * chartCard.scale)
                ctx.moveTo(left, top)
                ctx.lineTo(left + 4 * chartCard.scale, top + 7 * chartCard.scale)
                ctx.moveTo(left, centerY)
                ctx.lineTo(left + plotWidth, centerY)
                ctx.lineTo(left + plotWidth - 7 * chartCard.scale,
                           centerY - 4 * chartCard.scale)
                ctx.moveTo(left + plotWidth, centerY)
                ctx.lineTo(left + plotWidth - 7 * chartCard.scale,
                           centerY + 4 * chartCard.scale)
                ctx.stroke()

                ctx.font = "bold " + Math.max(12, 14 * chartCard.scale) + "px sans-serif"
                ctx.fillStyle = "#1A4DB5"
                ctx.textAlign = "center"
                ctx.textBaseline = "bottom"
                ctx.fillStyle = "#526174"
                ctx.textAlign = "right"
                ctx.textBaseline = "middle"
                ctx.fillText("t",
                             left + plotWidth + 11 * chartCard.scale,
                             centerY - 5 * chartCard.scale)

                if (count === 0) {
                    ctx.font = Math.max(13, 15 * chartCard.scale) + "px sans-serif"
                    ctx.fillStyle = "#94A3B8"
                    ctx.textAlign = "center"
                    ctx.textBaseline = "middle"
                    ctx.fillText("Waiting for serial waveform data",
                                 left + plotWidth / 2,
                                 top + plotHeight / 2)
                    return
                }

                ctx.save()
                ctx.beginPath()
                ctx.rect(left, top, plotWidth, plotHeight)
                ctx.clip()
                ctx.lineWidth = Math.max(1.5, 2 * chartCard.scale)
                ctx.lineJoin = "round"
                ctx.lineCap = "round"
                var series = []
                if (chartCard.displayMode === "X" || chartCard.displayMode === "Both")
                    series.push({ key: "x", color: "#1A4DB5" })
                if (chartCard.displayMode === "Y" || chartCard.displayMode === "Both")
                    series.push({ key: "y", color: "#D64545" })

                for (var seriesIndex = 0; seriesIndex < series.length; ++seriesIndex) {
                    ctx.strokeStyle = series[seriesIndex].color
                    ctx.beginPath()

                    for (var i = chartCard.windowStart; i < end; ++i) {
                        var sampleValue = Math.max(
                                    -axisLimit,
                                    Math.min(axisLimit,
                                             Number(samples[i][series[seriesIndex].key])))
                        var x = left + (count === 1
                                        ? plotWidth
                                        : plotWidth * (i - chartCard.windowStart)
                                          / (count - 1))
                        var sampleY = top + (axisLimit - sampleValue)
                                  * plotHeight / (2 * axisLimit)
                        if (i === chartCard.windowStart)
                            ctx.moveTo(x, sampleY)
                        else
                            ctx.lineTo(x, sampleY)
                    }

                    ctx.stroke()

                    if (showSamplePoints) {
                        ctx.fillStyle = series[seriesIndex].color
                        for (var pointIndex = chartCard.windowStart;
                             pointIndex < end; ++pointIndex) {
                            var pointValue = Math.max(
                                        -axisLimit,
                                        Math.min(axisLimit,
                                                 Number(samples[pointIndex][series[seriesIndex].key])))
                            var pointX = left + (count === 1
                                                 ? plotWidth
                                                 : plotWidth * (pointIndex - chartCard.windowStart)
                                                   / (count - 1))
                            var pointY = top + (axisLimit - pointValue)
                                       * plotHeight / (2 * axisLimit)
                            ctx.beginPath()
                            ctx.arc(pointX, pointY,
                                    Math.max(2, 2.5 * chartCard.scale),
                                    0, 2 * Math.PI)
                            ctx.fill()
                        }
                    }
                }

                if (chartCard.zoomInLevel >= 2) {
                    var peakMarkers = []
                    for (var peakSeriesIndex = 0;
                         peakSeriesIndex < series.length;
                         ++peakSeriesIndex) {
                        var peakSeries = series[peakSeriesIndex]
                        var positiveIndex = chartCard.windowStart
                        var negativeIndex = chartCard.windowStart
                        var positiveValue = Number(samples[positiveIndex][peakSeries.key])
                        var negativeValue = positiveValue
                        for (var sampleIndex = chartCard.windowStart + 1;
                             sampleIndex < end;
                             ++sampleIndex) {
                            var value = Number(samples[sampleIndex][peakSeries.key])
                            if (value > positiveValue) {
                                positiveValue = value
                                positiveIndex = sampleIndex
                            }
                            if (value < negativeValue) {
                                negativeValue = value
                                negativeIndex = sampleIndex
                            }
                        }
                        peakMarkers.push({
                            label: peakSeries.key.toUpperCase() + " +Peak",
                            value: positiveValue,
                            index: positiveIndex
                        })
                        peakMarkers.push({
                            label: peakSeries.key.toUpperCase() + " -Peak",
                            value: negativeValue,
                            index: negativeIndex
                        })
                    }

                    var peakFontSize = Math.max(15,
                                                Math.min(18, 16 * chartCard.scale))
                    var peakBoxHeight = peakFontSize + 12 * chartCard.scale
                    var peakPadding = 8 * chartCard.scale
                    var peakGap = 5 * chartCard.scale
                    var placedPeakBoxes = []
                    ctx.font = "600 " + peakFontSize + "px sans-serif"
                    ctx.textBaseline = "middle"

                    for (var peakIndex = 0;
                         peakIndex < peakMarkers.length;
                         ++peakIndex) {
                        var peak = peakMarkers[peakIndex]
                        peak.text = peak.label + ": " + peak.value.toFixed(2)
                        peak.boxWidth = ctx.measureText(peak.text).width
                                        + 2 * peakPadding
                        peak.x = left + (count === 1
                                         ? plotWidth
                                         : plotWidth * (peak.index - chartCard.windowStart)
                                           / (count - 1))
                        peak.value = Math.max(-axisLimit,
                                              Math.min(axisLimit, peak.value))
                        peak.y = top + (axisLimit - peak.value)
                                 * plotHeight / (2 * axisLimit)
                        peak.boxX = Math.max(left,
                                             Math.min(left + plotWidth - peak.boxWidth,
                                                      peak.x - peak.boxWidth / 2))

                        var aboveY = peak.y - peakBoxHeight - peakGap
                        var belowY = peak.y + peakGap
                        var candidates = []
                        for (var above = aboveY;
                             above >= top;
                             above -= peakBoxHeight + peakGap)
                            candidates.push(above)
                        for (var below = belowY;
                             below + peakBoxHeight <= top + plotHeight;
                             below += peakBoxHeight + peakGap)
                            candidates.push(below)

                        for (var candidateIndex = 0;
                             candidateIndex < candidates.length;
                             ++candidateIndex) {
                            var candidateY = candidates[candidateIndex]
                            var overlaps = false
                            for (var placedIndex = 0;
                                 placedIndex < placedPeakBoxes.length;
                                 ++placedIndex) {
                                var placed = placedPeakBoxes[placedIndex]
                                if (peak.boxX < placed.x + placed.width
                                        && peak.boxX + peak.boxWidth > placed.x
                                        && candidateY < placed.y + placed.height
                                        && candidateY + peakBoxHeight > placed.y) {
                                    overlaps = true
                                    break
                                }
                            }
                            if (!overlaps) {
                                peak.boxY = candidateY
                                break
                            }
                        }
                        if (peak.boxY === undefined)
                            peak.boxY = Math.max(top,
                                                 Math.min(top + plotHeight - peakBoxHeight,
                                                          aboveY))

                        placedPeakBoxes.push({
                            x: peak.boxX,
                            y: peak.boxY,
                            width: peak.boxWidth,
                            height: peakBoxHeight
                        })

                        var guideEndY = peak.boxY < peak.y
                                ? peak.boxY + peakBoxHeight : peak.boxY
                        ctx.strokeStyle = "#000000"
                        ctx.lineWidth = Math.max(1.5, 1.5 * chartCard.scale)
                        var dashLength = Math.max(3, 4 * chartCard.scale)
                        var dashGap = Math.max(2, 3 * chartCard.scale)
                        var guideDirection = guideEndY < peak.y ? -1 : 1
                        for (var guideY = peak.y;
                             guideDirection < 0 ? guideY > guideEndY
                                                : guideY < guideEndY;
                             guideY += guideDirection * (dashLength + dashGap)) {
                            ctx.beginPath()
                            ctx.moveTo(peak.x, guideY)
                            ctx.lineTo(peak.x,
                                       guideDirection < 0
                                       ? Math.max(guideEndY, guideY - dashLength)
                                       : Math.min(guideEndY, guideY + dashLength))
                            ctx.stroke()
                        }

                        ctx.beginPath()
                        ctx.arc(peak.x, peak.y,
                                Math.max(3, 3.5 * chartCard.scale),
                                0, 2 * Math.PI)
                        ctx.fillStyle = "#FFFFFF"
                        ctx.fill()
                        ctx.strokeStyle = "#000000"
                        ctx.lineWidth = Math.max(1.5, 1.5 * chartCard.scale)
                        ctx.stroke()

                        ctx.fillStyle = "#FFFFFF"
                        ctx.fillRect(peak.boxX, peak.boxY,
                                     peak.boxWidth, peakBoxHeight)
                        ctx.strokeStyle = "#111827"
                        ctx.lineWidth = Math.max(1, chartCard.scale)
                        ctx.strokeRect(peak.boxX, peak.boxY,
                                       peak.boxWidth, peakBoxHeight)
                        ctx.fillStyle = "#111827"
                        ctx.textAlign = "left"
                        ctx.textBaseline = "middle"
                        ctx.fillText(peak.text,
                                     peak.boxX + peakPadding,
                                     peak.boxY + peakBoxHeight / 2)
                    }
                }

                var cursorIndices = []
                var cursorColors = []
                if (chartCard.cursorEnabled && chartCard.hoverSampleIndex >= 0) {
                    cursorIndices.push(chartCard.hoverSampleIndex)
                    cursorColors.push("#F59E0B")
                }
                if (chartCard.firstCursorIndex >= 0) {
                    cursorIndices.push(chartCard.firstCursorIndex)
                    cursorColors.push("#16804A")
                }
                if (chartCard.secondCursorIndex >= 0) {
                    cursorIndices.push(chartCard.secondCursorIndex)
                    cursorColors.push("#B42318")
                }

                for (var cursor = 0; cursor < cursorIndices.length; ++cursor) {
                    var cursorIndex = cursorIndices[cursor]
                    if (cursorIndex < chartCard.windowStart || cursorIndex >= end)
                        continue

                    var cursorX = left + (count === 1
                                          ? plotWidth
                                          : plotWidth * (cursorIndex - chartCard.windowStart)
                                            / (count - 1))
                    var dashStep = Math.max(1, 10 * chartCard.scale)
                    var dashLength = Math.max(1, 5 * chartCard.scale)
                    ctx.strokeStyle = cursorColors[cursor]
                    ctx.lineWidth = Math.max(1, chartCard.scale)
                    for (var dashY = top; dashY < top + plotHeight;
                         dashY += dashStep) {
                        ctx.beginPath()
                        ctx.moveTo(cursorX, dashY)
                        ctx.lineTo(cursorX,
                                   Math.min(top + plotHeight,
                                            dashY + dashLength))
                        ctx.stroke()
                    }

                    if (cursorIndex === chartCard.firstCursorIndex
                            || cursorIndex === chartCard.secondCursorIndex) {
                        var selectedKeys = ["x", "y"]
                        var selectedColors = ["#1A4DB5", "#D64545"]
                        for (var keyIndex = 0; keyIndex < selectedKeys.length; ++keyIndex) {
                            var selectedValue = Math.max(
                                        -axisLimit,
                                        Math.min(axisLimit,
                                                 Number(samples[cursorIndex][selectedKeys[keyIndex]])))
                            var selectedY = top + (axisLimit - selectedValue)
                                       * plotHeight / (2 * axisLimit)
                            ctx.beginPath()
                            ctx.arc(cursorX, selectedY,
                                    Math.max(2, 4 * chartCard.scale),
                                    0, 2 * Math.PI)
                            ctx.fillStyle = "#FFFFFF"
                            ctx.fill()
                            ctx.lineWidth = 2 * chartCard.scale
                            ctx.strokeStyle = selectedColors[keyIndex]
                            ctx.stroke()
                        }
                    }
                }

                ctx.restore()
        }

        Component.onCompleted: requestPaint()
    }

    MouseArea {
        anchors.fill: plot
        enabled: chartCard.cursorEnabled && chartCard.samples.length > 0
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton

        onPositionChanged: function(mouse) {
            chartCard.hoverSampleIndex = chartCard.sampleIndexAt(mouse.x, mouse.y)
        }

        onExited: chartCard.hoverSampleIndex = -1

        onClicked: function(mouse) {
            var index = chartCard.sampleIndexAt(mouse.x, mouse.y)
            if (index < 0)
                return

            if (chartCard.firstCursorIndex < 0 || chartCard.secondCursorIndex >= 0) {
                chartCard.firstCursorIndex = index
                chartCard.secondCursorIndex = -1
            } else {
                chartCard.secondCursorIndex = index
            }
            chartCard.hoverSampleIndex = index
        }
    }

    Rectangle {
        visible: chartCard.cursorEnabled && chartCard.firstCursorIndex >= 0
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 14 * chartCard.scale
        width: Math.min(cursorInfo.implicitWidth + 24 * chartCard.scale,
                        chartCard.width * 0.48)
        height: cursorInfo.implicitHeight + 20 * chartCard.scale
        radius: 5 * chartCard.scale
        color: "#FFFFFF"
        border.width: 1
        border.color: "#DCE5F5"

        Text {
            id: cursorInfo
            anchors.fill: parent
            anchors.margins: 10 * chartCard.scale
            color: "#334155"
            font.pixelSize: Math.max(17, 19 * chartCard.scale)
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.Wrap
            text: "P1: " + chartCard.pointDescription(
                      chartCard.firstCursorIndex)
                  + "    t: "
                  + chartCard.formatSampleTime(
                      chartCard.sampleTimeMilliseconds(chartCard.firstCursorIndex))
                  + (chartCard.secondCursorIndex >= 0
                     ? "\nP2: " + chartCard.pointDescription(
                           chartCard.secondCursorIndex)
                       + "    t: "
                       + chartCard.formatSampleTime(
                           chartCard.sampleTimeMilliseconds(chartCard.secondCursorIndex))
                       + "\nΔ: "
                       + chartCard.formatSampleTime(
                           Math.abs(chartCard.secondCursorIndex
                                    - chartCard.firstCursorIndex)
                           * 10000 / Math.max(1, chartCard.samples.length - 1))
                     : "")
        }
    }

    onSamplesChanged: {
        if (samples.length === 0)
            zoomInLevel = 0
        var wasFollowingLatest =
                windowStart + visibleSamples >= previousSampleCount
        if (wasFollowingLatest)
            windowStart = Math.max(0, samples.length - visibleSamples)
        previousSampleCount = samples.length
        plot.requestPaint()
    }

    onWindowStartChanged: plot.requestPaint()
    onVisibleSamplesChanged: plot.requestPaint()
    onValueKeyChanged: plot.requestPaint()
    onDisplayModeChanged: plot.requestPaint()
    onCursorEnabledChanged: plot.requestPaint()
    onHoverSampleIndexChanged: plot.requestPaint()
    onFirstCursorIndexChanged: plot.requestPaint()
    onSecondCursorIndexChanged: plot.requestPaint()
}
