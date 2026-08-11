import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import AppState 1.0

import Backend 1.0



import "../components"

Item {
    id: root

    property bool showTopBar: true
    property var globalTopBar

    property string lastValidBatch: "General Batch"
    property string lastValidProduct: "Default Product"

    property int previousDDPower: 0
    property real previousDDFrequency: 25.0

    property int ddPower: 0
    property real ddFrequency: 25.0

    property bool batchRunning: false
    property bool batchPaused: false

    property int activeBatchReportId: -1

    property var batchStartDateTime: null
    property var batchEndDateTime: null

    property int batchRunSeconds: 0
    property int batchPauseSeconds: 0

    property var batchPauseStartTime: null

    property string currentBatchId: "General Batch"
    property string currentProductName: "Default Product"
    property string currentProductCode: "default code"
    property string currentProductSno: "01-001"

    function notify(msg) {
        if (globalTopBar && globalTopBar.showNotification)
            globalTopBar.showNotification(msg)
    }

    function getAuditUser()
    {
        if (GlobalState.loggedInUserRole !== "" &&
            GlobalState.loggedInUserName !== "")
        {
            var initial = "U"

            if (GlobalState.loggedInUserRole === "Admin")
                initial = "A"
            else if (GlobalState.loggedInUserRole === "Supervisor")
                initial = "S"
            else if (GlobalState.loggedInUserRole === "Operator")
                initial = "O"

            return initial + "/" + GlobalState.loggedInUserName
        }

        return "---"
    }


    function saveDDAudit(action, oldValue, newValue)
    {
        var auditUser = "---"

        if (GlobalState.loggedInUserRole !== "" &&
            GlobalState.loggedInUserName !== "")
        {
            var initial = "U"

            if (GlobalState.loggedInUserRole === "Admin")
                initial = "A"
            else if (GlobalState.loggedInUserRole === "Supervisor")
                initial = "S"
            else if (GlobalState.loggedInUserRole === "Operator")
                initial = "O"

            auditUser = initial + "/" + GlobalState.loggedInUserName
        }


        databaseManager.addAuditTrailRecord(
            auditUser,
            oldValue !== undefined ? String(oldValue) : "",
            newValue !== undefined ? String(newValue) : "",
            action
        )
    }

    function currentDateTime()
    {
        return Qt.formatDateTime(
            new Date(),
            "dd/MM/yyyy HH:mm:ss"
        )
    }

    Timer {
        id: batchTimer

        interval: 1000
        repeat: true

        onTriggered: {

            if (!root.batchRunning)
                return

            if (root.batchPaused)
                return

            root.batchRunSeconds++
        }
    }

    AccessDeniedPopup {
        id: accessDeniedPopup
    }

    opacity: 0
    Behavior on opacity { NumberAnimation { duration: 400 } }

    function loadDDSettings()
    {
        var settings = databaseManager.getDDSettings()

        if (settings.ddPower !== undefined)
            ddPower = settings.ddPower

        if (settings.ddFreq !== undefined)
            ddFrequency = settings.ddFreq

        console.log(
            "DD settings reloaded:",
            "Power =", ddPower,
            "Frequency =", ddFrequency
        )
    }

    Component.onCompleted: {

        opacity = 1

        loadDDSettings()
    }

    Connections {
        target: databaseManager

        function onMachineParametersChanged()
        {
            console.log(
                "machineparameters changed -> DD screen reload"
            )

            root.loadDDSettings()
        }
    }

    Rectangle {
    Typography {
        id: screenTypography
        scale: root.scale || 1.0
    }
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

                        ColumnLayout {
                            Layout.fillWidth: true

                            // ===== BATCH FIELD  =====
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

                                                if (GlobalState.loggedInUserRole === ""
                                                        && !GlobalState.developerLogin
                                                        && !GlobalState.engineerLogin)
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

                                            if (GlobalState.loggedInUserRole === ""
                                                    && !GlobalState.developerLogin
                                                    && !GlobalState.engineerLogin)
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

                            // ===== PRODUCT FIELD =====
                            RowLayout {
                                Layout.fillWidth: true
                                Layout.topMargin: Math.max(20, 30 * root.scale)

                                visible: !GlobalState.showProductLib

                                Layout.preferredHeight: visible ? implicitHeight : 0

                                spacing: Math.max(6, 12 * root.scale)

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

                                                if (GlobalState.loggedInUserRole === ""
                                                        && !GlobalState.developerLogin
                                                        && !GlobalState.engineerLogin)
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

                                            if (GlobalState.loggedInUserRole === ""
                                                    && !GlobalState.developerLogin
                                                    && !GlobalState.engineerLogin)
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



                        // ================= BUTTONS =================
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 20

                            Item { Layout.fillWidth: true }

                            // START
                            ActionButton {
                                text: "Batch Start"
                                width: 100
                                height: 60
                                bgColor: "#1A4DB5"
                                hoverColor: "#123A8A"

                                font.pixelSize : 18

                                enabled: !root.batchRunning

                                onClicked: {

                                    if (GlobalState.loggedInUserRole === ""
                                            && !GlobalState.developerLogin
                                            && !GlobalState.engineerLogin)
                                    {
                                        accessDeniedPopup.popupTitle = "Access Denied !"

                                        accessDeniedPopup.popupMessage =
                                                "Please login first"

                                        accessDeniedPopup.open()
                                        return
                                    }

                                    root.batchRunning = true
                                    root.batchPaused = false

                                    root.batchStartDateTime = new Date()

                                    root.batchRunSeconds = 0
                                    root.batchPauseSeconds = 0

                                    root.batchPauseStartTime = null


                                    // =====================================================
                                    // DEFAULT VALUES
                                    // =====================================================

                                    var batchName = inputField.text.trim()

                                    if (batchName === "")
                                        batchName = "General Batch"

                                    var productName = productField.text.trim()

                                    if (productName === "")
                                        productName = "Default Product"


                                    root.currentBatchId = batchName
                                    root.currentProductName = productName
                                    root.currentProductCode = "default code"
                                    root.currentProductSno = "01-001"


                                    // =====================================================
                                    // CREATE BATCH REPORT
                                    // =====================================================

                                    var auditUser = getAuditUser()

                                    root.activeBatchReportId =
                                            databaseManager.createBatchReport(
                                                root.currentBatchId,
                                                root.currentProductName,
                                                root.currentProductCode,
                                                root.currentProductSno,
                                                Qt.formatDateTime(
                                                    root.batchStartDateTime,
                                                    "dd/MM/yyyy HH:mm:ss"
                                                ),
                                                auditUser
                                            )


                                    // =====================================================
                                    // START EVENT
                                    // =====================================================

                                    if (root.activeBatchReportId > 0)
                                    {
                                        databaseManager.addBatchReportEvent(
                                            root.activeBatchReportId,
                                            "START",
                                            Qt.formatDateTime(
                                                root.batchStartDateTime,
                                                "dd/MM/yyyy HH:mm:ss"
                                            ),
                                            auditUser
                                        )
                                    }


                                    // =====================================================
                                    // MCU
                                    // =====================================================

                                    SerialManager.setBatch(1)

                                    batchTimer.start()

                                    root.notify("✓ Batch Start")
                                }
                            }

                            // PAUSE / RESUME
                            ActionButton {
                                text: root.batchPaused ? "Batch Resume" : "Batch Pause"
                                width: 110
                                height: 60
                                bgColor: "#1A4DB5"
                                hoverColor: "#123A8A"

                                enabled: root.batchRunning

                                font.pixelSize : 18

                                onClicked: {

                                    if (GlobalState.loggedInUserRole === ""
                                            && !GlobalState.developerLogin
                                            && !GlobalState.engineerLogin)
                                    {
                                        accessDeniedPopup.popupTitle = "Access Denied !"

                                        accessDeniedPopup.popupMessage =
                                                "Please login first"

                                        accessDeniedPopup.open()
                                        return
                                    }

                                    root.batchPaused = !root.batchPaused

                                    var auditUser = getAuditUser()
                                    var eventTime = new Date()


                                    if (root.batchPaused)
                                    {
                                        // =================================================
                                        // PAUSE
                                        // =================================================

                                        root.batchPauseStartTime = eventTime

                                        databaseManager.addBatchReportEvent(
                                            root.activeBatchReportId,
                                            "PAUSE",
                                            Qt.formatDateTime(
                                                eventTime,
                                                "dd/MM/yyyy HH:mm:ss"
                                            ),
                                            auditUser
                                        )

                                        SerialManager.setBatch(2)

                                        root.notify("⏸ Batch Paused")
                                    }
                                    else
                                    {
                                        // =================================================
                                        // RESUME
                                        // =================================================

                                        if (root.batchPauseStartTime !== null)
                                        {
                                            var pauseSeconds =
                                                    Math.floor(
                                                        (eventTime.getTime() -
                                                         root.batchPauseStartTime.getTime()) / 1000
                                                    )

                                            root.batchPauseSeconds += pauseSeconds
                                        }

                                        root.batchPauseStartTime = null

                                        databaseManager.addBatchReportEvent(
                                            root.activeBatchReportId,
                                            "RESUME",
                                            Qt.formatDateTime(
                                                eventTime,
                                                "dd/MM/yyyy HH:mm:ss"
                                            ),
                                            auditUser
                                        )

                                        SerialManager.setBatch(1)

                                        root.notify("▶ Batch Resumed")
                                    }
                                }
                            }

                            // END
                            ActionButton {
                                text: "Batch End"
                                width: 100
                                height: 60
                                bgColor: "#1A4DB5"
                                hoverColor: "#123A8A"

                                enabled: root.batchRunning

                                font.pixelSize : 18

                                onClicked: {

                                    if (GlobalState.loggedInUserRole === ""
                                            && !GlobalState.developerLogin
                                            && !GlobalState.engineerLogin)
                                    {
                                        accessDeniedPopup.popupTitle = "Access Denied !"

                                        accessDeniedPopup.popupMessage =
                                                "Please login first"

                                        accessDeniedPopup.open()
                                        return
                                    }

                                    var endTime = new Date()
                                    var auditUser = getAuditUser()


                                    // =====================================================
                                    // IF CURRENTLY PAUSED
                                    // =====================================================

                                    if (root.batchPaused &&
                                        root.batchPauseStartTime !== null)
                                    {
                                        var finalPauseSeconds =
                                                Math.floor(
                                                    (endTime.getTime() -
                                                     root.batchPauseStartTime.getTime()) / 1000
                                                )

                                        root.batchPauseSeconds += finalPauseSeconds
                                    }


                                    // =====================================================
                                    // TOTAL DURATION
                                    // =====================================================

                                    var totalDuration =
                                            Math.floor(
                                                (endTime.getTime() -
                                                 root.batchStartDateTime.getTime()) / 1000
                                            )


                                    // =====================================================
                                    // SAVE END EVENT
                                    // =====================================================

                                    databaseManager.addBatchReportEvent(
                                        root.activeBatchReportId,
                                        "END",
                                        Qt.formatDateTime(
                                            endTime,
                                            "dd/MM/yyyy HH:mm:ss"
                                        ),
                                        auditUser
                                    )


                                    // =====================================================
                                    // FINISH BATCH REPORT
                                    // =====================================================

                                    var rejectionCount = 0

                                    // Replace this with your actual rejection counter
                                    // when the batch rejection integration is available.

                                    databaseManager.finishBatchReport(
                                        root.activeBatchReportId,
                                        Qt.formatDateTime(
                                            endTime,
                                            "dd/MM/yyyy HH:mm:ss"
                                        ),
                                        root.batchRunSeconds,
                                        root.batchPauseSeconds,
                                        totalDuration,
                                        auditUser,
                                        rejectionCount
                                    )


                                    // =====================================================
                                    // RESET UI
                                    // =====================================================

                                    batchTimer.stop()

                                    root.batchRunning = false
                                    root.batchPaused = false

                                    root.batchPauseStartTime = null

                                    root.lastValidBatch = "General Batch"
                                    root.currentBatchId = "General Batch"

                                    // Update the visible TextField
                                    inputField.text = "General Batch"

                                    SerialManager.setBatch(0)

                                    root.notify("■ Batch End")
                                }
                            }

                            Item { Layout.fillWidth: true }
                            Item { Layout.fillHeight: true }
                        }
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
                        text: "De-duster Menu"
                        font.pixelSize: 18

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
                                font.pixelSize: 15

                                color: "#6B7280"
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.margins: 16
                            }
                            Item { Layout.fillHeight: true }

                            DDButton {
                                id: ddBtn

                                Layout.alignment: Qt.AlignHCenter

                                onToggleRequested: {

                                    SerialManager.setDDuster(toggled)


                                    saveDDAudit(
                                        toggled ? "DD ON" : "DD OFF"
                                    )


                                    root.notify(
                                        toggled ? "✓ DD ON" : "✓ DD OFF"
                                    )
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

                        enabled: ddBtn.toggled

                        opacity: enabled ? 1.0 : 0.5

                        Text {
                            text: "Power (Volt)"
                            font.pixelSize: 15

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

                                value: ddPower

                                stepSize: 1
                                decimals: 0

                                onValueChangedDelayed: function(val)
                                {
                                    if (ddPower !== val)
                                        previousDDPower = ddPower

                                    ddPower = val

                                    SerialManager.setDDPower(val)
                                }

                                onSaveClicked: function(val)
                                {
                                    var settings = databaseManager.getDDSettings()

                                    var oldValue = settings.ddPower


                                    databaseManager.saveDDPower(val)


                                    saveDDAudit(
                                        "DD Power Changed",
                                        oldValue,
                                        val
                                    )


                                    root.notify("✓ DD Power Saved : " + val)
                                    root.globalTopBar.resetSessionTimer()
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

                        enabled: ddBtn.toggled

                        opacity: enabled ? 1.0 : 0.5

                        Text {
                            text: "Frequency (Hz)"
                            font.pixelSize: 15

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

                                minValue: 25.0
                                maxValue: 50.0

                                value: ddFrequency

                                stepSize: 0.1
                                decimals: 1

                                onValueChangedDelayed: function(val)
                                {
                                    if (ddFrequency !== val)
                                        previousDDFrequency = ddFrequency

                                    ddFrequency = val

                                    var freq = Math.round(val * 10)

                                    SerialManager.setDDFrequency(freq)
                                }

                                onSaveClicked: function(val)
                                {
                                    var settings = databaseManager.getDDSettings()

                                    var oldValue = settings.ddFreq


                                    databaseManager.saveDDFrequency(val)


                                    saveDDAudit(
                                        "DD Frequency Changed",
                                        oldValue.toFixed(1),
                                        val.toFixed(1)
                                    )


                                    root.notify("✓ DD Frequency Saved : " + val.toFixed(1))
                                    root.globalTopBar.resetSessionTimer()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
