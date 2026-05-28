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

    // =====================================================
    // PAGE OPEN ANIMATION
    // =====================================================

    opacity: 0.0

    property real pageScale: 0.85

    transform: Scale {
        origin.x: root.width / 2
        origin.y: root.height / 2

        xScale: root.pageScale
        yScale: root.pageScale
    }

    Component.onCompleted: {
        openAnimation.start()
    }

    // =====================================================
    // OPEN
    // =====================================================

    ParallelAnimation {
        id: openAnimation

        NumberAnimation {
            target: root
            property: "opacity"

            from: 0.0
            to: 1.0

            duration: 650

            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: root
            property: "pageScale"

            from: 0.85
            to: 1.0

            duration: 650

            easing.type: Easing.OutBack

            easing.overshoot: 1.05
        }
    }

    // =====================================================
    // CLOSE
    // =====================================================

    ParallelAnimation {
        id: closeAnimation

        NumberAnimation {
            target: root
            property: "opacity"

            from: 1.0
            to: 0.0

            duration: 500

            easing.type: Easing.InOutCubic
        }

        NumberAnimation {
            target: root
            property: "pageScale"

            from: 1.0
            to: 0.85

            duration: 500

            easing.type: Easing.InOutCubic
        }
    }

    function closePage() {
        closeAnimation.start()
    }

    property string activeFilter: "Created"

    property real colSpacing: 16 * scale

    property real colSr: 60 * scale
    property real colType: 180 * scale
    property real colFile: 420 * scale
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
                    font.pixelSize: 26
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

            // ===== FILTER BAR =====
            Rectangle {
                height: 56 * root.scale
                width: filterRow.implicitWidth + 20 * root.scale
                color: "#FFFFFF"
                radius: 10 * root.scale
                border.color: "#D0D8EC"
                border.width: 1

                Row {
                    id: filterRow
                    anchors.centerIn: parent
                    spacing: 8 * root.scale

                    Repeater {
                        model: ["Created", "Deleted", "Copied"]

                        delegate: Rectangle {
                            property bool active: root.activeFilter === modelData

                            width: flbl.implicitWidth + 30 * root.scale
                            height: 36 * root.scale
                            radius: 6 * root.scale

                            color: active ? "#1A4DB5" : "#F0F4FF"
                            border.color: active ? "#1A4DB5" : "#B0BEE0"
                            border.width: 1

                            Text {
                                id: flbl
                                anchors.centerIn: parent
                                text: modelData + " Files"
                                font.pixelSize: 18
                                font.weight: Font.Medium
                                color: active ? "#FFFFFF" : "#1A1A1A"
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.activeFilter = modelData
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

                    // ===== TABLE HEADER =====
                    Rectangle {
                        Layout.fillWidth: true
                        height: 44 * root.scale

                        color: "#1A4DB5"
                        radius: 10 * root.scale

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right

                            height: 10 * root.scale
                            color: "#1A4DB5"
                        }

                        Row {
                            anchors.fill: parent
                            anchors.margins: 12 * root.scale
                            spacing: root.colSpacing

                            Text {
                                text: "Sr"
                                width: root.colSr
                                font.bold: true
                                color: "#FFF"
                                font.pixelSize: 20
                            }

                            Text {
                                text: root.activeFilter === "Created"
                                      ? "Report Type"
                                      : "File Name"

                                width: root.activeFilter === "Created"
                                       ? root.colType
                                       : root.colFile

                                font.bold: true
                                color: "#FFF"
                                font.pixelSize: 20
                            }

                            Text {
                                text: root.activeFilter === "Deleted"
                                      ? "Deleted On"
                                      : root.activeFilter === "Copied"
                                        ? "Copied On"
                                        : "Generated Date"

                                width: root.colDate
                                font.bold: true
                                color: "#FFF"
                                font.pixelSize: 20
                            }

                            Text {
                                text: root.activeFilter === "Created"
                                      ? "From"
                                      : "By"

                                width: root.colFrom
                                font.bold: true
                                color: "#FFF"
                                font.pixelSize: 20
                            }

                            Text {
                                text: root.activeFilter === "Created"
                                      ? "To"
                                      : ""

                                width: root.colTo
                                visible: root.activeFilter === "Created"

                                font.bold: true
                                color: "#FFF"
                                font.pixelSize: 20
                            }

                            Text {
                                text: root.activeFilter === "Created"
                                      ? "Generated By"
                                      : ""

                                width: root.colBy
                                visible: root.activeFilter === "Created"

                                font.bold: true
                                color: "#FFF"
                                font.pixelSize: 20
                            }
                        }
                    }

                    // ===== TABLE DATA =====
                    ListView {
                        id: tableList

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

                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                anchors.right: parent.right

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
                                    font.pixelSize: 18
                                    color: "#3A3A3A"
                                }

                                Text {
                                    text: root.activeFilter === "Created"
                                          ? (type || "-")
                                          : (fileName || "-")

                                    width: root.activeFilter === "Created"
                                           ? root.colType
                                           : root.colFile

                                    font.pixelSize: 18
                                    color: "#3A3A3A"

                                    wrapMode: Text.NoWrap
                                }

                                Text {
                                    text: date || "-"
                                    width: root.colDate

                                    font.pixelSize: 18
                                    color: "#3A3A3A"

                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: root.activeFilter === "Created"
                                          ? ((from || "-").split(" ")[0])
                                          : (by || "-")

                                    width: root.colFrom

                                    font.pixelSize: 18
                                    color: "#3A3A3A"

                                    elide: Text.ElideRight
                                }

                                Text {
                                    visible: root.activeFilter === "Created"
                                    text: (to || "-").split(" ")[0]
                                    width: root.colTo

                                    font.pixelSize: 18
                                    color: "#3A3A3A"

                                    elide: Text.ElideRight
                                }

                                Text {
                                    visible: root.activeFilter === "Created"
                                    text: by || "-"
                                    width: root.colBy

                                    font.pixelSize: 18
                                    color: "#1A4DB5"
                                    font.weight: Font.Medium

                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }

                    // ===== NO DATA =====
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        visible: tableList.count === 0

                        Column {
                            anchors.centerIn: parent
                            spacing: 16 * root.scale

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "No data found"

                                font.pixelSize: 24
                                font.weight: Font.Medium
                                color: "#8896B0"
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "No records available"

                                font.pixelSize: 20
                                color: "#B0BEE0"
                            }
                        }
                    }
                }
            }
        }
    }
}
