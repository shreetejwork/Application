import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import AppState 1.0

import "../components"

Item {
    id: root

    property bool showTopBar: true
    property var globalTopBar



    property real baseHeight: 700
    property real scale: Math.max(0.9, Math.min(1.8, height / baseHeight))


    // =================================================
    // HISTOGRAM CARD
    // =================================================

    Rectangle {
        id: histogramCard

        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(parent.width, 900 * root.scale)
        height: 300 * root.scale

        radius: 22 * root.scale
        color: "#FFFFFF"

        border.width: 2
        border.color: "#6F95D6"

        property real zoomFactor: 1.0

        Column {
            anchors.fill: parent
            anchors.leftMargin: 18 * root.scale
            anchors.rightMargin: 18 * root.scale
            anchors.topMargin: 18 * root.scale
            spacing: 14 * root.scale

            // ===== TITLE =====
            Text {
                text: "Coil Output Histogram"
                anchors.horizontalCenter: parent.horizontalCenter

                font.pixelSize: 22 * root.scale
                font.bold: true
                color: "#1A4DB5"
            }

            // =================================================
            // GRAPH AREA
            // =================================================

            Flickable {
                id: flickArea

                width: parent.width
                height: 230 * root.scale

                clip: true

                // 🔥 FIX 1: REMOVE implicitWidth dependency loop
                contentWidth: Math.max(flickArea.width, 900 * root.scale)
                contentHeight: graphContent.height

                boundsBehavior: Flickable.StopAtBounds
                interactive: true

                // ================= ZOOM =================

                WheelHandler {
                    acceptedDevices: PointerDevice.Mouse
                    enabled: zoomMouse.containsMouse

                    onWheel: function(event) {
                        histogramCard.zoomFactor =
                            Math.max(0.7, Math.min(3.0,
                                histogramCard.zoomFactor * (event.angleDelta.y > 0 ? 1.1 : 0.9)
                            ))
                    }
                }

                MouseArea {
                    id: zoomMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                }

                // =================================================
                // GRAPH CONTENT
                // =================================================

                Item {
                    id: graphContent

                    // 🔥 FIX 2: NO implicitWidth recursion
                    width: Math.max(
                               flickArea.width,
                               histogramRow.count * (46 * root.scale) + (80 * root.scale)
                           )

                    height: flickArea.height

                    // ================= Y AXIS =================

                    Column {
                        id: yAxis

                        width: 40 * root.scale
                        height: parent.height - (35 * root.scale)

                        Repeater {
                            model: 6

                            delegate: Item {
                                width: parent.width
                                height: yAxis.height / 6

                                Text {
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter

                                    text: 100 - (index * 20)
                                    font.pixelSize: 12 * root.scale
                                    color: "#5B6B8C"
                                }
                            }
                        }
                    }

                    // ================= GRAPH =================

                    Column {
                        anchors.left: yAxis.right
                        anchors.leftMargin: 10 * root.scale

                        // 🔥 FIX 3: REMOVE parent.width dependency loop
                        width: Math.max(flickArea.width, histogramRow.count * 46 * root.scale)
                        height: parent.height

                        spacing: 4 * root.scale

                        Item {
                            width: parent.width
                            height: parent.height - (30 * root.scale)

                            // GRID
                            Column {
                                anchors.fill: parent

                                Repeater {
                                    model: 5

                                    delegate: Rectangle {
                                        width: parent.width
                                        height: 1
                                        color: "#E1E8F5"
                                        y: (index + 1) * (parent.height / 5)
                                    }
                                }
                            }

                            // AXES
                            Rectangle {
                                width: 2
                                color: "#4A5E8A"
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                            }

                            Rectangle {
                                height: 2
                                color: "#4A5E8A"
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                            }

                            // ================= BARS =================

                            Row {
                                id: histogramRow

                                anchors.left: yAxis.right
                                anchors.leftMargin: 10 * root.scale
                                anchors.bottom: parent.bottom

                                spacing: 12 * root.scale

                                // 🔥 FIX 4: LOCK WIDTH (NO implicitWidth loop)
                                width: histogramRow.count * (46 * root.scale)

                                property var values: [
                                    22, 48, 65, 40, 85,
                                    55, 72, 95, 62, 38,
                                    70, 45, 88, 91, 53
                                ]

                                Repeater {
                                    model: histogramRow.values.length

                                    delegate: Column {
                                        spacing: 6 * root.scale

                                        Item {
                                            // 🔥 FIX 5: rounded + stable zoom scaling
                                            width: Math.round(Math.max(
                                                              18 * root.scale,
                                                              34 * root.scale * histogramCard.zoomFactor
                                                          ))
                                            height: 150 * root.scale

                                            Rectangle {
                                                width: parent.width
                                                height: (histogramRow.values[index] / 100) * parent.height

                                                anchors.bottom: parent.bottom
                                                anchors.horizontalCenter: parent.horizontalCenter

                                                radius: 6 * root.scale

                                                gradient: Gradient {
                                                    GradientStop { position: 0.0; color: "#58A6FF" }
                                                    GradientStop { position: 1.0; color: "#1A4DB5" }
                                                }
                                            }
                                        }

                                        Text {
                                            text: index + 1
                                            width: parent.width
                                            horizontalAlignment: Text.AlignHCenter

                                            font.pixelSize: 12 * root.scale
                                            font.bold: true
                                            color: "#5B6B8C"
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
