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
        samples = packetSamples
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
            Layout.preferredHeight: 30 * root.scale

            Text {
                text: "Waveform"
                color: "#1A4DB5"
                font.pixelSize: 20 * root.scale
                font.weight: Font.DemiBold
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
                text: root.captureEnabled
                      ? "Stop capture" : "Start capture"
                Layout.preferredWidth: 112 * root.scale
                accent: root.captureEnabled
                        ? "#B42318" : "#16804A"
                onClicked: {
                    root.captureEnabled = !root.captureEnabled
                    if (root.captureEnabled)
                        root.showPacket(Backend.SerialManager.xyPlotData)
                }
            }
        }

        WaveformChart {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 0
            scale: root.scale
            title: "X"
            valueKey: "x"
            traceColor: "#1A4DB5"
            samples: root.samples
        }

        WaveformChart {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 0
            scale: root.scale
            title: "Y"
            valueKey: "y"
            traceColor: "#D64545"
            samples: root.samples
        }
    }
}
