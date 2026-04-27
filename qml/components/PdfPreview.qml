import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
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

    // 🔥 DATA FROM MAIN SCREEN
    ListModel {
        id: internalModel
    }
    property alias dataModel: internalModel

    property string fromDate: ""
    property string toDate: ""

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

            // ================= HTML PREVIEW =================
            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                Rectangle {
                    width: parent.width - 40
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: "white"
                    radius: 4
                    border.color: "#CCCCCC"

                    Column {
                        width: parent.width
                        spacing: 6

                        Text {
                            text: "<h2>Audit Trail Report</h2>" +
                                  "<p><b>From:</b> " + root.fromDate +
                                  " | <b>To:</b> " + root.toDate + "</p>"
                            textFormat: Text.RichText
                            wrapMode: Text.Wrap
                            font.pixelSize: 16
                        }

                        Repeater {
                            model: dataModel

                            delegate: Text {
                                text: sr + " | " + date + " | " + time + " | " + user +
                                      " | " + old + " → " + newVal + " | " + remark
                                font.pixelSize: 14
                            }
                        }
                    }
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

                    // ===== SAVE PDF =====
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
                                var fileName = Qt.formatDateTime(now, "dd-MM-yyyy-HH-mm") + ".pdf"

                                var filePath =
                                    StandardPaths.writableLocation(StandardPaths.DocumentsLocation)
                                    + "/" + fileName

                                PdfExporter.exportTableToPdf(
                                    modelToArray(dataModel),
                                    fromDate,
                                    toDate,
                                    filePath
                                )
                            }
                        }
                    }

                    // ===== CLOSE =====
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
