import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Pdf
import QtQuick.Window

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

    property url pdfSource: ""

    onOpened: Qt.callLater(computeRenderScale)

    function computeRenderScale() {
        if (pdfDoc.status === PdfDocument.Ready && pdfDoc.pageCount > 0) {
            var pageSize = pdfDoc.pagePointSize(0)

            // Fit page width exactly to container
            var scale = pdfContainer.width / pageSize.width

            pdfView.renderScale = scale
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: "#F0F2F8"
        clip: true

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // ===== HEADER =====
            Rectangle {
                Layout.fillWidth: true
                height: 54
                color: "#1A4DB5"
                // Only top corners rounded
                radius: 12
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 12
                    color: "#1A4DB5"
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12

                    Text {
                        text: "PDF Preview"
                        color: "white"
                        font.pixelSize: 18
                        font.bold: true
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Item { Layout.fillWidth: true }
                }
            }

            // ===== PDF VIEWER =====
            Rectangle {
                id: pdfContainer
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "#ffffff"   // white bg like a real PDF viewer
                clip: true

                PdfDocument {
                    id: pdfDoc
                    source: root.pdfSource
                    onStatusChanged: {
                        if (status === PdfDocument.Ready) {
                            Qt.callLater(root.computeRenderScale)
                        }
                    }
                }

                PdfMultiPageView {
                    id: pdfView

                    anchors.fill: parent

                    document: pdfDoc

                    focus: true

                    renderScale: 1.0

                    PinchHandler {
                        id: pinch
                        target: null

                        onScaleChanged: {
                            pdfView.renderScale = Math.max(
                                        0.5,
                                        Math.min(4.0,
                                                 pdfView.renderScale * pinch.scale))
                        }
                    }
                }

                onWidthChanged: Qt.callLater(root.computeRenderScale)
            }

            // ===== FOOTER =====
            Rectangle {
                Layout.fillWidth: true
                height: 50
                color: "#FFFFFF"
                // Only bottom corners rounded
                radius: 12
                Rectangle {
                    anchors.top: parent.top
                    width: parent.width
                    height: 12
                    color: "#FFFFFF"
                }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 16

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

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.close()
                        }
                    }
                }
            }
        }
    }
}
