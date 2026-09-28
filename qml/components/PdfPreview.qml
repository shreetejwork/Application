import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Pdf
import QtQuick.Window

Popup {
    id: root

    Typography {
        id: componentTypography
        scale: root.scale || 1.0
    }

    Typography {
        id: pdfTypography
        scale: 1.0
    }

    modal: true
    focus: true

    width: parent.width * 0.9
    height: parent.height * 0.9
    anchors.centerIn: parent

    background: Rectangle {
        color: "transparent"
    }

    Overlay.modal: Rectangle {
        color: "#80000000"
    }

    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    property url pdfSource: ""

    onOpened: {
        Qt.callLater(computeRenderScale)
    }

    function computeRenderScale() {
        if (pdfDoc.status === PdfDocument.Ready && pdfDoc.pageCount > 0) {
            var pageSize = pdfDoc.pagePointSize(0)

            if (pageSize.width > 0) {
                pdfView.renderScale =
                        pdfContainer.width / pageSize.width
            }
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

            Rectangle {
                Layout.fillWidth: true
                height: 54
                color: "#1A4DB5"
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
                    spacing: 8

                    Text {
                        text: "PDF Preview"
                        color: "white"
                        font.pixelSize: pdfTypography.body
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        width: 40
                        height: 36
                        radius: 6
                        color: upArea.pressed
                               ? "#0D3A8A"
                               : "#2D6AD4"
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            anchors.centerIn: parent
                            text: "▲"
                            color: "white"
                            font.pixelSize: 16
                        }

                        MouseArea {
                            id: upArea
                            anchors.fill: parent

                            onClicked: {
                                console.log("[PDF-BUTTON] UP clicked")

                                if (pdfView.currentPage > 0) {
                                    pdfView.currentPage =
                                            pdfView.currentPage - 1
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: 40
                        height: 36
                        radius: 6
                        color: downArea.pressed
                               ? "#0D3A8A"
                               : "#2D6AD4"
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            anchors.centerIn: parent
                            text: "▼"
                            color: "white"
                            font.pixelSize: 16
                        }

                        MouseArea {
                            id: downArea
                            anchors.fill: parent

                            onClicked: {
                                console.log("[PDF-BUTTON] DOWN clicked")

                                if (pdfView.currentPage <
                                        pdfDoc.pageCount - 1) {
                                    pdfView.currentPage =
                                            pdfView.currentPage + 1
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: pdfContainer

                Layout.fillWidth: true
                Layout.fillHeight: true

                color: "#FFFFFF"
                clip: true

                PdfDocument {
                    id: pdfDoc

                    source: root.pdfSource

                    onStatusChanged: {
                        console.log(
                            "[PDF] Status:",
                            pdfDoc.status
                        )

                        if (pdfDoc.status === PdfDocument.Ready) {
                            Qt.callLater(root.computeRenderScale)
                        }
                    }
                }

                PdfMultiPageView {
                    id: pdfView

                    anchors.fill: parent

                    document: pdfDoc
                    focus: true
                    activeFocusOnTab: true
                    renderScale: 1.0

                    onCurrentPageChanged: {
                        console.log(
                            "[PDF-VIEW] currentPage:",
                            pdfView.currentPage
                        )
                    }
                }

                // TOUCH DRAG TEST ONLY
                // This does not move or modify the PDF.
                MultiPointTouchArea {
                    id: touchTest

                    anchors.fill: parent
                    z: 1000

                    minimumTouchPoints: 1
                    maximumTouchPoints: 1
                    mouseEnabled: false

                    onPressed: {
                        console.log("========== TOUCH TEST ==========")
                        console.log("[TOUCH] PRESSED")
                        console.log("[TOUCH] X:", touchPoints[0].x)
                        console.log("[TOUCH] Y:", touchPoints[0].y)
                    }

                    onUpdated: {
                        console.log(
                            "[TOUCH] MOVED:",
                            touchPoints[0].x,
                            touchPoints[0].y
                        )
                    }

                    onReleased: {
                        console.log("[TOUCH] RELEASED")
                        console.log("================================")
                    }

                    onCanceled: {
                        console.log("[TOUCH] CANCELED")
                    }
                }

                onWidthChanged: {
                    Qt.callLater(root.computeRenderScale)
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 50

                color: "#FFFFFF"
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
                            font.pixelSize: pdfTypography.caption
                        }

                        MouseArea {
                            anchors.fill: parent

                            onClicked: {
                                console.log(
                                    "[PDF-BUTTON] CLOSE clicked"
                                )

                                root.close()
                            }
                        }
                    }
                }
            }
        }
    }
}
