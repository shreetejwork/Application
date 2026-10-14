import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCore
import AppState 1.0
import CustomComponents 1.0
import Backend 1.0


import "../components"

Item {
    Typography {
        id: componentTypography
        scale: root.scale || 1.0
    }
    id: root

    anchors.fill: parent

    property var globalTopBar
    property var notify

    property real baseWidth:  1024
    property real baseHeight: 600

    property real scale: Math.min(
                             width  / baseWidth,
                             height / baseHeight
                             )

    // Holds the async grabToImage result so it isn't garbage-collected
    // before the callback fires
    property var pendingGrab: null

    // =========================================================
    // TYPOGRAPHY FOR XY PLOT SCREEN
    // =========================================================

    Typography {
        id: plotTypography
        scale: root.scale
    }


    function exportPdf()
    {
        if (typeof PdfExporter === "undefined" || !PdfExporter) {
            console.log("ERROR: PdfExporter is not available in this screen's context!")
            return
        }

        pendingGrab = graphCard.grabToImage(function(result) {

            if (!result) {
                console.log("Grab failed: result is null")
                pendingGrab = null
                return
            }

            var tempImage =
                    StandardPaths.writableLocation(StandardPaths.TempLocation)
                    + "/xyplot_tmp.png"

            var ok = result.saveToFile(tempImage)
            console.log("Temp image saved:", ok, tempImage)

            if (!ok) {
                console.log("Failed to save temp grab image to:", tempImage)
                pendingGrab = null
                return
            }

            try {
                var sessionInfo = {
                    "loggedInUserName": GlobalState.loggedInUserName,
                    "loggedInUserRole": GlobalState.loggedInUserRole
                }

                var savedPath = PdfExporter.exportXYPlotToPdf(
                            tempImage,
                            productPhaseText.text,
                            signalText.text,
                            amplitudeText.text,
                            sessionInfo
                            )
                console.log("XY Plot PDF saved at:", savedPath)

                if (notify) {
                    notify("PDF saved: " + savedPath)
                }
            } catch (e) {
                console.log("EXCEPTION calling exportXYPlotToPdf:", e)
            }

            pendingGrab = null
        })
    }

    property real bodyFont:  13 * scale
    property real smallFont: 11 * scale

    property var xyLineHistory: []
    property var latestXYTrace: []
    readonly property int maxPlotSamples: 1000

    function updateLatestXYTrace(points) {
        if (!points || points.length === 0)
            return

        var trace = []
        for (var i = 0; i < points.length; ++i) {
            var rawX = points[i].rawX
            var rawY = points[i].rawY
            trace.push({
                           x: Number(rawX !== undefined ? rawX : points[i].x),
                           y: Number(rawY !== undefined ? rawY : points[i].y)
                       })
        }

        var history = root.xyLineHistory.concat(trace)
        if (history.length > root.maxPlotSamples)
            history = history.slice(history.length - root.maxPlotSamples)

        xyLineHistory = history
        latestXYTrace = trace
    }

    function clearPlotBuffer() {
        xyLineHistory = []
        latestXYTrace = []
    }

    Component.onDestruction: SerialManager.setPlotMode(false)

    Connections {
        target: SerialManager

        function onXyPlotDataChanged() {
            root.updateLatestXYTrace(SerialManager.xyPlotData)
        }
    }

    Component.onCompleted: {
        SerialManager.setPlotMode(true)
        root.updateLatestXYTrace(SerialManager.xyPlotData)
    }

    Rectangle {
        anchors.fill: parent
        color: "#F5F7FC"
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 10 * root.scale
        anchors.rightMargin: 10 * root.scale
        anchors.topMargin: 10 * root.scale
        anchors.bottomMargin: 10 * root.scale
        spacing: 8 * root.scale

        // ── MAIN ROW ──────────────────────────────────────────────────────────
        Item {
            id: mainRow
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                id: parameterColumn
                width: 280 * root.scale
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                spacing: 10 * root.scale

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8 * root.scale

                    WaveformControlButton {
                        id: savePdfButton
                        text: "Save PDF"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40 * root.scale
                        labelPixelSize: plotTypography.body
                        accent: "#1A4DB5"
                        onClicked: {
                            var path = exportPdf()
                            if (path !== "" && globalTopBar
                                    && globalTopBar.showNotification) {
                                globalTopBar.showNotification(
                                            "✓ PDF saved successfully")
                            }
                        }
                    }

                    WaveformControlButton {
                        text: "Clear Buffer"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40 * root.scale
                        labelPixelSize: plotTypography.body
                        accent: "#B42318"
                        enabled: root.xyLineHistory.length > 0
                        onClicked: root.clearPlotBuffer()
                    }
                }

                // ── PARAMETERS ────────────────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    radius:       16 * root.scale
                    color:        "#FFFFFF"
                    border.width: 1
                    border.color: "#DCE5F5"

                    ColumnLayout {
                        anchors.fill:    parent
                        anchors.margins: 12 * root.scale
                        spacing: 10 * root.scale

                        // ── Product Phase card ─────────────────────────────────
                        Rectangle {
                            Layout.fillWidth:  true
                            Layout.fillHeight: true

                            radius:       12 * root.scale
                            color:        "#F7F9FD"
                            border.width: 1
                            border.color: "#DCE5F5"

                            ColumnLayout {
                                anchors.fill:    parent
                                anchors.margins: 14 * root.scale
                                spacing: 8 * root.scale

                                Text {
                                    text: "Product\nPhase"
                                    font.pixelSize: plotTypography.subHeading
                                    color: "#1A4DB5"
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Text {
                                    id: productPhaseText
                                    text: Number(SerialManager.productPhase).toFixed(1)
                                    font.pixelSize: plotTypography.body
                                    color: "#1A4DB5"
                                }
                            }
                        }

                        // ── Signal card ────────────────────────────────────────
                        Rectangle {
                            Layout.fillWidth:  true
                            Layout.fillHeight: true

                            radius:       12 * root.scale
                            color:        "#F7F9FD"
                            border.width: 1
                            border.color: "#DCE5F5"

                            ColumnLayout {
                                anchors.fill:    parent
                                anchors.margins: 14 * root.scale
                                spacing: 8 * root.scale

                                Text {
                                    text: "Signal"
                                    font.pixelSize: plotTypography.subHeading
                                    color: "#1A4DB5"
                                }

                                Text {
                                    id: signalText
                                    text: SerialManager.signal
                                    font.pixelSize: plotTypography.body
                                    color: "#0F8A60"
                                }
                            }
                        }

                        // ── Amplitude card ─────────────────────────────────────
                        Rectangle {
                            Layout.fillWidth:  true
                            Layout.fillHeight: true

                            radius:       12 * root.scale
                            color:        "#F7F9FD"
                            border.width: 1
                            border.color: "#DCE5F5"

                            ColumnLayout {
                                anchors.fill:    parent
                                anchors.margins: 14 * root.scale
                                spacing: 8 * root.scale

                                Text {
                                    text: "Amplitude"
                                    font.pixelSize: plotTypography.subHeading
                                    color: "#1A4DB5"
                                }

                                Text {
                                    id: amplitudeText
                                    text: SerialManager.amplitude
                                    font.pixelSize: plotTypography.body
                                    color: "#D64545"
                                }
                            }
                        }
                    }
                }
            }

            // ── GRAPH CARD ────────────────────────────────────────────────────
            Item {
                id: plotArea
                anchors.left: parent.left
                anchors.right: parameterColumn.left
                anchors.rightMargin: 10 * root.scale
                anchors.top: parent.top
                anchors.bottom: parent.bottom

                Rectangle {
                    id: graphCard

                    width: Math.max(0, Math.min(plotArea.width, plotArea.height))
                    height: width
                    anchors.centerIn: parent

                    radius:       16 * root.scale
                    color:        "#FFFFFF"
                    border.width: 1
                    border.color: "#DCE5F5"

                    MagneticFieldPlotItem {
                        id: plot
                        anchors.fill:         parent
                        anchors.leftMargin:   8 * root.scale
                        anchors.rightMargin:  8 * root.scale
                        anchors.topMargin:    8 * root.scale
                        anchors.bottomMargin: 8 * root.scale

                        axisData:        root.latestXYTrace
                        fieldHistory:    root.xyLineHistory.length > 0
                                         ? [{ points: root.xyLineHistory,
                                              color: "#1A4DB5" }]
                                         : []
                        showPointLabels: false
                    }
                }
            }
        }
    }
}
