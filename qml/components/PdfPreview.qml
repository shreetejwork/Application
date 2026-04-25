import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtWebEngine
import Qt.labs.platform

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

    // 🔥 PDF FILE PATH FROM C++
    property string filePath: ""

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
                height: Math.max(48, 54 * root.scaleFactor)
                color: "#1A4DB5"
                radius: 12

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16

                    Text {
                        Layout.fillWidth: true
                        text: "PDF Preview"
                        color: "white"
                        font.pixelSize: Math.max(14, 18 * root.scaleFactor)
                        font.bold: true
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            // ================= PDF VIEW =================
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "#FFFFFF"

                WebEngineView {
                    id: pdfViewer
                    anchors.fill: parent

                    // 🔥 IMPORTANT: loads generated PDF
                    url: root.filePath
                }

                // fallback message if no file
                Text {
                    anchors.centerIn: parent
                    text: root.filePath === "" ? "No PDF loaded" : ""
                    color: "#888888"
                    font.pixelSize: 18
                }
            }

            // ================= FOOTER =================
            Rectangle {
                Layout.fillWidth: true
                height: Math.max(56, 62 * root.scaleFactor)
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
                            text: "Download"
                            color: "white"
                            font.bold: true
                        }

                        TapHandler {
                            onTapped: {
                                // Just re-save same file (optional overwrite/download behavior)

                                var now = new Date()
                                var fileName = Qt.formatDateTime(now, "dd-MM-yyyy-HH-mm") + ".pdf"

                                var filePath =
                                    StandardPaths.writableLocation(StandardPaths.DocumentsLocation)
                                    + "/" + fileName

                                PdfExporter.exportTableToPdf(
                                    [],   // optional if you already passed data in C++
                                    root.fromDate,
                                    root.toDate,
                                    filePath
                                )

                                root.filePath = "file://" + filePath
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
                            onTapped: root.close()
                        }
                    }
                }
            }
        }
    }
}
