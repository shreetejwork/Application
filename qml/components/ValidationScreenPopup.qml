import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import AppState 1.0
import Backend 1.0

Popup {
    id: validationScreenPopup

    // ============================================================
    // POPUP SIZE
    // ============================================================

    width: 850
    height: 540

    x: (Overlay.overlay.width - width) / 2
    y: (Overlay.overlay.height - height) / 2

    modal: true
    focus: true
    dim: true

    closePolicy: Popup.NoAutoClose

    Overlay.modal: Rectangle {
        color: "#66000000"
    }

    // ============================================================
    // TYPOGRAPHY
    // ============================================================

    Typography {
        id: vTypography
        scale: 1.0
    }

    // ============================================================
    // VALIDATION STATE
    // ============================================================

    property int totalRounds: 3
    property int currentRound: 1

    property var roundStatus: [
        false,
        false,
        false
    ]

    property int roundDuration: 60
    property int remainingSeconds: roundDuration

    // TRUE when signal has crossed the threshold
    property bool rejectCycleStarted: false

    // running | passed | failed
    property string validationState: "running"

    // ============================================================
    // STATE COLOR
    // ============================================================

    property color stateColor:
        validationState === "failed"
        ? "#FF5252"
        : validationState === "passed"
        ? "#2ECC71"
        : "#1A4DB5"

    // ============================================================
    // TIME FORMAT
    // ============================================================

    function formatTime(sec)
    {
        var m = Math.floor(sec / 60)
        var s = sec % 60

        return (m < 10 ? "0" : "") + m +
               ":" +
               (s < 10 ? "0" : "") + s
    }

    // ============================================================
    // AUDIT
    // ============================================================

    function saveValidationAudit(action)
    {
        var role = GlobalState.loggedInUserRole
        var username = GlobalState.loggedInUserName

        var auditUser = "---"

        // Keep the same Developer / Engineer handling
        // from the original working code.

        if (GlobalState.developerLogin) {

            auditUser = "D/Developer"

        }
        else if (GlobalState.engineerLogin) {

            auditUser = "E/Engineer"

        }
        else if (role !== "" && username !== "") {

            var initial = "U"

            if (role === "Admin")
                initial = "A"
            else if (role === "Supervisor")
                initial = "S"
            else if (role === "Operator")
                initial = "O"

            auditUser = initial + "/" + username
        }

        databaseManager.addAuditTrailRecord(
            auditUser,
            "",
            "",
            action
        )
    }

    // ============================================================
    // START VALIDATION
    // ============================================================

    function startValidation()
    {
        // Always stop an old timer first
        countdownTimer.stop()

        // Reset validation
        currentRound = 1

        roundStatus = [
            false,
            false,
            false
        ]

        remainingSeconds = roundDuration

        rejectCycleStarted = false

        validationState = "running"

        // ========================================================
        // RESET RESULT ANIMATION
        // ========================================================

        successFailureAnimation.stop()

        successFailureCircle.scale = 0.70
        successFailureCircle.opacity = 0
        successFailureCircle.visible = false

        resultIcon.scale = 0.40
        resultIcon.opacity = 0

        // ========================================================
        // RESET TIMER ARC
        // ========================================================

        if (timerBackgroundCanvas)
            timerBackgroundCanvas.requestPaint()

        if (timerArcCanvas)
            timerArcCanvas.requestPaint()

        // ========================================================
        // START COUNTDOWN
        // ========================================================

        countdownTimer.start()

        console.log(
            "Validation started - Round:",
            currentRound
        )
    }

    // ============================================================
    // COMPLETE CURRENT ROUND
    // ============================================================

    function completeRound()
    {
        // ========================================================
        // IMPORTANT:
        // Ignore any signal changes after validation is finished.
        // ========================================================

        if (validationState !== "running")
            return

        // Protect against invalid round
        if (currentRound < 1 || currentRound > totalRounds)
            return

        // ========================================================
        // MARK CURRENT ROUND AS PASSED
        // ========================================================

        var arr = roundStatus.slice()

        arr[currentRound - 1] = true

        roundStatus = arr

        console.log(
            "Validation Round Passed:",
            currentRound,
            "/",
            totalRounds
        )

        // ========================================================
        // ROUND DOT ANIMATION
        // ========================================================

        Qt.callLater(function() {

            var item =
                    indicatorRepeater.itemAt(
                        currentRound - 1
                    )

            if (item)
                item.pop()
        })

        // ========================================================
        // FINAL ROUND
        // ========================================================

        if (currentRound === totalRounds) {

            console.log(
                "FINAL VALIDATION ROUND PASSED"
            )

            // Stop countdown FIRST
            countdownTimer.stop()

            // Make validation state passed
            validationState = "passed"

            // Make sure rejection cycle is no longer active
            rejectCycleStarted = false

            // Make sure the final timer state is painted
            if (timerArcCanvas)
                timerArcCanvas.requestPaint()

            // ====================================================
            // SAVE AUDIT
            // ====================================================

            saveValidationAudit(
                "Validation Passed"
            )

            // ====================================================
            // SHOW SUCCESS ANIMATION
            // ====================================================

            Qt.callLater(function() {

                showSuccessAnimation()

                // After validation is completely passed,
                // allow rejection counting again.

                GlobalState.countRejection = true

                console.log(
                    "Count Rejection:",
                    GlobalState.countRejection
                )
            })

            return
        }

        // ========================================================
        // MOVE TO NEXT ROUND
        // ========================================================

        currentRound++

        // Reset timer for next round
        remainingSeconds = roundDuration

        // Reset signal cycle for next sample
        rejectCycleStarted = false

        console.log(
            "Starting Validation Round:",
            currentRound,
            "/",
            totalRounds
        )

        // Repaint timer arc for new round
        if (timerArcCanvas)
            timerArcCanvas.requestPaint()
    }

    // ============================================================
    // SHOW SUCCESS ANIMATION
    // ============================================================

    function showSuccessAnimation()
    {
        // Make sure result state is visible
        successFailureCircle.visible = true

        // Reset animation state
        successFailureCircle.scale = 0.70
        successFailureCircle.opacity = 0

        resultIcon.scale = 0.40
        resultIcon.opacity = 0

        // Start animation
        successFailureAnimation.start()
    }

    // ============================================================
    // SHOW FAILURE ANIMATION
    // ============================================================

    function showFailureAnimation()
    {
        successFailureCircle.visible = true

        successFailureCircle.scale = 0.70
        successFailureCircle.opacity = 0

        resultIcon.scale = 0.40
        resultIcon.opacity = 0

        successFailureAnimation.start()
    }

    // ============================================================
    // POPUP OPENED
    // ============================================================

    onOpened: {

        // While validation is running, do not count rejection
        GlobalState.countRejection = false

        startValidation()

        console.log(
            "Validation popup opened"
        )

        console.log(
            "Round duration:",
            roundDuration
        )

        console.log(
            "Signal threshold:",
            GlobalState.signalThreshold
        )

        console.log(
            "Current round:",
            currentRound
        )
    }

    // ============================================================
    // POPUP CLOSED
    // ============================================================

    onClosed: {

        countdownTimer.stop()

        successFailureAnimation.stop()

        rejectCycleStarted = false

        console.log(
            "Validation popup closed"
        )
    }

    // ============================================================
    // COUNTDOWN TIMER
    // ============================================================

    Timer {
        id: countdownTimer

        interval: 1000
        repeat: true
        running: false

        onTriggered: {

            // ====================================================
            // SAFETY CHECK
            // ====================================================

            if (
                validationScreenPopup.validationState
                !== "running"
            ) {
                stop()
                return
            }

            // ====================================================
            // NORMAL COUNTDOWN
            // ====================================================

            if (
                validationScreenPopup.remainingSeconds
                > 1
            ) {

                validationScreenPopup.remainingSeconds--

            }

            // ====================================================
            // TIMEOUT
            // ====================================================

            else {

                validationScreenPopup.remainingSeconds = 0

                // Stop timer
                stop()

                // Stop signal validation
                validationScreenPopup.rejectCycleStarted = false

                // Mark validation failed
                validationScreenPopup.validationState =
                        "failed"

                // Repaint final timer state
                if (timerArcCanvas)
                    timerArcCanvas.requestPaint()

                // =================================================
                // SAVE FAILURE AUDIT
                // =================================================

                saveValidationAudit(
                    "Validation Failed"
                )

                // =================================================
                // FAILURE ANIMATION
                // =================================================

                Qt.callLater(function() {

                    showFailureAnimation()
                })

                // =================================================
                // ALLOW REJECTION COUNTING AGAIN
                // =================================================

                GlobalState.countRejection = true

                console.log(
                    "Validation Failed"
                )

                console.log(
                    "Count Rejection:",
                    GlobalState.countRejection
                )
            }
        }
    }

    // ============================================================
    // REPAINT TIMER ARC
    // ============================================================

    onRemainingSecondsChanged: {

        if (timerArcCanvas)
            timerArcCanvas.requestPaint()
    }

    onRoundDurationChanged: {

        if (timerArcCanvas)
            timerArcCanvas.requestPaint()
    }

    // ============================================================
    // SIGNAL VS THRESHOLD
    // ============================================================

    Connections {

        target: SerialManager

        enabled:
            validationScreenPopup.validationState
            === "running"

        function onSignalChanged()
        {
            // ====================================================
            // VALIDATION IS NOT RUNNING
            // ====================================================

            if (
                validationScreenPopup.validationState
                !== "running"
            ) {
                return
            }

            // ====================================================
            // SAMPLE HAS CROSSED SIGNAL THRESHOLD
            // ====================================================

            if (
                SerialManager.signal
                > GlobalState.signalThreshold
            ) {

                if (
                    !validationScreenPopup.rejectCycleStarted
                ) {

                    validationScreenPopup.rejectCycleStarted =
                            true

                    console.log(
                        "Validation sample detected - Round:",
                        validationScreenPopup.currentRound,
                        "Signal:",
                        SerialManager.signal,
                        "Threshold:",
                        GlobalState.signalThreshold
                    )
                }

            }

            // ====================================================
            // SAMPLE HAS COME BACK BELOW THRESHOLD
            // ====================================================

            else {

                if (
                    validationScreenPopup.rejectCycleStarted
                ) {

                    // Reset current sample cycle FIRST
                    validationScreenPopup.rejectCycleStarted =
                            false

                    console.log(
                        "Validation sample completed - Round:",
                        validationScreenPopup.currentRound
                    )

                    // =================================================
                    // THIS IS THE IMPORTANT PART:
                    // Every completed HIGH -> LOW cycle passes
                    // one round, including the FINAL round.
                    // =================================================

                    validationScreenPopup.completeRound()
                }
            }
        }
    }

    // ============================================================
    // OPEN ANIMATION
    // ============================================================

    enter: Transition {

        ParallelAnimation {

            NumberAnimation {
                property: "opacity"

                from: 0
                to: 1

                duration: 350

                easing.type:
                    Easing.OutQuad
            }

            NumberAnimation {
                property: "scale"

                from: 0.85
                to: 1.0

                duration: 350

                easing.type:
                    Easing.OutBack
            }
        }
    }

    // ============================================================
    // CLOSE ANIMATION
    // ============================================================

    exit: Transition {

        ParallelAnimation {

            NumberAnimation {
                property: "opacity"

                from: 1
                to: 0

                duration: 250

                easing.type:
                    Easing.InQuad
            }

            NumberAnimation {
                property: "scale"

                from: 1
                to: 0.85

                duration: 250

                easing.type:
                    Easing.InQuad
            }
        }
    }

    // ============================================================
    // POPUP BACKGROUND
    // ============================================================

    background: Item {

        id: popupContent

        width: validationScreenPopup.width
        height: validationScreenPopup.height

        // ========================================================
        // OUTER GLOW
        // ========================================================

        Rectangle {

            id: glowBorder

            anchors.centerIn: parent

            width:
                parent.width + 14

            height:
                parent.height + 14

            radius: 30

            color: "transparent"

            border.color:
                validationScreenPopup.stateColor

            border.width: 3

            opacity: 0.18

            antialiasing: true

            SequentialAnimation {

                running:
                    validationScreenPopup.validationState
                    === "running"

                loops:
                    Animation.Infinite

                NumberAnimation {

                    target: glowBorder

                    property: "opacity"

                    from: 0.12
                    to: 0.32

                    duration: 800

                    easing.type:
                        Easing.InOutQuad
                }

                NumberAnimation {

                    target: glowBorder

                    property: "opacity"

                    from: 0.32
                    to: 0.12

                    duration: 800

                    easing.type:
                        Easing.InOutQuad
                }
            }
        }

        // ========================================================
        // CARD
        // ========================================================

        Rectangle {

            anchors.fill: parent

            radius: 24

            antialiasing: true

            gradient: Gradient {

                orientation:
                    Gradient.Vertical

                GradientStop {
                    position: 0.0
                    color: "#FFFFFF"
                }

                GradientStop {
                    position: 1.0
                    color: "#F0F3FA"
                }
            }

            border.color: "#D0D8EC"
            border.width: 1
        }

        // ========================================================
        // EXIT BUTTON
        // ========================================================

        Rectangle {

            id: exitButton

            visible:
                validationScreenPopup.validationState
                === "running"

            width: 45
            height: 45

            radius: 22.5

            anchors.top: parent.top
            anchors.right: parent.right

            anchors.topMargin: 25
            anchors.rightMargin: 25

            color:

                exitMouse.pressed
                ? "#D32F2F"

                : exitMouse.containsMouse
                ? "#F8D7DA"

                : "#FFFFFF"

            border.color: "#D0D8EC"
            border.width: 1

            antialiasing: true

            Text {

                anchors.centerIn: parent

                text: "✕"

                font.pixelSize: 25

                color:
                    exitMouse.pressed
                    ? "white"
                    : "#1A4DB5"
            }

            // ====================================================
            // EXISTING MOUSE INPUT
            // ====================================================

            MouseArea {

                id: exitMouse

                anchors.fill: parent

                hoverEnabled: true

                preventStealing: true

                cursorShape:
                    Qt.PointingHandCursor

                onPressed: {
                    exitButton.scale = 0.92
                }

                onReleased: {
                    exitButton.scale = 1.0
                }

                onCanceled: {
                    exitButton.scale = 1.0
                }

                onClicked: {

                    countdownTimer.stop()

                    validationScreenPopup.rejectCycleStarted =
                            false

                    GlobalState.countRejection = true

                    saveValidationAudit(
                        "Validation Skipped"
                    )

                    validationScreenPopup.close()
                }
            }

            // ====================================================
            // TOUCHSCREEN INPUT
            // ====================================================

            MultiPointTouchArea {

                id: exitTouchArea

                anchors.fill: parent

                maximumTouchPoints: 1

                onPressed: {

                    exitButton.scale = 0.92
                }

                onReleased: {

                    exitButton.scale = 1.0

                    countdownTimer.stop()

                    validationScreenPopup.rejectCycleStarted =
                            false

                    GlobalState.countRejection = true

                    saveValidationAudit(
                        "Validation Skipped"
                    )

                    validationScreenPopup.close()
                }

                onCanceled: {

                    exitButton.scale = 1.0
                }
            }
        }

        // ========================================================
        // MAIN CONTENT
        // ========================================================

        ColumnLayout {

            id: mainLayout

            anchors.fill: parent

            anchors.leftMargin: 34
            anchors.rightMargin: 34

            anchors.topMargin: 40
            anchors.bottomMargin: 30

            spacing: 12

            // ====================================================
            // HEADER
            // ====================================================

            RowLayout {

                Layout.fillWidth: true

                Layout.preferredHeight: 45

                Column {

                    Layout.fillWidth: true

                    spacing: 6

                    Text {

                        text:
                            "Validation Screen"

                        font.pixelSize:
                            vTypography.title

                        color:
                            "#1A4DB5"
                    }

                    Rectangle {

                        width: 80
                        height: 4

                        radius: 2

                        color:
                            "#1A4DB5"
                    }
                }

                Rectangle {

                    visible:
                        validationScreenPopup.validationState
                        !== "running"

                    height: 34

                    width:
                        statusBadgeText.implicitWidth + 28

                    radius: 17

                    color:
                        validationScreenPopup.stateColor

                    Text {

                        id: statusBadgeText

                        anchors.centerIn: parent

                        text:

                            validationScreenPopup.validationState
                            === "passed"
                            ? "Passed"
                            : "Failed"

                        font.pixelSize:
                            vTypography.bodySmall

                        color: "white"
                    }
                }
            }

            // ====================================================
            // TIMER / RESULT AREA
            // ====================================================

            Item {

                id: timerContainer

                Layout.alignment:
                    Qt.AlignHCenter

                Layout.preferredWidth: 190
                Layout.preferredHeight: 190

                width: 190
                height: 190

                // =================================================
                // TIMER CONTENT
                // =================================================

                Item {

                    id: timerContent

                    anchors.fill: parent

                    visible:
                        validationScreenPopup.validationState
                        === "running"

                    // =============================================
                    // GREY BACKGROUND RING
                    // =============================================

                    Canvas {

                        id: timerBackgroundCanvas

                        anchors.fill: parent

                        antialiasing: true

                        onPaint: {

                            var ctx =
                                getContext("2d")

                            ctx.clearRect(
                                0,
                                0,
                                width,
                                height
                            )

                            var cx =
                                width / 2

                            var cy =
                                height / 2

                            var radius =
                                72

                            var lineWidth =
                                10

                            ctx.beginPath()

                            ctx.lineWidth =
                                lineWidth

                            ctx.strokeStyle =
                                "#E2E7F5"

                            ctx.lineCap =
                                "round"

                            ctx.arc(
                                cx,
                                cy,
                                radius,
                                0,
                                Math.PI * 2,
                                false
                            )

                            ctx.stroke()
                        }

                        Component.onCompleted: {
                            requestPaint()
                        }
                    }

                    // =============================================
                    // COUNTDOWN ARC
                    // =============================================

                    Canvas {

                        id: timerArcCanvas

                        anchors.fill: parent

                        z: 2

                        antialiasing: true

                        onPaint: {

                            var ctx =
                                getContext("2d")

                            ctx.clearRect(
                                0,
                                0,
                                width,
                                height
                            )

                            var cx =
                                width / 2

                            var cy =
                                height / 2

                            var radius =
                                72

                            var lineWidth =
                                10

                            var duration =
                                Math.max(
                                    1,
                                    validationScreenPopup.roundDuration
                                )

                            var remaining =
                                Math.max(
                                    0,
                                    Math.min(
                                        validationScreenPopup.remainingSeconds,
                                        duration
                                    )
                                )

                            var progress =
                                remaining / duration

                            var startAngle =
                                -Math.PI / 2

                            ctx.beginPath()

                            ctx.lineWidth =
                                lineWidth

                            ctx.strokeStyle =
                                remaining <= 10
                                ? "#FF5252"
                                : "#1A4DB5"

                            ctx.lineCap =
                                "round"

                            // =====================================
                            // FULL CIRCLE
                            // =====================================

                            if (progress >= 0.999) {

                                ctx.arc(
                                    cx,
                                    cy,
                                    radius,
                                    0,
                                    Math.PI * 2,
                                    false
                                )

                            }

                            // =====================================
                            // PARTIAL ARC
                            // =====================================

                            else if (progress > 0) {

                                var sweep =
                                    progress *
                                    Math.PI *
                                    2

                                ctx.arc(
                                    cx,
                                    cy,
                                    radius,
                                    startAngle,
                                    startAngle + sweep,
                                    false
                                )
                            }

                            ctx.stroke()
                        }

                        Component.onCompleted: {

                            console.log(
                                "COUNTDOWN CANVAS CREATED",
                                width,
                                height
                            )

                            requestPaint()
                        }

                        onWidthChanged: {
                            requestPaint()
                        }

                        onHeightChanged: {
                            requestPaint()
                        }
                    }

                    // =============================================
                    // TIMER TEXT
                    // =============================================

                    Column {

                        anchors.centerIn: parent

                        spacing: 2

                        z: 10

                        Text {

                            anchors.horizontalCenter:
                                parent.horizontalCenter

                            text:
                                validationScreenPopup.formatTime(
                                    validationScreenPopup.remainingSeconds
                                )

                            font.pixelSize:
                                vTypography.title * 1.5

                            color:

                                validationScreenPopup.remainingSeconds
                                <= 10

                                ? "#FF5252"

                                : "#1A2E52"
                        }

                        Text {

                            anchors.horizontalCenter:
                                parent.horizontalCenter

                            text:
                                "remaining"

                            font.pixelSize:
                                vTypography.body * 0.85

                            color:
                                "#3D3846"
                        }
                    }
                }

                // =================================================
                // SUCCESS / FAILURE RESULT
                // =================================================

                Item {

                    id: resultContent

                    anchors.fill: parent

                    visible:
                        validationScreenPopup.validationState
                        !== "running"

                    // =================================================
                    // ANIMATED OUTER CIRCLE
                    // =================================================

                    Rectangle {

                        id: successFailureCircle

                        width: 150
                        height: 150

                        radius: 75

                        anchors.centerIn: parent

                        visible: false

                        opacity: 0

                        scale: 0.70

                        color:
                            validationScreenPopup.validationState
                            === "passed"
                            ? "#2ECC71"
                            : "#FF5252"

                        border.width: 5

                        border.color:
                            validationScreenPopup.validationState
                            === "passed"
                            ? "#25B866"
                            : "#E53935"

                        antialiasing: true

                        // =================================================
                        // INNER CIRCLE
                        // =================================================

                        Rectangle {

                            id: resultInnerCircle

                            width: 122
                            height: 122

                            radius: 61

                            anchors.centerIn: parent

                            color: "#FFFFFF"

                            antialiasing: true

                            // =============================================
                            // RESULT ICON
                            // =============================================

                            Text {

                                id: resultIcon

                                anchors.centerIn: parent

                                text:

                                    validationScreenPopup.validationState
                                    === "passed"

                                    ? "✓"

                                    : "✕"

                                font.pixelSize: 68

                                color:

                                    validationScreenPopup.validationState
                                    === "passed"

                                    ? "#2ECC71"

                                    : "#FF5252"

                                opacity: 0

                                scale: 0.40

                                antialiasing: true
                            }
                        }

                        // =================================================
                        // SUCCESS / FAILURE ANIMATION
                        // =================================================

                        SequentialAnimation {

                            id: successFailureAnimation

                            // ---------------------------------------------
                            // Circle appears
                            // ---------------------------------------------

                            ParallelAnimation {

                                NumberAnimation {

                                    target:
                                        successFailureCircle

                                    property:
                                        "scale"

                                    from: 0.70
                                    to: 1.0

                                    duration: 420

                                    easing.type:
                                        Easing.OutBack
                                }

                                NumberAnimation {

                                    target:
                                        successFailureCircle

                                    property:
                                        "opacity"

                                    from: 0
                                    to: 1

                                    duration: 280

                                    easing.type:
                                        Easing.OutQuad
                                }
                            }

                            // ---------------------------------------------
                            // Icon appears
                            // ---------------------------------------------

                            ParallelAnimation {

                                NumberAnimation {

                                    target:
                                        resultIcon

                                    property:
                                        "scale"

                                    from: 0.40
                                    to: 1.0

                                    duration: 300

                                    easing.type:
                                        Easing.OutBack
                                }

                                NumberAnimation {

                                    target:
                                        resultIcon

                                    property:
                                        "opacity"

                                    from: 0
                                    to: 1

                                    duration: 250

                                    easing.type:
                                        Easing.OutQuad
                                }
                            }

                            // ---------------------------------------------
                            // Small pulse
                            // ---------------------------------------------

                            SequentialAnimation {

                                NumberAnimation {

                                    target:
                                        successFailureCircle

                                    property:
                                        "scale"

                                    from: 1.0
                                    to: 1.06

                                    duration: 180

                                    easing.type:
                                        Easing.OutQuad
                                }

                                NumberAnimation {

                                    target:
                                        successFailureCircle

                                    property:
                                        "scale"

                                    from: 1.06
                                    to: 1.0

                                    duration: 180

                                    easing.type:
                                        Easing.InOutQuad
                                }
                            }
                        }
                    }
                }
            }

            // ====================================================
            // MESSAGE CARD
            // ====================================================

            Rectangle {

                Layout.fillWidth: true

                Layout.preferredHeight: 68

                radius: 14

                color: "#FFFFFF"

                border.color:
                    validationScreenPopup.stateColor

                border.width: 1.5

                antialiasing: true

                RowLayout {

                    anchors.centerIn: parent

                    spacing: 14

                    Rectangle {

                        width: 15
                        height: 15

                        radius: 7.5

                        color:
                            validationScreenPopup.stateColor

                        Layout.preferredWidth: 15
                        Layout.preferredHeight: 15

                        SequentialAnimation on opacity {

                            running:
                                validationScreenPopup.validationState
                                === "running"

                            loops:
                                Animation.Infinite

                            NumberAnimation {
                                from: 1
                                to: 0.25
                                duration: 600
                            }

                            NumberAnimation {
                                from: 0.25
                                to: 1
                                duration: 600
                            }
                        }
                    }

                    Text {

                        font.pixelSize:
                            vTypography.subHeading

                        color:
                            "#1A4DB5"

                        text: {

                            if (
                                validationScreenPopup.validationState
                                === "failed"
                            )
                                return "Validation Failed"

                            if (
                                validationScreenPopup.validationState
                                === "passed"
                            )
                                return "Validation Passed"

                            return "Please pass the sample for validation"
                        }
                    }
                }
            }

            // ====================================================
            // ROUND STEPPER
            // ====================================================

            RowLayout {

                Layout.alignment:
                    Qt.AlignHCenter

                spacing: 0

                Repeater {

                    id: indicatorRepeater

                    model:
                        validationScreenPopup.totalRounds

                    delegate: RowLayout {

                        spacing: 0

                        function pop()
                        {
                            popAnim.start()
                        }

                        Rectangle {

                            id: dot

                            width: 40
                            height: 40

                            radius: 20

                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40

                            antialiasing: true

                            color:

                                validationScreenPopup.roundStatus[index]

                                ? "#2ECC71"

                                : (
                                    validationScreenPopup.currentRound
                                    === index + 1

                                    &&
                                    validationScreenPopup.validationState
                                    === "running"
                                  )

                                ? "#FFFFFF"

                                : "#D8DCE6"

                            border.width:

                                (
                                    validationScreenPopup.currentRound
                                    === index + 1

                                    &&
                                    validationScreenPopup.validationState
                                    === "running"
                                )

                                ? 3
                                : 1

                            border.color:

                                (
                                    validationScreenPopup.currentRound
                                    === index + 1

                                    &&
                                    validationScreenPopup.validationState
                                    === "running"
                                )

                                ? "#1A4DB5"
                                : "#D8DCE6"

                            Text {

                                anchors.centerIn: parent

                                visible:
                                    validationScreenPopup.roundStatus[index]

                                text: "✓"

                                color: "white"

                                font.pixelSize:
                                    vTypography.bodySmall
                            }

                            Text {

                                anchors.centerIn: parent

                                visible:
                                    !validationScreenPopup.roundStatus[index]

                                text:
                                    index + 1

                                color:

                                    validationScreenPopup.currentRound
                                    === index + 1

                                    &&
                                    validationScreenPopup.validationState
                                    === "running"

                                    ? "#1A4DB5"
                                    : "#8A93A6"

                                font.pixelSize:
                                    vTypography.bodySmall
                            }

                            SequentialAnimation {

                                id: popAnim

                                NumberAnimation {

                                    target: dot

                                    property: "scale"

                                    from: 1
                                    to: 1.35

                                    duration: 140
                                }

                                NumberAnimation {

                                    target: dot

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
                                validationScreenPopup.totalRounds - 1

                            Layout.preferredWidth: 46
                            Layout.preferredHeight: 3

                            width: 46
                            height: 3

                            color:

                                validationScreenPopup.roundStatus[index]
                                ? "#2ECC71"
                                : "#D8DCE6"
                        }
                    }
                }
            }

            // ====================================================
            // FLEXIBLE SPACE
            // ====================================================

            Item {

                Layout.fillHeight: true

                Layout.minimumHeight: 1
            }

            // ====================================================
            // BUTTON
            // ====================================================

            Row {

                Layout.alignment:
                    Qt.AlignHCenter

                spacing: 22

                visible:
                    validationScreenPopup.validationState
                    !== "running"

                Rectangle {

                    id: closeBtn

                    width: 160
                    height: 52

                    radius: 12

                    color:
                        closeArea.pressed
                        ? "#0D3BA8"
                        : "#1A4DB5"

                    scale:
                        closeArea.pressed
                        ? 0.96
                        : 1.0

                    antialiasing: true

                    Text {

                        anchors.centerIn: parent

                        text:

                            validationScreenPopup.validationState
                            === "passed"

                            ? "Done"

                            : "Close"

                        color: "white"

                        font.pixelSize:
                            vTypography.body
                    }

                    // ====================================================
                    // EXISTING MOUSE INPUT
                    // ====================================================

                    MouseArea {

                        id: closeArea

                        anchors.fill: parent

                        preventStealing: true

                        cursorShape:
                            Qt.PointingHandCursor

                        onPressed: {

                            closeBtn.scale = 0.96
                        }

                        onReleased: {

                            closeBtn.scale = 1.0
                        }

                        onCanceled: {

                            closeBtn.scale = 1.0
                        }

                        onClicked: {

                            countdownTimer.stop()

                            GlobalState.countRejection = true

                            validationScreenPopup.close()

                            console.log(
                                "Count Rejection:",
                                GlobalState.countRejection
                            )
                        }
                    }

                    // ====================================================
                    // TOUCHSCREEN INPUT
                    // ====================================================

                    MultiPointTouchArea {

                        id: closeTouchArea

                        anchors.fill: parent

                        maximumTouchPoints: 1

                        onPressed: {

                            closeBtn.scale = 0.96
                        }

                        onReleased: {

                            closeBtn.scale = 1.0

                            countdownTimer.stop()

                            GlobalState.countRejection = true

                            validationScreenPopup.close()

                            console.log(
                                "Count Rejection:",
                                GlobalState.countRejection
                            )
                        }

                        onCanceled: {

                            closeBtn.scale = 1.0
                        }
                    }
                }
            }
        }
    }
}
