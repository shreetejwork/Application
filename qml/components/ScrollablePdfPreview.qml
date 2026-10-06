pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Pdf

Popup {
    id: root

    Typography {
        id: pdfTypography
        scale: 1.0
    }

    modal: true
    focus: true
    width: parent ? parent.width * 0.9 : 900
    height: parent ? parent.height * 0.9 : 500
    anchors.centerIn: parent
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    property url pdfSource: ""
    property int currentPage: 0
    property real touchStartContentY: 0

    function navigatePage(offset) {
        if (pdfDocument.status !== PdfDocument.Ready
                || pdfDocument.pageCount <= 0)
            return

        var target = Math.max(0, Math.min(currentPage + offset,
                                         pdfDocument.pageCount - 1))
        currentPage = target
        pagesList.positionViewAtIndex(target, ListView.Beginning)
    }

    function resetPreview() {
        currentPage = 0
        if (pdfDocument.pageCount > 0)
            pagesList.positionViewAtBeginning()
    }

    onOpened: Qt.callLater(resetPreview)
    onPdfSourceChanged: {
        if (opened)
            Qt.callLater(resetPreview)
    }

    background: Rectangle {
        color: "transparent"
    }

    Overlay.modal: Rectangle {
        color: "#80000000"
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
                Layout.preferredHeight: 54
                color: "#1A4DB5"
                radius: 12

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 12
                    color: parent.color
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

                    Text {
                        text: pdfDocument.status === PdfDocument.Ready
                              && pdfDocument.pageCount > 0
                              ? "Page " + (root.currentPage + 1)
                                + " of " + pdfDocument.pageCount
                              : ""
                        color: "white"
                        font.pixelSize: pdfTypography.caption
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Rectangle {
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 36
                        radius: 6
                        color: previousArea.pressed ? "#0D3A8A" : "#2D6AD4"
                        Layout.alignment: Qt.AlignVCenter
                        opacity: root.currentPage > 0 ? 1 : 0.55

                        Text {
                            anchors.centerIn: parent
                            text: "▲"
                            color: "white"
                            font.pixelSize: 16
                        }

                        MouseArea {
                            id: previousArea
                            anchors.fill: parent
                            enabled: pdfDocument.status === PdfDocument.Ready
                                     && pdfDocument.pageCount > 0
                            onClicked: root.navigatePage(-1)
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 36
                        radius: 6
                        color: nextArea.pressed ? "#0D3A8A" : "#2D6AD4"
                        Layout.alignment: Qt.AlignVCenter
                        opacity: root.currentPage < pdfDocument.pageCount - 1
                                 ? 1 : 0.55

                        Text {
                            anchors.centerIn: parent
                            text: "▼"
                            color: "white"
                            font.pixelSize: 16
                        }

                        MouseArea {
                            id: nextArea
                            anchors.fill: parent
                            enabled: pdfDocument.status === PdfDocument.Ready
                                     && pdfDocument.pageCount > 0
                            onClicked: root.navigatePage(1)
                        }
                    }
                }
            }

            Item {
                id: pdfContainer
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                PdfDocument {
                    id: pdfDocument
                    source: root.pdfSource

                    onStatusChanged: {
                        if (pdfDocument.status === PdfDocument.Ready)
                            Qt.callLater(root.resetPreview)
                    }
                }

                ListView {
                    id: pagesList
                    anchors.fill: parent
                    clip: true
                    interactive: true
                    boundsBehavior: Flickable.StopAtBounds
                    flickableDirection: Flickable.VerticalFlick
                    spacing: 12
                    cacheBuffer: height
                    model: pdfDocument.status === PdfDocument.Ready
                           ? pdfDocument.pageCount : 0

                    delegate: Item {
                        id: pageRow
                        required property int index
                        width: pagesList.width

                        property size pagePointSize: pdfDocument.pagePointSize(index)
                        property real pageWidth: Math.max(1, width - 40)
                        property real pageScale: pagePointSize.width > 0
                                                 ? pageWidth / pagePointSize.width
                                                 : 1
                        property real pageHeight: pagePointSize.width > 0
                                                  ? pagePointSize.height * pageScale
                                                  : 1
                        height: pageHeight + 24

                        DragHandler {
                            target: null
                            acceptedDevices: PointerDevice.AllDevices
                            grabPermissions: PointerHandler.CanTakeOverFromItems
                                            | PointerHandler.CanTakeOverFromHandlersOfDifferentType
                                            | PointerHandler.ApprovesTakeOverByAnything
                            yAxis.enabled: true
                            xAxis.enabled: false

                            onActiveChanged: {
                                if (active)
                                    root.touchStartContentY = pagesList.contentY
                            }

                            onTranslationChanged: {
                                if (active) {
                                    var maxContentY = Math.max(
                                                0, pagesList.contentHeight
                                                   - pagesList.height)
                                    pagesList.contentY = Math.max(
                                                0, Math.min(
                                                    root.touchStartContentY
                                                    - activeTranslation.y,
                                                    maxContentY))
                                }
                            }
                        }

                        Rectangle {
                            anchors.centerIn: parent
                            width: pageRow.pageWidth
                            height: pageRow.pageHeight
                            color: "white"
                            border.color: "#D5DCE8"
                            border.width: 1

                            PdfPageView {
                                anchors.fill: parent
                                document: pdfDocument
                                renderScale: pageRow.pageScale
                                zoomEnabled: false

                                Component.onCompleted: goToPage(pageRow.index)
                            }
                        }
                    }

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                    }

                    onMovementEnded: {
                        var index = indexAt(width / 2, contentY + height / 2)
                        if (index >= 0)
                            root.currentPage = index
                    }

                    onContentYChanged: {
                        var index = indexAt(width / 2, contentY + height / 2)
                        if (index >= 0)
                            root.currentPage = index
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    visible: pdfDocument.status !== PdfDocument.Ready
                             || pdfDocument.pageCount <= 0
                    color: "#FFFFFF"

                    Text {
                        anchors.centerIn: parent
                        width: parent.width - 32
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                        color: "#5B6575"
                        font.pixelSize: pdfTypography.body
                        text: pdfDocument.status === PdfDocument.Error
                              ? "Unable to load this PDF."
                              : pdfDocument.status === PdfDocument.Ready
                                ? "This PDF has no pages."
                                : "Loading PDF..."
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                color: "#FFFFFF"
                radius: 12

                Rectangle {
                    anchors.top: parent.top
                    width: parent.width
                    height: 12
                    color: parent.color
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: 120
                    height: 40
                    radius: 6
                    color: closeArea.pressed ? "#0D3A8A" : "#1A4DB5"

                    Text {
                        anchors.centerIn: parent
                        text: "Close"
                        color: "white"
                        font.pixelSize: pdfTypography.caption
                    }

                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        onClicked: root.close()
                    }
                }
            }
        }
    }
}
