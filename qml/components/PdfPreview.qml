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
        if (pdfDoc.status !== PdfDocument.Ready)
            return

        if (pdfDoc.pageCount <= 0)
            return

        var pageSize = pdfDoc.pagePointSize(0)

        if (pageSize.width > 0) {
            pdfView.renderScale =
                    pdfContainer.width / pageSize.width
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

            // =================================================
            // HEADER
            // =================================================

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

                        font.pixelSize:
                                pdfTypography.body

                        Layout.alignment:
                                Qt.AlignVCenter
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    // =================================================
                    // PREVIOUS PAGE
                    // =================================================

                    Rectangle {
                        width: 40
                        height: 36

                        radius: 6

                        color: upArea.pressed
                               ? "#0D3A8A"
                               : "#2D6AD4"

                        Layout.alignment:
                                Qt.AlignVCenter

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
                                if (pdfView.currentPage > 0) {
                                    pdfView.currentPage =
                                            pdfView.currentPage - 1
                                }
                            }
                        }
                    }

                    // =================================================
                    // NEXT PAGE
                    // =================================================

                    Rectangle {
                        width: 40
                        height: 36

                        radius: 6

                        color: downArea.pressed
                               ? "#0D3A8A"
                               : "#2D6AD4"

                        Layout.alignment:
                                Qt.AlignVCenter

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

            // =================================================
            // PDF AREA
            // =================================================

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
                        if (pdfDoc.status ===
                                PdfDocument.Ready) {

                            Qt.callLater(
                                        root.computeRenderScale)
                        }
                    }
                }

                // =================================================
                // ORIGINAL PDF VIEW
                // =================================================

                PdfMultiPageView {
                    id: pdfView

                    anchors.fill: parent

                    document: pdfDoc

                    focus: true

                    activeFocusOnTab: true

                    renderScale: 1.0
                }

                // =================================================
                // TOUCH DRAG HANDLER
                //
                // Transparent.
                // Does not change visual design.
                //
                // It only detects vertical finger movement and
                // changes the PDF page.
                // =================================================

                MouseArea {
                    id: touchDragArea

                    anchors.fill: parent

                    z: 10

                    enabled: true

                    hoverEnabled: false

                    preventStealing: true

                    property real startX: 0
                    property real startY: 0

                    property bool dragging: false

                    onPressed: {
                        startX = mouse.x
                        startY = mouse.y

                        dragging = false
                    }

                    onPositionChanged: {
                        var dx = mouse.x - startX
                        var dy = mouse.y - startY

                        if (!dragging) {
                            if (Math.abs(dy) > 25 &&
                                    Math.abs(dy) >
                                    Math.abs(dx)) {

                                dragging = true
                            }
                        }
                    }

                    onReleased: {
                        var dx = mouse.x - startX
                        var dy = mouse.y - startY

                        if (Math.abs(dy) >= 40 &&
                                Math.abs(dy) >
                                Math.abs(dx)) {

                            if (dy < 0) {
                                // Finger moved UP
                                if (pdfView.currentPage <
                                        pdfDoc.pageCount - 1) {

                                    pdfView.currentPage =
                                            pdfView.currentPage + 1
                                }
                            } else {
                                // Finger moved DOWN
                                if (pdfView.currentPage > 0) {

                                    pdfView.currentPage =
                                            pdfView.currentPage - 1
                                }
                            }
                        }

                        dragging = false
                    }

                    onCanceled: {
                        dragging = false
                    }
                }

                onWidthChanged: {
                    Qt.callLater(
                                root.computeRenderScale)
                }
            }

            // =================================================
            // FOOTER
            // =================================================

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

                            font.pixelSize:
                                    pdfTypography.caption
                        }

                        MouseArea {
                            anchors.fill: parent

                            onClicked: {
                                root.close()
                            }
                        }
                    }
                }
            }
        }
    }
}
