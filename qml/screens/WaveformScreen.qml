import QtQuick
import QtQuick.Layouts
import Backend 1.0 as Backend
import "../components"

Item {
    id: root

    anchors.fill: parent
    property real scale: Math.min(width / 1024, height / 600)
    property var samples: []
    property bool captureEnabled: true
    property string displayMode: "Both"
    readonly property int maxHistorySamples: 10000

    Component.onDestruction: Backend.SerialManager.setPlotMode(false)

    function showPacket(points) {
        if (!points || points.length === 0)
            return

        var packetSamples = []
        for (var i = 0; i < points.length; ++i) {
            packetSamples.push({
                                   x: Number(points[i].rawX),
                                   y: Number(points[i].rawY)
                               })
        }
        var history = samples.concat(packetSamples)
        if (history.length > maxHistorySamples)
            history = history.slice(history.length - maxHistorySamples)
        samples = history
    }

    Component.onCompleted: {
        Backend.SerialManager.setPlotMode(true)
        root.showPacket(Backend.SerialManager.xyPlotData)
    }

    Connections {
        target: Backend.SerialManager

        function onXyPlotDataChanged() {
            if (root.captureEnabled)
                root.showPacket(Backend.SerialManager.xyPlotData)
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#F5F7FC"
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8 * root.scale
        spacing: 8 * root.scale

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 34 * root.scale

            Text {
                text: "Waveform"
                color: "#1A4DB5"
                font.pixelSize: 30 * root.scale
            }

            Item { Layout.fillWidth: true }

            Text {
                text: root.captureEnabled
                      ? (root.samples.length > 0
                         ? "Capturing · " + root.samples.length + " samples"
                         : "Waiting for serial data...")
                      : "Capture paused"
                color: "#64748B"
                font.pixelSize: 12 * root.scale
            }

            WaveformControlButton {
                text: "‹ Older"
                Layout.preferredWidth: 68 * root.scale
                Layout.preferredHeight: 30 * root.scale
                accent: "#1A4DB5"
                enabled: waveformChart.windowStart > 0
                onClicked: waveformChart.moveWindow(-Math.max(
                                                          1,
                                                          Math.floor(waveformChart.visibleSamples * 0.8)))
            }

            WaveformControlButton {
                text: "Newer ›"
                Layout.preferredWidth: 68 * root.scale
                Layout.preferredHeight: 30 * root.scale
                accent: "#1A4DB5"
                enabled: waveformChart.windowStart + waveformChart.visibleSamples
                         < waveformChart.samples.length
                onClicked: waveformChart.moveWindow(Math.max(
                                                        1,
                                                        Math.floor(waveformChart.visibleSamples * 0.8)))
            }

            WaveformControlButton {
                text: "Zoom −"
                Layout.preferredWidth: 62 * root.scale
                Layout.preferredHeight: 30 * root.scale
                accent: "#1A4DB5"
                enabled: waveformChart.visibleSamples < waveformChart.maxVisibleSamples
                onClicked: waveformChart.zoomOut()
            }

            WaveformControlButton {
                text: "Zoom +"
                Layout.preferredWidth: 62 * root.scale
                Layout.preferredHeight: 30 * root.scale
                accent: "#1A4DB5"
                enabled: waveformChart.visibleSamples > waveformChart.minVisibleSamples
                onClicked: waveformChart.zoomIn()
            }

            WaveformControlButton {
                text: "Reset"
                Layout.preferredWidth: 52 * root.scale
                Layout.preferredHeight: 30 * root.scale
                accent: "#1A4DB5"
                onClicked: waveformChart.resetView()
            }

            WaveformControlButton {
                text: "X"
                Layout.preferredWidth: 42 * root.scale
                Layout.preferredHeight: 30 * root.scale
                accent: "#1A4DB5"
                selected: root.displayMode === "X"
                onClicked: root.displayMode = "X"
            }

            WaveformControlButton {
                text: "Y"
                Layout.preferredWidth: 42 * root.scale
                Layout.preferredHeight: 30 * root.scale
                accent: "#D64545"
                selected: root.displayMode === "Y"
                onClicked: root.displayMode = "Y"
            }

            WaveformControlButton {
                text: "Both"
                Layout.preferredWidth: 52 * root.scale
                Layout.preferredHeight: 30 * root.scale
                accent: "#334155"
                selected: root.displayMode === "Both"
                onClicked: root.displayMode = "Both"
            }

            WaveformControlButton {
                text: root.captureEnabled
                      ? "Stop capture" : "Start capture"
                Layout.preferredWidth: 112 * root.scale
                accent: root.captureEnabled
                        ? "#B42318" : "#16804A"
                onClicked: {
                    root.captureEnabled = !root.captureEnabled
                }
            }
        }

        WaveformChart {
            id: waveformChart
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 0
            scale: root.scale
            visibleSamples: root.maxHistorySamples
            title: "Waveform"
            displayMode: root.displayMode
            samples: root.samples
        }
    }
}
