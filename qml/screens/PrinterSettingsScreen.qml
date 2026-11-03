import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    anchors.fill: parent

    property real scale: Math.min(width / 1024, height / 600)
    property var globalTopBar

    Rectangle {
        anchors.fill: parent
        color: "#F5F7FC"
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24 * root.scale
        spacing: 12 * root.scale

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Printer Settings"
                color: "#1A4DB5"
                font.pixelSize: Math.max(24, 30 * root.scale)
                Layout.fillWidth: true
            }

            Button {
                text: "Refresh"
                onClicked: PrinterManager.refresh()
            }
        }

        Text {
            Layout.fillWidth: true
            text: PrinterManager.status
            color: "#475569"
            font.pixelSize: Math.max(14, 17 * root.scale)
            wrapMode: Text.Wrap
        }

        Text {
            Layout.fillWidth: true
            text: PrinterManager.defaultPrinter.length > 0
                  ? "Default printer: " + PrinterManager.defaultPrinter
                  : "No system default printer"
            color: "#16804A"
            font.pixelSize: Math.max(15, 18 * root.scale)
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "white"
            radius: 8
            border.color: "#D8E0EF"

            ListView {
                id: printerList
                anchors.fill: parent
                anchors.margins: 10 * root.scale
                clip: true
                spacing: 8 * root.scale
                model: PrinterManager.printers

                delegate: Rectangle {
                    required property var modelData
                    width: printerList.width
                    height: 94 * root.scale
                    radius: 6
                    color: "#F8FAFC"
                    border.color: "#E2E8F0"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10 * root.scale
                        spacing: 12 * root.scale

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3

                            Text {
                                text: modelData.name
                                color: "#172B4D"
                                font.pixelSize: Math.max(15, 18 * root.scale)
                                font.bold: true
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: "Model: " + modelData.model +
                                      "  |  Driver: " + modelData.driver
                                color: modelData.driver.indexOf("Not installed") >= 0
                                       ? "#B42318" : "#475569"
                                font.pixelSize: Math.max(12, 14 * root.scale)
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: (modelData.connected
                                       ? "Connected - "
                                       : "Disconnected - ") + modelData.state
                                color: modelData.ready ? "#16804A" : "#B42318"
                                font.pixelSize: Math.max(11, 12 * root.scale)
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        Button {
                            text: PrinterManager.installRunning
                                  ? "Installing..."
                                  : "Install driver"
                            enabled: !PrinterManager.installRunning &&
                                     modelData.brand.length > 0 &&
                                     modelData.driver.indexOf("Not installed") >= 0
                            onClicked: PrinterManager.installDriver(modelData.key)
                        }

                        Button {
                            text: PrinterManager.defaultPrinter === modelData.name
                                  ? "Default"
                                  : "Set default"
                            enabled: modelData.queued &&
                                     PrinterManager.defaultPrinter !== modelData.name
                            onClicked: PrinterManager.setDefaultPrinter(modelData.name)
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: printerList.count === 0
                    text: "No printers found. Connect a printer and refresh."
                    color: "#64748B"
                    font.pixelSize: Math.max(15, 18 * root.scale)
                }
            }
        }
    }

    Connections {
        target: PrinterManager

        function onPrinterConnected(printerName) {
            if (root.globalTopBar)
                root.globalTopBar.showNotification(
                            "Printer connected: " + printerName)
        }
    }
}
