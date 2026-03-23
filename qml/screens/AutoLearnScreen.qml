import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import AppState 1.0

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
            }
        }

        // Popup used by AnalogGauge's `machinePhaseClicked` interaction
        CustomPopup {
            id: popup
            anchors.fill: parent
            globalTopBar: root.globalTopBar
        }
    }
}
