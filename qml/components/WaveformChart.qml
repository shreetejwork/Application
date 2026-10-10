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

    property int visibleSamples: 10000
    property int windowStart: Math.max(0, samples.length - visibleSamples)
    property int previousSampleCount: samples.length
    property real highestAxisLimit: 0

    readonly property int minVisibleSamples: 20
    readonly property int maxVisibleSamples: 10000
    readonly property real valueLimit: 32768

    function moveWindow(amount) {
        windowStart = Math.max(0,
                               Math.min(samples.length - visibleSamples,
                                        windowStart + amount))
    }

    function zoomIn() {
        var center = windowStart + visibleSamples / 2
        visibleSamples = Math.max(minVisibleSamples,
                                  Math.floor(visibleSamples / 1.5))
        windowStart = Math.max(0,
                               Math.min(samples.length - visibleSamples,
                                        Math.round(center - visibleSamples / 2)))
    }

    function zoomOut() {
        var center = windowStart + visibleSamples / 2
        visibleSamples = Math.min(maxVisibleSamples,
                                  Math.ceil(visibleSamples * 1.5))
        windowStart = Math.max(0,
                               Math.min(samples.length - visibleSamples,
                                        Math.round(center - visibleSamples / 2)))
    }

    function resetView() {
        visibleSamples = maxVisibleSamples
        windowStart = Math.max(0, samples.length - visibleSamples)
    }

    function currentAxisLimit() {
        var maxMagnitude = 0
        var end = Math.min(samples.length, windowStart + visibleSamples)
        var keys = displayMode === "Both" ? ["x", "y"] : [displayMode.toLowerCase()]
        for (var i = windowStart; i < end; ++i) {
            for (var keyIndex = 0; keyIndex < keys.length; ++keyIndex)
                maxMagnitude = Math.max(maxMagnitude,
                                        Math.abs(Number(samples[i][keys[keyIndex]])))
        }

        if (maxMagnitude > 0) {
            maxMagnitude = Math.min(valueLimit, maxMagnitude)
            var power = Math.pow(10, Math.floor(Math.log(maxMagnitude) / Math.LN10))
            var normalized = maxMagnitude / power
            var rounded = normalized <= 1 ? 1
                        : normalized <= 2 ? 2
                        : normalized <= 5 ? 5 : 10
            var requiredLimit = Math.min(valueLimit, rounded * power)
            if (requiredLimit > highestAxisLimit)
                highestAxisLimit = requiredLimit
        }

        return highestAxisLimit > 0 ? highestAxisLimit : 1000
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
                var end = chartCard.windowStart + count
                var axisLimit = chartCard.currentAxisLimit()

                ctx.font = Math.max(10, 12 * chartCard.scale) + "px sans-serif"
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

                ctx.font = "bold " + Math.max(10, 13 * chartCard.scale) + "px sans-serif"
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
                    ctx.font = Math.max(12, 14 * chartCard.scale) + "px sans-serif"
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
                }

                ctx.restore()
        }

        Component.onCompleted: requestPaint()
    }

    onSamplesChanged: {
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
}
