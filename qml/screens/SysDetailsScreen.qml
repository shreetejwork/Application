import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import AppState 1.0
import Backend 1.0

import "../components"

Item {
    id: root

    property bool showTopBar: true
    property var globalTopBar

    property real baseHeight: 700
    property real scale: Math.max(0.9, Math.min(1.8, height / baseHeight))

    Connections {
        target: GlobalState

        function onCoilBalancingOnChanged() {

            SerialManager.setCoilBalancingStatus(
                        GlobalState.coilBalancingOn
                        )

            console.log("Global Coil Balancing Changed:",
                        GlobalState.coilBalancingOn ? "ON" : "OFF")
        }
    }

    Component.onCompleted: {

        var data = databaseManager.getMachineInfo()

        GlobalState.supplierName =
                data.supplierName || ""

        GlobalState.serialNumber =
                data.serialNumber || ""

        GlobalState.userName =
                data.userName || ""

        GlobalState.machineId =
                data.machineId || "PHMX"

        GlobalState.location =
                data.location || ""
    }

    property var sysDetails: [

        {
            label: "Supplier Name",
            value: GlobalState.supplierName.length ?
                       GlobalState.supplierName : "..."
        },

        {
            label: "Serial Number",
            value: GlobalState.serialNumber.length ?
                       GlobalState.serialNumber : "..."
        },

        {
            label: "User",
            value: GlobalState.userName.length ?
                       GlobalState.userName : "..."
        },

        {
            label: "Machine ID",
            value: GlobalState.machineId.length ?
                       GlobalState.machineId : "PHMX"
        },

        {
            label: "Location",
            value: GlobalState.location.length ?
                       GlobalState.location : "..."
        },

        {
            label: "Version",
            value: "v4.0.1"
        }
    ]

    Rectangle {

        Typography {
            id: screenTypography
            scale: root.scale
        }

        anchors.fill: parent
        color: "#F5F7FC"

        Item {
            anchors {
                fill: parent
                leftMargin: 30 * root.scale
                rightMargin: 30 * root.scale
                topMargin: 10 * root.scale
                bottomMargin: 12 * root.scale
            }

            Column {
                id: centerColumn

                anchors.centerIn: parent

                width: Math.min(720 * root.scale, parent.width * 0.82)

                spacing: 12 * root.scale

                // ================= HEADING =================

                Column {

                    spacing: 4 * root.scale

                    Text {
                        text: "About Machine"
                        font.pixelSize: 24 * root.scale
                        color: "#1A4DB5"
                    }

                    Rectangle {
                        width: 72 * root.scale
                        height: 4 * root.scale
                        radius: 2
                        color: "#1A4DB5"
                    }
                }

                // ================= COIL OUTPUT =================

                Rectangle {
                    width: parent.width * 0.92
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: 155 * root.scale

                    radius: 22 * root.scale
                    color: "#FFFFFF"

                    border.width: 2
                    border.color: "#6F95D6"


                    Column {
                        anchors.fill: parent
                        anchors.margins: 14 * root.scale
                        spacing: 10 * root.scale

                        Item {
                            width: parent.width
                            height: 40 * root.scale

                            Button {
                                id: coilBalanceButton

                                anchors.centerIn: parent

                                width: 150 * root.scale
                                height: 40 * root.scale

                                text: GlobalState.coilBalancingOn
                                      ? "Coil Balancing ON"
                                      : "Coil Balancing OFF"

                                onClicked: {
                                    GlobalState.coilBalancingOn = !GlobalState.coilBalancingOn
                                }

                                contentItem: Text {
                                    text: coilBalanceButton.text
                                    font.pixelSize: 16 * root.scale
                                    font.bold: true

                                    color: GlobalState.coilBalancingOn
                                           ? "#1A4DB5"
                                           : "#FFFFFF"

                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                background: Rectangle {
                                    radius: 10 * root.scale

                                    color: GlobalState.coilBalancingOn
                                           ? "#FFFFFF"
                                           : (coilBalanceButton.pressed ? "#153F94" : "#1A4DB5")

                                    border.width: 1
                                    border.color: "#1A4DB5"

                                    Behavior on color {
                                        ColorAnimation { duration: 150 }
                                    }

                                    Behavior on border.color {
                                        ColorAnimation { duration: 150 }
                                    }
                                }
                            }
                        }

                        CoilProgressBar {
                            width: parent.width
                            height: 78 * root.scale

                            scale: root.scale
                            value: SerialManager.coilOutput
                            maxValue: 10000
                            label: "Coil Output"
                        }
                    }
                }

                // ================= CARD =================

                Rectangle {

                    width: parent.width * 0.92
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: gridContent.implicitHeight + (90 * root.scale)

                    radius: 22 * root.scale
                    color: "#FFFFFF"

                    border.width: 2
                    border.color: "#6F95D6"

                    Column {

                        id: gridContent

                        anchors.centerIn: parent
                        width: parent.width * 0.90

                        spacing: 12 * root.scale

                        GridLayout {

                            width: parent.width

                            columns: 2

                            rowSpacing: 10 * root.scale
                            columnSpacing: 14 * root.scale

                            Repeater {

                                model: root.sysDetails

                                delegate: Rectangle {

                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 62 * root.scale

                                    radius: 12 * root.scale
                                    color: "#F7F9FF"

                                    border.width: 1
                                    border.color: "#D7E2F5"

                                    Column {

                                        anchors.fill: parent
                                        anchors.margins: 10 * root.scale

                                        spacing: 2 * root.scale

                                        Text {
                                            text: modelData.label
                                            font.pixelSize: 18 * root.scale
                                            color: "#5B6B8C"
                                        }

                                        Text {
                                            text: modelData.value
                                            font.pixelSize: 20 * root.scale
                                            color: "#1A4DB5"

                                            width: parent.width
                                            elide: Text.ElideRight
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
