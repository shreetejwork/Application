import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

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

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2 * root.scale

                Text {
                    text: "Printer Settings"
                    color: "#1A4DB5"
                    font.pixelSize: Math.max(24, 30 * root.scale)
                }

                Text {
                    text: "Manage connected printers, drivers, and the system default"
                    color: "#64748B"
                    font.pixelSize: Math.max(12, 14 * root.scale)
                }
            }

            RowLayout {
                spacing: 8 * root.scale

                WaveformControlButton {
                    text: PrinterManager.printerSearchEnabled
                          ? "Search: On"
                          : "Search: Off"
                    accent: PrinterManager.printerSearchEnabled
                            ? "#16804A" : "#64748B"
                    selected: PrinterManager.printerSearchEnabled
                    labelPixelSize: Math.max(13, 15 * root.scale)
                    Layout.preferredWidth: 112 * root.scale
                    Layout.preferredHeight: 38 * root.scale
                    onClicked: PrinterManager.setPrinterSearchEnabled(
                                   !PrinterManager.printerSearchEnabled)
                }

                WaveformControlButton {
                    text: "Refresh"
                    accent: "#1A4DB5"
                    labelPixelSize: Math.max(13, 15 * root.scale)
                    Layout.preferredWidth: 100 * root.scale
                    Layout.preferredHeight: 38 * root.scale
                    onClicked: PrinterManager.refresh()
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 42 * root.scale
            radius: 6
            color: "#EEF4FF"
            border.color: "#D8E5FC"

            Text {
                anchors.fill: parent
                anchors.leftMargin: 12 * root.scale
                anchors.rightMargin: 12 * root.scale
                text: PrinterManager.status
                color: "#334155"
                font.pixelSize: Math.max(13, 15 * root.scale)
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.Wrap
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 38 * root.scale
            radius: 6
            color: "#ECFDF3"
            border.color: "#C9EBD8"

            Text {
                anchors.fill: parent
                anchors.leftMargin: 12 * root.scale
                text: PrinterManager.defaultPrinter.length > 0
                      ? "Default printer: " + PrinterManager.defaultPrinter
                      : "No system default printer"
                color: "#16804A"
                font.pixelSize: Math.max(14, 16 * root.scale)
                font.weight: Font.Medium
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
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
                    height: 102 * root.scale
                    radius: 8
                    color: "#FFFFFF"
                    border.color: "#D8E0EF"

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

                        WaveformControlButton {
                            text: PrinterManager.installRunning
                                  ? "Installing..."
                                  : "Install driver"
                            accent: "#1A4DB5"
                            labelPixelSize: Math.max(11, 13 * root.scale)
                            Layout.preferredWidth: 112 * root.scale
                            Layout.preferredHeight: 36 * root.scale
                            enabled: !PrinterManager.installRunning &&
                                     modelData.brand.length > 0 &&
                                     modelData.driver.indexOf("Not installed") >= 0
                            onClicked: PrinterManager.installDriver(modelData.key)
                        }

                        WaveformControlButton {
                            text: PrinterManager.defaultPrinter === modelData.name
                                  ? "Default"
                                  : "Set default"
                            accent: "#16804A"
                            selected: PrinterManager.defaultPrinter === modelData.name
                            labelPixelSize: Math.max(11, 13 * root.scale)
                            Layout.preferredWidth: 104 * root.scale
                            Layout.preferredHeight: 36 * root.scale
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
