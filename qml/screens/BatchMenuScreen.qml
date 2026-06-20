import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import AppState 1.0

import Backend 1.0

import "../components"

Item {
    id: root

    implicitWidth: 1024
    implicitHeight: 600

    property bool showTopBar: true
    property var globalTopBar

    AccessDeniedPopup {
        id: accessDeniedPopup
    }

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
                font.pixelSize: 26

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
                            font.pixelSize: 20
                            color: "#6B7280"
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

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
                                    readOnly: root.batchRunning
                                    inputMethodHints: Qt.ImhNone

                                    background: null
                                    padding: 0
                                    leftPadding: 0
                                    rightPadding: 0
                                    topPadding: 0
                                    bottomPadding: 0

                                    cursorVisible: activeFocus

                                    function saveBatch()
                                    {
                                        GlobalState.loginKeyboardRequest = false

                                        if (text.trim() === "") {
                                            text = "General Batch"
                                            root.lastValidBatch = text
                                            root.notify("⚠ Empty not allowed")
                                        } else {
                                            root.lastValidBatch = text.trim()
                                            text = root.lastValidBatch
                                            root.notify("✓ Batch Updated")
                                        }

                                        readOnly = true
                                        focus = false
                                    }

                                    onActiveFocusChanged: {
                                        if (activeFocus) {
                                            GlobalState.activeInputField = inputField
                                            GlobalState.loginKeyboardRequest = true

                                            Qt.callLater(function() {
                                                inputField.selectAll()
                                            })
                                        } else if (!readOnly) {
                                            saveBatch()
                                        }
                                    }

                                    onAccepted: {
                                        saveBatch()
                                    }

                                    MouseArea {
                                        anchors.fill: parent

                                        onPressed: {

                                            if (GlobalState.loggedInUserRole === "")
                                            {
                                                accessDeniedPopup.popupTitle = "Access Denied !"

                                                accessDeniedPopup.popupMessage =
                                                        "Please login first"

                                                accessDeniedPopup.open()
                                                return
                                            }

                                            inputField.forceActiveFocus()
                                        }
                                    }
                                }
                            }

                            Item {
                                id: editButton

                                width: editRow.implicitWidth
                                height: editRow.implicitHeight

                                Row {
                                    id: editRow
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Image {
                                        source: "qrc:/qt/qml/Application/assets/images/edit.png"
                                        width: 16
                                        height: 16

                                        opacity: root.batchRunning ? 0.5 : 1.0

                                        fillMode: Image.PreserveAspectFit
                                        smooth: true
                                    }

                                    Text {
                                        text: "Edit"
                                        font.pixelSize: 15
                                        color: root.batchRunning ? "#9CA3AF" : "#1A4DB5"

                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent

                                    cursorShape: root.batchRunning
                                                 ? Qt.ArrowCursor
                                                 : Qt.PointingHandCursor

                                    enabled: !root.batchRunning

                                    onClicked: {

                                        if (GlobalState.loggedInUserRole === "")
                                        {
                                            accessDeniedPopup.popupTitle = "Access Denied !"

                                            accessDeniedPopup.popupMessage =
                                                    "Please login first"

                                            accessDeniedPopup.open()
                                            return
                                        }

                                        inputField.readOnly = false
                                        inputField.forceActiveFocus()

                                        Qt.callLater(function() {
                                            inputField.selectAll()
                                        })
                                    }
                                }
                            }
                        }
                    }

                    // ===== PRODUCT =====
                    ColumnLayout {
                        Layout.fillWidth: true

                        visible: !GlobalState.showProductLib

                        Layout.preferredHeight: visible ? implicitHeight : 0

                        spacing: 6 * root.scale

                        Text {
                            text: "Product Name"
                            font.pixelSize: 20
                            color: "#6B7280"
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 48
                                radius: 10
                                color: "#F9FAFB"
                                border.color: productField.activeFocus ? "#1A4DB5" : "#D1D5DB"
                                border.width: 1

                                Behavior on border.color { ColorAnimation { duration: 150 } }

                                TextField {
                                    id: productField
                                    anchors.fill: parent
                                    anchors.margins: 10

                                    text: root.lastValidProduct
                                    font.pixelSize: 18
                                    color: "#1A4DB5"

                                    property bool isPasswordField: false

                                    focus: false
                                    activeFocusOnPress: true
                                    readOnly: root.batchRunning
                                    inputMethodHints: Qt.ImhNone

                                    background: null
                                    padding: 0
                                    leftPadding: 0
                                    rightPadding: 0
                                    topPadding: 0
                                    bottomPadding: 0

                                    cursorVisible: activeFocus

                                    function saveProduct()
                                    {
                                        GlobalState.loginKeyboardRequest = false

                                        if (text.trim() === "") {
                                            text = "Default Product"
                                            root.lastValidProduct = text
                                            root.notify("⚠ Empty not allowed")
                                        } else {
                                            root.lastValidProduct = text.trim()
                                            text = root.lastValidProduct
                                            root.notify("✓ Product Updated")
                                        }

                                        readOnly = true
                                        focus = false
                                    }

                                    onActiveFocusChanged: {
                                        if (activeFocus) {
                                            GlobalState.activeInputField = productField
                                            GlobalState.loginKeyboardRequest = true

                                            Qt.callLater(function() {
                                                productField.selectAll()
                                            })
                                        } else if (!readOnly) {
                                            saveProduct()
                                        }
                                    }

                                    onAccepted: {
                                        saveProduct()
                                    }

                                    MouseArea {
                                        anchors.fill: parent

                                        onPressed: {

                                            if (GlobalState.loggedInUserRole === "")
                                            {
                                                accessDeniedPopup.popupTitle = "Access Denied !"

                                                accessDeniedPopup.popupMessage =
                                                        "Please login first"

                                                accessDeniedPopup.open()
                                                return
                                            }

                                            productField.forceActiveFocus()
                                        }
                                    }
                                }
                            }

                            Item {
                                width: productEditRow.implicitWidth
                                height: productEditRow.implicitHeight

                                Row {
                                    id: productEditRow
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Image {
                                        source: "qrc:/qt/qml/Application/assets/images/edit.png"
                                        width: 16
                                        height: 16

                                        fillMode: Image.PreserveAspectFit
                                        smooth: true

                                        opacity: root.batchRunning ? 0.5 : 1.0
                                    }

                                    Text {
                                        text: "Edit"
                                        font.pixelSize: 15
                                        color: root.batchRunning ? "#9CA3AF" : "#1A4DB5"

                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent

                                    cursorShape: root.batchRunning
                                                 ? Qt.ArrowCursor
                                                 : Qt.PointingHandCursor

                                    enabled: !root.batchRunning

                                    onClicked: {

                                        if (GlobalState.loggedInUserRole === "")
                                        {
                                            accessDeniedPopup.popupTitle = "Access Denied !"

                                            accessDeniedPopup.popupMessage =
                                                    "Please login first"

                                            accessDeniedPopup.open()
                                            return
                                        }

                                        productField.readOnly = false
                                        productField.forceActiveFocus()

                                        Qt.callLater(function() {
                                            productField.selectAll()
                                        })
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
                        width: 100
                        height: 50
                        enabled: !root.batchRunning

                        onClicked: {
                            root.batchRunning = true
                            root.batchPaused = false

                            SerialManager.setBatch(1)

                            root.notify("✓ Batch Start")
                        }
                    }

                    ActionButton {
                        text: root.batchPaused ? "Batch Resume" : "Batch Pause"
                        width: 110
                        height: 50
                        enabled: root.batchRunning

                        onClicked: {
                            root.batchPaused = !root.batchPaused

                            if (root.batchPaused)
                                SerialManager.setBatch(2)
                            else
                                SerialManager.setBatch(1)

                            root.notify(root.batchPaused ? "⏸ Paused" : "▶ Resumed")
                        }
                    }

                    ActionButton {
                        text: "Batch End"
                        width: 100
                        height: 50
                        enabled: root.batchRunning

                        onClicked: {
                            root.batchRunning = false
                            root.batchPaused = false

                            SerialManager.setBatch(0)

                            root.notify("■ Batch End")
                        }
                    }

                    Item { Layout.fillWidth: true }
                }
            }
        }
    }
}
