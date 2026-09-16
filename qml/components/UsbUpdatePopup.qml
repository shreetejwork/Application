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

        anchors.topMargin: 14
        anchors.bottomMargin: 14

        spacing: 6

        // ========================================================
        // HEADER
        // ========================================================

        Item {

            Layout.fillWidth: true
            Layout.preferredHeight: 62

            Column {

                anchors.centerIn: parent

                spacing: 3

                Label {

                    text: "Software Update"

                    color: popupRoot.primaryColor

                    font.pixelSize: 30
                    font.weight: Font.DemiBold

                    horizontalAlignment:
                        Text.AlignHCenter

                    anchors.horizontalCenter:
                        parent.horizontalCenter
                }

                Label {

                    text: "Update application software from USB"

                    color:
                        popupRoot.secondaryColor

                    font.pixelSize: 15
                    font.weight: Font.Medium

                    horizontalAlignment:
                        Text.AlignHCenter

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
            Layout.preferredHeight: 78

            // ----------------------------------------------------
            // BASE CONNECTOR
            // ----------------------------------------------------

            Rectangle {

                anchors.left: parent.left
                anchors.right: parent.right

                anchors.leftMargin: 95
                anchors.rightMargin: 95

                y: 18

                height: 4

                radius: 2

                color: "#D9DEE8"
            }

            // ----------------------------------------------------
            // PROGRESS CONNECTOR
            // ----------------------------------------------------

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

                height: 4

                radius: 2

                color:
                    popupRoot.successColor
            }

            // ----------------------------------------------------
            // STEP ITEMS
            // ----------------------------------------------------

            Repeater {

                model: 4

                Item {

                    width:
                        stepArea.width / 4

                    height:
                        stepArea.height

                    x:
                        index * (stepArea.width / 4)

                    // ------------------------------------------------
                    // STEP CIRCLE
                    // ------------------------------------------------

                    Rectangle {

                        id: stepCircle

                        width: 40
                        height: 40

                        radius: 20

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

                            font.pixelSize: 20

                        }
                    }

                    // ------------------------------------------------
                    // STEP LABEL
                    // ------------------------------------------------

                    Label {

                        anchors.top:
                            stepCircle.bottom

                        anchors.topMargin: 7

                        anchors.left:
                            parent.left

                        anchors.right:
                            parent.right

                        text: {

                            if (index === 0)
                                return "Checking USB"

                            if (index === 1)
                                return "Checking ApplicationNew"

                            if (index === 2)
                                return "Installing Application"

                            return "Complete"
                        }

                        color:
                            popupRoot.textColor

                        font.pixelSize: 16
                        font.weight: Font.Medium

                        horizontalAlignment:
                            Text.AlignHCenter

                        verticalAlignment:
                            Text.AlignVCenter

                        wrapMode:
                            Text.WordWrap

                        maximumLineCount: 2

                        elide:
                            Text.ElideRight
                    }
                }
            }
        }

        // ========================================================
        // STATUS AREA
        // ========================================================

        Item {

            Layout.fillWidth: true

            Layout.preferredHeight: 118

            // ----------------------------------------------------
            // PROGRESS
            // ----------------------------------------------------

            Item {

                anchors.centerIn: parent

                width: 116
                height: 116

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

                        var radius = 47

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

                    font.pixelSize: 28

                }
            }

            // ----------------------------------------------------
            // ERROR
            // ----------------------------------------------------

            Rectangle {

                anchors.centerIn: parent

                width: 112
                height: 112

                radius: 56

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

                    font.pixelSize: 56

                }
            }

            // ----------------------------------------------------
            // SUCCESS
            // ----------------------------------------------------

            Rectangle {

                anchors.centerIn: parent

                width: 112
                height: 112

                radius: 56

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

                    font.pixelSize: 50

                }
            }
        }

        // ========================================================
        // STATUS MESSAGE
        // ========================================================

        Rectangle {

            Layout.fillWidth: true

            Layout.preferredHeight: 58

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

                anchors.leftMargin: 18
                anchors.rightMargin: 18

                spacing: 12

                // ------------------------------------------------
                // STATUS INDICATOR
                // ------------------------------------------------

                Rectangle {

                    Layout.preferredWidth: 10
                    Layout.preferredHeight: 10

                    radius: 5

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

                // ------------------------------------------------
                // STATUS TEXT
                // ------------------------------------------------

                Label {

                    Layout.fillWidth: true

                    text: {

                        if (popupRoot.showError)
                            return popupRoot.errorText

                        return popupRoot.statusText
                    }

                    color:
                        popupRoot.textColor

                    font.pixelSize: 16
                    font.weight: Font.Medium

                    horizontalAlignment:
                        Text.AlignHCenter

                    verticalAlignment:
                        Text.AlignVCenter

                    wrapMode:
                        Text.WordWrap

                    maximumLineCount: 2

                    elide:
                        Text.ElideRight
                }
            }
        }

        // ========================================================
        // CONFIRMATION
        // ========================================================

        Label {

            Layout.fillWidth: true

            Layout.preferredHeight: 28

            visible:
                popupRoot.showConfirmation

            text:
                "Do you want to start the updated application now?"

            color:
                popupRoot.textColor

            font.pixelSize: 17
            font.weight: Font.Medium

            horizontalAlignment:
                Text.AlignHCenter

            verticalAlignment:
                Text.AlignVCenter

            wrapMode:
                Text.WordWrap
        }

        // ========================================================
        // BUTTONS
        // ========================================================

        Item {

            Layout.fillWidth: true

            Layout.preferredHeight: 46

            // ----------------------------------------------------
            // CANCEL
            // ----------------------------------------------------

            Rectangle {

                id: cancelButton

                width: 140
                height: 46

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

                    font.pixelSize: 18
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

                width: 140
                height: 46

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

                    font.pixelSize: 18
                    font.weight: Font.Medium
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

                width: 140
                height: 46

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

                    font.pixelSize: 18
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

                width: 140
                height: 46

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

                    font.pixelSize: 18
                    font.weight: Font.Medium
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
