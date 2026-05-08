import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    anchors.fill: parent

    property real baseWidth: 1024
    property real baseHeight: 600
    property real scale: Math.min(width / baseWidth,
                                  height / baseHeight)

    property real colSpacing: 16 * scale

    property real colSr: 80 * scale
    property real colBatch: 420 * scale
    property real colDate: 220 * scale
    property real colBy: 220 * scale

    // =========================================================
    // DUMMY DATA
    // =========================================================

    ListModel {
        id: batchHistoryModel

        ListElement {
            batchName: "BATCH_001"
            generatedOn: "08/05/2026 10:15 AM"
            generatedBy: "Admin"
        }

        ListElement {
            batchName: "BATCH_002"
            generatedOn: "08/05/2026 11:42 AM"
            generatedBy: "Operator"
        }

        ListElement {
            batchName: "BATCH_003"
            generatedOn: "08/05/2026 12:18 PM"
            generatedBy: "Supervisor"
        }

        ListElement {
            batchName: "BATCH_004"
            generatedOn: "08/05/2026 01:05 PM"
            generatedBy: "Admin"
        }

        ListElement {
            batchName: "BATCH_005"
            generatedOn: "08/05/2026 02:27 PM"
            generatedBy: "Engineer"
        }

        ListElement {
            batchName: "BATCH_006"
            generatedOn: "08/05/2026 03:50 PM"
            generatedBy: "System"
        }

        ListElement {
            batchName: "BATCH_007"
            generatedOn: "08/05/2026 04:12 PM"
            generatedBy: "Operator"
        }

        ListElement {
            batchName: "BATCH_008"
            generatedOn: "08/05/2026 05:01 PM"
            generatedBy: "Admin"
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#F5F7FC"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24 * root.scale
            spacing: 16 * root.scale

            // =====================================================
            // HEADER
            // =====================================================

            Column {
                spacing: 6 * root.scale

                Text {
                    text: "Batch History"
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
            // TABLE
            // =====================================================

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true

                radius: 10 * root.scale
                color: "#FFFFFF"

                border.color: "#D0D8EC"
                border.width: 1

                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // =================================================
                    // TABLE HEADER
                    // =================================================

                    Rectangle {
                        Layout.fillWidth: true
                        height: 46 * root.scale

                        color: "#1A4DB5"
                        radius: 10 * root.scale

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom

                            height: 10 * root.scale
                            color: "#1A4DB5"
                        }

                        Row {
                            anchors.fill: parent
                            anchors.margins: 12 * root.scale
                            spacing: root.colSpacing

                            Text {
                                text: "Sr No."
                                width: root.colSr

                                font.pixelSize: 20 * root.scale
                                font.bold: true
                                color: "#FFFFFF"
                            }

                            Text {
                                text: "Batch Name / ID"
                                width: root.colBatch

                                font.pixelSize: 20 * root.scale
                                font.bold: true
                                color: "#FFFFFF"
                            }

                            Text {
                                text: "Generated On"
                                width: root.colDate

                                font.pixelSize: 20 * root.scale
                                font.bold: true
                                color: "#FFFFFF"
                            }

                            Text {
                                text: "Generated By"
                                width: root.colBy

                                font.pixelSize: 20 * root.scale
                                font.bold: true
                                color: "#FFFFFF"
                            }
                        }
                    }

                    // =================================================
                    // TABLE DATA
                    // =================================================

                    ListView {
                        id: tableList

                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        clip: true
                        spacing: 0

                        model: batchHistoryModel

                        delegate: Rectangle {

                            width: ListView.view.width
                            height: 44 * root.scale

                            color: index % 2 === 0
                                   ? "#FFFFFF"
                                   : "#F4F7FF"

                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom

                                height: 1
                                color: "#E4EAF5"
                            }

                            Row {
                                anchors.fill: parent
                                anchors.margins: 12 * root.scale
                                spacing: root.colSpacing

                                Text {
                                    text: index + 1
                                    width: root.colSr

                                    font.pixelSize: 18 * root.scale
                                    color: "#3A3A3A"

                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: batchName
                                    width: root.colBatch

                                    font.pixelSize: 18 * root.scale
                                    color: "#3A3A3A"

                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: generatedOn
                                    width: root.colDate

                                    font.pixelSize: 18 * root.scale
                                    color: "#3A3A3A"

                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: generatedBy
                                    width: root.colBy

                                    font.pixelSize: 18 * root.scale
                                    font.weight: Font.Medium
                                    color: "#1A4DB5"

                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }

                    // =================================================
                    // NO DATA
                    // =================================================

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        visible: tableList.count === 0

                        Column {
                            anchors.centerIn: parent
                            spacing: 16 * root.scale

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter

                                text: "No Batch History"

                                font.pixelSize: 24 * root.scale
                                font.weight: Font.Medium
                                color: "#8896B0"
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter

                                text: "No records available"

                                font.pixelSize: 20 * root.scale
                                color: "#B0BEE0"
                            }
                        }
                    }
                }
            }
        }
    }
}
