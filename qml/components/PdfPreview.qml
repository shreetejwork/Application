import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Pdf
import QtQuick.Window

Popup {
    Typography {
        id: componentTypography
        scale: root.scale || 1.0
    }

    id: root

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

    Typography {
        id: pdfTypography
        scale: 1.0
    }

    // =====================================================
    // PDF SCALE
    // =====================================================

    onOpened: Qt.callLater(computeRenderScale)

    function computeRenderScale() {
        if (pdfDoc.status === PdfDocument.Ready &&
                pdfDoc.pageCount > 0) {

            var pageSize = pdfDoc.pagePointSize(0)

            if (pageSize.width > 0) {
                var newScale = pdfContainer.width / pageSize.width
                pdfView.renderScale = newScale
            }
        }
    }

    // =====================================================
    // TOUCH PAGE NAVIGATION
    // =====================================================

    property real touchStartY: 0
    property real touchStartX: 0
    property bool touchTracking: false

    function handleTouchRelease(endX, endY) {

        if (!touchTracking)
            return

        touchTracking = false

        var deltaX = endX - touchStartX
        var deltaY = endY - touchStartY

        // Ignore small movements
        if (Math.abs(deltaY) < 40)
            return

        // Ignore mostly horizontal movements
        if (Math.abs(deltaX) > Math.abs(deltaY))
            return

        // Swipe UP -> next page
        if (deltaY < 0) {

            if (pdfView.currentPage < pdfDoc.pageCount - 1) {
                pdfView.currentPage =
                        pdfView.currentPage + 1
            }
        }

        // Swipe DOWN -> previous page
        else {

            if (pdfView.currentPage > 0) {
                pdfView.currentPage =
                        pdfView.currentPage - 1
            }
        }
    }

    // =====================================================
    // MAIN BACKGROUND
    // =====================================================

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

                        font.pixelSize: pdfTypography.body

                        Layout.alignment: Qt.AlignVCenter
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    // =============================================
                    // UP BUTTON
                    // =============================================

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

                                if (pdfView.currentPage > 0) {
                                    pdfView.currentPage =
                                            pdfView.currentPage - 1
                                }
                            }
                        }
                    }

                    // =============================================
                    // DOWN BUTTON
                    // =============================================

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
            // PDF VIEWER
            // =================================================

            Rectangle {
                id: pdfContainer

                Layout.fillWidth: true
                Layout.fillHeight: true

                color: "#ffffff"

                clip: true

                PdfDocument {
                    id: pdfDoc

                    source: root.pdfSource

                    onStatusChanged: {

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
                }

                // =================================================
                // TOUCH OVERLAY
                // =================================================
                //
                // Transparent overlay used only for touchscreen
                // swipe detection.
                //
                // It does not change the PDF appearance.
                // It does not change the existing buttons.
                // It does not change PDF rendering.
                //
                // =================================================

                MultiPointTouchArea {
                    id: touchArea

                    anchors.fill: parent

                    z: 100

                    minimumTouchPoints: 1
                    maximumTouchPoints: 1

                    mouseEnabled: false

                    onPressed: {

                        if (touchPoints.length > 0) {

                            root.touchStartX =
                                    touchPoints[0].x

                            root.touchStartY =
                                    touchPoints[0].y

                            root.touchTracking = true
                        }
                    }

                    onReleased: {

                        if (touchPoints.length > 0) {

                            root.handleTouchRelease(
                                        touchPoints[0].x,
                                        touchPoints[0].y)
                        }
                        else {
                            root.touchTracking = false
                        }
                    }

                    onCanceled: {
                        root.touchTracking = false
                    }
                }

                // =================================================
                // WIDTH CHANGE
                // =================================================

                onWidthChanged: {
                    Qt.callLater(root.computeRenderScale)
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

                            font.pixelSize: pdfTypography.caption
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
