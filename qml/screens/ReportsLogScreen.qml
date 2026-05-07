import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import AppState 1.0

Item {
    id: root
    anchors.fill: parent

    property real baseWidth: 1024
    property real baseHeight: 600
    property real scale: Math.min(width / baseWidth, height / baseHeight)

    property string activeFilter: "Created"

    property real colSpacing: 16 * scale

    property real colSr: 60 * scale
    property real colType: 180 * scale
    property real colFile: 260 * scale
    property real colDate: 160 * scale
    property real colFrom: 140 * scale
    property real colTo: 140 * scale
    property real colBy: 140 * scale

    Rectangle {
        anchors.fill: parent
        color: "#F5F7FC"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24 * root.scale
            spacing: 16 * root.scale

            // ===== HEADER =====
            Column {
                spacing: 6 * root.scale

                Text {
                    text: "Reports Log"
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

            // ===== FILTER =====
            Rectangle {
                height: 38 * root.scale
                width: filterRow.implicitWidth + 8 * root.scale
                color: "#EDF1FA"
                radius: 8 * root.scale
                border.color: "#C8D4EE"
                border.width: 1

                Row {
                    id: filterRow
                    anchors.centerIn: parent
                    spacing: 4 * root.scale

                    Repeater {
                        model: ["Created", "Deleted", "Copied"]

                        Rectangle {
                            property bool active: root.activeFilter === modelData
                            width: flbl.implicitWidth + 20 * root.scale
                            height: 30 * root.scale
                            radius: 6 * root.scale
                            color: active ? "#1A4DB5" : "transparent"

                            Text {
                                id: flbl
                                anchors.centerIn: parent
                                text: modelData + " Files"
                                font.pixelSize: 14 * root.scale
                                font.weight: active ? Font.SemiBold : Font.Normal
                                color: active ? "#FFFFFF" : "#4A5E8A"
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.activeFilter = modelData
                                cursorShape: Qt.PointingHandCursor
                            }
                        }
                    }
                }
            }

            // ===== TABLE =====
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

                    // ===== HEADER ROW =====
                    Rectangle {
                        Layout.fillWidth: true
                        height: 44 * root.scale
                        color: "#1A4DB5"

                        Row {
                            anchors.fill: parent
                            anchors.margins: 12 * root.scale
                            spacing: root.colSpacing

                            Text {
                                text: "Sr"
                                width: root.colSr
                                color: "#FFF"
                                font.bold: true
                            }

                            Text {
                                text: root.activeFilter === "Created"
                                      ? "Report Type"
                                      : "File Name"

                                width: root.activeFilter === "Created"
                                       ? root.colType
                                       : root.colFile

                                color: "#FFF"
                                font.bold: true
                            }

                            Text {
                                text: root.activeFilter === "Deleted"
                                      ? "Deleted On"
                                      : root.activeFilter === "Copied"
                                        ? "Copied On"
                                        : "Generated Date"

                                width: root.colDate
                                color: "#FFF"
                                font.bold: true
                            }

                            Text {
                                text: root.activeFilter === "Created"
                                      ? "From"
                                      : "By"

                                width: root.colFrom
                                color: "#FFF"
                                font.bold: true
                            }

                            Text {
                                text: root.activeFilter === "Created"
                                      ? "To"
                                      : ""

                                width: root.colTo
                                visible: root.activeFilter === "Created"
                                color: "#FFF"
                                font.bold: true
                            }

                            Text {
                                text: root.activeFilter === "Created"
                                      ? "Generated By"
                                      : ""

                                width: root.colBy
                                visible: root.activeFilter === "Created"
                                color: "#FFF"
                                font.bold: true
                            }
                        }
                    }

                    // ===== DATA =====
                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true

                        model: {
                            if (root.activeFilter === "Created")
                                return GlobalState.reportsLogModel

                            if (root.activeFilter === "Deleted")
                                return GlobalState.deletedFilesModel

                            return GlobalState.copiedFilesModel
                        }

                        delegate: Rectangle {
                            width: ListView.view.width
                            height: 42 * root.scale

                            color: index % 2 === 0
                                   ? "#FFFFFF"
                                   : "#F4F7FF"

                            Row {
                                anchors.fill: parent
                                anchors.margins: 12 * root.scale
                                spacing: root.colSpacing

                                Text {
                                    text: index + 1
                                    width: root.colSr
                                }

                                Text {
                                    text: root.activeFilter === "Created"
                                          ? (type || "-")
                                          : (fileName || "-")

                                    width: root.activeFilter === "Created"
                                           ? root.colType
                                           : root.colFile
                                }

                                Text {
                                    text: date || "-"
                                    width: root.colDate
                                }

                                Text {
                                    text: root.activeFilter === "Created"
                                          ? (from || "-")
                                          : (by || "-")

                                    width: root.colFrom
                                }

                                Text {
                                    visible: root.activeFilter === "Created"
                                    text: to || "-"
                                    width: root.colTo
                                }

                                Text {
                                    visible: root.activeFilter === "Created"
                                    text: by || "-"
                                    width: root.colBy
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
