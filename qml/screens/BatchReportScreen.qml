import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    anchors.fill: parent

    property real baseWidth: 1024
    property real baseHeight: 600
    property real scale: Math.max(0.75, Math.min(width / baseWidth, height / baseHeight))

    property string searchText: ""

    property int visibleCount: {
        var count = 0
        for (var i = 0; i < tableList.count; i++) {
            var m = tableList.model.get(i)
            if (m.batch.toLowerCase().includes(root.searchText.toLowerCase()))
                count++
        }
        return count
    }

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
                    text: "Batch Report"
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

            // ===== FILTER BAR =====
            Rectangle {
                Layout.fillWidth: true
                height: 56 * root.scale
                color: "#FFFFFF"
                radius: 10 * root.scale
                border.color: "#D0D8EC"
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10 * root.scale
                    spacing: 10 * root.scale

                    Rectangle {
                        width: 220 * root.scale
                        height: 36 * root.scale
                        radius: 6 * root.scale
                        color: "#F0F4FF"
                        border.color: "#B0BEE0"

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 6 * root.scale

                            Text { text: "🔍"; font.pixelSize: 16 * root.scale }

                            TextInput {
                                id: searchInput
                                Layout.fillWidth: true
                                font.pixelSize: 16 * root.scale
                                color: "#1A1A1A"
                                clip: true
                                text: root.searchText
                                onTextChanged: root.searchText = text

                                Text {
                                    anchors.fill: parent
                                    text: "Search batch..."
                                    color: "#8896B0"
                                    visible: parent.text === ""
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Repeater {
                        model: ["COPY", "PRINT", "PDF"]

                        delegate: Rectangle {
                            width: 80 * root.scale
                            height: 36 * root.scale
                            radius: 6 * root.scale
                            color: "#FFFFFF"
                            border.color: "#1A4DB5"
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                font.pixelSize: 16 * root.scale
                                color: "#1A4DB5"
                                font.weight: Font.Medium
                            }

                            MouseArea {
                                anchors.fill: parent
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

                    // HEADER
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

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10 * root.scale

                            Text { text: "G/No"; Layout.preferredWidth: 70 * root.scale; color: "#FFFFFF"; font.bold: true; font.pixelSize: 20 * root.scale }
                            Text { text: "S/No"; Layout.preferredWidth: 70 * root.scale; color: "#FFFFFF"; font.bold: true; font.pixelSize: 20 * root.scale }
                            Text { text: "Started At"; Layout.preferredWidth: 200 * root.scale; color: "#FFFFFF"; font.bold: true; font.pixelSize: 20 * root.scale }
                            Text { text: "Ended At"; Layout.preferredWidth: 200 * root.scale; color: "#FFFFFF"; font.bold: true; font.pixelSize: 20 * root.scale }
                            Text { text: "Batch"; Layout.fillWidth: true; color: "#FFFFFF"; font.bold: true; font.pixelSize: 20 * root.scale }
                            Text { text: "User"; Layout.preferredWidth: 120 * root.scale; color: "#FFFFFF"; font.bold: true; font.pixelSize: 20 * root.scale }
                        }
                    }

                    // LIST
                    ListView {
                        id: tableList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true

                        model: ListModel {
                            ListElement { gno: "1"; sno: "1"; started: "10/08/2025 18:21:00"; ended: "---"; batch: "default batch"; user: "ADMIN" }
                            ListElement { gno: "2"; sno: "2"; started: "10/08/2025 19:10:00"; ended: "---"; batch: "production batch"; user: "USER" }
                            ListElement { gno: "3"; sno: "3"; started: "11/08/2025 09:00:00"; ended: "---"; batch: "testing batch"; user: "ADMIN" }
                        }

                        delegate: Rectangle {
                            property bool searchMatch: batch.toLowerCase().includes(root.searchText.toLowerCase())

                            visible: searchMatch
                            width: ListView.view.width
                            height: visible ? 42 * root.scale : 0
                            color: index % 2 === 0 ? "#FFFFFF" : "#F4F7FF"

                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                anchors.right: parent.right
                                height: 1
                                color: "#E4EAF5"
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10 * root.scale

                                Text { text: gno; Layout.preferredWidth: 70 * root.scale; font.pixelSize: 18 * root.scale; color: "#3A3A3A" }
                                Text { text: sno; Layout.preferredWidth: 70 * root.scale; font.pixelSize: 18 * root.scale; color: "#3A3A3A" }
                                Text { text: started; Layout.preferredWidth: 200 * root.scale; font.pixelSize: 18 * root.scale; color: "#3A3A3A" }
                                Text { text: ended; Layout.preferredWidth: 200 * root.scale; font.pixelSize: 18 * root.scale; color: "#3A3A3A" }
                                Text { text: batch; Layout.fillWidth: true; font.pixelSize: 18 * root.scale; color: "#3A3A3A" }

                                Rectangle {
                                    Layout.preferredWidth: 120 * root.scale
                                    height: 24 * root.scale
                                    radius: 4 * root.scale
                                    color: user === "ADMIN" ? "#E8EEFF"
                                          : user === "USER" ? "#E8F5E9"
                                          : "transparent"

                                    Text {
                                        anchors.centerIn: parent
                                        text: user
                                        font.pixelSize: 18 * root.scale
                                        font.weight: Font.Medium
                                        color: user === "ADMIN" ? "#1A4DB5"
                                              : user === "USER" ? "#2E7D32"
                                              : "#888888"
                                    }
                                }
                            }
                        }

                        // NO DATA
                        Item {
                            anchors.fill: parent
                            visible: root.visibleCount === 0

                            Text {
                                anchors.centerIn: parent
                                text: "No data found"
                                font.pixelSize: 22 * root.scale
                                color: "#8896B0"
                            }
                        }
                    }
                }
            }
        }
    }
}
