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
    property string displayMode: "All"
    readonly property int maxHistorySamples: 10000

    Component.onDestruction: Backend.SerialManager.setWaveformMode(false)

    function showPacket(points) {
        if (!points || points.length === 0)
            return

        var packetSamples = []
        for (var i = 0; i < points.length; ++i) {
            packetSamples.push({
                                   x: Number(points[i].x),
                                   y: Number(points[i].y),
                                   z1: Number(points[i].z1),
                                   z2: Number(points[i].z2)
                               })
        }
        var history = samples.concat(packetSamples)
        if (history.length > maxHistorySamples)
            history = history.slice(history.length - maxHistorySamples)
        samples = history
    }

    function clearBuffer() {
        samples = []
        waveformChart.resetView()
        waveformChart.clearCursorSelection()
    }

    Component.onCompleted: {
        Backend.SerialManager.setWaveformMode(true)
        root.showPacket(Backend.WaveformManager.waveformData)
    }

    Connections {
        target: Backend.WaveformManager

        function onWaveformDataChanged() {
            if (root.captureEnabled)
                root.showPacket(Backend.WaveformManager.waveformData)
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
            Layout.preferredHeight: 40 * root.scale

            Text {
                text: "Waveform"
                color: "#1A4DB5"
                font.pixelSize: Math.max(24, 30 * root.scale)
            }

            Item { Layout.fillWidth: true }

            Text {
                text: root.captureEnabled
                      ? (root.samples.length > 0
                         ? "Capturing · " + root.samples.length + " samples"
                         : "Waiting for serial data...")
                      : "Capture paused"
                color: "#64748B"
                font.pixelSize: Math.max(12, 14 * root.scale)
            }

            WaveformControlButton {
                text: "Clear Buffer"
                Layout.preferredWidth: 100 * root.scale
                Layout.preferredHeight: 38 * root.scale
                labelPixelSize: Math.max(12, 14 * root.scale)
                accent: "#B42318"
                enabled: root.samples.length > 0
                onClicked: root.clearBuffer()
            }

            WaveformControlButton {
                text: "←"
                Layout.preferredWidth: 42 * root.scale
                Layout.preferredHeight: 38 * root.scale
                labelPixelSize: Math.max(18, 20 * root.scale)
                accent: "#1A4DB5"
                enabled: waveformChart.windowStart > 0
                onClicked: waveformChart.moveWindow(-Math.max(
                                                          1,
                                                          Math.floor(waveformChart.visibleSamples * 0.1)))
            }

            WaveformControlButton {
                text: "→"
                Layout.preferredWidth: 42 * root.scale
                Layout.preferredHeight: 38 * root.scale
                labelPixelSize: Math.max(18, 20 * root.scale)
                accent: "#1A4DB5"
                enabled: waveformChart.windowStart + waveformChart.visibleSamples
                         < waveformChart.samples.length
                onClicked: waveformChart.moveWindow(Math.max(
                                                        1,
                                                        Math.floor(waveformChart.visibleSamples * 0.1)))
            }

            WaveformControlButton {
                text: "Zoom −"
                Layout.preferredWidth: 68 * root.scale
                Layout.preferredHeight: 38 * root.scale
                labelPixelSize: Math.max(12, 14 * root.scale)
                accent: "#1A4DB5"
                enabled: waveformChart.visibleSamples < waveformChart.maxVisibleSamples
                onClicked: waveformChart.zoomOut()
            }

            WaveformControlButton {
                text: "Zoom +"
                Layout.preferredWidth: 68 * root.scale
                Layout.preferredHeight: 38 * root.scale
                labelPixelSize: Math.max(12, 14 * root.scale)
                accent: "#1A4DB5"
                enabled: waveformChart.visibleSamples > waveformChart.minVisibleSamples
                onClicked: waveformChart.zoomIn()
            }

            WaveformControlButton {
                text: "Reset"
                Layout.preferredWidth: 60 * root.scale
                Layout.preferredHeight: 38 * root.scale
                labelPixelSize: Math.max(12, 14 * root.scale)
                accent: "#1A4DB5"
                onClicked: waveformChart.resetView()
            }

        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 38 * root.scale
            spacing: 6 * root.scale

            Repeater {
                model: [
                    { label: "X", color: "#1A4DB5" },
                    { label: "Y", color: "#D64545" },
                    { label: "Z1", color: "#16804A" },
                    { label: "Z2", color: "#8B5CF6" },
                    { label: "All", color: "#334155" }
                ]

                delegate: WaveformControlButton {
                    required property var modelData
                    text: modelData.label
                    Layout.preferredWidth: text === "All" ? 54 * root.scale
                                                               : 48 * root.scale
                    Layout.preferredHeight: 34 * root.scale
                    labelPixelSize: Math.max(12, 14 * root.scale)
                    accent: modelData.color
                    selected: root.displayMode === modelData.label
                    onClicked: root.displayMode = modelData.label
                }
            }

            Item { Layout.fillWidth: true }

            WaveformControlButton {
                text: "Cursor"
                visible: !root.captureEnabled
                Layout.preferredWidth: 68 * root.scale
                Layout.preferredHeight: 34 * root.scale
                labelPixelSize: Math.max(12, 14 * root.scale)
                accent: "#16804A"
                selected: waveformChart.cursorEnabled
                enabled: root.samples.length > 0
                onClicked: {
                    waveformChart.cursorEnabled = !waveformChart.cursorEnabled
                    if (!waveformChart.cursorEnabled)
                        waveformChart.clearCursorSelection()
                }
            }

            WaveformControlButton {
                text: root.captureEnabled
                      ? "Stop capture" : "Start capture"
                Layout.preferredWidth: 112 * root.scale
                Layout.preferredHeight: 34 * root.scale
                labelPixelSize: Math.max(12, 14 * root.scale)
                accent: root.captureEnabled
                        ? "#B42318" : "#16804A"
                onClicked: {
                    if (root.captureEnabled) {
                        root.captureEnabled = false
                    } else {
                        waveformChart.cursorEnabled = false
                        waveformChart.clearCursorSelection()
                        root.captureEnabled = true
                    }
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
