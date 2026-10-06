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
    property string currentBatchId: "General Batch"
    property int activeBatchReportId: -1
    property int batchRejectionCount: 0
    property int rejectionCountAtLastBuffer: 0
    property var batchStartDateTime: null
    property var batchPauseStartTime: null
    property int batchRunSeconds: 0
    property int batchPauseSeconds: 0

    function isAuthorized() {
        if (GlobalState.loggedInUserRole !== ""
                || GlobalState.developerLogin
                || GlobalState.engineerLogin)
            return true

        accessDeniedPopup.popupTitle = "Access Denied !"
        accessDeniedPopup.popupMessage = "Please login first"
        accessDeniedPopup.open()
        return false
    }

    function notify(msg) {
        if (root.globalTopBar && root.globalTopBar.showNotification) {
            root.globalTopBar.showNotification(msg)
        } else {
            console.log(msg) // fallback
        }
    }

    function getAuditUser() {
        if (GlobalState.loggedInUserRole === ""
                || GlobalState.loggedInUserName === "")
            return "---"

        var initial = "U"
        if (GlobalState.loggedInUserRole === "Admin")
            initial = "A"
        else if (GlobalState.loggedInUserRole === "Supervisor")
            initial = "S"
        else if (GlobalState.loggedInUserRole === "Operator")
            initial = "O"
        return initial + "/" + GlobalState.loggedInUserName
    }

    function flushPendingBatchRejections(eventTime, auditUser) {
        if (root.activeBatchReportId <= 0)
            return false

        var count = Number(GlobalState.activeBatchRejectCount)
        var delta = count - root.rejectionCountAtLastBuffer
        if (delta <= 0)
            return true

        if (databaseManager.addBatchReportEvent(
                    root.activeBatchReportId,
                    "REJECT",
                    Qt.formatDateTime(eventTime, "dd/MM/yyyy HH:mm:ss"),
                    auditUser,
                    delta)) {
            root.batchRejectionCount += delta
            root.rejectionCountAtLastBuffer = count
            return true
        } else {
            return false
        }
    }

    function startBatch() {
        if (!root.isAuthorized())
            return

        var loadedProduct = databaseManager.getActiveProduct()
        if (!loadedProduct || loadedProduct.name === undefined) {
            root.notify("⚠ No product loaded")
            return
        }

        var startTime = new Date()
        var user = root.getAuditUser()
        var batchId = root.lastValidBatch
        var productName = String(loadedProduct.name)
        var productCode = String(loadedProduct.code)
        var groupNo = Number(loadedProduct.groupNo)
        var productSno = "G" + String(groupNo).padStart(2, "0")
                           + "/" + String(loadedProduct.sr)
        var reportId = databaseManager.createBatchReport(
                    batchId,
                    productName,
                    productCode,
                    productSno,
                    Qt.formatDateTime(startTime, "dd/MM/yyyy HH:mm:ss"),
                    user)

        if (reportId <= 0) {
            root.notify("⚠ Unable to create batch report")
            return
        }

        root.currentBatchId = batchId
        root.activeBatchReportId = reportId
        root.batchStartDateTime = startTime
        root.batchRunSeconds = 0
        root.batchPauseSeconds = 0
        root.batchPauseStartTime = null
        root.batchRejectionCount = 0
        GlobalState.activeBatchRejectCount = 0
        root.rejectionCountAtLastBuffer = 0
        root.batchRunning = true
        root.batchPaused = false
        GlobalState.batchRunning = true
        GlobalState.batchPaused = false

        var startEventSaved = databaseManager.addBatchReportEvent(
                    reportId,
                    "START",
                    Qt.formatDateTime(startTime, "dd/MM/yyyy HH:mm:ss"),
                    user,
                    0)

        SerialManager.setBatch(1)
        batchTimer.start()
        rejectionBufferTimer.start()
        root.notify(startEventSaved
                    ? "✓ Batch Start"
                    : "⚠ Batch started, but the start event could not be saved")
    }

    function toggleBatchPause() {
        if (!root.isAuthorized())
            return

        var eventTime = new Date()
        var user = root.getAuditUser()
        if (!root.batchPaused) {
            var rejectionsSaved = root.flushPendingBatchRejections(eventTime, user)
            root.batchPaused = true
            GlobalState.batchPaused = true
            root.batchPauseStartTime = eventTime
            var pauseSaved = databaseManager.addBatchReportEvent(
                        root.activeBatchReportId,
                        "PAUSE",
                        Qt.formatDateTime(eventTime, "dd/MM/yyyy HH:mm:ss"),
                        user)
            SerialManager.setBatch(2)
            root.notify(rejectionsSaved && pauseSaved
                        ? "⏸ Batch Paused"
                        : "⚠ Batch paused, but report data could not be fully saved")
            return
        }

        if (root.batchPauseStartTime !== null) {
            root.batchPauseSeconds += Math.floor(
                        (eventTime.getTime()
                         - root.batchPauseStartTime.getTime()) / 1000)
        }
        root.batchPauseStartTime = null
        root.batchPaused = false
        GlobalState.batchPaused = false
        root.rejectionCountAtLastBuffer = Math.max(
                    root.rejectionCountAtLastBuffer,
                    Number(GlobalState.activeBatchRejectCount))
        var resumeSaved = databaseManager.addBatchReportEvent(
                    root.activeBatchReportId,
                    "RESUME",
                    Qt.formatDateTime(eventTime, "dd/MM/yyyy HH:mm:ss"),
                    user)
        SerialManager.setBatch(1)
        root.notify(resumeSaved
                    ? "▶ Batch Resumed"
                    : "⚠ Batch resumed, but the resume event could not be saved")
    }

    function endBatch() {
        if (!root.isAuthorized())
            return

        var endTime = new Date()
        var user = root.getAuditUser()
        if (root.batchPaused && root.batchPauseStartTime !== null) {
            root.batchPauseSeconds += Math.floor(
                        (endTime.getTime()
                         - root.batchPauseStartTime.getTime()) / 1000)
        }

        var rejectionsSaved = root.flushPendingBatchRejections(endTime, user)
        var endText = Qt.formatDateTime(endTime, "dd/MM/yyyy HH:mm:ss")
        var totalSeconds = root.batchStartDateTime
                           ? Math.floor((endTime.getTime()
                                         - root.batchStartDateTime.getTime()) / 1000)
                           : root.batchRunSeconds
        var eventSaved = databaseManager.addBatchReportEvent(
                    root.activeBatchReportId, "END", endText, user)
        var reportSaved = databaseManager.finishBatchReport(
                    root.activeBatchReportId,
                    endText,
                    root.batchRunSeconds,
                    root.batchPauseSeconds,
                    totalSeconds,
                    user,
                    root.batchRejectionCount)

        batchTimer.stop()
        rejectionBufferTimer.stop()
        root.batchRunning = false
        root.batchPaused = false
        GlobalState.batchRunning = false
        GlobalState.batchPaused = false
        GlobalState.activeBatchRejectCount = 0
        root.batchPauseStartTime = null
        root.batchRejectionCount = 0
        root.rejectionCountAtLastBuffer = 0
        root.activeBatchReportId = -1
        root.batchStartDateTime = null
        root.lastValidBatch = "General Batch"
        root.currentBatchId = "General Batch"
        inputField.text = "General Batch"
        SerialManager.setBatch(0)
        root.notify(eventSaved && reportSaved && rejectionsSaved
                    ? "■ Batch End"
                    : "⚠ Batch ended, but report data could not be fully saved")
    }

    Timer {
        id: batchTimer
        interval: 1000
        repeat: true
        onTriggered: {
            if (root.batchRunning && !root.batchPaused)
                root.batchRunSeconds++
        }
    }

    Timer {
        id: rejectionBufferTimer
        interval: 60 * 1000
        repeat: true
        onTriggered: {
            if (root.batchRunning && !root.batchPaused
                    && !root.flushPendingBatchRejections(
                        new Date(), root.getAuditUser()))
                root.notify("⚠ Unable to save batch rejection event")
        }
    }

    // ===== MAIN LAYOUT =====
    ColumnLayout {
        anchors.centerIn: parent

        anchors.verticalCenterOffset: GlobalState.loginKeyboardRequest
                                      ? -130 * root.scale
                                      : 0

        width: Math.min(parent.width * 0.82, 900)
        spacing: 18 * root.scale

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
            Layout.preferredHeight: Math.min(root.height * 0.68, 480)

            radius: 22
            color: "#FFFFFF"
            border.color: "#E5E7EB"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 26 * root.scale
                spacing: 20 * root.scale

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
                                    property bool batchNameEditing: false

                                    focus: false
                                    activeFocusOnPress: true
                                    readOnly: root.batchRunning || !batchNameEditing
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

                                        batchNameEditing = false
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
                                            if (!root.isAuthorized())
                                                return

                                            if (root.batchRunning)
                                                return

                                            inputField.batchNameEditing = true
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
                                        if (!root.isAuthorized())
                                            return

                                        inputField.batchNameEditing = true
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
                                            if (!root.isAuthorized())
                                                return

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
                                        if (!root.isAuthorized())
                                            return

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
                    spacing: 14 * root.scale

                    ActionButton {
                        text: "Batch Start"
                        Layout.fillWidth: true
                        Layout.preferredWidth: 150 * root.scale
                        Layout.minimumWidth: 130 * root.scale
                        Layout.preferredHeight: 56 * root.scale
                        font.pixelSize: Math.max(14, 16 * root.scale)
                        bgColor: "#1A4DB5"
                        hoverColor: "#123A8A"
                        enabled: !root.batchRunning

                        onClicked: {
                            root.startBatch()
                        }
                    }

                    ActionButton {
                        text: root.batchPaused ? "Batch Resume" : "Batch Pause"
                        Layout.fillWidth: true
                        Layout.preferredWidth: 180 * root.scale
                        Layout.minimumWidth: 160 * root.scale
                        Layout.preferredHeight: 56 * root.scale
                        font.pixelSize: Math.max(14, 16 * root.scale)
                        bgColor: root.batchPaused ? "#22A447" : "#1A4DB5"
                        hoverColor: root.batchPaused ? "#188638" : "#123A8A"
                        enabled: root.batchRunning

                        onClicked: {
                            root.toggleBatchPause()
                        }
                    }

                    ActionButton {
                        text: "Batch End"
                        Layout.fillWidth: true
                        Layout.preferredWidth: 150 * root.scale
                        Layout.minimumWidth: 130 * root.scale
                        Layout.preferredHeight: 56 * root.scale
                        font.pixelSize: Math.max(14, 16 * root.scale)
                        bgColor: "#1A4DB5"
                        hoverColor: "#123A8A"
                        enabled: root.batchRunning

                        onClicked: {
                            root.endBatch()
                        }
                    }
                }
            }
        }
    }
}
