import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import AppState 1.0
import Backend 1.0

import "../components"

Item {
    id: root
    anchors.fill: parent

    property real baseWidth: 1024
    property real baseHeight: 600
    property real scale: Math.min(width / baseWidth, height / baseHeight)

    Rectangle {
    Typography {
        id: screenTypography
        scale: root.scale || 1.0
    }
        anchors.fill: parent
        color: "#F5F7FC"

        Column {
            anchors.fill: parent
            anchors.margins: 30 * root.scale
            spacing: 24 * root.scale

            // ===== HEADER =====
            Column {
                spacing: 6

                Text {
                    text: "Developer Settings"
                    font.pixelSize: 28

                    color: "#1A4DB5"
                }

                Rectangle {
                    width: 70 * root.scale
                    height: 4 * root.scale
                    radius: 2 * root.scale
                    color: "#1A4DB5"
                }
            }

            // ===== CARDS =====
            Flow {
                id: flow
                width: parent.width
                spacing: 20 * root.scale


                property real cardWidth: (width - (spacing * 2)) / 3

                // ===== Card 1 =====
                Rectangle {
                    width: flow.cardWidth
                    height: 120 * root.scale
                    radius: 16
                    color: "#FFFFFF"
                    border.color: "#E5E7EB"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 16

                        ColumnLayout {
                            Layout.fillWidth: true

                            Text {
                                text: "D-Duster"
                                font.pixelSize: 20

                                color: "#111827"
                            }

                            Text {
                                text: GlobalState.showDDuster
                                      ? "D-duster Screen On"
                                      : "D-duster Screen Off"
                                font.pixelSize: 16
                                color: "#6B7280"
                            }
                        }

                        DDButton {
                            width: 90 * root.scale
                            height: 36 * root.scale

                            toggled: GlobalState.showDDuster

                            onToggledChanged: {
                                GlobalState.showDDuster = toggled

                                var machineType = toggled
                                    ? "Combo (MD+DD)"
                                    : "Only MD"

                                databaseManager.saveMachineInfo(
                                    GlobalState.supplierName,
                                    GlobalState.serialNumber,
                                    GlobalState.machineId,
                                    GlobalState.userName,
                                    GlobalState.location,
                                    machineType
                                )
                            }
                        }
                    }
                }
                // ===== Card 2 =====
                Rectangle {
                    width: flow.cardWidth
                    height: 120 * root.scale
                    radius: 16
                    color: "#FFFFFF"
                    border.color: "#E5E7EB"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 16

                        ColumnLayout {
                            Layout.fillWidth: true

                            Text {
                                text: "N/W Settings"
                                font.pixelSize: 20

                                color: "#111827"
                            }

                            Text {
                                text: GlobalState.showNetworkScreen
                                      ? "N/W Screen On"
                                      : "N/W Screen Off"
                                font.pixelSize: 16
                                color: "#6B7280"
                            }
                        }

                        DDButton {
                            width: 90 * root.scale
                            height: 36 * root.scale

                            toggled: GlobalState.showNetworkScreen

                            onToggledChanged: {
                                GlobalState.showNetworkScreen = toggled
                            }
                        }
                    }
                }
                // ===== Card 3 =====
                Rectangle {
                    width: flow.cardWidth
                    height: 120 * root.scale
                    radius: 16
                    color: "#FFFFFF"
                    border.color: "#E5E7EB"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 16

                        ColumnLayout {
                            Layout.fillWidth: true

                            Text {
                                text: "Audit Trail Report"
                                font.pixelSize: 20

                                color: "#111827"
                            }

                            Text {
                                text: GlobalState.showAuditTrail
                                      ? "Audit Trail On"
                                      : "Audit Trail Off"
                                font.pixelSize: 16
                                color: "#6B7280"
                            }
                        }

                        DDButton {
                            width: 90 * root.scale
                            height: 36 * root.scale

                            toggled: GlobalState.showAuditTrail

                            onToggledChanged: {
                                GlobalState.showAuditTrail = toggled
                            }
                        }
                    }
                }

                // ===== Card 4 =====
                Rectangle {
                    width: flow.cardWidth
                    height: 120 * root.scale
                    radius: 16
                    color: "#FFFFFF"
                    border.color: "#E5E7EB"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 16

                        ColumnLayout {
                            Layout.fillWidth: true

                            Text {
                                text: "Product Library"
                                font.pixelSize: 20

                                color: "#111827"
                            }

                            Text {
                                text: GlobalState.showProductLib
                                      ? "Product Library On"
                                      : "Product Library Off"
                                font.pixelSize: 16
                                color: "#6B7280"
                            }
                        }

                        DDButton {
                            width: 90 * root.scale
                            height: 36 * root.scale

                            toggled: GlobalState.showProductLib

                            onToggledChanged: {
                                GlobalState.showProductLib = toggled
                            }
                        }
                    }
                }

                // ===== Card 5 =====
                Rectangle {
                    width: flow.cardWidth
                    height: 120 * root.scale
                    radius: 16
                    color: "#FFFFFF"
                    border.color: "#E5E7EB"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 16

                        ColumnLayout {
                            Layout.fillWidth: true

                            Text {
                                text: "Tracking"
                                font.pixelSize: 20

                                color: "#111827"
                            }

                            Text {
                                text: GlobalState.showTrackingScreen
                                      ? "Tracking On"
                                      : "Tracking Off"
                                font.pixelSize: 16
                                color: "#6B7280"
                            }
                        }

                        DDButton {
                            width: 90 * root.scale
                            height: 36 * root.scale

                            toggled: GlobalState.showTrackingScreen

                            onToggledChanged: {
                                GlobalState.showTrackingScreen = toggled
                            }
                        }
                    }
                }

                // ===== Card 6 : Baud Rate =====
                Rectangle {
                    width: flow.cardWidth
                    height: 120 * root.scale
                    radius: 16
                    color: "#FFFFFF"
                    border.color: "#E5E7EB"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 16

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Text {
                                text: "Baud Rate"
                                font.pixelSize: 20
                                color: "#111827"
                            }

                            Text {
                                text: GlobalState.baudRate + " bps"
                                font.pixelSize: 16
                                color: "#6B7280"
                            }
                        }

                        ComboBox {
                            id: baudRateCombo

                            Layout.preferredWidth: 180 * root.scale
                            Layout.preferredHeight: 52 * root.scale

                            model: [
                                "115200",
                                "256000"
                            ]

                            currentIndex: GlobalState.baudRate === 256000 ? 1 : 0

                            font.pixelSize: 18 * root.scale

                            // Main button
                            background: Rectangle {
                                radius: 8 * root.scale
                                color: baudRateCombo.pressed ? "#E5E7EB" : "#FFFFFF"
                                border.width: 1.5 * root.scale
                                border.color: "#D0D8EC"
                            }

                            contentItem: Text {
                                leftPadding: 16 * root.scale
                                rightPadding: 42 * root.scale

                                text: baudRateCombo.displayText
                                font.pixelSize: 18 * root.scale
                                color: "#1A1A1A"
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                            }

                            // Large, easy-to-touch arrow area
                            indicator: Canvas {
                                x: baudRateCombo.width - width - 12 * root.scale
                                y: (baudRateCombo.height - height) / 2

                                width: 24 * root.scale
                                height: 24 * root.scale

                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.clearRect(0, 0, width, height)

                                    ctx.beginPath()
                                    ctx.moveTo(5 * root.scale, 8 * root.scale)
                                    ctx.lineTo(12 * root.scale, 16 * root.scale)
                                    ctx.lineTo(19 * root.scale, 8 * root.scale)

                                    ctx.lineWidth = 2.5 * root.scale
                                    ctx.strokeStyle = "#1A4DB5"
                                    ctx.lineCap = "round"
                                    ctx.lineJoin = "round"
                                    ctx.stroke()
                                }
                            }

                            // Touch-friendly popup
                            popup: Popup {
                                y: baudRateCombo.height + 6 * root.scale

                                width: baudRateCombo.width
                                padding: 6 * root.scale

                                background: Rectangle {
                                    radius: 8 * root.scale
                                    color: "#FFFFFF"
                                    border.width: 1.5 * root.scale
                                    border.color: "#D0D8EC"
                                }

                                contentItem: ListView {
                                    implicitHeight: contentHeight
                                    clip: true

                                    model: baudRateCombo.popup.visible
                                           ? baudRateCombo.delegateModel
                                           : null

                                    delegate: ItemDelegate {
                                        width: baudRateCombo.width - 12 * root.scale
                                        height: 52 * root.scale

                                        highlighted: ListView.isCurrentItem

                                        contentItem: Text {
                                            text: modelData
                                            font.pixelSize: 18 * root.scale
                                            color: "#1A1A1A"
                                            verticalAlignment: Text.AlignVCenter
                                            leftPadding: 14 * root.scale
                                        }

                                        background: Rectangle {
                                            radius: 6 * root.scale
                                            color: highlighted ? "#E5E7EB" : "#FFFFFF"
                                        }

                                        onClicked: {
                                            baudRateCombo.currentIndex = index
                                            baudRateCombo.popup.close()

                                            var selectedBaudRate = parseInt(modelData)

                                            if (selectedBaudRate === 115200 ||
                                                selectedBaudRate === 256000) {

                                                GlobalState.baudRate = selectedBaudRate
                                                SerialManager.setBaudRate(selectedBaudRate)
                                            }
                                        }
                                    }
                                }
                            }

                            // Keep keyboard/mouse activation working too
                            onActivated: {
                                var selectedBaudRate = parseInt(currentText)

                                if (selectedBaudRate === 115200 ||
                                    selectedBaudRate === 256000) {

                                    GlobalState.baudRate = selectedBaudRate
                                    SerialManager.setBaudRate(selectedBaudRate)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
