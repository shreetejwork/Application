import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import AppState 1.0

import "../components"

Item {
    id: root

    implicitWidth: 1024
    implicitHeight: 600

    property bool showTopBar: true
    property var globalTopBar

    // scale system
    property real baseWidth: 1024
    property real baseHeight: 600
    property real scale: Math.min(width / baseWidth, height / baseHeight)

    property bool batchRunning: false
    property bool batchPaused: false

    property string lastValidBatch: "General Batch"
    property string lastValidProduct: "Default Product"

    function notify(msg) {
        if (root.globalTopBar && root.globalTopBar.showNotification) {
            root.globalTopBar.showNotification(msg)
        } else {
            console.log(msg) // fallback
        }
    }

    // ===== MAIN LAYOUT =====
    ColumnLayout {
        anchors.centerIn: parent

        anchors.verticalCenterOffset: GlobalState.loginKeyboardRequest
                                      ? -130 * root.scale
                                      : 0

        width: Math.min(parent.width * 0.75, 900)
        spacing: 20 * root.scale

        Behavior on anchors.verticalCenterOffset {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutQuad
            }
        }

        // ===== HEADER =====
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: "Batch Menu"
                font.pixelSize: 26 * root.scale
                font.bold: true
                color: "#1A4DB5"
            }

            Rectangle {
                width: 60
                height: 4
                radius: 2
                color: "#1A4DB5"
            }
        }

        // ===== CARD =====
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(root.height * 0.65, 480)

            radius: 22
            color: "#FFFFFF"
            border.color: "#E5E7EB"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 30 * root.scale
                spacing: 24 * root.scale

                // ===== INPUTS =====
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 18 * root.scale

                    // ===== BATCH =====
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6 * root.scale

                        Text {
                            text: "Batch Name"
                            font.pixelSize: 20 * root.scale
                            color: "#6B7280"
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 52
                                radius: 12
                                color: "#F9FAFB"
                                border.color: inputField.activeFocus ? "#1A4DB5" : "#D1D5DB"

                                TextField {
                                    id: inputField
                                    anchors.fill: parent
                                    anchors.margins: 12

                                    text: root.lastValidBatch
                                    font.pixelSize: 18
                                    color: "#1A4DB5"

                                    readOnly: root.batchRunning
                                    background: null

                                    onActiveFocusChanged: {
                                        if (activeFocus) {
                                            GlobalState.activeInputField = inputField
                                            GlobalState.loginKeyboardRequest = true
                                        }
                                    }

                                    onAccepted: {
                                        GlobalState.loginKeyboardRequest = false

                                        if (text.trim() === "") {
                                            text = "General Batch"
                                            root.notify("⚠ Empty not allowed")
                                        } else {
                                            root.lastValidBatch = text
                                            root.notify("✓ Batch Updated")
                                        }

                                        focus = false
                                        readOnly = true
                                    }
                                }
                            }

                            Text {
                                text: "Edit"
                                Layout.preferredWidth: 60
                                verticalAlignment: Text.AlignVCenter
                                font.pixelSize: 14
                                color: root.batchRunning ? "#9CA3AF" : "#2563EB"

                                MouseArea {
                                    anchors.fill: parent
                                    enabled: !root.batchRunning
                                    cursorShape: Qt.PointingHandCursor

                                    onClicked: {
                                        inputField.readOnly = false
                                        inputField.forceActiveFocus()
                                        inputField.selectAll()
                                        GlobalState.loginKeyboardRequest = true
                                    }
                                }
                            }
                        }
                    }

                    // ===== PRODUCT =====
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6 * root.scale

                        Text {
                            text: "Product Name"
                            font.pixelSize: 20 * root.scale
                            color: "#6B7280"
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 52
                                radius: 12
                                color: "#F9FAFB"
                                border.color: productField.activeFocus ? "#1A4DB5" : "#D1D5DB"

                                TextField {
                                    id: productField
                                    anchors.fill: parent
                                    anchors.margins: 12

                                    text: root.lastValidProduct
                                    font.pixelSize: 18
                                    color: "#1A4DB5"

                                    readOnly: root.batchRunning
                                    background: null

                                    onActiveFocusChanged: {
                                        if (activeFocus) {
                                            GlobalState.activeInputField = productField
                                            GlobalState.loginKeyboardRequest = true
                                        }
                                    }

                                    onAccepted: {
                                        GlobalState.loginKeyboardRequest = false

                                        if (text.trim() === "") {
                                            text = "Default Product"
                                            root.notify("⚠ Empty not allowed")
                                        } else {
                                            root.lastValidProduct = text
                                            root.notify("✓ Product Updated")
                                        }

                                        focus = false
                                        readOnly = true
                                    }
                                }
                            }

                            Text {
                                text: "Edit"
                                Layout.preferredWidth: 60
                                verticalAlignment: Text.AlignVCenter
                                font.pixelSize: 14
                                color: root.batchRunning ? "#9CA3AF" : "#2563EB"

                                MouseArea {
                                    anchors.fill: parent
                                    enabled: !root.batchRunning

                                    onClicked: {
                                        productField.readOnly = false
                                        productField.forceActiveFocus()
                                        productField.selectAll()
                                        GlobalState.loginKeyboardRequest = true
                                    }
                                }
                            }
                        }
                    }
                }

                // ===== BUTTONS =====
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 20

                    Item { Layout.fillWidth: true }

                    ActionButton {
                        text: "Batch Start"
                        width: 130
                        height: 50
                        enabled: !root.batchRunning

                        onClicked: {
                            root.batchRunning = true
                            root.batchPaused = false
                            root.notify("✓ Batch Start")
                        }
                    }

                    ActionButton {
                        text: root.batchPaused ? "Batch Resume" : "Batch Pause"
                        width: 120
                        height: 50
                        enabled: root.batchRunning

                        onClicked: {
                            root.batchPaused = !root.batchPaused
                            root.notify(root.batchPaused ? "⏸ Paused" : "▶ Resumed")
                        }
                    }

                    ActionButton {
                        text: "Batch End"
                        width: 110
                        height: 50
                        enabled: root.batchRunning

                        onClicked: {
                            root.batchRunning = false
                            root.batchPaused = false
                            root.notify("■ Batch End")
                        }
                    }

                    Item { Layout.fillWidth: true }
                }
            }
        }
    }
}
