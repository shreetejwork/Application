import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import CustomComponents 1.0

Item {
    id: root

    anchors.fill: parent

    // =========================================================
    // EXTERNAL PROPERTIES
    // =========================================================

    property var globalTopBar
    property var notify

    // =========================================================
    // RESPONSIVE SCALE
    // =========================================================

    property real baseWidth: 1024
    property real baseHeight: 600

    property real scale: Math.min(
                             width / baseWidth,
                             height / baseHeight
                         )

    // =========================================================
    // DUMMY MAGNETIC FIELD DATA
    // =========================================================

    property var magneticFieldData: [
        { x: -90, y: -55 },
        { x: -70, y: -32 },
        { x: -50, y: -8 },
        { x: -30, y: 18 },
        { x: -10, y: 36 },
        { x: 10, y: 44 },
        { x: 30, y: 28 },
        { x: 50, y: 6 },
        { x: 70, y: -18 },
        { x: 90, y: -42 }
    ]

    Rectangle {
        anchors.fill: parent
        color: "#F5F7FC"
    }

    // =========================================================
    // MAIN CONTENT
    // =========================================================

    ColumnLayout {
        anchors.fill: parent

        anchors.leftMargin: 8 * root.scale
        anchors.rightMargin: 8 * root.scale
        anchors.topMargin: 22 * root.scale
        anchors.bottomMargin: 22 * root.scale

        spacing: 10 * root.scale

        // =====================================================
        // HEADING
        // =====================================================

        Column {
            spacing: 6 * root.scale

            Text {
                text: "X,Y Plot"

                font.pixelSize: 26 * root.scale
                font.bold: true

                color: "#1A4DB5"
            }

            Rectangle {
                width: 80 * root.scale
                height: 4 * root.scale

                radius: 2 * root.scale

                color: "#1A4DB5"
            }
        }

        // =====================================================
        // CONTENT AREA
        // =====================================================

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true

            spacing: 16 * root.scale

            // =================================================
            // GRAPH AREA (LARGER)
            // =================================================

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // Graph gets most of the screen
                Layout.horizontalStretchFactor: 6

                radius: 26 * root.scale

                color: "#FFFFFF"

                border.width: 2
                border.color: "#DCE6F5"

                layer.enabled: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12 * root.scale

                    spacing: 10 * root.scale

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        radius: 22 * root.scale

                        color: "#FBFCFF"

                        border.width: 1
                        border.color: "#E3EAF5"

                        MagneticFieldPlotItem {
                            id: plot

                            anchors.fill: parent

                            // Reduced margins so graph uses more space
                            anchors.leftMargin: 5 * root.scale
                            anchors.rightMargin: 5 * root.scale
                            anchors.topMargin: 5 * root.scale
                            anchors.bottomMargin: 5 * root.scale

                            fieldData: root.magneticFieldData

                            showPointLabels: false
                        }
                    }
                }
            }

            // =================================================
            // FIELD VALUES PANEL
            // =================================================

            Rectangle {
                Layout.preferredWidth: 250 * root.scale
                Layout.maximumWidth: 280 * root.scale
                Layout.fillHeight: true

                // Smaller than graph
                Layout.horizontalStretchFactor: 1

                radius: 28 * root.scale

                color: "#FFFFFF"

                border.width: 2
                border.color: "#DCE6F5"

                layer.enabled: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14 * root.scale

                    spacing: 18 * root.scale

                    Flickable {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        clip: true

                        contentWidth: width
                        contentHeight: valuesColumn.height

                        Column {
                            id: valuesColumn

                            width: parent.width

                            spacing: 14 * root.scale

                            Repeater {
                                model: root.magneticFieldData

                                delegate: Rectangle {

                                    width: valuesColumn.width
                                    height: 92 * root.scale

                                    radius: 20 * root.scale

                                    color: "#F8FAFE"

                                    border.width: 1
                                    border.color: "#DCE6F5"

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 18 * root.scale

                                        spacing: 16 * root.scale

                                        Rectangle {
                                            width: 18 * root.scale
                                            height: 18 * root.scale

                                            radius: width / 2

                                            color: "#3B6FD8"
                                        }

                                        ColumnLayout {
                                            spacing: 6 * root.scale

                                            Text {
                                                text: "Point "
                                                      + (index + 1)

                                                font.pixelSize: root.bodyFont
                                                font.bold: true

                                                color: "#1B365D"
                                            }

                                            RowLayout {
                                                spacing: 16 * root.scale

                                                Text {
                                                    text: "X : "
                                                          + modelData.x

                                                    font.pixelSize: root.smallFont
                                                    font.bold: true

                                                    color: "#4E5F78"
                                                }

                                                Text {
                                                    text: "Y : "
                                                          + modelData.y

                                                    font.pixelSize: root.smallFont
                                                    font.bold: true

                                                    color: "#4E5F78"
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
    }
}
