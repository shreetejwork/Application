import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import AppState 1.0
import Backend 1.0

Popup {
    id: validationScreenPopup

    Typography {
        id: vTypography

        scale: validationScreenPopup.uiScale
    }

    property real baseWidth: 1024
    property real baseHeight: 600


    property real uiScale: Math.min(
                                Overlay.overlay.width / baseWidth,
                                Overlay.overlay.height / baseHeight
                            )

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
    // THEME HELPERS
    // ============================================================

    property color stateColor: validationState === "failed" ? "#FF5252"
                                : validationState === "passed" ? "#2ECC71"
                                : "#1A4DB5"

    // ============================================================
    // STATE
    // ============================================================

    property int totalRounds: 3
    property int currentRound: 1
    property var roundStatus: [false, false, false]

    property int roundDuration: 180
    property int remainingSeconds: roundDuration

    property bool rejectCycleStarted: false

    // "running" | "passed" | "failed"
    property string validationState: "running"

    function formatTime(sec) {
        var m = Math.floor(sec / 60)
        var s = sec % 60
        return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s
    }

    function startValidation() {
        currentRound = 1
        roundStatus = [false, false, false]
        remainingSeconds = roundDuration
        rejectCycleStarted = false
        validationState = "running"
        countdownTimer.start()
    }

    function completeRound() {
        var arr = roundStatus.slice()
        arr[currentRound - 1] = true
        roundStatus = arr

        Qt.callLater(function() {
            if (indicatorRepeater.itemAt(currentRound - 1))
                indicatorRepeater.itemAt(currentRound - 1).pop()
        })

        if (currentRound === totalRounds) {
            validationState = "passed"
            countdownTimer.stop()
        } else {
            currentRound++
            remainingSeconds = roundDuration
        }
    }

    onOpened: startValidation()

    // ============================================================
    // TIMER
    // ============================================================

    Timer {
        id: countdownTimer
        interval: 1000
        repeat: true
        running: false

        onTriggered: {
            if (validationScreenPopup.remainingSeconds > 0) {
                validationScreenPopup.remainingSeconds--
            } else {
                validationScreenPopup.validationState = "failed"
                countdownTimer.stop()
            }
        }
    }

    // ============================================================
    // SIGNAL vs THRESHOLD LOGIC
    // ============================================================

    Connections {
        target: SerialManager
        enabled: validationScreenPopup.validationState === "running"

        function onSignalChanged() {

            if (SerialManager.signal > GlobalState.signalThreshold) {

                if (!validationScreenPopup.rejectCycleStarted) {
                    validationScreenPopup.rejectCycleStarted = true
                }
            } else {

                if (validationScreenPopup.rejectCycleStarted) {

                    validationScreenPopup.rejectCycleStarted = false
                    GlobalState.rejectedCount++
                    validationScreenPopup.completeRound()
                }
            }
        }
    }

    // ============================================================
    // OPEN / CLOSE ANIMATION
    // ============================================================

    enter: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 350; easing.type: Easing.OutQuad }
            NumberAnimation { property: "scale"; from: 0.85; to: 1.0; duration: 350; easing.type: Easing.OutBack }
        }
    }

    exit: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 250; easing.type: Easing.InQuad }
            NumberAnimation { property: "scale"; from: 1; to: 0.85; duration: 250; easing.type: Easing.InQuad }
        }
    }

    // ============================================================
    // BACKGROUND / CONTENT
    // ============================================================

    background: Item {
        id: popupContent
        implicitWidth: validationScreenPopup.width
        implicitHeight: validationScreenPopup.height
        transformOrigin: Item.Center

        // ---- Outer glow ----
        Rectangle {
            id: glowBorder
            anchors.centerIn: parent
            width: parent.width + 14 * uiScale
            height: parent.height + 14 * uiScale
            radius: 30 * uiScale
            color: "transparent"
            border.color: validationScreenPopup.stateColor
            border.width: 3
            opacity: 0.18
            antialiasing: true

            Behavior on border.color { ColorAnimation { duration: 250 } }

            SequentialAnimation {
                running: validationScreenPopup.validationState === "running"
                loops: Animation.Infinite

                NumberAnimation { target: glowBorder; property: "opacity"; from: 0.12; to: 0.32; duration: 800; easing.type: Easing.InOutQuad }
                NumberAnimation { target: glowBorder; property: "opacity"; from: 0.32; to: 0.12; duration: 800; easing.type: Easing.InOutQuad }
            }
        }

        // ---- Card surface with subtle gradient ----
        Rectangle {
            anchors.fill: parent
            radius: 24 * uiScale
            antialiasing: true

            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: "#FFFFFF" }
                GradientStop { position: 1.0; color: "#F0F3FA" }
            }

            border.color: "#D0D8EC"
            border.width: 1
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 34 * uiScale
            anchors.topMargin: 40 * uiScale
            spacing: 16 * uiScale

            // ===== HEADER ROW =====
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "Validation Screen"
                    font.pixelSize: vTypography.title
                    font.bold: true
                    color: "#1A2E52"
                    Layout.fillWidth: true
                }

                Rectangle {
                    radius: 20 * uiScale
                    height: 34 * uiScale
                    width: roundBadgeText.implicitWidth + 28 * uiScale
                    color: "#E8EEFB"
                    border.color: "#D0D8EC"
                    border.width: 1
                    antialiasing: true
                    visible: validationScreenPopup.validationState === "running"

                    Text {
                        id: roundBadgeText
                        anchors.centerIn: parent
                        text: "Round " + validationScreenPopup.currentRound + " / " + validationScreenPopup.totalRounds
                        font.pixelSize: vTypography.bodySmall
                        font.bold: true
                        color: "#1A4DB5"
                    }
                }

                Rectangle {
                    radius: 20 * uiScale
                    height: 34 * uiScale
                    width: statusBadgeText.implicitWidth + 28 * uiScale
                    color: validationScreenPopup.stateColor
                    antialiasing: true
                    visible: validationScreenPopup.validationState !== "running"

                    Text {
                        id: statusBadgeText
                        anchors.centerIn: parent
                        text: validationScreenPopup.validationState === "passed" ? "Passed" : "Failed"
                        font.pixelSize: vTypography.bodySmall
                        font.bold: true
                        color: "white"
                    }
                }
            }

            Item { Layout.preferredHeight: 4 * uiScale }

            // ===== CIRCULAR TIMER =====

            Item {
                Layout.alignment: Qt.AlignHCenter
                width: 190 * uiScale
                height: 190 * uiScale
                visible: validationScreenPopup.validationState === "running"

                // track
                Canvas {
                    id: timerTrack
                    anchors.fill: parent
                    renderTarget: Canvas.Image
                    renderStrategy: Canvas.Immediate
                    smooth: true

                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()

                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.reset()
                        var cx = width / 2, cy = height / 2
                        var r = Math.min(width, height) / 2 - 10 * uiScale
                        ctx.lineWidth = 10 * uiScale
                        ctx.strokeStyle = "#E2E7F5"
                        ctx.beginPath()
                        ctx.arc(cx, cy, r, 0, Math.PI * 2)
                        ctx.stroke()
                    }
                }

                // progress arc
                Canvas {
                    id: timerArc
                    anchors.fill: parent
                    renderTarget: Canvas.Image
                    renderStrategy: Canvas.Immediate
                    smooth: true

                    property real fraction: validationScreenPopup.remainingSeconds / validationScreenPopup.roundDuration

                    onFractionChanged: requestPaint()
                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()

                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.reset()
                        var cx = width / 2, cy = height / 2
                        var r = Math.min(width, height) / 2 - 10 * uiScale
                        var start = -Math.PI / 2
                        var end = start + (Math.PI * 2 * fraction)

                        ctx.lineWidth = 10 * uiScale
                        ctx.lineCap = "round"
                        ctx.strokeStyle = validationScreenPopup.remainingSeconds <= 10
                                          ? "#FF5252" : "#1A4DB5"
                        ctx.beginPath()
                        ctx.arc(cx, cy, r, start, end, false)
                        ctx.stroke()
                    }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 2

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: validationScreenPopup.formatTime(validationScreenPopup.remainingSeconds)
                        font.pixelSize: vTypography.title * 1.5
                        font.bold: true
                        color: validationScreenPopup.remainingSeconds <= 10 ? "#FF5252" : "#1A2E52"
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "remaining"
                        font.pixelSize: vTypography.bodySmall * 0.85
                        color: "#8A93A6"
                    }
                }
            }

            // ===== RESULT ICON (passed / failed) =====
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 96 * uiScale
                height: 96 * uiScale
                radius: width / 2
                color: validationScreenPopup.stateColor
                antialiasing: true
                visible: validationScreenPopup.validationState !== "running"
                opacity: 0.12

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * 0.72
                    height: width
                    radius: width / 2
                    color: validationScreenPopup.stateColor
                    antialiasing: true

                    Text {
                        anchors.centerIn: parent
                        text: validationScreenPopup.validationState === "passed" ? "✓" : "✕"
                        color: "white"
                        font.pixelSize: vTypography.title * 1.3
                        font.bold: true
                    }
                }
            }

            Item { Layout.fillHeight: true }

            // ===== CENTER MESSAGE CARD =====
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 76 * uiScale
                radius: 14 * uiScale
                color: "#FFFFFF"
                border.color: validationScreenPopup.stateColor
                border.width: 1.5
                antialiasing: true

                Behavior on border.color { ColorAnimation { duration: 250 } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 14 * uiScale

                    Rectangle {
                        width: 10 * uiScale
                        height: 10 * uiScale
                        radius: width / 2
                        color: validationScreenPopup.stateColor
                        antialiasing: true
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: 10 * uiScale
                        Layout.preferredHeight: 10 * uiScale

                        SequentialAnimation on opacity {
                            running: validationScreenPopup.validationState === "running"
                            loops: Animation.Infinite
                            NumberAnimation { from: 1; to: 0.25; duration: 600 }
                            NumberAnimation { from: 0.25; to: 1; duration: 600 }
                        }
                    }

                    Text {
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: vTypography.body
                        font.bold: true
                        color: "#1A2E52"
                        text: {
                            if (validationScreenPopup.validationState === "failed")
                                return "Validation Failed"
                            if (validationScreenPopup.validationState === "passed")
                                return "Validation Passed"
                            return "Please pass the sample for validation"
                        }
                    }
                }
            }

            // ===== ROUND STEPPER =====
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 6 * uiScale
                spacing: 0

                Repeater {
                    id: indicatorRepeater
                    model: validationScreenPopup.totalRounds

                    delegate: RowLayout {
                        spacing: 0

                        function pop() {
                            popAnim.start()
                        }

                        Rectangle {
                            id: dot
                            width: 34 * uiScale
                            height: 34 * uiScale
                            radius: width / 2
                            antialiasing: true

                            // Belt-and-braces: pin explicit Layout sizes
                            // too, so this can't collapse if the layout
                            // pass resolves implicit sizing differently
                            // on a slower/embedded platform.
                            Layout.preferredWidth: 34 * uiScale
                            Layout.preferredHeight: 34 * uiScale

                            color: validationScreenPopup.roundStatus[index] ? "#FF5252"
                                   : (validationScreenPopup.currentRound === index + 1
                                      && validationScreenPopup.validationState === "running")
                                     ? "#FFFFFF" : "#D8DCE6"

                            border.width: (validationScreenPopup.currentRound === index + 1
                                           && validationScreenPopup.validationState === "running") ? 3 : 0
                            border.color: "#1A4DB5"

                            Behavior on color { ColorAnimation { duration: 200 } }

                            SequentialAnimation {
                                id: popAnim
                                NumberAnimation { target: dot; property: "scale"; from: 1.0; to: 1.35; duration: 140; easing.type: Easing.OutQuad }
                                NumberAnimation { target: dot; property: "scale"; from: 1.35; to: 1.0; duration: 160; easing.type: Easing.OutBack }
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: validationScreenPopup.roundStatus[index]
                                text: "✓"
                                color: "white"
                                font.pixelSize: vTypography.bodySmall
                                font.bold: true
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: !validationScreenPopup.roundStatus[index]
                                text: (index + 1)
                                color: validationScreenPopup.currentRound === index + 1
                                       && validationScreenPopup.validationState === "running"
                                       ? "#1A4DB5" : "#8A93A6"
                                font.pixelSize: vTypography.bodySmall
                                font.bold: true
                            }
                        }

                        Rectangle {
                            visible: index < validationScreenPopup.totalRounds - 1
                            width: 46 * uiScale
                            height: 3
                            color: validationScreenPopup.roundStatus[index] ? "#FF5252" : "#D8DCE6"

                            Layout.preferredWidth: 46 * uiScale
                            Layout.preferredHeight: 3

                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }

            // ===== BUTTONS =====
            Row {
                Layout.alignment: Qt.AlignHCenter
                spacing: 22 * uiScale
                visible: validationScreenPopup.validationState !== "running"

                Rectangle {
                    id: closeBtn
                    width: 160 * uiScale
                    height: 52 * uiScale
                    radius: 12 * uiScale
                    color: closeArea.pressed ? "#0D3BA8" : "#1A4DB5"
                    scale: closeArea.pressed ? 0.96 : 1.0
                    antialiasing: true

                    Behavior on scale { NumberAnimation { duration: 120 } }
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: validationScreenPopup.validationState === "passed" ? "Done" : "Close"
                        color: "white"
                        font.pixelSize: vTypography.body
                        font.bold: true
                    }

                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            countdownTimer.stop()
                            validationScreenPopup.close()
                        }
                    }
                }
            }
        }
    }
}
