import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import AppState 1.0
import "../components"

Item {
    id: root

    property bool showTopBar: true
    property var globalTopBar

    property string lastValidBatch: "General Batch"

    property bool batchRunning: false
    property bool batchPaused: false

    function notify(msg) {
        if (globalTopBar && globalTopBar.showNotification)
            globalTopBar.showNotification(msg)
    }

    opacity: 0
    Behavior on opacity { NumberAnimation { duration: 400 } }
    Component.onCompleted: opacity = 1

    Rectangle {
        anchors.fill: parent
        color: "#F5F7FC"

        RowLayout {
            anchors.fill: parent

            anchors.topMargin: showTopBar ? topBar.height : 20
            anchors.leftMargin: Math.min(35, parent.width * 0.05)
            anchors.rightMargin: Math.min(35, parent.width * 0.05)
            anchors.bottomMargin: Math.min(35, parent.height * 0.05)

            spacing: Math.min(30, parent.width * 0.03)

            Layout.minimumWidth: 600

            // =========== LEFT SIDE ===========
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                spacing: 10

                Column {
                    spacing: 4

                    Text {
                        text: "Batch Menu"
                        font.pixelSize: 18
                        font.bold: true
                        color: "#1A4DB5"
                    }

                    Rectangle {
                        width: 40
                        height: 3
                        radius: 2
                        color: "#1A4DB5"
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 16
                    color: "#FFFFFF"
                    border.color: "#E5E7EB"
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 24
                        spacing: 20

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.topMargin: Math.max(10, 20 * root.scale)
                            spacing: Math.max(6, 12 * root.scale)

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 48
                                radius: 10
                                color: "#F9FAFB"
                                border.color: inputField.activeFocus ? "#1A4DB5" : "#D1D5DB"
                                border.width: 1

                                Behavior on border.color { ColorAnimation { duration: 150 } }

                                TextField {
                                    id: inputField
                                    anchors.fill: parent
                                    anchors.margins: 10

                                    text: root.lastValidBatch
                                    font.pixelSize: 18
                                    color: "#1A4DB5"

                                    property bool isPasswordField: false

                                    focus: false
                                    activeFocusOnPress: true

                                    readOnly: root.batchRunning   // DISABLE WHILE RUNNING

                                    inputMethodHints: Qt.ImhNone  // important for Pi

                                    background: null
                                    padding: 0
                                    leftPadding: 0
                                    rightPadding: 0
                                    topPadding: 0
                                    bottomPadding: 0

                                    cursorVisible: activeFocus


                                    onActiveFocusChanged: {
                                        if (activeFocus) {
                                            GlobalState.activeInputField = inputField
                                            GlobalState.loginKeyboardRequest = true   // show keyboard
                                        }
                                    }


                                    MouseArea {
                                        anchors.fill: parent
                                        onPressed: {
                                            inputField.forceActiveFocus()
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

                                        inputField.focus = false
                                        inputField.readOnly = true
                                    }
                                }
                            }

                            Text {
                                text: "Edit"
                                font.pixelSize: 12
                                color: root.batchRunning ? "#9CA3AF" : "#1A4DB5"  // Visual feedback

                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: root.batchRunning ? Qt.ArrowCursor : Qt.PointingHandCursor

                                    enabled: !root.batchRunning   // DISABLE CLICK

                                    onClicked: {
                                        inputField.readOnly = false
                                        inputField.forceActiveFocus()
                                        inputField.selectAll()

                                        GlobalState.loginKeyboardRequest = true
                                    }
                                    Keys.onReturnPressed: {
                                        card.confirmed(text.trim())
                                        focus = false
                                    }

                                }
                            }
                        }

                        Item { Layout.fillHeight: true }

                        // ================= BUTTONS =================
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 20

                            Item { Layout.fillWidth: true }

                            // START
                            ActionButton {
                                text: "Batch Start"
                                width: 100
                                height: 50
                                bgColor: "#1A4DB5"
                                hoverColor: "#123A8A"

                                enabled: !root.batchRunning

                                onClicked: {
                                    root.batchRunning = true
                                    root.batchPaused = false
                                    root.notify("✓ Batch Start")
                                }
                            }

                            // PAUSE / RESUME
                            ActionButton {
                                text: root.batchPaused ? "Batch Resume" : "Batch Pause"
                                width: 110
                                height: 50
                                bgColor: "#1A4DB5"
                                hoverColor: "#123A8A"

                                enabled: root.batchRunning

                                onClicked: {
                                    root.batchPaused = !root.batchPaused
                                    root.notify(root.batchPaused ? "⏸ Paused" : "▶ Resumed")
                                }
                            }

                            // END
                            ActionButton {
                                text: "Batch End"
                                width: 100
                                height: 50
                                bgColor: "#1A4DB5"
                                hoverColor: "#123A8A"

                                enabled: root.batchRunning

                                onClicked: {
                                    root.batchRunning = false
                                    root.batchPaused = false
                                    root.notify("■ Batch End")
                                }
                            }

                            Item { Layout.fillWidth: true }
                        }

                        // ================= REPORT BUTTONS =================
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.topMargin: 20
                            spacing: 20

                            Item { Layout.fillWidth: true }

                            ActionButton {
                                text: "View Report"
                                width: 100
                                height: 50
                                bgColor: "#1A4DB5"
                                hoverColor: "#123A8A"
                                onClicked: root.notify("✓ View Report")
                            }

                            ActionButton {
                                text: "PDF Report"
                                width: 100
                                height: 50
                                bgColor: "#1A4DB5"
                                hoverColor: "#123A8A"
                                onClicked: root.notify("✓ PDF Report")
                            }

                            ActionButton {
                                text: "Print Report"
                                width: 100
                                height: 50
                                bgColor: "#1A4DB5"
                                hoverColor: "#123A8A"
                                onClicked: root.notify("✓ Print Report")
                            }

                            Item { Layout.fillWidth: true }
                        }

                        Item { Layout.fillHeight: true }
                    }
                }
            }

            // RIGHT SIDE
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                spacing: 10

                Column {
                    spacing: 4

                    Text {
                        text: "D Duster Menu"
                        font.pixelSize: 18
                        font.bold: true
                        color: "#1A4DB5"
                    }

                    Rectangle {
                        width: 40
                        height: 3
                        radius: 2
                        color: "#1A4DB5"
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 20

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 140
                        radius: 16
                        color: "#FFFFFF"
                        border.color: "#E5E7EB"
                        border.width: 1

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 20
                            spacing: 12

                            Text {
                                text: "DD ON/OFF"
                                font.pixelSize: 13
                                font.bold: true
                                color: "#6B7280"
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Item { Layout.fillHeight: true }

                            DDButton {
                                id: ddBtn
                                Layout.alignment: Qt.AlignHCenter

                                onToggledChanged: {
                                    root.notify(toggled ? "✓ DD ON" : "✓ DD OFF")
                                }
                            }

                            Item { Layout.fillHeight: true }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 16
                        color: "#FFFFFF"
                        border.color: "#E5E7EB"
                        border.width: 1

                        Text {
                            text: "Power (Volt)"
                            font.pixelSize: 13
                            font.bold: true
                            color: "#6B7280"
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.margins: 16
                        }

                        Item {
                            anchors.fill: parent

                            ValueControl {
                                anchors.centerIn: parent
                                anchors.verticalCenterOffset: -parent.height * 0.1
                                width: parent.width * 0.7

                                minValue: 0
                                maxValue: 100
                                value: 0

                                onSaveClicked: (val) => {
                                    root.notify("✓ DD Power Saved: " + val)
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 16
                        color: "#FFFFFF"
                        border.color: "#E5E7EB"
                        border.width: 1

                        Text {
                            text: "Frequency (Hz)"
                            font.pixelSize: 13
                            font.bold: true
                            color: "#6B7280"
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.margins: 16
                        }

                        Item {
                            anchors.fill: parent

                            ValueControl {
                                anchors.centerIn: parent
                                anchors.verticalCenterOffset: -parent.height * 0.1
                                width: parent.width * 0.7

                                minValue: 25
                                maxValue: 50
                                value: 25

                                onSaveClicked: (val) => {
                                    root.notify("✓ DD Frequency Saved: " + val)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
