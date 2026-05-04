import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    anchors.fill: parent

    property var globalTopBar

    property real baseWidth: 1024
    property real baseHeight: 600
    property real scale: Math.min(width / baseWidth, height / baseHeight)

    property string searchText: ""

    // ===== TOUCH-FRIENDLY SIZES =====
    property real rowHeight:    56 * scale
    property real btnHeight:    44 * scale
    property real filterHeight: 64 * scale

    // ===== COLUMN WIDTHS =====
    property real colSpacing: 16 * scale

    property real colSno:     60  * scale
    property real colBatch:   200 * scale
    property real colStarted: 200 * scale
    property real colEnded:   200 * scale
    property real colPdf:     130 * scale

    property real colProduct: {
        var used = colSno + colBatch + colStarted + colEnded + colPdf + (colSpacing * 5)
        return Math.max(100 * scale, tableContainer.width - used - 24 * scale)
    }

    property int visibleCount: {
        var count = 0
        for (var i = 0; i < tableList.count; i++) {
            var m = tableList.model.get(i)
            if (m.batch.toLowerCase().includes(root.searchText.toLowerCase())) count++
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

            // ===== TABLE =====
            Rectangle {
                id: tableContainer
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

                    // TABLE HEADER
                    Rectangle {
                        Layout.fillWidth: true
                        height: 52 * root.scale
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

                            Text { text: "S/No";       width: root.colSno;     font.bold: true; color: "#FFF"; font.pixelSize: 20 * root.scale; verticalAlignment: Text.AlignVCenter; height: parent.height }
                            Text { text: "Batch";      width: root.colBatch;   font.bold: true; color: "#FFF"; font.pixelSize: 20 * root.scale; verticalAlignment: Text.AlignVCenter; height: parent.height }
                            Text { text: "Product";    width: root.colProduct; font.bold: true; color: "#FFF"; font.pixelSize: 20 * root.scale; verticalAlignment: Text.AlignVCenter; height: parent.height }
                            Text { text: "Started At"; width: root.colStarted; font.bold: true; color: "#FFF"; font.pixelSize: 20 * root.scale; verticalAlignment: Text.AlignVCenter; height: parent.height }
                            Text { text: "Ended At";   width: root.colEnded;   font.bold: true; color: "#FFF"; font.pixelSize: 20 * root.scale; verticalAlignment: Text.AlignVCenter; height: parent.height }
                            Text { text: "Save PDF";   width: root.colPdf;     font.bold: true; color: "#FFF"; font.pixelSize: 20 * root.scale; verticalAlignment: Text.AlignVCenter; height: parent.height }
                        }
                    }

                    // TABLE ROWS
                    ListView {
                        id: tableList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true

                        model: ListModel {
                            ListElement { sno: "1"; batch: "default batch";    product: "Tablet A";  started: "10/08/2025 18:21:00"; ended: "---"; pdf: "" }
                            ListElement { sno: "2"; batch: "production batch"; product: "Tablet A";  started: "10/08/2025 19:10:00"; ended: "---"; pdf: "" }
                            ListElement { sno: "3"; batch: "testing batch";    product: "Capsule C"; started: "11/08/2025 09:00:00"; ended: "---"; pdf: "" }
                            ListElement { sno: "4"; batch: "batch alpha";      product: "Tablet D";  started: "12/08/2025 10:00:00"; ended: "12/08/2025 14:00:00"; pdf: "" }
                            ListElement { sno: "5"; batch: "batch beta";       product: "Capsule E"; started: "13/08/2025 08:30:00"; ended: "---"; pdf: "" }
                        }

                        delegate: Rectangle {
                            property bool searchOk: batch.toLowerCase().includes(root.searchText.toLowerCase())

                            visible: searchOk
                            width: ListView.view.width
                            height: visible ? root.rowHeight : 0
                            color: index % 2 === 0 ? "#FFFFFF" : "#F4F7FF"

                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                anchors.right: parent.right
                                height: 1
                                color: "#E4EAF5"
                            }

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin:  12 * root.scale
                                anchors.rightMargin: 12 * root.scale
                                anchors.topMargin:   0
                                anchors.bottomMargin: 0
                                spacing: root.colSpacing

                                Text {
                                    text: sno
                                    width: root.colSno
                                    height: parent.height
                                    font.pixelSize: 18 * root.scale
                                    color: "#3A3A3A"
                                    verticalAlignment: Text.AlignVCenter
                                }

                                Text {
                                    text: batch
                                    width: root.colBatch
                                    height: parent.height
                                    font.pixelSize: 18 * root.scale
                                    color: "#1A4DB5"
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                    verticalAlignment: Text.AlignVCenter
                                }

                                Text {
                                    text: product
                                    width: root.colProduct
                                    height: parent.height
                                    font.pixelSize: 18 * root.scale
                                    color: "#3A3A3A"
                                    elide: Text.ElideRight
                                    verticalAlignment: Text.AlignVCenter
                                }

                                Text {
                                    text: started
                                    width: root.colStarted
                                    height: parent.height
                                    font.pixelSize: 18 * root.scale
                                    color: "#3A3A3A"
                                    verticalAlignment: Text.AlignVCenter
                                }

                                Text {
                                    text: ended
                                    width: root.colEnded
                                    height: parent.height
                                    font.pixelSize: 18 * root.scale
                                    color: ended === "---" ? "#8896B0" : "#3A3A3A"
                                    verticalAlignment: Text.AlignVCenter
                                }

                                // ===== SAVE PDF BUTTON  =====
                                Item {
                                    width: root.colPdf
                                    height: parent.height

                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: root.colPdf - 8 * root.scale
                                        height: root.btnHeight         // 44px tap target
                                        radius: 8 * root.scale
                                        color: saveMouse.pressed ? "#1A4DB5" : "#FFFFFF"
                                        border.color: "#1A4DB5"
                                        border.width: 1.5

                                        Text {
                                            anchors.centerIn: parent
                                            text: "Save PDF"
                                            font.pixelSize: 17 * root.scale
                                            font.weight: Font.Medium
                                            color: saveMouse.pressed ? "#FFFFFF" : "#1A4DB5"
                                        }

                                        MouseArea {
                                            id: saveMouse
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                // Pass the batch row data
                                                var batchInfo = {
                                                    "sno":         sno,
                                                    "batch":       batch,
                                                    "product":     product,
                                                    "started":     started,
                                                    "ended":       ended,
                                                    "productSno":  "01-001",
                                                    "productCode": "default code"
                                                }

                                                // Pass rejection rows for this batch — replace with real data from your model
                                                var rejections = []
                                                // Example: loop your rejection model filtered by batch
                                                // for (var i = 0; i < rejectionModel.count; i++) {
                                                //     var r = rejectionModel.get(i)
                                                //     if (r.batchName === batch) {
                                                //         rejections.push({ date: r.date, time: r.time, rejectCount: r.rejectCount })
                                                //     }
                                                // }

                                                var savedPath = PdfExporter.exportBatchToPdf(batchInfo, rejections)

                                                if (globalTopBar && globalTopBar.showNotification)
                                                    globalTopBar.showNotification("✓ Batch PDF saved")
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // ===== NO DATA =====
                        Item {
                            anchors.fill: parent
                            visible: root.visibleCount === 0

                            Column {
                                anchors.centerIn: parent
                                spacing: 16 * root.scale

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "No data found"
                                    font.pixelSize: 24 * root.scale
                                    font.weight: Font.Medium
                                    color: "#8896B0"
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "No records match the selected filters"
                                    font.pixelSize: 20 * root.scale
                                    color: "#B0BEE0"
                                }

                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 160 * root.scale
                                    height: 52 * root.scale
                                    radius: 12 * root.scale
                                    color: "#1A4DB5"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Reset Filters"
                                        font.pixelSize: 18 * root.scale
                                        font.weight: Font.Medium
                                        color: "#FFFFFF"
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            searchInput.text = ""
                                            root.searchText = ""
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
