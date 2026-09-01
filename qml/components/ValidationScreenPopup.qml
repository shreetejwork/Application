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
    // START VALIDATION
    // ============================================================

    function startValidation()
    {
        countdownTimer.stop()

        currentRound = 1

        roundStatus = [
            false,
            false,
            false
        ]

        remainingSeconds = roundDuration

        rejectCycleStarted = false

        validationState = "running"

        // Give Canvas a clean starting state
        if (timerArcCanvas)
            timerArcCanvas.requestPaint()

        countdownTimer.start()
    }

    // ============================================================
    // COMPLETE ROUND
    // ============================================================

    function completeRound()
    {
        if (validationState !== "running")
            return

        var arr = roundStatus.slice()

        arr[currentRound - 1] = true

        roundStatus = arr

        Qt.callLater(function() {

            var item =
                indicatorRepeater.itemAt(currentRound - 1)

            if (item)
                item.pop()
        })

        // ========================================================
        // FINAL ROUND
        // ========================================================

        if (currentRound === totalRounds) {

            validationState = "passed"

            countdownTimer.stop()

            if (timerArcCanvas)
                timerArcCanvas.requestPaint()

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

        if (timerArcCanvas)
            timerArcCanvas.requestPaint()
    }

    // ============================================================
    // POPUP OPENED
    // ============================================================

    onOpened: {

        GlobalState.countRejection = false

        startValidation()

        console.log(
            "Validation popup opened"
        )

        console.log(
            "Round duration:",
            roundDuration
        )
    }

    // ============================================================
    // POPUP CLOSED
    // ============================================================

    onClosed: {

        countdownTimer.stop()

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

            if (
                validationScreenPopup.validationState
                !== "running"
            ) {
                stop()
                return
            }

            if (
                validationScreenPopup.remainingSeconds
                > 1
            ) {

                validationScreenPopup.remainingSeconds--

            } else {

                validationScreenPopup.remainingSeconds = 0

                validationScreenPopup.validationState =
                    "failed"

                stop()

                if (timerArcCanvas)
                    timerArcCanvas.requestPaint()

                saveValidationAudit(
                    "Validation Failed"
                )

                GlobalState.countRejection = true

                console.log(
                    "Validation Failed"
                )
            }
        }
    }

    // ============================================================
    // REPAINT CANVAS
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
            if (
                SerialManager.signal
                > GlobalState.signalThreshold
            ) {

                if (
                    !validationScreenPopup.rejectCycleStarted
                ) {

                    validationScreenPopup.rejectCycleStarted =
                        true
                }

            } else {

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

            MouseArea {

                id: exitMouse

                anchors.fill: parent

                hoverEnabled: true

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
        //
        // IMPORTANT:
        // TIMER IS INSIDE THIS COLUMN.
        //
        // Therefore Layout.alignment works correctly.
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

                // STATUS BADGE
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
            // TIMER
            // ====================================================

            Item {

                id: timerContainer

                Layout.alignment:
                    Qt.AlignHCenter

                Layout.preferredWidth: 190
                Layout.preferredHeight: 190

                width: 190
                height: 190

                visible:
                    validationScreenPopup.validationState
                    === "running"

                // =================================================
                // GREY BACKGROUND RING
                // =================================================

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

                // =================================================
                // COUNTDOWN ARC
                // =================================================

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

                        // =================================================
                        // FULL CIRCLE
                        // =================================================

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

                        // =================================================
                        // PARTIAL COUNTDOWN ARC
                        // =================================================

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

                // =================================================
                // TIMER TEXT
                // =================================================

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
                            "#8A93A6"
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
            // BOTTOM BUTTON AREA
            // ====================================================

            Item {

                Layout.fillHeight: true

                Layout.minimumHeight: 1
            }

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

                    MouseArea {

                        id: closeArea

                        anchors.fill: parent

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
}
