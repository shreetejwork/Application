import QtQuick
import QtQuick.Layouts
import "."

Rectangle {
    id: chartCard

    property real scale: 1
    property string title: "X"
    property string valueKey: "x"
    property color traceColor: "#1A4DB5"
    property var selectedChannels: ["x", "y", "z1", "z2"]
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

    function channelKeys() {
        return selectedChannels.slice()
    }

    function channelColor(key) {
        if (key === "x")
            return "#1A4DB5"
        if (key === "y")
            return "#D64545"
        if (key === "z1")
            return "#16804A"
        return "#8B5CF6"
    }

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

        var keys = channelKeys()
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
        var keys = channelKeys()
        var values = []
        for (var i = 0; i < keys.length; ++i)
            values.push(keys[i].toUpperCase() + ": "
                        + Number(point[keys[i]]).toFixed(2))
        return values.join(", ")
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

    function peakPoints(positive) {
        var start = Math.max(0, windowStart)
        var end = Math.min(samples.length, windowStart + visibleSamples)
        if (start >= end)
            return []

        var keys = channelKeys()
        var peaks = []
        for (var keyIndex = 0; keyIndex < keys.length; ++keyIndex) {
            var key = keys[keyIndex]
            var channelPeaks = []
            var risingCrossings = []
            for (var i = start + 1; i < end; ++i) {
                if (Number(samples[i - 1][key]) <= 0
                        && Number(samples[i][key]) > 0)
                    risingCrossings.push(i)
            }

            for (var cycle = 0; cycle + 1 < risingCrossings.length; ++cycle) {
                var cycleStart = risingCrossings[cycle]
                var cycleEnd = risingCrossings[cycle + 1]
                var peakIndex = cycleStart
                var peakValue = Number(samples[cycleStart][key])
                for (var pointIndex = cycleStart + 1;
                     pointIndex < cycleEnd;
                     ++pointIndex) {
                    var pointValue = Number(samples[pointIndex][key])
                    if ((positive && pointValue > peakValue)
                            || (!positive && pointValue < peakValue)) {
                        peakValue = pointValue
                        peakIndex = pointIndex
                    }
                }

                channelPeaks.push({
                    index: peakIndex,
                    value: peakValue
                })
            }

            if (channelPeaks.length === 0) {
                var framePeakIndex = start
                var framePeakValue = Number(samples[start][key])
                for (var frameIndex = start + 1; frameIndex < end; ++frameIndex) {
                    var frameValue = Number(samples[frameIndex][key])
                    if ((positive && frameValue > framePeakValue)
                            || (!positive && frameValue < framePeakValue)) {
                        framePeakValue = frameValue
                        framePeakIndex = frameIndex
                    }
                }
                channelPeaks.push({
                    index: framePeakIndex,
                    value: framePeakValue
                })
            }

            var highestAmplitude = 0
            for (var peakIndex = 0; peakIndex < channelPeaks.length; ++peakIndex) {
                var amplitude = positive
                        ? Math.max(0, channelPeaks[peakIndex].value)
                        : Math.max(0, -channelPeaks[peakIndex].value)
                highestAmplitude = Math.max(highestAmplitude, amplitude)
            }

            var peakNumber = 0
            var minimumAmplitude = highestAmplitude * 0.25
            for (var filteredIndex = 0;
                 filteredIndex < channelPeaks.length;
                 ++filteredIndex) {
                var candidate = channelPeaks[filteredIndex]
                var candidateAmplitude = positive
                        ? Math.max(0, candidate.value)
                        : Math.max(0, -candidate.value)
                if (candidateAmplitude < minimumAmplitude)
                    continue

                ++peakNumber
                peaks.push({
                    key: key,
                    number: peakNumber,
                    index: candidate.index,
                    value: candidate.value
                })
            }
        }

        return peaks
    }

    function peakInfoText(positive) {
        var peaks = peakPoints(positive)
        var details = []
        for (var i = 0; i < peaks.length; ++i) {
            var peak = peaks[i]
            details.push((positive ? "+" : "-") + peak.key.toUpperCase()
                         + peak.number + ": " + peak.value.toFixed(2)
                         + " @ " + formatSampleTime(
                             sampleTimeMilliseconds(peak.index)))
        }
        return details.join("\n")
    }

    function currentAxisLimit() {
        var maxMagnitude = 0
        var keys = channelKeys()
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
                var channelKeys = chartCard.channelKeys()
                for (var channelIndex = 0;
                     channelIndex < channelKeys.length;
                     ++channelIndex) {
                    series.push({
                        key: channelKeys[channelIndex],
                        color: chartCard.channelColor(channelKeys[channelIndex])
                    })
                }

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
                    var allPeaks = chartCard.peakPoints(true)
                                .concat(chartCard.peakPoints(false))
                    for (var peakIndex = 0;
                         peakIndex < allPeaks.length;
                         ++peakIndex) {
                        var peak = allPeaks[peakIndex]
                        var peakX = left + (count === 1
                                            ? plotWidth
                                            : plotWidth * (peak.index
                                                           - chartCard.windowStart)
                                              / (count - 1))
                        var peakValue = Math.max(-axisLimit,
                                                 Math.min(axisLimit, peak.value))
                        var peakY = top + (axisLimit - peakValue)
                                    * plotHeight / (2 * axisLimit)
                        var peakColor = chartCard.channelColor(peak.key)

                        ctx.beginPath()
                        ctx.arc(peakX, peakY,
                                Math.max(5, 6 * chartCard.scale),
                                0, 2 * Math.PI)
                        ctx.fillStyle = "#FFFFFF"
                        ctx.fill()
                        ctx.lineWidth = Math.max(1.5, 2 * chartCard.scale)
                        ctx.strokeStyle = "#111827"
                        ctx.stroke()

                        ctx.beginPath()
                        ctx.arc(peakX, peakY,
                                Math.max(2.5, 3 * chartCard.scale),
                                0, 2 * Math.PI)
                        ctx.fillStyle = peakColor
                        ctx.fill()
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
                        var selectedKeys = chartCard.channelKeys()
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
                            ctx.strokeStyle =
                                    chartCard.channelColor(selectedKeys[keyIndex])
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
        id: positivePeakPopup
        visible: chartCard.zoomInLevel >= 2 && chartCard.samples.length > 0
        z: 2
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: 95 * chartCard.scale
        anchors.topMargin: 10 * chartCard.scale
        width: Math.min(positivePeakInfo.implicitWidth + 24 * chartCard.scale,
                        chartCard.width * 0.48)
        height: positivePeakInfo.implicitHeight + 20 * chartCard.scale
        radius: 5 * chartCard.scale
        color: "#FFFFFF"
        border.width: 1
        border.color: "#DCE5F5"

        Text {
            id: positivePeakInfo
            anchors.fill: parent
            anchors.margins: 10 * chartCard.scale
            color: "#334155"
            font.pixelSize: Math.max(17, 19 * chartCard.scale)
            font.weight: Font.Medium
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.Wrap
            text: chartCard.peakInfoText(true)
        }
    }

    Rectangle {
        id: negativePeakPopup
        visible: chartCard.zoomInLevel >= 2 && chartCard.samples.length > 0
        z: 2
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: 95 * chartCard.scale
        anchors.bottomMargin: 10 * chartCard.scale
        width: Math.min(negativePeakInfo.implicitWidth + 24 * chartCard.scale,
                        chartCard.width * 0.48)
        height: negativePeakInfo.implicitHeight + 20 * chartCard.scale
        radius: 5 * chartCard.scale
        color: "#FFFFFF"
        border.width: 1
        border.color: "#DCE5F5"

        Text {
            id: negativePeakInfo
            anchors.fill: parent
            anchors.margins: 10 * chartCard.scale
            color: "#334155"
            font.pixelSize: Math.max(17, 19 * chartCard.scale)
            font.weight: Font.Medium
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.Wrap
            text: chartCard.peakInfoText(false)
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
    onSelectedChannelsChanged: plot.requestPaint()
    onCursorEnabledChanged: plot.requestPaint()
    onHoverSampleIndexChanged: plot.requestPaint()
    onFirstCursorIndexChanged: plot.requestPaint()
    onSecondCursorIndexChanged: plot.requestPaint()
}
