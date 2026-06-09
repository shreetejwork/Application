import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import AppState 1.0

Popup {
    id: loginPopup

    enter: Transition {
        ParallelAnimation {

            NumberAnimation {
                property: "opacity"
                from: 0.0
                to: 1.0
                duration: 350
                easing.type: Easing.OutQuad
            }

            NumberAnimation {
                property: "scale"
                from: 0.0
                to: 1.0
                duration: 350
                easing.type: Easing.OutQuad
            }
        }
    }

    exit: Transition {
        ParallelAnimation {

            NumberAnimation {
                property: "opacity"
                from: 1.0
                to: 0.0
                duration: 280
                easing.type: Easing.InQuad
            }

            NumberAnimation {
                property: "scale"
                from: 1.0
                to: 0.0
                duration: 280
                easing.type: Easing.InQuad
            }
        }
    }

    property real baseWidth: 1024
    property real baseHeight: 600

    property bool isLongPress: false
    property int longPressCount: 0

    property bool devModeActive: false
    property bool fieldsLocked: false

    property string developerPassword: "dev123"
    property string engineerPassword: "eng123"

    property string errorText: ""
    property bool hasError: false

    property int maxAttempts: 5
    property int blockDurationSeconds: 60


    property string currentSelectedUser: ""


    property string blockedUserName: ""
    property int blockedRemainingSeconds: 0

    // ── Storage helpers ───────────────────────────────────────────────────────

    function loadBlocked() {
        try {
            return JSON.parse(GlobalState.blockedUsersJson || "{}")
        } catch(e) {
            return {}
        }
    }

    function saveBlocked(obj) {
        GlobalState.blockedUsersJson = JSON.stringify(obj)
    }

    function loadAttempts() {
        try {
            return JSON.parse(GlobalState.failedAttemptsJson || "{}")
        } catch(e) {
            return {}
        }
    }

    function saveAttempts(obj) {
        GlobalState.failedAttemptsJson = JSON.stringify(obj)
    }

    // =========================================================
    // TYPOGRAPHY FOR LOGIN POPUP
    // =========================================================

    Typography {
        id: loginTypography
        scale: 1.0
    }

    signal loginRequested(string userType, string username, string password)
    signal clearRequested()

    // =========================================================
    // BLOCK COUNTDOWN TIMER
    // ticks every second while a blocked user is selected
    // =========================================================
    Timer {
        id: blockCountdownTimer

        interval: 1000
        repeat: true
        running: loginPopup.blockedUserName !== ""

        onTriggered: {
            if (!loginPopup.isUserBlocked(loginPopup.blockedUserName)) {
                // Block expired – clear state
                loginPopup.blockedUserName = ""
                loginPopup.blockedRemainingSeconds = 0
                loginPopup.errorText = ""
                loginPopup.hasError = false
                stop()
                return
            }

            loginPopup.blockedRemainingSeconds =
                loginPopup.getBlockRemaining(loginPopup.blockedUserName)

            // Only show the blocked message if this user is currently selected
            if (loginPopup.currentSelectedUser === loginPopup.blockedUserName) {
                loginPopup.errorText =
                    loginPopup.blockedUserName
                    + " is blocked. Try again in "
                    + loginPopup.formatRemaining(loginPopup.blockedRemainingSeconds)
                loginPopup.hasError = true
            }
        }
    }

    // =========================================================
    // HELPER FUNCTIONS
    // =========================================================

    function isUserBlocked(username) {
        var blocked = loadBlocked()
        if (!blocked[username])
            return false

        var remaining = blocked[username] - Date.now()

        if (remaining <= 0) {
            // Expired – clean up persisted data
            delete blocked[username]
            saveBlocked(blocked)

            var attempts = loadAttempts()
            attempts[username] = 0
            saveAttempts(attempts)

            return false
        }

        return true
    }

    function getBlockRemaining(username) {
        var blocked = loadBlocked()
        if (!blocked[username])
            return 0
        return Math.ceil((blocked[username] - Date.now()) / 1000)
    }

    // Returns how many attempts the user has left before being blocked
    function attemptsRemaining(username) {
        var attempts = loadAttempts()
        var used = attempts[username] ? attempts[username] : 0
        return maxAttempts - used
    }

    function registerFailedAttempt(username) {
        var attempts = loadAttempts()
        if (!attempts[username])
            attempts[username] = 0
        attempts[username]++
        saveAttempts(attempts)

        var used = attempts[username]
        var left = maxAttempts - used

        if (used >= maxAttempts) {
            // Block the user – persist unblock timestamp
            var blocked = loadBlocked()
            blocked[username] = Date.now() + (blockDurationSeconds * 1000)
            saveBlocked(blocked)

            // Reset attempt counter now that they are blocked
            attempts[username] = 0
            saveAttempts(attempts)

            loginPopup.blockedUserName = username
            loginPopup.blockedRemainingSeconds = loginPopup.getBlockRemaining(username)

            loginPopup.errorText =
                username
                + " is blocked. Try again in "
                + loginPopup.formatRemaining(loginPopup.blockedRemainingSeconds)
            loginPopup.hasError = true

            blockCountdownTimer.restart()
        } else {
            loginPopup.errorText =
                "Wrong password. "
                + left
                + " attempt(s) remaining before lockout."
            loginPopup.hasError = true
        }
    }

    function clearFailedAttempts(username) {
        var attempts = loadAttempts()
        attempts[username] = 0
        saveAttempts(attempts)
    }

    // Formats seconds into "Xd Xh Xm Xs" so long block durations are readable
    function formatRemaining(seconds) {
        if (seconds <= 0) return "0s"
        var d = Math.floor(seconds / 86400)
        var h = Math.floor((seconds % 86400) / 3600)
        var m = Math.floor((seconds % 3600) / 60)
        var s = seconds % 60
        var parts = []
        if (d > 0) parts.push(d + "d")
        if (h > 0) parts.push(h + "h")
        if (m > 0) parts.push(m + "m")
        if (s > 0 || parts.length === 0) parts.push(s + "s")
        return parts.join(" ")
    }

    // Called whenever the selected username changes; refreshes error display
    function refreshErrorForUser(username) {
        if (username === "" || username === "--- Select ---") {
            loginPopup.errorText = ""
            loginPopup.hasError  = false
            loginPopup.blockedUserName = ""
            blockCountdownTimer.stop()
            return
        }

        if (loginPopup.isUserBlocked(username)) {
            loginPopup.blockedUserName = username
            loginPopup.blockedRemainingSeconds = loginPopup.getBlockRemaining(username)
            loginPopup.errorText =
                username
                + " is blocked. Try again in "
                + loginPopup.formatRemaining(loginPopup.blockedRemainingSeconds)
            loginPopup.hasError = true
            blockCountdownTimer.restart()
        } else {
            // Show leftover attempt-warning if any failed attempts exist
            var attempts = loadAttempts()
            var used = attempts[username] ? attempts[username] : 0
            if (used > 0) {
                var left = maxAttempts - used
                loginPopup.errorText =
                    "Wrong password. "
                    + left
                    + " attempt(s) remaining before lockout."
                loginPopup.hasError = true
            } else {
                loginPopup.errorText = ""
                loginPopup.hasError  = false
            }

            // Stop tracking a different user's block countdown
            if (loginPopup.blockedUserName !== username) {
                loginPopup.blockedUserName = ""
                blockCountdownTimer.stop()
            }
        }
    }

    // =====================================================
    // QT 6.5 KEYBOARD FIX
    // =====================================================

    parent: Overlay.overlay

    font.family: Application.font.family

    modal: false
    focus: false

    closePolicy: Popup.NoAutoClose

    width: 520 * scale
    height: 430 * scale

    x: (Overlay.overlay.width - width) / 2

    property real keyboardHeight: GlobalState.loginKeyboardRequest
                                  ? Overlay.overlay.height * 0.2
                                  : 0

    property real keyboardOffset:
        GlobalState.loginKeyboardRequest
        ? (keyboardHeight / 2 + 40 * scale)
        : 0

    property real baseY:
        (Overlay.overlay.height - height) / 2 - (40 * scale)

    y: baseY - keyboardOffset

    // =====================================================
    // OUTSIDE CLICK CLOSE
    // =====================================================

    Overlay.modal: Rectangle {

        color: "#80000000"

        MouseArea {
            anchors.fill: parent

            onClicked: {
                GlobalState.loginKeyboardRequest = false
                GlobalState.activeInputField = null
                loginPopup.close()
            }
        }
    }

    // =====================================================
    // OPEN / CLOSE
    // =====================================================

    onOpened: {

        userTypeValue.text  = "--- Select ---"
        usernameValue.text  = "--- Select ---"
        passwordInput.text  = ""

        // Reset password visibility
        passwordInput.echoMode = TextInput.Password

        loginPopup.errorText          = ""
        loginPopup.hasError           = false
        loginPopup.currentSelectedUser = ""

        loginPopup.devModeActive  = false
        loginPopup.fieldsLocked   = false
        loginPopup.longPressCount = 0

        passwordInput.focus = false

        GlobalState.loginKeyboardRequest = false
        GlobalState.activeInputField     = null

        if (selectionPopup.visible)
            selectionPopup.close()
    }

    onClosed: {
        passwordInput.text     = ""
        passwordInput.echoMode = TextInput.Password

        passwordInput.focus = false

        loginPopup.devModeActive   = false
        loginPopup.fieldsLocked    = false
        loginPopup.currentSelectedUser = ""

        GlobalState.loginKeyboardRequest = false
        GlobalState.activeInputField     = null
    }

    background: Rectangle {
        color: "#EBEBEB"
        radius: 20 * scale
        border.color: "#C8C8C8"
        border.width: 1
    }



    // =====================================================
    // CLOSE BUTTON
    // =====================================================

    Rectangle {
        width: 34 * scale
        height: 34 * scale

        radius: width / 2

        color: closeMouse.containsMouse ? "#1A4DB5" : "#1A4DB5"

        anchors.top: parent.top
        anchors.right: parent.right

        anchors.topMargin:  3  * scale
        anchors.rightMargin: 12 * scale

        z: 999

        Text {
            anchors.centerIn: parent
            text: "✕"
            color: "white"
            font.pixelSize: loginTypography.body
        }

        MouseArea {
            id: closeMouse

            anchors.fill: parent

            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onClicked: {
                GlobalState.loginKeyboardRequest = false
                GlobalState.activeInputField     = null
                loginPopup.close()
            }
        }
    }

    // ================= SELECTION POPUP =================
    Popup {
        id: selectionPopup

        font.family: Application.font.family

        modal: true
        focus: true

        anchors.centerIn: Overlay.overlay

        property var    modelData: []
        property string title: ""
        property var    onSelectCallback

        // Extended model that carries { label, username, blocked, remaining }
        property var richModel: []

        width:  340 * scale
        height: (4 * 64 * scale) + (64 * scale)

        background: Rectangle {
            radius: 18 * scale
            color: "white"
            border.color: "#E0E3EB"
            border.width: 1
        }

        contentItem: Column {
            anchors.fill: parent

            // Header
            Rectangle {
                width: parent.width
                height: 64 * scale
                color: "white"
                radius: 18 * scale
                clip: true

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: radius
                    color: "#1A4DB5"
                }

                Text {
                    anchors.centerIn: parent
                    text: selectionPopup.title
                    color: "#1A4DB5"
                    font.pixelSize: loginTypography.body
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: "#E5E7EB"
            }

            Flickable {
                width: parent.width
                height: 4 * 64 * scale

                contentHeight: listColumn.height

                clip: true

                Column {
                    id: listColumn

                    width: parent.width

                    // ---- Simple string list (used for User Type) ----
                    Repeater {
                        model: selectionPopup.richModel.length === 0
                               ? selectionPopup.modelData
                               : []

                        delegate: Rectangle {
                            width: parent.width
                            height: 64 * scale

                            color: simpleMouse.pressed
                                   ? "#E8EDFF"
                                   : (index % 2 === 0 ? "#FFFFFF" : "#FAFBFF")

                            Rectangle {
                                anchors.bottom: parent.bottom
                                width: parent.width
                                height: 1
                                color: "#F0F0F0"
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 20 * scale
                                text: modelData
                                font.pixelSize: loginTypography.body
                                color: "#1A1A2E"
                            }

                            MouseArea {
                                id: simpleMouse
                                anchors.fill: parent
                                enabled: !loginPopup.fieldsLocked
                                onClicked: {
                                    selectionPopup.close()
                                    if (selectionPopup.onSelectCallback)
                                        selectionPopup.onSelectCallback(modelData)
                                }
                            }
                        }
                    }

                    // ---- Rich user list (used for Username, shows badge) ----
                    Repeater {
                        model: selectionPopup.richModel.length > 0
                               ? selectionPopup.richModel
                               : []

                        delegate: Rectangle {
                            width: parent.width
                            height: 64 * scale

                            property var entry: selectionPopup.richModel[index]

                            color: richMouse.pressed
                                   ? "#E8EDFF"
                                   : (index % 2 === 0 ? "#FFFFFF" : "#FAFBFF")

                            Rectangle {
                                anchors.bottom: parent.bottom
                                width: parent.width
                                height: 1
                                color: "#F0F0F0"
                            }

                            // Username label
                            Text {
                                id: userLabel
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 20 * scale
                                text: entry ? entry.username : ""
                                font.pixelSize: loginTypography.body
                                color: (entry && entry.blocked) ? "#999999" : "#1A1A2E"
                            }

                            // Blocked badge (right side)
                            Rectangle {
                                visible: entry ? entry.blocked : false
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: parent.right
                                anchors.rightMargin: 16 * scale

                                width: badgeText.implicitWidth + 20 * scale
                                height: 26 * scale
                                radius: 13 * scale
                                color: "#FF5252"

                                Text {
                                    id: badgeText
                                    anchors.centerIn: parent
                                    text: entry
                                          ? ("Blocked for " + (entry.label || (entry.remaining + "s")))
                                          : ""
                                    color: "white"
                                    font.pixelSize: loginTypography.tiny
                                }
                            }

                            MouseArea {
                                id: richMouse
                                anchors.fill: parent
                                enabled: !loginPopup.fieldsLocked
                                onClicked: {
                                    if (!entry) return
                                    selectionPopup.close()
                                    if (selectionPopup.onSelectCallback)
                                        selectionPopup.onSelectCallback(entry.username)
                                }
                            }
                        }
                    }
                }
            }
        }

        // Live-refresh the "remaining" seconds shown on blocked badges while popup is open
        Timer {
            id: badgeRefreshTimer
            interval: 1000
            repeat: true
            running: selectionPopup.visible && selectionPopup.richModel.length > 0

            onTriggered: {
                var updated = []
                for (var i = 0; i < selectionPopup.richModel.length; i++) {
                    var entry   = selectionPopup.richModel[i]
                    var blocked = loginPopup.isUserBlocked(entry.username)
                    var rem     = blocked ? loginPopup.getBlockRemaining(entry.username) : 0
                    updated.push({
                        username:  entry.username,
                        blocked:   blocked,
                        remaining: rem,
                        label:     blocked ? loginPopup.formatRemaining(rem) : ""
                    })
                }
                selectionPopup.richModel = updated
            }
        }
    }

    // ================= MAIN CONTENT =================
    contentItem: Flickable {
        id: flick

        anchors.fill: parent
        anchors.margins: 28 * scale

        contentWidth: width
        contentHeight: columnContent.height

        clip: true

        function adjustView() {
            if (passwordInput.activeFocus) {
                var itemY = passwordInput.mapToItem(columnContent, 0, 0).y
                contentY = Math.max(0, itemY - height * 0.4)
            }
        }

        ColumnLayout {
            id: columnContent

            width: flick.width

            spacing: 14 * scale

            Text {
                text: "Login"
                font.pixelSize: loginTypography.title
                color: "#1A4DB5"
            }

            // USER TYPE
            Rectangle {
                Layout.fillWidth: true
                height: 58 * scale
                radius: 10 * scale
                color: "#F2F2F2"
                border.color: "#1A4DB5"

                Text {
                    id: userTypeValue
                    anchors.left: parent.left
                    anchors.leftMargin: 18 * scale
                    anchors.verticalCenter: parent.verticalCenter
                    text: "--- Select ---"
                    font.pixelSize: loginTypography.body
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 18 * scale
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Usertype"
                    color: "#AAAAAA"
                    font.pixelSize: loginTypography.body
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: !loginPopup.fieldsLocked

                    onClicked: {
                        selectionPopup.title    = "Select User Type"
                        selectionPopup.richModel = []
                        selectionPopup.modelData = [
                            "Admin",
                            "Supervisor",
                            "Operator"
                        ]

                        selectionPopup.onSelectCallback = function(val) {
                            userTypeValue.text = val
                            // Reset username and errors when role changes
                            usernameValue.text = "--- Select ---"
                            loginPopup.currentSelectedUser = ""
                            loginPopup.errorText = ""
                            loginPopup.hasError  = false
                            loginPopup.blockedUserName = ""
                            blockCountdownTimer.stop()
                        }

                        selectionPopup.open()
                    }
                }
            }

            // USERNAME
            Rectangle {
                Layout.fillWidth: true
                height: 58 * scale
                radius: 10 * scale
                color: "#F2F2F2"
                border.color: "#1A4DB5"

                Text {
                    id: usernameValue
                    anchors.left: parent.left
                    anchors.leftMargin: 18 * scale
                    anchors.verticalCenter: parent.verticalCenter
                    text: "--- Select ---"
                    font.pixelSize: loginTypography.body
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 18 * scale
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Username"
                    color: "#AAAAAA"
                    font.pixelSize: loginTypography.body
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: !loginPopup.fieldsLocked

                    onClicked: {
                        if (userTypeValue.text === "--- Select ---")
                            return

                        selectionPopup.title = "Select Username"
                        selectionPopup.modelData = []

                        var users = databaseManager.getUsersByRole(userTypeValue.text)

                        // Build rich model with block info
                        var rich = []
                        for (var i = 0; i < users.length; i++) {
                            var name    = users[i]
                            var blocked = loginPopup.isUserBlocked(name)
                            var rem     = blocked ? loginPopup.getBlockRemaining(name) : 0
                            rich.push({
                                username:  name,
                                blocked:   blocked,
                                remaining: rem,
                                label:     blocked ? loginPopup.formatRemaining(rem) : ""
                            })
                        }
                        selectionPopup.richModel = rich

                        selectionPopup.onSelectCallback = function(username)
                        {
                            usernameValue.text = username
                            loginPopup.currentSelectedUser = username

                            passwordInput.text = ""

                            // First show block-related errors
                            loginPopup.refreshErrorForUser(username)

                            // If user is blocked, don't overwrite the message
                            if (loginPopup.isUserBlocked(username))
                                return

                            // Password expired
                            if (databaseManager.isPasswordExpired(username)) {

                                loginPopup.errorText =
                                    "Password expired. Please change your password."

                                loginPopup.hasError = true
                                return
                            }

                            // Password expiry warning
                            var days = databaseManager.daysUntilPasswordExpiry(username)

                            if (days >= 0 && days <= 7) {

                                loginPopup.errorText =
                                    days === 0
                                    ? "Password expires today."
                                    : "Password will expire in " + days + " day(s)."

                                loginPopup.hasError = true
                            }
                        }

                        selectionPopup.open()
                    }
                }
            }

            // PASSWORD
            Rectangle {
                Layout.fillWidth: true
                height: 58 * scale
                radius: 10 * scale
                color: "#F2F2F2"

                border.color: loginPopup.hasError ? "#FF5252" : "#1A4DB5"
                border.width: loginPopup.hasError ? 2 : 1

                TextField {
                    id: passwordInput

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 18 * scale
                    anchors.rightMargin: 18 * scale
                    anchors.verticalCenter: parent.verticalCenter

                    property bool isPasswordField: true

                    echoMode: TextInput.Password

                    background: null
                    padding: 0

                    font.pixelSize: loginTypography.heading
                    color: "#000000"

                    inputMethodHints:
                        Qt.ImhPreferLatin
                        | Qt.ImhNoPredictiveText
                        | Qt.ImhSensitiveData
                        | Qt.ImhNone

                    activeFocusOnPress: true
                    activeFocusOnTab:   true

                    onAccepted: {
                        GlobalState.loginKeyboardRequest = false
                        focus = false
                    }

                    onTextChanged: {
                        // Clear error only if it's a "wrong password" error,
                        // not a "blocked" error – let the user type freely
                        if (loginPopup.hasError && !loginPopup.isUserBlocked(loginPopup.currentSelectedUser)) {
                            loginPopup.errorText = ""
                            loginPopup.hasError  = false
                        }
                    }

                    onActiveFocusChanged: {
                        if (activeFocus) {
                            GlobalState.activeInputField     = passwordInput
                            GlobalState.loginKeyboardRequest = true
                            if (flick)
                                flick.adjustView()
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton

                    onPressed: {
                        passwordInput.forceActiveFocus()
                        GlobalState.activeInputField     = passwordInput
                        GlobalState.loginKeyboardRequest = true
                        if (flick)
                            flick.adjustView()
                        mouse.accepted = false
                    }
                }

                // PLACEHOLDER
                Text {
                    id: placeholderText
                    anchors.right: parent.right
                    anchors.rightMargin: 18 * scale
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Password"
                    color: "#AAAAAA"
                    font.pixelSize: loginTypography.body
                    visible: passwordInput.text.length === 0
                }

                // SHOW / HIDE toggle
                Rectangle {
                    id: toggle
                    anchors.right: parent.right
                    anchors.rightMargin: 12 * scale
                    anchors.verticalCenter: parent.verticalCenter
                    width: 50 * scale
                    height: 32 * scale
                    color: "transparent"
                    visible: passwordInput.text.length > 0

                    Text {
                        anchors.centerIn: parent
                        text: passwordInput.echoMode === TextInput.Password
                              ? "Show"
                              : "Hide"
                        color: "#1A4DB5"
                        font.pixelSize: loginTypography.small
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            passwordInput.echoMode =
                                passwordInput.echoMode === TextInput.Password
                                ? TextInput.Normal
                                : TextInput.Password
                        }
                    }
                }
            }

            // ERROR TEXT
            Text {
                Layout.fillWidth: true
                text: loginPopup.errorText
                color: "#FF5252"
                horizontalAlignment: Text.AlignHCenter
                visible: loginPopup.hasError
                wrapMode: Text.WordWrap
                font.pixelSize: loginTypography.caption
            }

            // BUTTONS
            Row {
                Layout.alignment: Qt.AlignHCenter
                spacing: 20 * scale

                // LOGIN button
                Rectangle {
                    width: 160 * scale
                    height: 52 * scale
                    radius: 10 * scale
                    color: "#1A4DB5"

                    Text {
                        anchors.centerIn: parent
                        text: "Login"
                        color: "white"
                        font.pixelSize: loginTypography.body
                    }

                    MouseArea {
                        anchors.fill: parent

                        Timer {
                            id: longPressTimer
                            interval: 3000
                            repeat: false

                            onTriggered: {
                                loginPopup.longPressCount++

                                if (loginPopup.longPressCount >= 2) {
                                    loginPopup.devModeActive = true
                                    loginPopup.fieldsLocked  = false

                                    passwordInput.forceActiveFocus()

                                    GlobalState.activeInputField     = passwordInput
                                    GlobalState.loginKeyboardRequest = true

                                    loginPopup.longPressCount = 0
                                }
                            }
                        }

                        onPressed:  longPressTimer.start()
                        onReleased: longPressTimer.stop()

                        onClicked: {
                            if (userTypeValue.text  === "--- Select ---" ||
                                usernameValue.text  === "--- Select ---")
                                return

                            if (loginPopup.devModeActive)
                                return

                            // Do not allow login attempt while user is blocked
                            if (loginPopup.isUserBlocked(loginPopup.currentSelectedUser)) {
                                loginPopup.refreshErrorForUser(loginPopup.currentSelectedUser)
                                return
                            }

                            loginPopup.loginRequested(
                                userTypeValue.text,
                                usernameValue.text,
                                passwordInput.text
                            )
                        }
                    }
                }

                // CLEAR button
                Rectangle {
                    width: 160 * scale
                    height: 52 * scale
                    radius: 10 * scale
                    border.color: "#1A4DB5"
                    border.width: 2
                    color: "white"

                    Text {
                        anchors.centerIn: parent
                        text: "Clear"
                        color: "#1A4DB5"
                        font.pixelSize: loginTypography.body
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !loginPopup.fieldsLocked

                        onClicked: {
                            userTypeValue.text = "--- Select ---"
                            usernameValue.text = "--- Select ---"

                            passwordInput.text     = ""
                            passwordInput.echoMode = TextInput.Password

                            loginPopup.devModeActive       = false
                            loginPopup.fieldsLocked        = false
                            loginPopup.currentSelectedUser = ""
                            loginPopup.errorText           = ""
                            loginPopup.hasError            = false
                            loginPopup.blockedUserName     = ""

                            blockCountdownTimer.stop()

                            loginPopup.clearRequested()
                        }
                    }
                }
            }
        }
    }

    function onLoginSuccess(username) {
        loginPopup.clearFailedAttempts(username)
        loginPopup.errorText = ""
        loginPopup.hasError  = false
        loginPopup.close()
    }

    function onLoginFailure(username) {
        // Guard: don't record an attempt if already blocked
        if (loginPopup.isUserBlocked(username)) {
            loginPopup.refreshErrorForUser(username)
            return
        }
        loginPopup.registerFailedAttempt(username)
    }
}
