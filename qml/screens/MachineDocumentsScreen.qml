import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import AppState 1.0
import "../components"

Item {
    id: root
    anchors.fill: parent

    property var globalTopBar
    property real baseWidth: 1024
    property real baseHeight: 600
    property real scale: Math.min(width / baseWidth, height / baseHeight)

    ListModel {
        id: documentModel
    }

    function notify(message) {
        if (root.globalTopBar && root.globalTopBar.showNotification)
            root.globalTopBar.showNotification(message)
    }

    function loadDocuments() {
        documentModel.clear()

        var files = PdfExporter.getMachineDocumentFiles()
        for (var i = 0; i < files.length; ++i) {
            var path = files[i]
            documentModel.append({
                fileName: path.split("/").pop(),
                filePath: path
            })
        }
    }

    function viewDocument(path) {
        pdfPreview.pdfSource = "file:///" + path
        pdfPreview.open()
    }

    function copyDocument(path) {
        if (PdfExporter.usbCopyRunning) {
            notify("⚠ A file copy is already in progress")
            return
        }

        if (!PdfExporter.isUsbMounted()) {
            notify("⚠ USB not connected")
            return
        }

        if (!PdfExporter.startMoveFilesToUsb([path], GlobalState.machineId))
            notify("⚠ Failed to copy document to USB")
        else if (root.globalTopBar && root.globalTopBar.showNotification)
            root.globalTopBar.showNotification("Copying...", true)
    }

    function printDocument(path) {
        if (!PdfExporter.isPrinterAvailable()) {
            notify("⚠ No default printer available")
            return
        }

        if (PdfExporter.printPdfFiles([path]))
            notify("✓ Document sent to printer")
        else
            notify("⚠ Failed to send document to printer")
    }

    function generateMachineSummary() {
        var path = PdfExporter.generateMachineSummaryDocument(
                    databaseManager.getMachineInfo())
        if (path.length) {
            loadDocuments()
            notify("✓ Machine Summary Document generated")
        } else {
            notify("⚠ Failed to generate Machine Summary Document")
        }
    }

    Component.onCompleted: {
        openAnimation.start()
        loadDocuments()
    }

    Connections {
        target: PdfExporter

        function onUsbCopyFinished(success, filePaths) {
            if (filePaths.length)
                root.notify(success
                            ? "✓ Document copied to USB"
                            : "⚠ Failed to copy document to USB")
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#F5F7FC"
    }

    ParallelAnimation {
        id: openAnimation

        NumberAnimation {
            target: content
            property: "opacity"
            from: 0.0
            to: 1.0
            duration: 550
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: content
            property: "animationScale"
            from: 0.88
            to: 1.0
            duration: 650
            easing.type: Easing.OutBack
            easing.overshoot: 1.08
        }

        NumberAnimation {
            target: content
            property: "animationY"
            from: 40 * root.scale
            to: 0
            duration: 600
            easing.type: Easing.OutCubic
        }
    }

    Item {
        id: content
        anchors.fill: parent
        opacity: 0.0

        property real animationScale: 0.88
        property real animationY: 40 * root.scale

        transform: [
            Scale {
                origin.x: content.width / 2
                origin.y: content.height / 2
                xScale: content.animationScale
                yScale: content.animationScale
            },
            Translate {
                y: content.animationY
            }
        ]

        Rectangle {
            anchors.fill: parent
            color: "#EDF1FA"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 28 * root.scale
                spacing: 18 * root.scale

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Column {
                        spacing: 6 * root.scale

                        Text {
                            text: "Machine Documents"
                            font.pixelSize: 26
                            color: "#1A4DB5"
                        }

                        Rectangle {
                            width: 80 * root.scale
                            height: 4 * root.scale
                            radius: 2 * root.scale
                            color: "#1A4DB5"
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        Layout.preferredWidth: 280 * root.scale
                        Layout.preferredHeight: 38 * root.scale
                        radius: 8 * root.scale
                        color: "#1A4DB5"

                        Text {
                            anchors.centerIn: parent
                            text: "Generate Machine Summary Document"
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            color: "#FFFFFF"
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.generateMachineSummary()
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 14 * root.scale
                    color: "#FFFFFF"
                    border.color: "#C8D4EE"
                    border.width: 1
                    clip: true

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0

                        Rectangle {
                            Layout.fillWidth: true
                            height: 46 * root.scale
                            color: "#1A4DB5"
                            radius: 14 * root.scale

                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                anchors.right: parent.right
                                height: 14 * root.scale
                                color: "#1A4DB5"
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16 * root.scale
                                anchors.rightMargin: 16 * root.scale

                                Text {
                                    text: "File Name"
                                    color: "#FFFFFF"
                                    font.pixelSize: 16
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    verticalAlignment: Text.AlignVCenter
                                    opacity: 0.92
                                }

                                Text {
                                    text: "Actions"
                                    color: "#FFFFFF"
                                    font.pixelSize: 16
                                    Layout.preferredWidth: 270 * root.scale
                                    Layout.fillHeight: true
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    opacity: 0.92
                                }
                            }
                        }

                        ListView {
                            id: documentList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            visible: documentModel.count > 0
                            model: documentModel
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds

                            ScrollBar.vertical: ScrollBar {
                                policy: ScrollBar.AsNeeded
                                width: 8 * root.scale
                            }

                            delegate: Rectangle {
                                width: ListView.view.width
                                height: 60 * root.scale
                                color: index % 2 === 0 ? "#FFFFFF" : "#F7F9FF"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 16 * root.scale
                                    anchors.rightMargin: 16 * root.scale
                                    spacing: 10 * root.scale

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 10 * root.scale

                                        Image {
                                            source: "qrc:/qt/qml/Application/assets/images/pdf.png"
                                            Layout.preferredWidth: 20 * root.scale
                                            Layout.preferredHeight: 20 * root.scale
                                            Layout.alignment: Qt.AlignVCenter
                                            fillMode: Image.PreserveAspectFit
                                            smooth: true
                                            mipmap: true
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: fileName
                                            font.pixelSize: 15
                                            color: "#2A3550"
                                            elide: Text.ElideRight
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                    }

                                    RowLayout {
                                        Layout.preferredWidth: 270 * root.scale
                                        spacing: 6 * root.scale

                                        Repeater {
                                            model: ["View", "Copy", "Print"]

                                            delegate: Rectangle {
                                                Layout.fillWidth: true
                                                Layout.preferredHeight: 38 * root.scale
                                                radius: 7 * root.scale
                                                color: "#FFFFFF"
                                                border.color: modelData === "Copy"
                                                              ? "#2E7D32" : "#1A4DB5"
                                                border.width: 1

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: modelData
                                                    font.pixelSize: 15
                                                    font.weight: Font.Medium
                                                    color: modelData === "Copy"
                                                           ? "#2E7D32" : "#1A4DB5"
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        if (modelData === "View")
                                                            root.viewDocument(filePath)
                                                        else if (modelData === "Copy")
                                                            root.copyDocument(filePath)
                                                        else
                                                            root.printDocument(filePath)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    width: parent.width
                                    height: 1
                                    color: "#E4EAF5"
                                }
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            visible: documentModel.count === 0

                            Column {
                                anchors.centerIn: parent
                                spacing: 14 * root.scale

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "No machine documents found"
                                    font.pixelSize: 22
                                    font.weight: Font.Medium
                                    color: "#8896B0"
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "No PDF files in the Machine Documents folder"
                                    font.pixelSize: 15
                                    color: "#B0BEE0"
                                }

                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 130 * root.scale
                                    height: 42 * root.scale
                                    radius: 10 * root.scale
                                    color: "#1A4DB5"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "↺  Refresh"
                                        font.pixelSize: 15
                                        color: "#FFFFFF"
                                        font.weight: Font.Medium
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.loadDocuments()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    ScrollablePdfPreview {
        id: pdfPreview
    }
}
