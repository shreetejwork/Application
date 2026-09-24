
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import AppState 1.0
import Backend 1.0

Popup {
    id: validationpopupnew

    // ================================================================
    // POPUP SETUP
    // ================================================================

    parent: Overlay.overlay

    width: 850
    height: 540

    x: Math.round((Overlay.overlay.width - width) / 2)
    y: Math.round((Overlay.overlay.height - height) / 2)

    modal: true
    focus: true
    dim: true

    closePolicy: Popup.NoAutoClose

    property var globalTopBar: null

    property int totalRounds: 3
    property int currentRound: 1
    property var roundStatus: [false, false, false]

    property int roundDuration: 60
    property int remainingSeconds: roundDuration

    property bool rejectCycleStarted: false
    property string validationState: "running"

    readonly property color stateColor:
        validationState === "failed"
        ? "#FF5252"
        : validationState === "passed"
          ? "#2ECC71"
          : "#1A4DB5"

    Overlay.modal: Rectangle {
        color: "#66000000"
    }

    Typography {
        id: typography
        scale: 1.0
    }

    // ================================================================
    // HELPER FUNCTIONS
    // ================================================================

    function formatTime(value) {
        var minutes = Math.floor(value / 60)
        var seconds = value % 60

        return (minutes < 10 ? "0" : "") + minutes + ":" +
               (seconds < 10 ? "0" : "") + seconds
    }

    function notify(message) {
        if (globalTopBar && globalTopBar.showNotification)
            globalTopBar.showNotification(message)
    }

    function recordAudit(action) {
        var role = GlobalState.loggedInUserRole
        var username = GlobalState.loggedInUserName

        var prefix = "U"
        var auditUser = "---"

        if (GlobalState.developerLogin) {
            auditUser = "D/Developer"
        }
        else if (GlobalState.engineerLogin) {
            auditUser = "E/Engineer"
        }
        else if (role !== "" && username !== "") {

            if (role === "Admin")
                prefix = "A"
            else if (role === "Supervisor")
                prefix = "S"
            else if (role === "Operator")
                prefix = "O"

            auditUser = prefix + "/" + username
        }

        databaseManager.addAuditTrailRecord(
            auditUser,
            "",
            "",
            action
        )
    }

    // ================================================================
    // RESULT ANIMATION
    // ================================================================

    function resetResult() {
        resultAnimation.stop()

        resultCircle.visible = false
        resultCircle.opacity = 0
        resultCircle.scale = 0.7

        resultMark.opacity = 0
        resultMark.scale = 0.4
    }

    function showResult() {
        resultCircle.visible = true
        resultCircle.opacity = 0
        resultCircle.scale = 0.7

        resultMark.opacity = 0
        resultMark.scale = 0.4

        resultAnimation.start()
    }

    // ================================================================
    // VALIDATION RESET
    // ================================================================

    function resetValidation() {
        countdown.stop()

        currentRound = 1
        roundStatus = [false, false, false]

        remainingSeconds = roundDuration

        rejectCycleStarted = false
        validationState = "running"

        resetResult()

        timerBackground.requestPaint()
        timerProgress.requestPaint()

        countdown.start()
    }

    // ================================================================
    // ROUND HANDLING
    // ================================================================

    function finishRound() {

        if (validationState !== "running")
            return

        if (currentRound < 1 || currentRound > totalRounds)
            return

        var updatedStatus = roundStatus.slice()

        updatedStatus[currentRound - 1] = true
        roundStatus = updatedStatus

        var completedIndex = currentRound - 1

        Qt.callLater(function() {

            var markerItem =
                    roundRepeater.itemAt(completedIndex)

            if (markerItem && markerItem.pulse)
                markerItem.pulse()
        })

        // ------------------------------------------------------------
        // FINAL ROUND
        // ------------------------------------------------------------

        if (currentRound === totalRounds) {

            countdown.stop()

            validationState = "passed"
            rejectCycleStarted = false

            timerProgress.requestPaint()

            recordAudit("Validation Passed")

            GlobalState.countRejection = true

            Qt.callLater(showResult)

            return
        }

        // ------------------------------------------------------------
        // NEXT ROUND
        // ------------------------------------------------------------

        currentRound++

        remainingSeconds = roundDuration
        rejectCycleStarted = false

        timerProgress.requestPaint()
    }

    // ================================================================
    // EXIT / CLOSE
    // ================================================================

    function skipValidation() {

        countdown.stop()

        rejectCycleStarted = false

        GlobalState.countRejection = true

        recordAudit("Validation Skipped")

        notify("Validation exit clicked")

        close()
    }

    function closeValidation() {

        countdown.stop()

        rejectCycleStarted = false

        GlobalState.countRejection = true

        notify("Validation close clicked")

        close()
    }

    // ================================================================
    // POPUP LIFECYCLE
    // ================================================================

    onOpened: {

        GlobalState.countRejection = false

        resetValidation()
    }

    onClosed: {

        countdown.stop()

        resultAnimation.stop()

        rejectCycleStarted = false
    }

    onRemainingSecondsChanged: {
        timerProgress.requestPaint()
    }

    onRoundDurationChanged: {
        timerProgress.requestPaint()
    }

    // ================================================================
    // COUNTDOWN
    // ================================================================

    Timer {
        id: countdown

        interval: 1000
        repeat: true
        running: false

        onTriggered: {

            if (validationpopupnew.validationState !== "running") {

                stop()

                return
            }

            if (validationpopupnew.remainingSeconds > 1) {

                validationpopupnew.remainingSeconds--

                return
            }

            validationpopupnew.remainingSeconds = 0

            stop()

            validationpopupnew.rejectCycleStarted = false

            validationpopupnew.validationState = "failed"

            validationpopupnew.timerProgress.requestPaint()

            validationpopupnew.recordAudit("Validation Failed")

            GlobalState.countRejection = true

            Qt.callLater(validationpopupnew.showResult)
        }
    }

    // ================================================================
    // SERIAL SIGNAL MONITORING
    // ================================================================

    Connections {
        target: SerialManager

        enabled:
            validationpopupnew.visible &&
            validationpopupnew.validationState === "running"

        function onSignalChanged() {

            if (validationpopupnew.validationState !== "running")
                return

            if (SerialManager.signal >
                    GlobalState.signalThreshold) {

                validationpopupnew.rejectCycleStarted = true

                return
            }

            if (validationpopupnew.rejectCycleStarted) {

                validationpopupnew.rejectCycleStarted = false

                validationpopupnew.finishRound()
            }
        }
    }

    // ================================================================
    // OPEN ANIMATION
    // ================================================================

    enter: Transition {

        ParallelAnimation {

            NumberAnimation {
                property: "opacity"

                from: 0
                to: 1

                duration: 350

                easing.type: Easing.OutQuad
            }

            NumberAnimation {
                property: "scale"

                from: 0.85
                to: 1

                duration: 350

                easing.type: Easing.OutBack
            }
        }
    }

    // ================================================================
    // CLOSE ANIMATION
    // ================================================================

    exit: Transition {

        ParallelAnimation {

            NumberAnimation {
                property: "opacity"

                from: 1
                to: 0

                duration: 250

                easing.type: Easing.InQuad
            }

            NumberAnimation {
                property: "scale"

                from: 1
                to: 0.85

                duration: 250

                easing.type: Easing.InQuad
            }
        }
    }

    // ================================================================
    // MAIN CONTENT
    //
    // Same design as the original popup.
    // contentItem is used so the Popup follows the same structure
    // as the working Login popup.
    // ================================================================

    background: Rectangle {
        color: "transparent"
        border.width: 0
    }

    contentItem: Item {
        id: content

        width: validationpopupnew.width
        height: validationpopupnew.height

        // ============================================================
        // OUTER GLOW
        // ============================================================

        Rectangle {
            id: glow

            anchors.centerIn: parent

            width: parent.width + 14
            height: parent.height + 14

            radius: 30

            color: "transparent"

            border.color: validationpopupnew.stateColor
            border.width: 3

            opacity: 0.25

            antialiasing: true

            SequentialAnimation on opacity {

                running:
                    validationpopupnew.validationState === "running"

                loops: Animation.Infinite

                NumberAnimation {
                    from: 0.12
                    to: 0.32

                    duration: 800

                    easing.type: Easing.InOutQuad
                }

                NumberAnimation {
                    from: 0.32
                    to: 0.12

                    duration: 800

                    easing.type: Easing.InOutQuad
                }
            }
        }

        // ============================================================
        // MAIN BACKGROUND
        // ============================================================

        Rectangle {
            anchors.fill: parent

            radius: 24

            antialiasing: true

            border.color: "#D0D8EC"
            border.width: 1

            gradient: Gradient {

                orientation: Gradient.Vertical

                GradientStop {
                    position: 0
                    color: "#FFFFFF"
                }

                GradientStop {
                    position: 1
                    color: "#F0F3FA"
                }
            }
        }

        // ============================================================
        // EXIT BUTTON
        //
        // Same interaction structure as LoginPopup:
        // - direct Rectangle
        // - MouseArea fills button
        // - explicit acceptedButtons
        // - high z
        // ============================================================

        Rectangle {
            id: exitButton

            visible:
                validationpopupnew.validationState === "running"

            width: 45
            height: 45

            radius: width / 2

            anchors.top: parent.top
            anchors.right: parent.right

            anchors.topMargin: 25
            anchors.rightMargin: 25

            color:
                exitMouseArea.pressed
                ? "#D32F2F"
                : "#FFFFFF"

            border.color: "#D0D8EC"
            border.width: 1

            scale:
                exitMouseArea.pressed
                ? 0.92
                : 1

            z: 999

            Behavior on scale {

                NumberAnimation {
                    duration: 80
                }
            }

            Text {
                anchors.centerIn: parent

                text: "✕"

                font.pixelSize: 25

                color:
                    exitMouseArea.pressed
                    ? "white"
                    : "#1A4DB5"
            }

            MouseArea {
                id: exitMouseArea

                anchors.fill: parent

                acceptedButtons: Qt.LeftButton

                hoverEnabled: false

                z: 1000

                onPressed: {
                    mouse.accepted = true
                }

                onReleased: {
                    mouse.accepted = true
                }

                onClicked: {

                    mouse.accepted = true

                    validationpopupnew.skipValidation()
                }
            }
        }

        // ============================================================
        // MAIN LAYOUT
        // ============================================================

        ColumnLayout {

            anchors.fill: parent

            anchors.leftMargin: 34
            anchors.rightMargin: 34
            anchors.topMargin: 40
            anchors.bottomMargin: 30

            spacing: 12

            // ========================================================
            // HEADER
            // ========================================================

            RowLayout {

                Layout.fillWidth: true
                Layout.preferredHeight: 45

                Column {

                    Layout.fillWidth: true

                    spacing: 6

                    Text {
                        text: "Validation Screen"

                        color: "#1A4DB5"

                        font.pixelSize: typography.title
                    }

                    Rectangle {

                        width: 80
                        height: 4

                        radius: 2

                        color: "#1A4DB5"
                    }
                }

                Rectangle {

                    visible:
                        validationpopupnew.validationState !== "running"

                    height: 34
                    width: badge.implicitWidth + 28

                    radius: 17

                    color:
                        validationpopupnew.stateColor

                    Text {

                        id: badge

                        anchors.centerIn: parent

                        text:
                            validationpopupnew.validationState === "passed"
                            ? "Passed"
                            : "Failed"

                        color: "white"

                        font.pixelSize:
                            typography.bodySmall
                    }
                }
            }

            // ========================================================
            // TIMER / RESULT
            // ========================================================

            Item {

                Layout.alignment:
                    Qt.AlignHCenter

                Layout.preferredWidth: 190
                Layout.preferredHeight: 190

                // ====================================================
                // RUNNING STATE
                // ====================================================

                Item {

                    anchors.fill: parent

                    visible:
                        validationpopupnew.validationState === "running"

                    Canvas {

                        id: timerBackground

                        anchors.fill: parent

                        onPaint: {

                            var context = getContext("2d")

                            context.clearRect(
                                0,
                                0,
                                width,
                                height
                            )

                            context.beginPath()

                            context.lineWidth = 10

                            context.strokeStyle = "#E2E7F5"

                            context.lineCap = "round"

                            context.arc(
                                width / 2,
                                height / 2,
                                72,
                                0,
                                Math.PI * 2
                            )

                            context.stroke()
                        }

                        Component.onCompleted: {
                            requestPaint()
                        }
                    }

                    Canvas {

                        id: timerProgress

                        anchors.fill: parent

                        z: 2

                        onPaint: {

                            var context = getContext("2d")

                            var duration =
                                Math.max(
                                    1,
                                    validationpopupnew.roundDuration
                                )

                            var progress =
                                Math.max(
                                    0,
                                    Math.min(
                                        validationpopupnew.remainingSeconds,
                                        duration
                                    )
                                ) / duration

                            context.clearRect(
                                0,
                                0,
                                width,
                                height
                            )

                            context.beginPath()

                            context.lineWidth = 10

                            context.strokeStyle =
                                validationpopupnew.remainingSeconds <= 10
                                ? "#FF5252"
                                : "#1A4DB5"

                            context.lineCap = "round"

                            if (progress >= 0.999) {

                                context.arc(
                                    width / 2,
                                    height / 2,
                                    72,
                                    0,
                                    Math.PI * 2
                                )

                            }
                            else if (progress > 0) {

                                context.arc(
                                    width / 2,
                                    height / 2,
                                    72,
                                    -Math.PI / 2,
                                    -Math.PI / 2 +
                                    progress * Math.PI * 2
                                )
                            }

                            context.stroke()
                        }

                        Component.onCompleted: {
                            requestPaint()
                        }
                    }

                    Column {

                        anchors.centerIn: parent

                        spacing: 2

                        z: 3

                        Text {

                            anchors.horizontalCenter: parent.horizontalCenter

                            text:
                                validationpopupnew.formatTime(
                                    validationpopupnew.remainingSeconds
                                )

                            color:
                                validationpopupnew.remainingSeconds <= 10
                                ? "#FF5252"
                                : "#1A2E52"

                            font.pixelSize:
                                typography.title * 1.5
                        }

                        Text {

                            anchors.horizontalCenter:
                                parent.horizontalCenter

                            text: "remaining"

                            color: "#3D3846"

                            font.pixelSize:
                                typography.body * 0.85
                        }
                    }
                }

                // ====================================================
                // RESULT STATE
                // ====================================================

                Item {

                    anchors.fill: parent

                    visible:
                        validationpopupnew.validationState !== "running"

                    Rectangle {

                        id: resultCircle

                        width: 150
                        height: 150

                        radius: width / 2

                        anchors.centerIn: parent

                        visible: false

                        opacity: 0
                        scale: 0.7

                        color:
                            validationpopupnew.validationState === "passed"
                            ? "#2ECC71"
                            : "#FF5252"

                        border.width: 5

                        border.color:
                            validationpopupnew.validationState === "passed"
                            ? "#25B866"
                            : "#E53935"

                        Rectangle {

                            width: 122
                            height: 122

                            radius: width / 2

                            anchors.centerIn: parent

                            color: "white"

                            Text {

                                id: resultMark

                                anchors.centerIn: parent

                                text:
                                    validationpopupnew.validationState === "passed"
                                    ? "✓"
                                    : "✕"

                                color:
                                    validationpopupnew.validationState === "passed"
                                    ? "#2ECC71"
                                    : "#FF5252"

                                font.pixelSize: 68

                                opacity: 0
                                scale: 0.4
                            }
                        }
                    }
                }
            }

            // ========================================================
            // STATUS MESSAGE
            // ========================================================

            Rectangle {

                Layout.fillWidth: true

                Layout.preferredHeight: 68

                radius: 14

                color: "white"

                border.color:
                    validationpopupnew.stateColor

                border.width: 1.5

                RowLayout {

                    anchors.centerIn: parent

                    spacing: 14

                    Rectangle {

                        width: 15
                        height: 15

                        radius: 7.5

                        color:
                            validationpopupnew.stateColor
                    }

                    Text {

                        font.pixelSize:
                            typography.subHeading

                        color: "#1A4DB5"

                        text:
                            validationpopupnew.validationState === "failed"
                            ? "Validation Failed"
                            : validationpopupnew.validationState === "passed"
                              ? "Validation Passed"
                              : "Please pass the sample for validation"
                    }
                }
            }

            // ========================================================
            // ROUND INDICATORS
            // ========================================================

            RowLayout {

                Layout.alignment:
                    Qt.AlignHCenter

                spacing: 0

                Repeater {

                    id: roundRepeater

                    model:
                        validationpopupnew.totalRounds

                    delegate: RowLayout {

                        spacing: 0

                        function pulse() {
                            markerAnimation.start()
                        }

                        Rectangle {

                            id: marker

                            width: 40
                            height: 40

                            radius: 20

                            color:
                                validationpopupnew.roundStatus[index]
                                ? "#2ECC71"
                                : validationpopupnew.currentRound === index + 1 &&
                                  validationpopupnew.validationState === "running"
                                  ? "white"
                                  : "#D8DCE6"

                            border.width:
                                validationpopupnew.currentRound === index + 1 &&
                                validationpopupnew.validationState === "running"
                                ? 3
                                : 1

                            border.color:
                                validationpopupnew.currentRound === index + 1 &&
                                validationpopupnew.validationState === "running"
                                ? "#1A4DB5"
                                : "#D8DCE6"

                            Text {

                                anchors.centerIn: parent

                                visible:
                                    validationpopupnew.roundStatus[index]

                                text: "✓"

                                color: "white"

                                font.pixelSize:
                                    typography.bodySmall
                            }

                            Text {

                                anchors.centerIn: parent

                                visible:
                                    !validationpopupnew.roundStatus[index]

                                text: index + 1

                                color:
                                    validationpopupnew.currentRound === index + 1 &&
                                    validationpopupnew.validationState === "running"
                                    ? "#1A4DB5"
                                    : "#8A93A6"

                                font.pixelSize:
                                    typography.bodySmall
                            }

                            SequentialAnimation {

                                id: markerAnimation

                                NumberAnimation {

                                    target: marker

                                    property: "scale"

                                    from: 1
                                    to: 1.35

                                    duration: 140
                                }

                                NumberAnimation {

                                    target: marker

                                    property: "scale"

                                    from: 1.35
                                    to: 1

                                    duration: 160

                                    easing.type:
                                        Easing.OutBack
                                }
                            }
                        }

                        Rectangle {

                            visible:
                                index <
                                validationpopupnew.totalRounds - 1

                            width: 46
                            height: 3

                            Layout.preferredWidth: 46
                            Layout.preferredHeight: 3

                            color:
                                validationpopupnew.roundStatus[index]
                                ? "#2ECC71"
                                : "#D8DCE6"
                        }
                    }
                }
            }

            // ========================================================
            // FLEXIBLE SPACER
            // ========================================================

            Item {

                Layout.fillHeight: true

                Layout.minimumHeight: 1
            }

            // ========================================================
            // BOTTOM BUTTON
            // ========================================================

            Row {

                visible:
                    validationpopupnew.validationState !== "running"

                Layout.alignment:
                    Qt.AlignHCenter

                spacing: 22

                Rectangle {

                    id: closeButton

                    width: 160
                    height: 52

                    radius: 12

                    color:
                        closeMouseArea.pressed
                        ? "#0D3BA8"
                        : "#1A4DB5"

                    scale:
                        closeMouseArea.pressed
                        ? 0.97
                        : 1

                    z: 999

                    Behavior on scale {

                        NumberAnimation {
                            duration: 80
                        }
                    }

                    Text {

                        anchors.centerIn: parent

                        text:
                            validationpopupnew.validationState === "passed"
                            ? "Done"
                            : "Close"

                        color: "white"

                        font.pixelSize:
                            typography.body
                    }

                    // ====================================================
                    // SAME BUTTON METHOD AS LOGIN POPUP
                    // ====================================================

                    MouseArea {

                        id: closeMouseArea

                        anchors.fill: parent

                        acceptedButtons: Qt.LeftButton

                        hoverEnabled: false

                        z: 1000

                        onPressed: {
                            mouse.accepted = true
                        }

                        onReleased: {
                            mouse.accepted = true
                        }

                        onClicked: {

                            mouse.accepted = true

                            validationpopupnew.closeValidation()
                        }
                    }
                }
            }
        }
    }

    // ================================================================
    // RESULT ANIMATION
    // ================================================================

    SequentialAnimation {

        id: resultAnimation

        ParallelAnimation {

            NumberAnimation {

                target: resultCircle

                property: "scale"

                from: 0.7
                to: 1

                duration: 420

                easing.type:
                    Easing.OutBack
            }

            NumberAnimation {

                target: resultCircle

                property: "opacity"

                from: 0
                to: 1

                duration: 280

                easing.type:
                    Easing.OutQuad
            }
        }

        ParallelAnimation {

            NumberAnimation {

                target: resultMark

                property: "scale"

                from: 0.4
                to: 1

                duration: 300

                easing.type:
                    Easing.OutBack
            }

            NumberAnimation {

                target: resultMark

                property: "opacity"

                from: 0
                to: 1

                duration: 250

                easing.type:
                    Easing.OutQuad
            }
        }
    }
}
