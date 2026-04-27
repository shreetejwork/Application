import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.platform
import QtQuick.Pdf   // ✅ REQUIRED FOR REAL PDF VIEW

Popup {
    id: root
    modal: true
    focus: true

    width: parent.width * 0.9
    height: parent.height * 0.9
    anchors.centerIn: parent

    background: Rectangle { color: "transparent" }
    Overlay.modal: Rectangle { color: "#80000000" }

    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    property real scaleFactor: Math.min(width / 1024, height / 768)

    // ================= TEMP DATA =================
    ListModel {
        id: internalModel
    }
    property alias dataModel: internalModel

    property string fromDate: ""
    property string toDate: ""

    // 🔥 TEMP PDF FILE PATH (IMPORTANT)
    property string filePath: ""

    // ================= CONVERT MODEL =================
    function modelToArray(model) {
        var arr = []
        for (var i = 0; i < model.count; i++) {
            arr.push(model.get(i))
        }
        return arr
    }

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: "#F0F2F8"

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // ================= HEADER =================
            Rectangle {
                Layout.fillWidth: true
                height: 54 * root.scaleFactor
                color: "#1A4DB5"
                radius: 12

                Text {
                    anchors.centerIn: parent
                    text: "PDF Preview"
                    color: "white"
                    font.pixelSize: 18 * root.scaleFactor
                    font.bold: true
                }
            }

            // ================= REAL PDF VIEW =================
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                PdfDocument {
                    id: pdfDoc
                    source: root.filePath
                }

                PdfView {
                    anchors.fill: parent
                    document: pdfDoc
                }
            }

            // ================= FOOTER =================
            Rectangle {
                Layout.fillWidth: true
                height: 60
                color: "#FFFFFF"

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 14

                    // ================= SAVE PDF =================
                    Rectangle {
                        width: 140
                        height: 40
                        radius: 6
                        color: "#1A4DB5"

                        Text {
                            anchors.centerIn: parent
                            text: "Save PDF"
                            color: "white"
                            font.bold: true
                        }

                        TapHandler {
                            onTapped: {

                                var now = new Date()
                                var fileName =
                                    Qt.formatDateTime(now, "dd-MM-yyyy-HH-mm") + ".pdf"

                                var filePath =
                                    StandardPaths.writableLocation(StandardPaths.DocumentsLocation)
                                    + "/" + fileName

                                // 🔥 FINAL EXPORT (REAL SAVE)
                                PdfExporter.exportTableToPdf(
                                    modelToArray(dataModel),
                                    fromDate,
                                    toDate,
                                    filePath
                                )

                                // 🔥 CLEAN TEMP FILE
                                PdfExporter.deleteTempPdf(root.filePath)

                                root.close()
                            }
                        }
                    }

                    // ================= CLOSE =================
                    Rectangle {
                        width: 120
                        height: 40
                        radius: 6
                        color: "#1A4DB5"

                        Text {
                            anchors.centerIn: parent
                            text: "Close"
                            color: "white"
                            font.bold: true
                        }

                        TapHandler {
                            onTapped: {
                                // 🔥 DELETE TEMP FILE
                                PdfExporter.deleteTempPdf(root.filePath)

                                root.close()
                            }
                        }
                    }
                }
            }
        }
    }
}
