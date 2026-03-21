import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import "../components"



Item {
    id: root

    property bool showTopBar: true
    property var globalTopBar

    Rectangle{
        anchors.fill: parent
        color: "#F5F7FC"

        // LEFT
        Item {
            id: leftCol
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width * 0.30

            AnalogGauge {
                id: analogGauge
                anchors.fill: parent
                trackingCountLabel: "Tracking Phase"
                trackingPhase: 50
                onMachinePhaseClicked: popup.open(
                                           "Machine Phase",
                                           analogGauge.machinePhase,
                                           function(val){ analogGauge.machinePhase = val },
                                           0, 180
                                           )
            }
        }
    }
}
