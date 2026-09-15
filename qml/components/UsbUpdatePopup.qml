import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: popupRoot

    width: 850
    height: 460

    x: Overlay.overlay
       ? Math.max(10, Math.round((Overlay.overlay.width - width) / 2))
       : 0

    y: Overlay.overlay
       ? Math.max(10, Math.round((Overlay.overlay.height - height) / 2) - 35)
       : 0

    modal: true
    focus: true
    closePolicy: Popup.NoAutoClose

    property color primaryColor: "#1A4DB5"
    property color backgroundColor: "#F5F7FC"
    property color borderColor: "#D0D8EC"
    property color textColor: "#1A2E52"
    property color secondaryColor: "#51657B"
    property color successColor: "#2ECC71"
    property color errorColor: "#FF3D4D"

    property string statusText: "Checking for USB..."
    property int progress: 0
    property bool isRunning: false
    property bool showError: false
    property bool showConfirmation: false
    property string errorText: ""
    property bool canClose: false

    signal startRequested()
    signal cancelRequested()
    signal confirmRequested()
    signal declineRequested()

    // ============================================================
    // OPEN UPDATE
    // ============================================================

    function openUpdate() {
        statusText = "Checking for USB..."
        progress = 0
        isRunning = true
        showError = false
        showConfirmation = false
        errorText = ""
        canClose = false

        open()

        startRequested()
    }

    // ============================================================
    // ERROR
    // ============================================================

    function showErrorMessage(message) {
        errorText = message
        statusText = ""
        progress = 0

        isRunning = false
        showError = true
        showConfirmation = false
        canClose = true
    }

    // ============================================================
    // SUCCESS
    // ============================================================

    function showSuccessConfirmation() {
        statusText = "Software update completed successfully"
        progress = 100

        isRunning = false
        showError = false
        showConfirmation = true
        canClose = false
    }

    // ============================================================
    // STEP STATE
    // ============================================================

    function stepState(stepIndex) {

        if (progress >= 100)
            return "completed"

        var completedStep = Math.floor(progress / 25)

        if (stepIndex < completedStep)
            return "completed"

        if (stepIndex === completedStep)
            return "active"

        return "inactive"
    }

    // ============================================================
    // MODAL BACKGROUND
    // ============================================================

    Overlay.modal: Rectangle {
        color: "#66000000"
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
                duration: 180
            }

            NumberAnimation {
                property: "scale"
                from: 0.96
                to: 1
                duration: 180
                easing.type: Easing.OutCubic
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
                duration: 140
            }

            NumberAnimation {
                property: "scale"
                from: 1
                to: 0.96
                duration: 140
                easing.type: Easing.InCubic
            }
        }
    }

    // ============================================================
    // BACKGROUND
    // ============================================================

    background: Rectangle {

        radius: 24

        color: "#FFFFFF"

        border.width: 1
        border.color: popupRoot.borderColor

        Rectangle {

            anchors.fill: parent
            anchors.margins: 2

            radius: 22

            color: "transparent"

            border.width: 1
            border.color: "#EEF1F7"
        }
    }

    // ============================================================
    // MAIN CONTENT
    // ============================================================

    contentItem: ColumnLayout {

        anchors.fill: parent

        anchors.leftMargin: 28
        anchors.rightMargin: 28

        anchors.topMargin: 16
        anchors.bottomMargin: 16

        spacing: 7

        // ========================================================
        // HEADER
        // ========================================================

        Item {

            Layout.fillWidth: true
            Layout.preferredHeight: 60

            Column {

                anchors.centerIn: parent

                spacing: 2

                Label {

                    text: "Software Update"

                    color: popupRoot.primaryColor

                    font.pixelSize: 28


                    anchors.horizontalCenter:
                        parent.horizontalCenter
                }


                Label {

                    text: "Update application software from USB"

                    color:
                        popupRoot.secondaryColor

                    font.pixelSize: 13

                    anchors.horizontalCenter:
                        parent.horizontalCenter
                }
            }
        }

        // ========================================================
        // STEPS
        // ========================================================

        Item {

            id: stepArea

            Layout.fillWidth: true
            Layout.preferredHeight: 76

            // Base connector
            Rectangle {

                anchors.left: parent.left
                anchors.right: parent.right

                anchors.leftMargin: 95
                anchors.rightMargin: 95

                y: 18

                height: 3

                radius: 2

                color: "#D9DEE8"
            }

            // Progress connector
            Rectangle {

                x: 95
                y: 18

                width: Math.max(
                           0,
                           Math.min(
                               stepArea.width - 190,
                               (stepArea.width - 190) *
                               popupRoot.progress / 100
                           )
                       )

                height: 3

                radius: 2

                color:
                    popupRoot.successColor
            }

            Repeater {

                model: 4

                Item {

                    width:
                        stepArea.width / 4

                    height:
                        stepArea.height

                    x:
                        index * (stepArea.width / 4)

                    Rectangle {

                        id: stepCircle

                        width: 38
                        height: 38

                        radius: 19

                        y: 0

                        anchors.horizontalCenter:
                            parent.horizontalCenter

                        color: {

                            var state =
                                    popupRoot.stepState(index)

                            if (state === "completed")
                                return popupRoot.successColor

                            if (state === "active")
                                return "#FFFFFF"

                            return "#E5E9F1"
                        }

                        border.width: {

                            var state =
                                    popupRoot.stepState(index)

                            return state === "active" ? 3 : 0
                        }

                        border.color:
                            popupRoot.primaryColor

                        Label {

                            anchors.centerIn: parent

                            text: {

                                var state =
                                        popupRoot.stepState(index)

                                if (state === "completed")
                                    return "✓"

                                return String(index + 1)
                            }

                            color: {

                                var state =
                                        popupRoot.stepState(index)

                                if (state === "completed")
                                    return "#FFFFFF"

                                if (state === "active")
                                    return popupRoot.primaryColor

                                return "#718096"
                            }

                            font.pixelSize: 16

                        }
                    }

                    Label {

                        anchors.top:
                            stepCircle.bottom

                        anchors.topMargin: 6

                        anchors.left:
                            parent.left

                        anchors.right:
                            parent.right

                        text: {

                            if (index === 0)
                                return "Check USB"

                            if (index === 1)
                                return "Check ApplicationNew"

                            if (index === 2)
                                return "Installing Application"

                            return "Complete"
                        }

                        color:
                            popupRoot.secondaryColor

                        font.pixelSize: 11

                        horizontalAlignment:
                            Text.AlignHCenter

                        verticalAlignment:
                            Text.AlignVCenter

                        wrapMode:
                            Text.WordWrap
                    }
                }
            }
        }

        // ========================================================
        // STATUS AREA
        // ========================================================

        Item {

            Layout.fillWidth: true

            Layout.preferredHeight: 128

            // ----------------------------------------------------
            // PROGRESS
            // ----------------------------------------------------

            Item {

                anchors.centerIn: parent

                width: 120
                height: 120

                visible:
                    !popupRoot.showError &&
                    !popupRoot.showConfirmation

                Canvas {

                    id: progressCanvas

                    anchors.fill: parent

                    onPaint: {

                        var ctx =
                                getContext("2d")

                        ctx.reset()

                        var centerX =
                                width / 2

                        var centerY =
                                height / 2

                        var radius = 48

                        // Background ring
                        ctx.beginPath()

                        ctx.arc(
                            centerX,
                            centerY,
                            radius,
                            0,
                            Math.PI * 2
                        )

                        ctx.lineWidth = 9

                        ctx.strokeStyle =
                            "#E5E9F1"

                        ctx.stroke()

                        // Progress ring
                        if (popupRoot.progress > 0) {

                            var startAngle =
                                -Math.PI / 2

                            var endAngle =
                                startAngle +
                                (
                                    Math.PI * 2 *
                                    popupRoot.progress /
                                    100
                                )

                            ctx.beginPath()

                            ctx.arc(
                                centerX,
                                centerY,
                                radius,
                                startAngle,
                                endAngle
                            )

                            ctx.lineWidth = 9

                            ctx.lineCap = "round"

                            ctx.strokeStyle =
                                popupRoot.primaryColor

                            ctx.stroke()
                        }
                    }
                }

                Label {

                    anchors.centerIn: parent

                    text:
                        popupRoot.progress + "%"

                    color:
                        popupRoot.primaryColor

                    font.pixelSize: 23

                }
            }

            // ----------------------------------------------------
            // ERROR
            // ----------------------------------------------------

            Rectangle {

                anchors.centerIn: parent

                width: 116
                height: 116

                radius: 58

                visible:
                    popupRoot.showError

                color:
                    "#FFF5F6"

                border.width: 5

                border.color:
                    popupRoot.errorColor

                Label {

                    anchors.centerIn: parent

                    text: "!"

                    color:
                        popupRoot.errorColor

                    font.pixelSize: 54

                }
            }

            // ----------------------------------------------------
            // SUCCESS
            // ----------------------------------------------------

            Rectangle {

                anchors.centerIn: parent

                width: 116
                height: 116

                radius: 58

                visible:
                    popupRoot.showConfirmation

                color:
                    "#F2FCF6"

                border.width: 5

                border.color:
                    popupRoot.successColor

                Label {

                    anchors.centerIn: parent

                    text: "✓"

                    color:
                        popupRoot.successColor

                    font.pixelSize: 48

                }
            }
        }

        // ========================================================
        // STATUS MESSAGE
        // ========================================================

        Rectangle {

            Layout.fillWidth: true

            Layout.preferredHeight: 54

            radius: 12

            color: {

                if (popupRoot.showError)
                    return "#FFF5F6"

                if (popupRoot.showConfirmation)
                    return "#F2FCF6"

                return "#F7F9FD"
            }

            border.width: 1.5

            border.color: {

                if (popupRoot.showError)
                    return popupRoot.errorColor

                if (popupRoot.showConfirmation)
                    return popupRoot.successColor

                return popupRoot.borderColor
            }

            RowLayout {

                anchors.fill: parent

                anchors.leftMargin: 16
                anchors.rightMargin: 16

                spacing: 12

                Rectangle {

                    Layout.preferredWidth: 9
                    Layout.preferredHeight: 9

                    radius: 4.5

                    color: {

                        if (popupRoot.showError)
                            return popupRoot.errorColor

                        if (popupRoot.showConfirmation)
                            return popupRoot.successColor

                        return popupRoot.primaryColor
                    }

                    SequentialAnimation on opacity {

                        running:
                            popupRoot.isRunning

                        loops:
                            Animation.Infinite

                        NumberAnimation {
                            from: 1
                            to: 0.3
                            duration: 550
                        }

                        NumberAnimation {
                            from: 0.3
                            to: 1
                            duration: 550
                        }
                    }
                }

                Label {

                    Layout.fillWidth: true

                    text: {

                        if (popupRoot.showError)
                            return popupRoot.errorText

                        return popupRoot.statusText
                    }

                    color:
                        popupRoot.textColor

                    font.pixelSize: 14

                    font.weight:
                        Font.Medium

                    horizontalAlignment:
                        Text.AlignHCenter

                    verticalAlignment:
                        Text.AlignVCenter

                    wrapMode:
                        Text.WordWrap
                }
            }
        }

        // ========================================================
        // CONFIRMATION
        // ========================================================

        Label {

            Layout.fillWidth: true

            Layout.preferredHeight: 25

            visible:
                popupRoot.showConfirmation

            text:
                "Do you want to start the updated application now?"

            color:
                popupRoot.textColor

            font.pixelSize: 18

            horizontalAlignment:
                Text.AlignHCenter

            verticalAlignment:
                Text.AlignVCenter
        }

        // ========================================================
        // BUTTONS
        // ========================================================

        Item {

            Layout.fillWidth: true

            Layout.preferredHeight: 44

            // ----------------------------------------------------
            // CANCEL
            // ----------------------------------------------------

            Rectangle {

                id: cancelButton

                width: 135
                height: 44

                anchors.left:
                    parent.left

                visible:
                    !popupRoot.showError &&
                    !popupRoot.showConfirmation

                radius: 11

                color: "#FFFFFF"

                border.width: 1.5

                border.color:
                    popupRoot.borderColor

                Label {

                    anchors.centerIn: parent

                    text: "Cancel"

                    color:
                        popupRoot.secondaryColor

                    font.pixelSize: 14
                    font.weight: Font.Medium
                }

                MouseArea {

                    anchors.fill: parent

                    enabled:
                        !popupRoot.isRunning ||
                        popupRoot.canClose

                    onClicked: {

                        popupRoot.cancelRequested()

                        popupRoot.close()
                    }
                }
            }

            // ----------------------------------------------------
            // YES
            // ----------------------------------------------------

            Rectangle {

                id: yesButton

                width: 135
                height: 44

                anchors.right:
                    noButton.left

                anchors.rightMargin: 10

                visible:
                    popupRoot.showConfirmation

                radius: 11

                color:
                    popupRoot.primaryColor

                Label {

                    anchors.centerIn: parent

                    text: "Yes"

                    color: "#FFFFFF"

                    font.pixelSize: 14

                }

                MouseArea {

                    anchors.fill: parent

                    onClicked: {

                        popupRoot.confirmRequested()
                    }
                }
            }

            // ----------------------------------------------------
            // NO
            // ----------------------------------------------------

            Rectangle {

                id: noButton

                width: 135
                height: 44

                anchors.right:
                    parent.right

                visible:
                    popupRoot.showConfirmation

                radius: 11

                color: "#FFFFFF"

                border.width: 1.5

                border.color:
                    popupRoot.borderColor

                Label {

                    anchors.centerIn: parent

                    text: "No"

                    color:
                        popupRoot.secondaryColor

                    font.pixelSize: 14
                    font.weight: Font.Medium
                }

                MouseArea {

                    anchors.fill: parent

                    onClicked: {

                        popupRoot.declineRequested()

                        popupRoot.close()
                    }
                }
            }

            // ----------------------------------------------------
            // OK
            // ----------------------------------------------------

            Rectangle {

                id: okButton

                width: 135
                height: 44

                anchors.horizontalCenter:
                    parent.horizontalCenter

                visible:
                    popupRoot.showError

                radius: 11

                color:
                    popupRoot.primaryColor

                Label {

                    anchors.centerIn: parent

                    text: "OK"

                    color: "#FFFFFF"

                    font.pixelSize: 14

                }

                MouseArea {

                    anchors.fill: parent

                    onClicked: {

                        popupRoot.close()
                    }
                }
            }
        }
    }

    // ============================================================
    // UPDATE PROGRESS CANVAS
    // ============================================================

    onProgressChanged: {

        if (progressCanvas)
            progressCanvas.requestPaint()
    }
}
