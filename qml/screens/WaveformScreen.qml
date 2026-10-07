import QtQuick
import QtQuick.Layouts
import Backend 1.0 as Backend
import "../components"

Item {
    id: root

    anchors.fill: parent
    property real scale: Math.min(width / 1024, height / 600)
    property var samples: []

    readonly property int maxSamples: 2000

    function appendPacket(points) {
        if (!points || points.length === 0)
            return

        var updatedSamples = samples.slice()
        for (var i = 0; i < points.length; ++i) {
            updatedSamples.push({
                                    x: Number(points[i].rawX),
                                    y: Number(points[i].rawY)
                                })
        }
        if (updatedSamples.length > maxSamples)
            updatedSamples.splice(0, updatedSamples.length - maxSamples)
        samples = updatedSamples
    }

    Component.onCompleted: root.appendPacket(Backend.SerialManager.waveformData)

    Connections {
        target: Backend.SerialManager

        function onWaveformDataChanged() {
            root.appendPacket(Backend.SerialManager.waveformData)
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
                text: root.samples.length > 0
                      ? root.samples.length + " samples"
                      : "Waiting for serial data..."
                color: "#64748B"
                font.pixelSize: 12 * root.scale
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
