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
    property var selectedChannels: ["x", "y", "z1", "z2"]
    property string packetGapMessage: ""
    readonly property int maxHistorySamples: 10000
    readonly property real sampleIntervalMilliseconds: 1

    Component.onDestruction: Backend.SerialManager.setWaveformMode(false)

    function isChannelSelected(channel) {
        return selectedChannels.indexOf(channel.toLowerCase()) >= 0
    }

    function toggleChannel(channel) {
        var updatedChannels = selectedChannels.slice()
        var index = updatedChannels.indexOf(channel.toLowerCase())
        if (index >= 0 && updatedChannels.length > 1)
            updatedChannels.splice(index, 1)
        else if (index < 0)
            updatedChannels.push(channel.toLowerCase())
        selectedChannels = updatedChannels
    }

    function showPacket(points) {
        if (!points || points.length === 0)
            return

        var updatedSamples = samples.concat(points)
        if (updatedSamples.length > maxHistorySamples)
            updatedSamples.splice(0, updatedSamples.length - maxHistorySamples)
        samples = updatedSamples
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

        function onPacketGapDetected(firstMissingPacket, missingPacketCount) {
            if (missingPacketCount === 1) {
                root.packetGapMessage =
                        "Packet " + firstMissingPacket + " is missing"
            } else {
                var lastMissingPacket =
                        (firstMissingPacket + missingPacketCount - 1) % 65536
                root.packetGapMessage =
                        "Packets " + firstMissingPacket + "-" + lastMissingPacket
                        + " are missing"
            }
            packetGapTimer.restart()
        }

    }

    Timer {
        id: packetGapTimer
        interval: 6000
        onTriggered: root.packetGapMessage = ""
    }

    Rectangle {
        anchors.fill: parent
        color: "#F5F7FC"
    }

    Rectangle {
        anchors.top: parent.top
        anchors.topMargin: 96 * root.scale
        anchors.right: parent.right
        anchors.rightMargin: 18 * root.scale
        width: gapMessage.implicitWidth + 58 * root.scale
        height: 42 * root.scale
        radius: 8 * root.scale
        color: "#FFF7E6"
        border.color: "#E6A23C"
        visible: root.packetGapMessage !== ""
        z: 2

        Row {
            anchors.centerIn: parent
            spacing: 9 * root.scale

            Rectangle {
                width: 20 * root.scale
                height: 20 * root.scale
                radius: 10 * root.scale
                anchors.verticalCenter: parent.verticalCenter
                color: "#E6A23C"

                Text {
                    anchors.centerIn: parent
                    text: "!"
                    color: "#FFFFFF"
                    font.pixelSize: 14 * root.scale
                    font.bold: true
                }
            }

            Text {
                id: gapMessage
                text: root.packetGapMessage
                color: "#7A4B08"
                font.pixelSize: 15 * root.scale
                font.weight: Font.DemiBold
                anchors.verticalCenter: parent.verticalCenter
            }
        }
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

            WaveformControlButton {
                text: "Clear Buffer"
                Layout.preferredWidth: 100 * root.scale
                Layout.preferredHeight: 38 * root.scale
                labelPixelSize: Math.max(15, 17 * root.scale)
                accent: "#B42318"
                enabled: root.samples.length > 0
                onClicked: root.clearBuffer()
            }

            WaveformControlButton {
                text: root.captureEnabled ? "Stop capture" : "Start capture"
                Layout.preferredWidth: 126 * root.scale
                Layout.preferredHeight: 38 * root.scale
                labelPixelSize: Math.max(15, 17 * root.scale)
                accent: root.captureEnabled ? "#B42318" : "#16804A"
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

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 42 * root.scale
            spacing: 6 * root.scale

            Item { Layout.fillWidth: true }

            WaveformControlButton {
                text: "←"
                Layout.preferredWidth: 44 * root.scale
                Layout.preferredHeight: 40 * root.scale
                labelPixelSize: Math.max(20, 22 * root.scale)
                accent: "#1A4DB5"
                enabled: waveformChart.windowStart > 0
                onClicked: waveformChart.moveWindow(-Math.max(
                                                          1,
                                                          Math.floor(waveformChart.visibleSamples * 0.1)))
            }

            WaveformControlButton {
                text: "→"
                Layout.preferredWidth: 44 * root.scale
                Layout.preferredHeight: 40 * root.scale
                labelPixelSize: Math.max(20, 22 * root.scale)
                accent: "#1A4DB5"
                enabled: waveformChart.windowStart + waveformChart.visibleSamples
                         < waveformChart.samples.length
                onClicked: waveformChart.moveWindow(Math.max(
                                                        1,
                                                        Math.floor(waveformChart.visibleSamples * 0.1)))
            }

            WaveformControlButton {
                text: "Zoom −"
                Layout.preferredWidth: 78 * root.scale
                Layout.preferredHeight: 40 * root.scale
                labelPixelSize: Math.max(15, 17 * root.scale)
                accent: "#1A4DB5"
                enabled: waveformChart.visibleSamples < waveformChart.maxVisibleSamples
                onClicked: waveformChart.zoomOut()
            }

            WaveformControlButton {
                text: "Zoom +"
                Layout.preferredWidth: 78 * root.scale
                Layout.preferredHeight: 40 * root.scale
                labelPixelSize: Math.max(15, 17 * root.scale)
                accent: "#1A4DB5"
                enabled: waveformChart.visibleSamples > waveformChart.minVisibleSamples
                onClicked: waveformChart.zoomIn()
            }

            WaveformControlButton {
                text: "Reset"
                Layout.preferredWidth: 68 * root.scale
                Layout.preferredHeight: 40 * root.scale
                labelPixelSize: Math.max(15, 17 * root.scale)
                accent: "#1A4DB5"
                onClicked: waveformChart.resetView()
            }

            Repeater {
                model: [
                    { label: "A", key: "x", color: "#1A4DB5" },
                    { label: "B", key: "y", color: "#D64545" },
                    { label: "C", key: "z1", color: "#16804A" },
                    { label: "D", key: "z2", color: "#8B5CF6" },
                    { label: "All", key: "", color: "#334155" }
                ]

                delegate: WaveformControlButton {
                    required property var modelData
                    text: modelData.label
                    Layout.preferredWidth: text === "All" ? 58 * root.scale
                                                               : 52 * root.scale
                    Layout.preferredHeight: 40 * root.scale
                    labelPixelSize: Math.max(15, 17 * root.scale)
                    accent: modelData.color
                    selectedFill: Qt.rgba(accent.r, accent.g, accent.b, 0.12)
                    selectedLabelColor: modelData.color
                    selected: text === "All"
                              ? root.selectedChannels.length === 4
                              : root.isChannelSelected(modelData.key)
                    onClicked: {
                        if (text === "All")
                            root.selectedChannels = ["x", "y", "z1", "z2"]
                        else
                            root.toggleChannel(modelData.key)
                    }
                }
            }

            Item { Layout.fillWidth: true }

            WaveformControlButton {
                text: "Cursor"
                visible: !root.captureEnabled
                Layout.preferredWidth: 68 * root.scale
                Layout.preferredHeight: 40 * root.scale
                labelPixelSize: Math.max(15, 17 * root.scale)
                accent: "#16804A"
                selected: waveformChart.cursorEnabled
                enabled: root.samples.length > 0
                onClicked: {
                    waveformChart.cursorEnabled = !waveformChart.cursorEnabled
                    if (!waveformChart.cursorEnabled)
                        waveformChart.clearCursorSelection()
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
            maxVisibleSamples: root.maxHistorySamples
            sampleIntervalMilliseconds: root.sampleIntervalMilliseconds
            title: "Waveform"
            selectedChannels: root.selectedChannels
            samples: root.samples
        }
    }
}
