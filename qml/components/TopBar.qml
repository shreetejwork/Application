import QtQuick
import QtQuick.Layouts
import AppState 1.0

import "../components"

Rectangle {
    id: root
    color: "#1A4DB5"

    property bool showBackButton: false
    signal menuClicked()
    signal backClicked()

    property string notificationText: ""
    property bool notificationVisible: false

    property bool usbConnected: false

    property bool isLoggedIn:
        GlobalState.loggedInUserName !== ""
        && GlobalState.loggedInUserName !== undefined

    Typography {
        id: topBarTypography
        scale: root.scale
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            root.usbConnected = PdfExporter.isUsbMounted()
        }
    }

    PowerOffPopup {
        id: powerPopup
    }

    LogoutPopup {
        id: logoutPopup

        onLogoutRequested: {

            var username = GlobalState.loggedInUserName
            var role     = GlobalState.loggedInUserRole

            var initial = "U"

            if (role === "Admin")
                initial = "A"
            else if (role === "Operator")
                initial = "O"
            else if (role === "Supervisor")
                initial = "S"


            root.showNotification(
                        "Logged out "
                        + initial
                        + "-"
                        + username)


            GlobalState.loggedInUserName = ""
            GlobalState.loggedInUserRole = ""

            countdownCircle.resetCountdown()
        }
    }

    LoginPopup {
        id: loginPopup


        // ================= NORMAL USER LOGIN =================

        onLoginRequested: function(userType, username, password) {

            if (loginPopup.isUserBlocked(username)) {

                var remaining = loginPopup.getBlockRemaining(username)

                loginPopup.errorText =
                        "User blocked. Try again in "
                        + remaining
                        + " seconds"

                loginPopup.hasError = true
                return
            }


            var valid =
                    databaseManager.validateLogin(
                        userType,
                        username,
                        password
                        )


            if (!valid) {

                loginPopup.registerFailedAttempt(username)

                return
            }


            if (databaseManager.isPasswordExpired(username)) {

                loginPopup.errorText =
                        "Password expired. Contact Admin."

                loginPopup.hasError = true
                return
            }


            loginPopup.errorText = ""
            loginPopup.hasError = false


            GlobalState.loggedInUserName = username
            GlobalState.loggedInUserRole = userType


            var initial = "U"


            if (userType === "Admin")
                initial = "A"

            else if (userType === "Operator")
                initial = "O"

            else if (userType === "Supervisor")
                initial = "S"



            root.showNotification(
                        "Logged in "
                        + initial
                        + "-"
                        + username
                        )


            var days =
                    databaseManager.daysUntilPasswordExpiry(username)


            if(days > 0 && days <= 7)
            {
                root.showNotification(
                            "Password expires in "
                            + days
                            + " day(s)"
                            )
            }


            loginPopup.clearFailedAttempts(username)


            countdownCircle.resetCountdown()


            loginPopup.close()
        }



        // ================= DEVELOPER LOGIN =================

        onDeveloperLoginSuccess:
        {

            root.showNotification(
                        "Developer mode activated"
                        )


            countdownCircle.resetCountdown()
        }



        // ================= ENGINEER LOGIN =================

        onEngineerLoginSuccess:
        {

            root.showNotification(
                        "Engineer mode activated"
                        )


            countdownCircle.resetCountdown()
        }
    }

    Timer {
        id: notificationTimer
        interval: 5000
        repeat: false
        onTriggered: root.notificationVisible = false
    }

    function showNotification(msg) {
        root.notificationText = (msg || "").toString()
        root.notificationVisible = root.notificationText.length > 0
        notificationTimer.restart()
    }

    function resetSessionTimer() {
        countdownCircle.resetCountdown()
    }

    property real baseHeight: 90
    property real scale: Math.max(0.6, height / baseHeight)

    property string userName: GlobalState.loggedInUserName
    property string userRole: GlobalState.loggedInUserRole

    signal bellClicked()

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: parent.width * 0.001
        anchors.rightMargin: parent.width * 0.02
        spacing: Math.max(6, root.width * 0.01)

        // ─── LEFT (TIME + MENU/BACK) ───────────────────────────────────────────
        Item {
            id: timeBlock
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: Math.min(root.width * 0.45, leftCluster.implicitWidth + root.width * 0.02)

            Row {
                id: leftCluster
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: root.width * 0.01
                spacing: Math.max(10 * root.scale, root.width * 0.015)

                // ── TIME ──
                Column {
                    spacing: Math.max(4, root.height * 0.02)
                    width: 180 * root.scale
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        text: Qt.formatTime(GlobalState.globalDateTime, " HH:mm:ss")
                        color: "white"
                        font.pixelSize: topBarTypography.heading
                    }

                    Text {
                        text: Qt.formatDate(GlobalState.globalDateTime, "dd MMM yyyy")
                        color: "white"
                        font.pixelSize: topBarTypography.subHeading
                        opacity: 0.9
                    }
                }

                // ── MENU BUTTON (opacity-hidden, space always reserved) ──
                Item {
                    id: menuButton
                    width: Math.max(36 * root.scale, root.height * 0.45)
                    height: width
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: root.showBackButton ? 0.0 : 1.0
                    enabled: !root.showBackButton

                    scale: menuMouseArea.pressed ? 0.88 : 1.0

                    Behavior on scale {
                        NumberAnimation { duration: 120; easing.type: Easing.OutBack }
                    }

                    Image {
                        anchors.centerIn: parent
                        source: "qrc:/qt/qml/Application/assets/images/Menu.png"
                        width: parent.width
                        height: parent.height
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }

                    MouseArea {
                        id: menuMouseArea
                        anchors.fill: parent
                        onClicked: root.menuClicked()
                    }
                }

                // ── BACK BUTTON (opacity-hidden, space always reserved) ──
                Item {
                    id: backButton
                    width: Math.max(36 * root.scale, root.height * 0.95)
                    height: width
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: root.showBackButton ? 1.0 : 0.0
                    enabled: root.showBackButton

                    scale: backMouseArea.pressed ? 0.88 : 1.0

                    Behavior on scale {
                        NumberAnimation { duration: 120; easing.type: Easing.OutBack }
                    }

                    Image {
                        id: backIcon
                        anchors.fill: parent
                        anchors.margins: width * 0.20
                        source: "qrc:/qt/qml/Application/assets/images/Back.png"
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        visible: status === Image.Ready
                    }

                    MouseArea {
                        id: backMouseArea
                        anchors.fill: parent
                        onClicked: {
                            if (GlobalState.loginKeyboardRequest) {
                                GlobalState.loginKeyboardRequest = false
                            }
                            root.backClicked()
                        }
                    }
                }
            }
        }

        // ─── CENTER (NOTIFICATION BAR) ─────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Item {
                anchors.centerIn: parent
                width: parent.width * 0.75
                height: parent.height * 0.75

                Rectangle {
                    id: notificationBanner

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter

                    height: Math.max(34, root.height * 0.28)

                    radius: 8
                    color: "#2C63D6"

                    border.color: "#80FFFFFF"
                    border.width: 1

                    opacity: root.notificationVisible ? 1 : 0

                    visible: opacity > 0

                    property real popupScale: root.notificationVisible ? 1.0 : 0.85


                    scale: popupScale


                    transformOrigin: Item.Center


                    Behavior on opacity {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }


                    Behavior on scale {
                        NumberAnimation {
                            duration: 450
                            easing.type: Easing.OutBack
                            easing.overshoot: 2.0
                        }
                    }


                    Text {
                        anchors.fill: parent

                        anchors.margins: Math.max(8, root.height * 0.08)

                        text: root.notificationText

                        color: "white"

                        elide: Text.ElideRight

                        horizontalAlignment: Text.AlignHCenter

                        verticalAlignment: Text.AlignVCenter

                        font.pixelSize: topBarTypography.subHeading
                    }
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: Math.max(1, 2 * root.scale)
                    color: "#80FFFFFF"
                }
            }
        }

        // ─── RIGHT SIDE ────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillHeight: true
            spacing: Math.max(6, root.width * 0.012)

            // ── USB STATUS (space always reserved) ──
            Item {
                id: usbItem
                opacity: root.usbConnected ? 1.0 : 0.0
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: root.height * 0.55
                Layout.preferredHeight: root.height * 0.55

                Image {
                    anchors.fill: parent
                    source: "qrc:/qt/qml/Application/assets/images/USB.png"
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }
            }

            // ── USER ICON + NAME/ROLE ──
            RowLayout {
                spacing: Math.max(4, root.width * 0.008)
                Layout.alignment: Qt.AlignVCenter

                Image {
                    source: "qrc:/qt/qml/Application/assets/images/User.png"
                    Layout.preferredWidth: root.height * 0.55
                    Layout.preferredHeight: root.height * 0.55
                    fillMode: Image.PreserveAspectFit
                    smooth: true

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.isLoggedIn ? logoutPopup.open() : loginPopup.open()
                    }
                }

                // ── ROLE + USERNAME (space always reserved, opacity toggled) ──
                ColumnLayout {
                    opacity: root.isLoggedIn ? 1.0 : 0.0
                    spacing: Math.max(2, root.height * 0.01)

                    // Fixed minimum width so column never collapses when hidden
                    Layout.minimumWidth: 80 * root.scale

                    Rectangle {
                        Layout.preferredHeight: root.height * 0.26
                        Layout.preferredWidth: Math.max(roleText.implicitWidth + root.width * 0.01, 60 * root.scale)
                        radius: root.height * 0.05
                        color: "#2C63D6"

                        Text {
                            id: roleText
                            anchors.centerIn: parent
                            text: GlobalState.loggedInUserRole
                            color: "white"
                            font.pixelSize: topBarTypography.subHeading
                        }
                    }

                    Text {
                        id: userNameText
                        property bool showFullName: false

                        text: showFullName
                              ? GlobalState.loggedInUserName
                              : (GlobalState.loggedInUserName.length > 10
                                 ? GlobalState.loggedInUserName.substring(0, 10) + "..."
                                 : GlobalState.loggedInUserName)
                        color: "white"
                        font.pixelSize: topBarTypography.heading

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                userNameText.showFullName = true
                                resetTimer.restart()
                            }
                        }

                        Timer {
                            id: resetTimer
                            interval: 5000
                            repeat: false
                            onTriggered: userNameText.showFullName = false
                        }
                    }
                }
            }

            // ── COUNTDOWN CIRCLE (space always reserved, opacity toggled) ──
            Rectangle {
                id: countdownCircle

                visible: root.isLoggedIn

                width: Math.max(48 * root.scale, root.height * 0.60)
                height: width
                radius: width / 2

                color: "transparent"

                border.color: "white"
                border.width: Math.max(1, root.height * 0.038)

                property int sessionTimeout: 180
                property int remainingSeconds: sessionTimeout
                property bool blink: false

                function resetCountdown() {
                    countdownTimer.stop()

                    remainingSeconds = sessionTimeout
                    blink = false

                    if (root.isLoggedIn)
                        countdownTimer.start()
                }

                // Reset whenever user logs in
                onVisibleChanged: {
                    if (visible)
                        resetCountdown()
                }

                opacity: remainingSeconds <= 20
                         ? (blink ? 0.2 : 1.0)
                         : 1.0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                    }
                }

                Timer {
                    id: countdownTimer

                    interval: 1000
                    repeat: true
                    running: false

                    onTriggered: {

                        if (!root.isLoggedIn) {
                            stop()
                            return
                        }

                        if (countdownCircle.remainingSeconds > 0) {

                            countdownCircle.remainingSeconds--
                        }

                        if (countdownCircle.remainingSeconds <= 0) {

                            stop()

                            countdownCircle.blink = false

                            GlobalState.loggedInUserName = ""
                            GlobalState.loggedInUserRole = ""

                            console.log("Auto logout")
                        }
                    }
                }

                Timer {
                    id: blinkTimer

                    interval: 400
                    repeat: true

                    running: root.isLoggedIn
                             && countdownCircle.remainingSeconds <= 20
                             && countdownCircle.remainingSeconds > 0

                    onTriggered: {
                        countdownCircle.blink =
                                !countdownCircle.blink
                    }
                }

                Text {
                    anchors.centerIn: parent

                    text: countdownCircle.remainingSeconds

                    color: "white"

                    font.pixelSize: topBarTypography.body
                }

                MouseArea {
                    anchors.fill: parent

                    onClicked: {
                        countdownCircle.resetCountdown()
                    }
                }
            }

            // ── POWER OFF ──
            Item {
                id: powerItem
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: root.width * 0.01
                Layout.preferredWidth: root.height * 0.65
                Layout.preferredHeight: root.height * 0.65

                property int longPressCount: 0
                property bool longPressTriggered: false

                Image {
                    anchors.fill: parent
                    source: "qrc:/qt/qml/Application/assets/images/PowerOff.png"
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }

                MouseArea {
                    anchors.fill: parent


                    Timer {
                        id: longPressTimer

                        interval: 3000
                        repeat: false


                        onTriggered: {

                            powerItem.longPressCount++

                            // First 3 second press completed
                            if (powerItem.longPressCount === 1) {

                                powerItem.longPressTriggered = true

                            }


                            // Second 3 second press completed
                            else if (powerItem.longPressCount === 2) {


                                powerItem.longPressCount = 0

                                powerItem.longPressTriggered = true


                                // if (GlobalState.developerLogin) {

                                //     console.log(
                                //         "Developer mode: Exiting to OS..."
                                //     )

                                //     Qt.quit()

                                // }

                                Qt.quit()
                                console.log(
                                    "Exiting to OS..."
                                )

                            }
                        }
                    }


                    // Reset second press counter after timeout
                    Timer {

                        id: longPressResetTimer

                        interval: 5000
                        repeat: false


                        onTriggered: {

                            powerItem.longPressCount = 0
                        }
                    }

                    onPressed: {

                        powerItem.longPressTriggered = false


                        longPressTimer.start()
                    }



                    onReleased: {

                        longPressTimer.stop()


                        // Start waiting time after first successful long press
                        if(powerItem.longPressCount === 1) {

                            longPressResetTimer.start()

                        }
                    }



                    onClicked: {

                        if(!powerItem.longPressTriggered) {

                            powerPopup.open()

                        }
                    }
                }
            }
        }
    }
}
