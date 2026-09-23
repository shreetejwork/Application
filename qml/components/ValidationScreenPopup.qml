import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import AppState 1.0
import Backend 1.0

Popup {
    id: validationScreenPopup

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

    Typography {
        id: vTypography
        scale: 1.0
    }

    property int totalRounds: 3
    property var globalTopBar: null
    property int currentRound: 1
    property var roundStatus: [false, false, false]
    property int roundDuration: 60
    property int remainingSeconds: roundDuration
    property bool rejectCycleStarted: false
    property string validationState: "running"

    property color stateColor: validationState === "failed"
                                 ? "#FF5252"
                                 : validationState === "passed"
                                   ? "#2ECC71"
                                   : "#1A4DB5"

    function formatTime(seconds) {
        var minutes = Math.floor(seconds / 60)
        var remainder = seconds % 60
        return (minutes < 10 ? "0" : "") + minutes + ":" +
               (remainder < 10 ? "0" : "") + remainder
    }

    function saveValidationAudit(action) {
        var role = GlobalState.loggedInUserRole
        var username = GlobalState.loggedInUserName
        var auditUser = "---"

        if (GlobalState.developerLogin) {
            auditUser = "D/Developer"
        } else if (GlobalState.engineerLogin) {
            auditUser = "E/Engineer"
        } else if (role !== "" && username !== "") {
            var initial = "U"
            if (role === "Admin")
                initial = "A"
            else if (role === "Supervisor")
                initial = "S"
            else if (role === "Operator")
                initial = "O"
            auditUser = initial + "/" + username
        }

        databaseManager.addAuditTrailRecord(auditUser, "", "", action)
    }

    function resetResultAnimation() {
        successFailureAnimation.stop()
        successFailureCircle.scale = 0.70
        successFailureCircle.opacity = 0
        successFailureCircle.visible = false
        resultIcon.scale = 0.40
        resultIcon.opacity = 0
    }

    function startValidation() {
        countdownTimer.stop()
        currentRound = 1
        roundStatus = [false, false, false]
        remainingSeconds = roundDuration
        rejectCycleStarted = false
        validationState = "running"
        resetResultAnimation()
        timerBackgroundCanvas.requestPaint()
        timerArcCanvas.requestPaint()
        countdownTimer.start()
    }

    function completeRound() {
        if (validationState !== "running" ||
            currentRound < 1 || currentRound > totalRounds)
            return

        var statuses = roundStatus.slice()
        statuses[currentRound - 1] = true
        roundStatus = statuses

        var completedRound = currentRound - 1
        Qt.callLater(function() {
            var indicator = indicatorRepeater.itemAt(completedRound)
            if (indicator)
                indicator.pop()
        })

        if (currentRound === totalRounds) {
            countdownTimer.stop()
            validationState = "passed"
            rejectCycleStarted = false
            timerArcCanvas.requestPaint()
            saveValidationAudit("Validation Passed")
            Qt.callLater(function() {
                showSuccessAnimation()
                GlobalState.countRejection = true
            })
            return
        }

        currentRound++
        remainingSeconds = roundDuration
        rejectCycleStarted = false
        timerArcCanvas.requestPaint()
    }

    function showSuccessAnimation() {
        successFailureCircle.visible = true
        successFailureCircle.scale = 0.70
        successFailureCircle.opacity = 0
        resultIcon.scale = 0.40
        resultIcon.opacity = 0
        successFailureAnimation.start()
    }

    function showFailureAnimation() {
        successFailureCircle.visible = true
        successFailureCircle.scale = 0.70
        successFailureCircle.opacity = 0
        resultIcon.scale = 0.40
        resultIcon.opacity = 0
        successFailureAnimation.start()
    }

    onOpened: {
        GlobalState.countRejection = false
        startValidation()
    }

    onClosed: {
        countdownTimer.stop()
        successFailureAnimation.stop()
        rejectCycleStarted = false
    }

    Timer {
        id: countdownTimer
        interval: 1000
        repeat: true

        onTriggered: {
            if (validationState !== "running") {
                stop()
                return
            }

            if (remainingSeconds > 1) {
                remainingSeconds--
                return
            }

            remainingSeconds = 0
            stop()
            rejectCycleStarted = false
            validationState = "failed"
            timerArcCanvas.requestPaint()
            saveValidationAudit("Validation Failed")
            Qt.callLater(showFailureAnimation)
            GlobalState.countRejection = true
        }
    }

    onRemainingSecondsChanged: timerArcCanvas.requestPaint()
    onRoundDurationChanged: timerArcCanvas.requestPaint()

    Connections {
        target: SerialManager
        enabled: validationState === "running"

        function onSignalChanged() {
            if (validationState !== "running")
                return

            if (SerialManager.signal > GlobalState.signalThreshold) {
                if (!rejectCycleStarted)
                    rejectCycleStarted = true
                return
            }

            if (rejectCycleStarted) {
                rejectCycleStarted = false
                completeRound()
            }
        }
    }

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

    background: Item {
        id: popupContent
        width: validationScreenPopup.width
        height: validationScreenPopup.height

        Rectangle {
            id: glowBorder
            anchors.centerIn: parent
            width: parent.width + 14
            height: parent.height + 14
            radius: 30
            color: "transparent"
            border.color: validationScreenPopup.stateColor
            border.width: 3
            opacity: 0.18
            antialiasing: true

            SequentialAnimation {
                running: validationScreenPopup.validationState === "running"
                loops: Animation.Infinite
                NumberAnimation {
                    target: glowBorder
                    property: "opacity"
                    from: 0.12
                    to: 0.32
                    duration: 800
                    easing.type: Easing.InOutQuad
                }
                NumberAnimation {
                    target: glowBorder
                    property: "opacity"
                    from: 0.32
                    to: 0.12
                    duration: 800
                    easing.type: Easing.InOutQuad
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: 24
            antialiasing: true
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: "#FFFFFF" }
                GradientStop { position: 1.0; color: "#F0F3FA" }
            }
            border.color: "#D0D8EC"
            border.width: 1
        }

        Rectangle {
            id: exitButton
            visible: validationScreenPopup.validationState === "running"
            width: 45
            height: 45
            radius: 22.5
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 25
            anchors.rightMargin: 25
            color: exitMouse.pressed ? "#D32F2F"
                                     : exitMouse.containsMouse ? "#F8D7DA" : "#FFFFFF"
            scale: exitMouse.pressed ? 0.92 : 1.0
            border.color: "#D0D8EC"
            border.width: 1
            antialiasing: true

            Text {
                anchors.centerIn: parent
                text: "✕"
                font.pixelSize: 25
                color: exitMouse.pressed ? "white" : "#1A4DB5"
            }

            MouseArea {
                id: exitMouse
                anchors.fill: parent
                hoverEnabled: true
                    onPressed: if (globalTopBar) globalTopBar.showNotification("Validation exit pressed")
                    onReleased: if (globalTopBar) globalTopBar.showNotification("Validation exit released")
                onClicked: {
                    if (globalTopBar) globalTopBar.showNotification("Validation exit clicked")
                    countdownTimer.stop()
                    rejectCycleStarted = false
                    GlobalState.countRejection = true
                    saveValidationAudit("Validation Skipped")
                    validationScreenPopup.close()
                }
            }
        }

        ColumnLayout {
            id: mainLayout
            anchors.fill: parent
            anchors.leftMargin: 34
            anchors.rightMargin: 34
            anchors.topMargin: 40
            anchors.bottomMargin: 30
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 45

                Column {
                    Layout.fillWidth: true
                    spacing: 6
                    Text {
                        text: "Validation Screen"
                        font.pixelSize: vTypography.title
                        color: "#1A4DB5"
                    }
                    Rectangle {
                        width: 80
                        height: 4
                        radius: 2
                        color: "#1A4DB5"
                    }
                }

                Rectangle {
                    visible: validationScreenPopup.validationState !== "running"
                    height: 34
                    width: statusBadgeText.implicitWidth + 28
                    radius: 17
                    color: validationScreenPopup.stateColor
                    Text {
                        id: statusBadgeText
                        anchors.centerIn: parent
                        text: validationScreenPopup.validationState === "passed" ? "Passed" : "Failed"
                        font.pixelSize: vTypography.bodySmall
                        color: "white"
                    }
                }
            }

            Item {
                id: timerContainer
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 190
                Layout.preferredHeight: 190
                width: 190
                height: 190

                Item {
                    id: timerContent
                    anchors.fill: parent
                    visible: validationScreenPopup.validationState === "running"

                    Canvas {
                        id: timerBackgroundCanvas
                        anchors.fill: parent
                        antialiasing: true
                        onPaint: {
                            var context = getContext("2d")
                            context.clearRect(0, 0, width, height)
                            context.beginPath()
                            context.lineWidth = 10
                            context.strokeStyle = "#E2E7F5"
                            context.lineCap = "round"
                            context.arc(width / 2, height / 2, 72, 0, Math.PI * 2, false)
                            context.stroke()
                        }
                        Component.onCompleted: requestPaint()
                    }

                    Canvas {
                        id: timerArcCanvas
                        anchors.fill: parent
                        z: 2
                        antialiasing: true
                        onPaint: {
                            var context = getContext("2d")
                            context.clearRect(0, 0, width, height)
                            var duration = Math.max(1, validationScreenPopup.roundDuration)
                            var remaining = Math.max(0, Math.min(validationScreenPopup.remainingSeconds, duration))
                            var progress = remaining / duration
                            var startAngle = -Math.PI / 2
                            context.beginPath()
                            context.lineWidth = 10
                            context.strokeStyle = remaining <= 10 ? "#FF5252" : "#1A4DB5"
                            context.lineCap = "round"
                            if (progress >= 0.999) {
                                context.arc(width / 2, height / 2, 72, 0, Math.PI * 2, false)
                            } else if (progress > 0) {
                                context.arc(width / 2, height / 2, 72, startAngle,
                                            startAngle + progress * Math.PI * 2, false)
                            }
                            context.stroke()
                        }
                        Component.onCompleted: requestPaint()
                        onWidthChanged: requestPaint()
                        onHeightChanged: requestPaint()
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 2
                        z: 10
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: validationScreenPopup.formatTime(validationScreenPopup.remainingSeconds)
                            font.pixelSize: vTypography.title * 1.5
                            color: validationScreenPopup.remainingSeconds <= 10 ? "#FF5252" : "#1A2E52"
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "remaining"
                            font.pixelSize: vTypography.body * 0.85
                            color: "#3D3846"
                        }
                    }
                }

                Item {
                    id: resultContent
                    anchors.fill: parent
                    visible: validationScreenPopup.validationState !== "running"

                    Rectangle {
                        id: successFailureCircle
                        width: 150
                        height: 150
                        radius: 75
                        anchors.centerIn: parent
                        visible: false
                        opacity: 0
                        scale: 0.70
                        color: validationScreenPopup.validationState === "passed" ? "#2ECC71" : "#FF5252"
                        border.width: 5
                        border.color: validationScreenPopup.validationState === "passed" ? "#25B866" : "#E53935"
                        antialiasing: true

                        Rectangle {
                            width: 122
                            height: 122
                            radius: 61
                            anchors.centerIn: parent
                            color: "#FFFFFF"
                            antialiasing: true

                            Text {
                                id: resultIcon
                                anchors.centerIn: parent
                                text: validationScreenPopup.validationState === "passed" ? "✓" : "✕"
                                font.pixelSize: 68
                                color: validationScreenPopup.validationState === "passed" ? "#2ECC71" : "#FF5252"
                                opacity: 0
                                scale: 0.40
                                antialiasing: true
                            }
                        }

                        SequentialAnimation {
                            id: successFailureAnimation
                            ParallelAnimation {
                                NumberAnimation {
                                    target: successFailureCircle
                                    property: "scale"
                                    from: 0.70
                                    to: 1.0
                                    duration: 420
                                    easing.type: Easing.OutBack
                                }
                                NumberAnimation {
                                    target: successFailureCircle
                                    property: "opacity"
                                    from: 0
                                    to: 1
                                    duration: 280
                                    easing.type: Easing.OutQuad
                                }
                            }
                            ParallelAnimation {
                                NumberAnimation {
                                    target: resultIcon
                                    property: "scale"
                                    from: 0.40
                                    to: 1.0
                                    duration: 300
                                    easing.type: Easing.OutBack
                                }
                                NumberAnimation {
                                    target: resultIcon
                                    property: "opacity"
                                    from: 0
                                    to: 1
                                    duration: 250
                                    easing.type: Easing.OutQuad
                                }
                            }
                            SequentialAnimation {
                                NumberAnimation {
                                    target: successFailureCircle
                                    property: "scale"
                                    from: 1.0
                                    to: 1.06
                                    duration: 180
                                    easing.type: Easing.OutQuad
                                }
                                NumberAnimation {
                                    target: successFailureCircle
                                    property: "scale"
                                    from: 1.06
                                    to: 1.0
                                    duration: 180
                                    easing.type: Easing.InOutQuad
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 68
                radius: 14
                color: "#FFFFFF"
                border.color: validationScreenPopup.stateColor
                border.width: 1.5
                antialiasing: true

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 14
                    Rectangle {
                        width: 15
                        height: 15
                        radius: 7.5
                        color: validationScreenPopup.stateColor
                        Layout.preferredWidth: 15
                        Layout.preferredHeight: 15
                        SequentialAnimation on opacity {
                            running: validationScreenPopup.validationState === "running"
                            loops: Animation.Infinite
                            NumberAnimation { from: 1; to: 0.25; duration: 600 }
                            NumberAnimation { from: 0.25; to: 1; duration: 600 }
                        }
                    }
                    Text {
                        font.pixelSize: vTypography.subHeading
                        color: "#1A4DB5"
                        text: validationScreenPopup.validationState === "failed"
                              ? "Validation Failed"
                              : validationScreenPopup.validationState === "passed"
                                ? "Validation Passed"
                                : "Please pass the sample for validation"
                    }
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 0

                Repeater {
                    id: indicatorRepeater
                    model: validationScreenPopup.totalRounds

                    delegate: RowLayout {
                        spacing: 0
                        function pop() { popAnim.start() }

                        Rectangle {
                            id: dot
                            width: 40
                            height: 40
                            radius: 20
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40
                            antialiasing: true
                            color: validationScreenPopup.roundStatus[index]
                                   ? "#2ECC71"
                                   : validationScreenPopup.currentRound === index + 1 && validationScreenPopup.validationState === "running"
                                     ? "#FFFFFF" : "#D8DCE6"
                            border.width: validationScreenPopup.currentRound === index + 1 && validationScreenPopup.validationState === "running" ? 3 : 1
                            border.color: validationScreenPopup.currentRound === index + 1 && validationScreenPopup.validationState === "running" ? "#1A4DB5" : "#D8DCE6"

                            Text {
                                anchors.centerIn: parent
                                visible: validationScreenPopup.roundStatus[index]
                                text: "✓"
                                color: "white"
                                font.pixelSize: vTypography.bodySmall
                            }
                            Text {
                                anchors.centerIn: parent
                                visible: !validationScreenPopup.roundStatus[index]
                                text: index + 1
                                color: validationScreenPopup.currentRound === index + 1 && validationScreenPopup.validationState === "running" ? "#1A4DB5" : "#8A93A6"
                                font.pixelSize: vTypography.bodySmall
                            }
                            SequentialAnimation {
                                id: popAnim
                                NumberAnimation { target: dot; property: "scale"; from: 1; to: 1.35; duration: 140 }
                                NumberAnimation { target: dot; property: "scale"; from: 1.35; to: 1; duration: 160; easing.type: Easing.OutBack }
                            }
                        }

                        Rectangle {
                            visible: index < validationScreenPopup.totalRounds - 1
                            Layout.preferredWidth: 46
                            Layout.preferredHeight: 3
                            width: 46
                            height: 3
                            color: validationScreenPopup.roundStatus[index] ? "#2ECC71" : "#D8DCE6"
                        }
                    }
                }
            }

            Item {
                Layout.fillHeight: true
                Layout.minimumHeight: 1
            }

            Row {
                Layout.alignment: Qt.AlignHCenter
                spacing: 22
                visible: validationScreenPopup.validationState !== "running"

                Rectangle {
                    id: closeBtn
                    width: 160
                    height: 52
                    radius: 12
                    color: closeArea.pressed ? "#0D3BA8" : "#1A4DB5"
                    scale: closeArea.pressed ? 0.96 : 1.0
                    antialiasing: true

                    Text {
                        anchors.centerIn: parent
                        text: validationScreenPopup.validationState === "passed" ? "Done" : "Close"
                        color: "white"
                        font.pixelSize: vTypography.body
                    }

                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        onPressed: if (globalTopBar) globalTopBar.showNotification("Validation close pressed")
                        onReleased: if (globalTopBar) globalTopBar.showNotification("Validation close released")
                        onClicked: {
                            if (globalTopBar) globalTopBar.showNotification("Validation close clicked")
                            countdownTimer.stop()
                            GlobalState.countRejection = true
                            validationScreenPopup.close()
                        }
                    }
                }
            }
        }
    }
}
