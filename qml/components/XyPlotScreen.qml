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

        anchors.leftMargin: 28 * root.scale
        anchors.rightMargin: 28 * root.scale
        anchors.topMargin: 22 * root.scale
        anchors.bottomMargin: 22 * root.scale

        spacing: 20 * root.scale

        // =====================================================
        // HEADING
        // =====================================================

        Column {
            spacing: 6 * root.scale

            Text {
                text: "XY Plot"

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

            spacing: 24 * root.scale

            // =================================================
            // GRAPH AREA
            // =================================================

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Layout.preferredWidth: 860 * root.scale

                radius: 26 * root.scale

                color: "#FFFFFF"

                border.width: 2
                border.color: "#DCE6F5"

                layer.enabled: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 22 * root.scale

                    spacing: 14 * root.scale

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
                            anchors.margins: 24 * root.scale

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
                Layout.preferredWidth: 300 * root.scale
                Layout.fillHeight: true

                radius: 26 * root.scale

                color: "#FFFFFF"

                border.width: 2
                border.color: "#DCE6F5"

                layer.enabled: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 22 * root.scale

                    spacing: 18 * root.scale

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: "Field Values"

                            font.pixelSize: 22 * root.scale
                            font.bold: true

                            color: "#1B365D"
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            width: 14 * root.scale
                            height: 14 * root.scale

                            radius: width / 2

                            color: "#3B6FD8"
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1

                        color: "#DCE6F5"
                    }

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
                                    height: 78 * root.scale

                                    radius: 18 * root.scale

                                    color: "#F8FAFE"

                                    border.width: 1
                                    border.color: "#DCE6F5"

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 16 * root.scale

                                        spacing: 14 * root.scale

                                        Rectangle {
                                            width: 16 * root.scale
                                            height: 16 * root.scale

                                            radius: width / 2

                                            color: "#3B6FD8"
                                        }

                                        ColumnLayout {
                                            spacing: 4 * root.scale

                                            Text {
                                                text: "Point "
                                                      + (index + 1)

                                                font.pixelSize: 16 * root.scale
                                                font.bold: true

                                                color: "#1B365D"
                                            }

                                            Text {
                                                text: "X : "
                                                      + modelData.x

                                                font.pixelSize: 15 * root.scale

                                                color: "#6B7A90"
                                            }

                                            Text {
                                                text: "Y : "
                                                      + modelData.y

                                                font.pixelSize: 15 * root.scale

                                                color: "#6B7A90"
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
