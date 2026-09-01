import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import AppState 1.0
import Backend 1.0

Popup {
    id: validationScreenPopup

    // ============================================================
    // TYPOGRAPHY
    // ============================================================

    Typography {
        id: vTypography
        scale: validationScreenPopup.uiScale
    }

    // ============================================================
    // BASE SIZE / SCALE
    // ============================================================

    property real baseWidth: 1024
    property real baseHeight: 600

    property real uiScale: Math.min(
                                Overlay.overlay.width / baseWidth,
                                Overlay.overlay.height / baseHeight
                            )

    // ============================================================
    // VALIDATION AUDIT
    // ============================================================

    function saveValidationAudit(action)
    {
        var role = GlobalState.loggedInUserRole
        var username = GlobalState.loggedInUserName

        var auditUser = "---"

        if (role !== "" && username !== "") {

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
    // POPUP SETTINGS
    // ============================================================

    modal: true
    focus: true
    dim: true

    closePolicy: Popup.NoAutoClose

    Overlay.modal: Rectangle {
        color: "#66000000"
    }

    width: 850 * uiScale
    height: 540 * uiScale

    x: (Overlay.overlay.width - width) / 2
    y: (Overlay.overlay.height - height) / 2

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
    // VALIDATION STATE
    // ============================================================

    property int totalRounds: 3

    property int currentRound: 1

    property var roundStatus: [false, false, false]

    // ============================================================
    // TIMER SETTINGS
    // ============================================================

    property int roundDuration: 60

    property int remainingSeconds: roundDuration

    // ============================================================
    // REJECTION CYCLE
    // ============================================================

    property bool rejectCycleStarted: false

    // running | passed | failed
    property string validationState: "running"

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
    // START VALIDATION
    // ============================================================

    function startValidation()
    {
        countdownTimer.stop()

        currentRound = 1

        roundStatus = [false, false, false]

        remainingSeconds = roundDuration

        rejectCycleStarted = false

        validationState = "running"

        // Make sure Canvas gets a fresh paint
        timerCanvas.requestPaint()

        countdownTimer.start()
    }

    // ============================================================
    // COMPLETE ROUND
    // ============================================================

    function completeRound()
    {
        // Safety
        if (validationScreenPopup.validationState !== "running")
            return

        var arr = roundStatus.slice()

        arr[currentRound - 1] = true

        roundStatus = arr

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

            validationState = "passed"

            countdownTimer.stop()

            timerCanvas.requestPaint()

            saveValidationAudit(
                "Validation Passed"
            )

            Qt.callLater(function() {

                GlobalState.countRejection = true

                console.log(
                    "Count Rejection:",
                    GlobalState.countRejection
                )
            })

            return
        }

        // ========================================================
        // NEXT ROUND
        // ========================================================

        currentRound++

        remainingSeconds = roundDuration

        timerCanvas.requestPaint()
    }

    // ============================================================
    // POPUP OPENED
    // ============================================================

    onOpened: {

        GlobalState.countRejection = false

        startValidation()

        console.log(
            "Count Rejection:",
            GlobalState.countRejection
        )
    }

    // ============================================================
    // POPUP CLOSED
    // ============================================================

    onClosed: {

        countdownTimer.stop()
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

            // ================================================
            // COUNTDOWN
            // ================================================

            if (validationScreenPopup.remainingSeconds > 0) {

                validationScreenPopup.remainingSeconds--

                // Explicit repaint
                timerCanvas.requestPaint()
            }

            // ================================================
            // TIMEOUT
            // ================================================

            if (
                validationScreenPopup.remainingSeconds <= 0
                &&
                validationScreenPopup.validationState === "running"
            ) {

                validationScreenPopup.validationState = "failed"

                countdownTimer.stop()

                timerCanvas.requestPaint()

                saveValidationAudit(
                    "Validation Failed"
                )

                GlobalState.countRejection = true

                console.log(
                    "Count Rejection:",
                    GlobalState.countRejection
                )
            }
        }
    }

    // ============================================================
    // SIGNAL VS THRESHOLD
    // ============================================================

    Connections {
        target: SerialManager

        enabled:
            validationScreenPopup.validationState === "running"

        function onSignalChanged()
        {
            if (
                SerialManager.signal >
                GlobalState.signalThreshold
            ) {

                if (
                    !validationScreenPopup.rejectCycleStarted
                ) {

                    validationScreenPopup.rejectCycleStarted =
                            true
                }
            }

            else {

                if (
                    validationScreenPopup.rejectCycleStarted
                ) {

                    validationScreenPopup.rejectCycleStarted =
                            false

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

                easing.type: Easing.OutQuad
            }

            NumberAnimation {
                property: "scale"

                from: 0.85
                to: 1.0

                duration: 350

                easing.type: Easing.OutBack
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

    // ============================================================
    // BACKGROUND / CONTENT
    // ============================================================

    background: Item {

        id: popupContent

        implicitWidth:
            validationScreenPopup.width

        implicitHeight:
            validationScreenPopup.height

        transformOrigin:
            Item.Center

        // ========================================================
        // OUTER GLOW
        // ========================================================

        Rectangle {

            id: glowBorder

            anchors.centerIn:
                parent

            width:
                parent.width +
                14 * uiScale

            height:
                parent.height +
                14 * uiScale

            radius:
                30 * uiScale

            color:
                "transparent"

            border.color:
                validationScreenPopup.stateColor

            border.width:
                3

            opacity:
                0.18

            antialiasing:
                true

            Behavior on border.color {

                ColorAnimation {
                    duration: 250
                }
            }

            SequentialAnimation {

                running:
                    validationScreenPopup.validationState ===
                    "running"

                loops:
                    Animation.Infinite

                NumberAnimation {

                    target:
                        glowBorder

                    property:
                        "opacity"

                    from:
                        0.12

                    to:
                        0.32

                    duration:
                        800

                    easing.type:
                        Easing.InOutQuad
                }

                NumberAnimation {

                    target:
                        glowBorder

                    property:
                        "opacity"

                    from:
                        0.32

                    to:
                        0.12

                    duration:
                        800

                    easing.type:
                        Easing.InOutQuad
                }
            }
        }

        // ========================================================
        // CARD
        // ========================================================

        Rectangle {

            anchors.fill:
                parent

            radius:
                24 * uiScale

            antialiasing:
                true

            gradient: Gradient {

                orientation:
                    Gradient.Vertical

                GradientStop {

                    position:
                        0.0

                    color:
                        "#FFFFFF"
                }

                GradientStop {

                    position:
                        1.0

                    color:
                        "#F0F3FA"
                }
            }

            border.color:
                "#D0D8EC"

            border.width:
                1
        }

        // ========================================================
        // EXIT BUTTON
        // ========================================================

        Rectangle {

            id: exitButton

            visible:
                validationScreenPopup.validationState ===
                "running"

            enabled:
                visible

            width:
                45 * uiScale

            height:
                45 * uiScale

            radius:
                width / 2

            anchors.top:
                parent.top

            anchors.right:
                parent.right

            anchors.topMargin:
                25 * uiScale

            anchors.rightMargin:
                25 * uiScale

            color:

                exitMouse.pressed
                ? "#D32F2F"

                : exitMouse.containsMouse
                ? "#F8D7DA"

                : "#FFFFFF"

            border.color:
                "#D0D8EC"

            border.width:
                1

            antialiasing:
                true

            Text {

                anchors.centerIn:
                    parent

                text:
                    "✕"

                font.pixelSize:
                    25 * uiScale

                font.bold:
                    true

                color:

                    exitMouse.pressed
                    ? "white"
                    : "#1A4DB5"
            }

            MouseArea {

                id: exitMouse

                anchors.fill:
                    parent

                enabled:
                    exitButton.visible

                hoverEnabled:
                    true

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

                    GlobalState.countRejection = true

                    saveValidationAudit(
                        "Validation Skipped"
                    )

                    validationScreenPopup.close()
                }
            }
        }

        // ========================================================
        // MAIN CONTENT
        // ========================================================

        ColumnLayout {

            anchors.fill:
                parent

            anchors.margins:
                34 * uiScale

            anchors.topMargin:
                40 * uiScale

            spacing:
                16 * uiScale

            // ====================================================
            // HEADER
            // ====================================================

            RowLayout {

                Layout.fillWidth:
                    true

                Column {

                    spacing:
                        6 * uiScale

                    Layout.fillWidth:
                        true

                    Text {

                        text:
                            "Validation Screen"

                        font.pixelSize:
                            vTypography.title

                        color:
                            "#1A4DB5"
                    }

                    Rectangle {

                        width:
                            80 * uiScale

                        height:
                            4 * uiScale

                        radius:
                            2 * uiScale

                        color:
                            "#1A4DB5"
                    }
                }

                Rectangle {

                    radius:
                        20 * uiScale

                    height:
                        34 * uiScale

                    width:
                        statusBadgeText.contentWidth +
                        28 * uiScale

                    color:
                        validationScreenPopup.stateColor

                    visible:
                        validationScreenPopup.validationState !==
                        "running"

                    Text {

                        id: statusBadgeText

                        anchors.centerIn:
                            parent

                        text:

                            validationScreenPopup.validationState ===
                            "passed"

                            ? "Passed"
                            : "Failed"

                        font.pixelSize:
                            vTypography.bodySmall

                        color:
                            "white"
                    }
                }
            }

            Item {

                Layout.preferredHeight:
                    4 * uiScale
            }

            // ====================================================
            // CIRCULAR TIMER
            // ====================================================

            Item {

                id: timerContainer

                Layout.alignment:
                    Qt.AlignHCenter

                width:
                    190 * uiScale

                height:
                    190 * uiScale

                visible:
                    validationScreenPopup.validationState ===
                    "running"

                // =================================================
                // TIMER CANVAS
                // =================================================

                Canvas {

                    id: timerCanvas

                    anchors.fill:
                        parent

                    antialiasing:
                        true

                    onPaint: {

                        var ctx = getContext("2d")

                        // =========================================
                        // CLEAR
                        // =========================================

                        ctx.clearRect(
                            0,
                            0,
                            width,
                            height
                        )

                        // =========================================
                        // CENTER
                        // =========================================

                        var cx =
                                width / 2

                        var cy =
                                height / 2

                        // =========================================
                        // RADIUS
                        // =========================================

                        var radius =
                                Math.min(
                                    width,
                                    height
                                ) * 0.40

                        // =========================================
                        // LINE WIDTH
                        // =========================================

                        var lineWidth =
                                Math.max(
                                    6,
                                    10 * uiScale
                                )

                        // =========================================
                        // TIMER VALUES
                        // =========================================

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

                        // =========================================
                        // PROGRESS
                        // =========================================

                        var progress =
                                remaining / duration

                        // =========================================
                        // START ANGLE
                        //
                        // -PI / 2 = 12 o'clock
                        // =========================================

                        var startAngle =
                                -Math.PI / 2

                        // =================================================
                        // 1. GREY BACKGROUND RING
                        // =================================================

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

                        // =================================================
                        // 2. COUNTDOWN ARC
                        // =================================================

                        if (progress > 0) {

                            var sweep =
                                    progress *
                                    Math.PI *
                                    2

                            var endAngle =
                                    startAngle +
                                    sweep

                            ctx.beginPath()

                            ctx.lineWidth =
                                    lineWidth

                            ctx.strokeStyle =
                                    remaining <= 10
                                    ? "#FF5252"
                                    : "#1A4DB5"

                            ctx.lineCap =
                                    "round"

                            ctx.arc(
                                cx,
                                cy,
                                radius,
                                startAngle,
                                endAngle,
                                false
                            )

                            ctx.stroke()
                        }
                    }

                    // =================================================
                    // INITIAL PAINT
                    // =================================================

                    Component.onCompleted: {

                        console.log(
                            "Validation Canvas created:",
                            width,
                            height
                        )

                        requestPaint()
                    }

                    // =================================================
                    // SIZE CHANGED
                    // =================================================

                    onWidthChanged: {

                        requestPaint()
                    }

                    onHeightChanged: {

                        requestPaint()
                    }
                }

                // =================================================
                // TIMER TEXT
                // =================================================

                Column {

                    anchors.centerIn:
                        parent

                    spacing:
                        2 * uiScale

                    z:
                        10

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

                            validationScreenPopup.remainingSeconds <= 10
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
                            "#8A93A6"
                    }
                }
            }

            // ====================================================
            // RESULT ICON
            // ====================================================

            Rectangle {

                Layout.alignment:
                    Qt.AlignHCenter

                width:
                    96 * uiScale

                height:
                    96 * uiScale

                radius:
                    width / 2

                color:
                    validationScreenPopup.stateColor

                antialiasing:
                    true

                visible:
                    validationScreenPopup.validationState !==
                    "running"

                opacity:
                    0.12

                Rectangle {

                    anchors.centerIn:
                        parent

                    width:
                        parent.width * 0.72

                    height:
                        width

                    radius:
                        width / 2

                    color:
                        validationScreenPopup.stateColor

                    antialiasing:
                        true

                    Text {

                        anchors.centerIn:
                            parent

                        text:

                            validationScreenPopup.validationState ===
                            "passed"

                            ? "✓"
                            : "✕"

                        color:
                            "#333"

                        font.pixelSize:
                            vTypography.title * 1.3
                    }
                }
            }

            // ====================================================
            // FLEXIBLE SPACE
            // ====================================================

            Item {

                Layout.fillHeight:
                    true
            }

            // ====================================================
            // MESSAGE CARD
            // ====================================================

            Rectangle {

                Layout.fillWidth:
                    true

                Layout.preferredHeight:
                    76 * uiScale

                radius:
                    14 * uiScale

                color:
                    "#FFFFFF"

                border.color:
                    validationScreenPopup.stateColor

                border.width:
                    1.5

                antialiasing:
                    true

                Behavior on border.color {

                    ColorAnimation {
                        duration: 250
                    }
                }

                RowLayout {

                    anchors.centerIn:
                        parent

                    spacing:
                        14 * uiScale

                    Rectangle {

                        width:
                            15 * uiScale

                        height:
                            15 * uiScale

                        radius:
                            width / 2

                        color:
                            validationScreenPopup.stateColor

                        antialiasing:
                            true

                        Layout.preferredWidth:
                            15 * uiScale

                        Layout.preferredHeight:
                            15 * uiScale

                        SequentialAnimation on opacity {

                            running:
                                validationScreenPopup.validationState ===
                                "running"

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

                        horizontalAlignment:
                            Text.AlignHCenter

                        font.pixelSize:
                            vTypography.subHeading

                        color:
                            "#1A4DB5"

                        text: {

                            if (
                                validationScreenPopup.validationState ===
                                "failed"
                            )
                                return "Validation Failed"

                            if (
                                validationScreenPopup.validationState ===
                                "passed"
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

                Layout.topMargin:
                    6 * uiScale

                spacing:
                    0

                Repeater {

                    id: indicatorRepeater

                    model:
                        validationScreenPopup.totalRounds

                    delegate: RowLayout {

                        spacing:
                            0

                        function pop()
                        {
                            popAnim.start()
                        }

                        Rectangle {

                            id: dot

                            width:
                                40 * uiScale

                            height:
                                40 * uiScale

                            radius:
                                width / 2

                            antialiasing:
                                true

                            Layout.preferredWidth:
                                40 * uiScale

                            Layout.preferredHeight:
                                40 * uiScale

                            color:

                                validationScreenPopup.roundStatus[index]

                                ? "#2ECC71"

                                : (
                                    validationScreenPopup.currentRound ===
                                    index + 1
                                    &&
                                    validationScreenPopup.validationState ===
                                    "running"
                                  )

                                ? "#FFFFFF"
                                : "#D8DCE6"

                            border.width:

                                (
                                    validationScreenPopup.currentRound ===
                                    index + 1
                                    &&
                                    validationScreenPopup.validationState ===
                                    "running"
                                )

                                ? 3
                                : 1

                            border.color:

                                (
                                    validationScreenPopup.currentRound ===
                                    index + 1
                                    &&
                                    validationScreenPopup.validationState ===
                                    "running"
                                )

                                ? "#1A4DB5"
                                : "#D8DCE6"

                            Behavior on color {

                                ColorAnimation {
                                    duration: 200
                                }
                            }

                            SequentialAnimation {

                                id: popAnim

                                NumberAnimation {

                                    target:
                                        dot

                                    property:
                                        "scale"

                                    from:
                                        1.0

                                    to:
                                        1.35

                                    duration:
                                        140

                                    easing.type:
                                        Easing.OutQuad
                                }

                                NumberAnimation {

                                    target:
                                        dot

                                    property:
                                        "scale"

                                    from:
                                        1.35

                                    to:
                                        1.0

                                    duration:
                                        160

                                    easing.type:
                                        Easing.OutBack
                                }
                            }

                            Text {

                                anchors.centerIn:
                                    parent

                                visible:
                                    validationScreenPopup.roundStatus[index]

                                text:
                                    "✓"

                                color:
                                    "white"

                                font.pixelSize:
                                    vTypography.bodySmall

                                font.bold:
                                    true
                            }

                            Text {

                                anchors.centerIn:
                                    parent

                                visible:
                                    !validationScreenPopup.roundStatus[index]

                                text:
                                    index + 1

                                color:

                                    validationScreenPopup.currentRound ===
                                    index + 1
                                    &&
                                    validationScreenPopup.validationState ===
                                    "running"

                                    ? "#1A4DB5"
                                    : "#8A93A6"

                                font.pixelSize:
                                    vTypography.bodySmall
                            }
                        }

                        Rectangle {

                            visible:
                                index <
                                validationScreenPopup.totalRounds - 1

                            width:
                                46 * uiScale

                            height:
                                3

                            color:

                                validationScreenPopup.roundStatus[index]
                                ? "#2ECC71"
                                : "#D8DCE6"

                            Layout.preferredWidth:
                                46 * uiScale

                            Layout.preferredHeight:
                                3

                            Behavior on color {

                                ColorAnimation {
                                    duration: 200
                                }
                            }
                        }
                    }
                }
            }

            // ====================================================
            // FLEXIBLE SPACE
            // ====================================================

            Item {

                Layout.fillHeight:
                    true
            }

            // ====================================================
            // BUTTONS
            // ====================================================

            Row {

                Layout.alignment:
                    Qt.AlignHCenter

                spacing:
                    22 * uiScale

                visible:
                    validationScreenPopup.validationState !==
                    "running"

                Rectangle {

                    id: closeBtn

                    width:
                        160 * uiScale

                    height:
                        52 * uiScale

                    radius:
                        12 * uiScale

                    color:
                        closeArea.pressed
                        ? "#0D3BA8"
                        : "#1A4DB5"

                    scale:
                        closeArea.pressed
                        ? 0.96
                        : 1.0

                    antialiasing:
                        true

                    Behavior on scale {

                        NumberAnimation {
                            duration: 120
                        }
                    }

                    Text {

                        anchors.centerIn:
                            parent

                        text:

                            validationScreenPopup.validationState ===
                            "passed"

                            ? "Done"
                            : "Close"

                        color:
                            "white"

                        font.pixelSize:
                            vTypography.body
                    }

                    MouseArea {

                        id: closeArea

                        anchors.fill:
                            parent

                        hoverEnabled:
                            true

                        cursorShape:
                            Qt.PointingHandCursor

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
                }
            }
        }
    }

    // ============================================================
    // REPAINT WHEN TIMER VALUES CHANGE
    // ============================================================

    onRemainingSecondsChanged: {

        timerCanvas.requestPaint()
    }

    onRoundDurationChanged: {

        timerCanvas.requestPaint()
    }
}
