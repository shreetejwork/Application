import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import AppState 1.0

Popup {
    id: validationAlarmPopup

    Typography {
        id: popupTypography
        scale: 1.0
    }

    property string popupTitle: "Validation Reminder"
    property string popupMessage: "This is reminder for Validation"
    property real baseWidth: 1024
    property real baseHeight: 600
    property real uiScale: Math.min(
                               Overlay.overlay.width / baseWidth,
                               Overlay.overlay.height / baseHeight
                           )
    property bool minimized: false

    signal continueClicked()

    AccessDeniedPopup {
        id: accessDeniedPopup
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

    function requireLogin() {
        if (GlobalState.isUserLoggedIn())
            return true

        accessDeniedPopup.popupTitle = "Access Denied !"
        accessDeniedPopup.popupMessage = "Please login first"
        accessDeniedPopup.open()
        return false
    }

    onOpened: {
        minimized = false
        minimizeTimer.stop()
        saveValidationAudit("Remainder for validation")
    }

    Timer {
        id: minimizeTimer
        interval: 5 * 60 * 1000
        repeat: false

        onTriggered: {
            if (!validationAlarmPopup.minimized)
                return

            validationAlarmPopup.minimized = false
            validationAlarmPopup.open()
        }
    }

    modal: true
    focus: true
    dim: true
    closePolicy: Popup.NoAutoClose

    Overlay.modal: Rectangle {
        color: "#66000000"
    }

    width: 520 * uiScale
    height: 360 * uiScale
    x: (Overlay.overlay.width - width) / 2
    y: (Overlay.overlay.height - height) / 2 + 35 * uiScale

    background: Item {}

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

    contentItem: Item {
        id: popupContent
        implicitWidth: validationAlarmPopup.width
        implicitHeight: validationAlarmPopup.height

        Rectangle {
            id: glowBorder
            anchors.centerIn: parent
            width: parent.width + 12 * validationAlarmPopup.uiScale
            height: parent.height + 12 * validationAlarmPopup.uiScale
            radius: 26 * validationAlarmPopup.uiScale
            color: "transparent"
            border.color: "#1A4DB5"
            border.width: 3
            opacity: 0.15
            antialiasing: true
        }

        Rectangle {
            anchors.fill: parent
            radius: 20 * validationAlarmPopup.uiScale
            color: "#EBEBEB"
            border.color: "#C8C8C8"
            border.width: 1
            antialiasing: true
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24 * validationAlarmPopup.uiScale
            spacing: 18 * validationAlarmPopup.uiScale

            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: 35 * validationAlarmPopup.uiScale
                text: validationAlarmPopup.popupTitle
                font.pixelSize: popupTypography.title
                color: "#1A4DB5"
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 82 * validationAlarmPopup.uiScale
                radius: 10 * validationAlarmPopup.uiScale
                color: "#F2F2F2"
                border.color: "#1A4DB5"
                antialiasing: true

                Text {
                    anchors.centerIn: parent
                    width: parent.width * 0.9
                    text: validationAlarmPopup.popupMessage
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: popupTypography.body
                    color: "#1A1A2E"
                }
            }

            Item {
                Layout.fillHeight: true
            }

            Row {
                Layout.alignment: Qt.AlignHCenter
                spacing: 18 * validationAlarmPopup.uiScale

                Button {
                    id: skipButton
                    text: "Skip"
                    width: 120 * validationAlarmPopup.uiScale
                    height: 48 * validationAlarmPopup.uiScale
                    padding: 0
                    font.pixelSize: popupTypography.body

                    background: Rectangle {
                        radius: 10 * validationAlarmPopup.uiScale
                        color: "white"
                        border.color: "#1A4DB5"
                        border.width: 2
                        antialiasing: true
                    }

                    contentItem: Text {
                        text: skipButton.text
                        color: "#1A4DB5"
                        font: skipButton.font
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: {
                        if (!validationAlarmPopup.requireLogin())
                            return

                        validationAlarmPopup.saveValidationAudit("Validation Skipped")
                        minimizeTimer.stop()
                        validationAlarmPopup.close()
                    }
                }

                Button {
                    id: minimizeButton
                    text: "Minimize"
                    width: 120 * validationAlarmPopup.uiScale
                    height: 48 * validationAlarmPopup.uiScale
                    padding: 0
                    font.pixelSize: popupTypography.body

                    background: Rectangle {
                        radius: 10 * validationAlarmPopup.uiScale
                        color: "white"
                        border.color: "#1A4DB5"
                        border.width: 2
                        antialiasing: true
                    }

                    contentItem: Text {
                        text: minimizeButton.text
                        color: "#1A4DB5"
                        font: minimizeButton.font
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: {
                        validationAlarmPopup.minimized = true
                        minimizeTimer.restart()
                        validationAlarmPopup.visible = false
                    }
                }

                Button {
                    id: continueButton
                    text: "Continue"
                    width: 120 * validationAlarmPopup.uiScale
                    height: 48 * validationAlarmPopup.uiScale
                    padding: 0
                    font.pixelSize: popupTypography.body

                    background: Rectangle {
                        radius: 10 * validationAlarmPopup.uiScale
                        color: "#1A4DB5"
                        antialiasing: true
                    }

                    contentItem: Text {
                        text: continueButton.text
                        color: "white"
                        font: continueButton.font
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: {
                        if (!validationAlarmPopup.requireLogin())
                            return

                        validationAlarmPopup.saveValidationAudit("Validation Started")
                        minimizeTimer.stop()
                        validationAlarmPopup.close()
                        validationAlarmPopup.continueClicked()
                    }
                }
            }
        }

        SequentialAnimation {
            running: validationAlarmPopup.visible
            loops: Animation.Infinite

            NumberAnimation {
                target: popupContent
                property: "scale"
                from: 1
                to: 1.02
                duration: 650
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                target: popupContent
                property: "scale"
                from: 1.02
                to: 1
                duration: 650
                easing.type: Easing.InOutSine
            }
            PauseAnimation {
                duration: 400
            }
        }

        SequentialAnimation {
            running: validationAlarmPopup.visible
            loops: Animation.Infinite

            NumberAnimation {
                target: glowBorder
                property: "opacity"
                from: 0.12
                to: 0.35
                duration: 700
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                target: glowBorder
                property: "opacity"
                from: 0.35
                to: 0.12
                duration: 700
                easing.type: Easing.InOutQuad
            }
        }
    }
}
