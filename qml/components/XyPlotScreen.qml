import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import CustomComponents 1.0

Item {
    id: root

    anchors.fill: parent

    property var globalTopBar
    property var notify

    property real baseWidth:  1024
    property real baseHeight: 600

    property real scale: Math.min(
                             width  / baseWidth,
                             height / baseHeight
                         )

    property real bodyFont:  13 * scale
    property real smallFont: 11 * scale

    property var magneticFieldData: [
        { x: -90, y: -55 },
        { x: -70, y: -32 },
        { x: -50, y:  -8 },
        { x: -30, y:  18 },
        { x: -10, y:  36 },
        { x:  10, y:  44 },
        { x:  30, y:  28 },
        { x:  50, y:   6 },
        { x:  70, y: -18 },
        { x:  90, y: -42 }
    ]

    Rectangle {
        anchors.fill: parent
        color: "#F5F7FC"
    }

    ColumnLayout {
        anchors.fill:         parent
        anchors.leftMargin:   10 * root.scale
        anchors.rightMargin:  10 * root.scale
        anchors.topMargin:    10 * root.scale
        anchors.bottomMargin: 10 * root.scale
        spacing: 8 * root.scale

        // ── SCREEN TITLE ──────────────────────────────────────────────────────
        Column {
            spacing: 10 * root.scale

            Text {
                text: "X,Y Plot"
                font.pixelSize: 26 * root.scale
                font.bold: true
                color: "#1A4DB5"
            }

            Rectangle {
                width:  60 * root.scale
                height:  3 * root.scale
                radius:  2 * root.scale
                color:  "#1A4DB5"
            }
        }

        // ── MAIN ROW ──────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth:  true
            Layout.fillHeight: true
            spacing: 10 * root.scale

            // ── LEFT PANEL ────────────────────────────────────────────────────
            Rectangle {
                Layout.preferredWidth: 180 * root.scale
                Layout.fillHeight:     true

                radius:       16 * root.scale
                color:        "#FFFFFF"
                border.width: 1
                border.color: "#DCE5F5"

                ColumnLayout {
                    anchors.fill:    parent
                    anchors.margins: 12 * root.scale
                    spacing: 10 * root.scale

                    // ── Product Phase card ─────────────────────────────────────
                    Rectangle {
                        Layout.fillWidth:  true
                        Layout.fillHeight: true

                        radius:       12 * root.scale
                        color:        "#F7F9FD"
                        border.width: 1
                        border.color: "#DCE5F5"

                        ColumnLayout {
                            anchors.fill:    parent
                            anchors.margins: 14 * root.scale
                            spacing: 8 * root.scale

                            Text {
                                text: "Product\nPhase"
                                font.pixelSize: 22 * root.scale
                                font.bold: true
                                color: "#1A4DB5"
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: "—"
                                font.pixelSize: 20 * root.scale
                                font.bold: true
                                color: "#1A4DB5"
                            }
                        }
                    }

                    // ── Signal card ────────────────────────────────────────────
                    Rectangle {
                        Layout.fillWidth:  true
                        Layout.fillHeight: true

                        radius:       12 * root.scale
                        color:        "#F7F9FD"
                        border.width: 1
                        border.color: "#DCE5F5"

                        ColumnLayout {
                            anchors.fill:    parent
                            anchors.margins: 14 * root.scale
                            spacing: 8 * root.scale

                            Text {
                                text: "Signal"
                                font.pixelSize: 22 * root.scale
                                font.bold: true
                                color: "#1A4DB5"
                            }

                            Text {
                                text: "400"
                                font.pixelSize: 20 * root.scale
                                font.bold: true
                                color: "#0F8A60"
                            }
                        }
                    }

                    // ── Amplitude card ─────────────────────────────────────────
                    Rectangle {
                        Layout.fillWidth:  true
                        Layout.fillHeight: true

                        radius:       12 * root.scale
                        color:        "#F7F9FD"
                        border.width: 1
                        border.color: "#DCE5F5"

                        ColumnLayout {
                            anchors.fill:    parent
                            anchors.margins: 14 * root.scale
                            spacing: 8 * root.scale

                            Text {
                                text: "Amplitude"
                                font.pixelSize: 22 * root.scale
                                font.bold: true
                                color: "#1A4DB5"
                            }

                            Text {
                                text: "—"
                                font.pixelSize: 20 * root.scale
                                font.bold: true
                                color: "#D64545"
                            }
                        }
                    }
                }
            }

            // ── GRAPH CARD ────────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth:  true
                Layout.fillHeight: true

                radius:       16 * root.scale
                color:        "#FFFFFF"
                border.width: 1
                border.color: "#DCE5F5"

                MagneticFieldPlotItem {
                    id: plot
                    anchors.fill:         parent
                    anchors.leftMargin:   8 * root.scale
                    anchors.rightMargin:  8 * root.scale
                    anchors.topMargin:    8 * root.scale
                    anchors.bottomMargin: 8 * root.scale

                    fieldData:       root.magneticFieldData
                    showPointLabels: false
                }
            }
        }
    }
}
