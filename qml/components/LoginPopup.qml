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
    
    // =========================================================
    // TYPOGRAPHY FOR LOGIN POPUP
    // =========================================================
    
    Typography {
        id: loginTypography
        scale: 1.0
    }

    signal loginRequested(string userType, string username, string password)
    signal clearRequested()

    // =====================================================
    // QT 6.5 KEYBOARD FIX
    // =====================================================

    parent: Overlay.overlay

    font.family: Application.font.family

    modal: false
    focus: false
    dim: true

    closePolicy: Popup.NoAutoClose

    width: 520 * scale
    height: 430 * scale

    x: (Overlay.overlay.width - width) / 2

    property real keyboardHeight: GlobalState.loginKeyboardRequest
                                  ? Overlay.overlay.height * 0.5
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

        userTypeValue.text = "--- Select ---"
        usernameValue.text = "--- Select ---"
        passwordInput.text = ""

        loginPopup.devModeActive = false
        loginPopup.fieldsLocked = false
        loginPopup.longPressCount = 0

        passwordInput.focus = false

        GlobalState.loginKeyboardRequest = false
        GlobalState.activeInputField = null

        if (selectionPopup.visible)
            selectionPopup.close()
    }

    onClosed: {

        passwordInput.focus = false

        loginPopup.devModeActive = false
        loginPopup.fieldsLocked = false

        GlobalState.loginKeyboardRequest = false
        GlobalState.activeInputField = null
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

        anchors.topMargin: 3 * scale
        anchors.rightMargin: 12 * scale

        z: 999

        Text {
            anchors.centerIn: parent

            text: "✕"

            color: "white"

            font.bold: true
            font.pixelSize: loginTypography.body
        }

        MouseArea {
            id: closeMouse

            anchors.fill: parent

            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onClicked: {

                GlobalState.loginKeyboardRequest = false
                GlobalState.activeInputField = null

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

        property var modelData: []
        property string title: ""
        property var onSelectCallback

        width: 340 * scale
        height: (4 * 64 * scale) + (64 * scale)

        background: Rectangle {
            radius: 18 * scale
            color: "white"
            border.color: "#E0E3EB"
            border.width: 1
        }

        contentItem: Column {
            anchors.fill: parent

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
                    font.bold: true
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

                    Repeater {
                        model: selectionPopup.modelData

                        delegate: Rectangle {
                            width: parent.width
                            height: 64 * scale

                            color: mouse.pressed
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
                                font.bold: true

                                color: "#1A1A2E"
                            }

                            MouseArea {
                                id: mouse

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
                }
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

                var itemY =
                        passwordInput.mapToItem(columnContent, 0, 0).y

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
                font.bold: true

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
                    font.bold: true
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 18 * scale
                    anchors.verticalCenter: parent.verticalCenter

                    text: "Usertype"

                    color: "#AAAAAA"

                    font.pixelSize: loginTypography.body
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent

                    enabled: !loginPopup.fieldsLocked

                    onClicked: {

                        selectionPopup.title = "Select User Type"

                        selectionPopup.modelData = [
                                    "Admin",
                                    "Operator",
                                    "User"
                                ]

                        selectionPopup.onSelectCallback = function(val) {
                            userTypeValue.text = val
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
                    font.bold: true
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 18 * scale
                    anchors.verticalCenter: parent.verticalCenter

                    text: "Username"

                    color: "#AAAAAA"

                    font.pixelSize: loginTypography.body
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent

                    enabled: !loginPopup.fieldsLocked

                    onClicked: {

                        selectionPopup.title = "Select Username"

                        selectionPopup.modelData = [
                                    "John Doe",
                                    "Jane Smith",
                                    "Bob Johnson",
                                    "John Doe",
                                    "Jane Smith",
                                    "Bob Johnson"
                                ]

                        selectionPopup.onSelectCallback = function(val) {
                            usernameValue.text = val
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

                border.color: "#1A4DB5"

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
                    font.bold: true

                    color: "#000000"

                    inputMethodHints:
                        Qt.ImhPreferLatin
                        | Qt.ImhNoPredictiveText
                        | Qt.ImhSensitiveData
                        | Qt.ImhNone

                    activeFocusOnPress: true
                    activeFocusOnTab: true

                    onAccepted: {

                        GlobalState.loginKeyboardRequest = false
                        focus = false
                    }

                    onActiveFocusChanged: {

                        if (activeFocus) {

                            GlobalState.activeInputField = passwordInput
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

                        GlobalState.activeInputField = passwordInput
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
                    font.bold: true

                    visible: passwordInput.text.length === 0
                }

                // SHOW / HIDE
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

                        font.pixelSize: loginTypography.small

                        color: "#1A4DB5"

                        font.bold: true
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

            // BUTTONS
            Row {
                Layout.alignment: Qt.AlignHCenter

                spacing: 20 * scale

                Rectangle {
                    width: 160 * scale
                    height: 52 * scale

                    radius: 10 * scale

                    color: "#1A4DB5"

                    Text {
                        anchors.centerIn: parent

                        text: "Login"

                        color: "white"

                        font.bold: true
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
                                    loginPopup.fieldsLocked = false

                                    passwordInput.forceActiveFocus()

                                    GlobalState.activeInputField =
                                            passwordInput

                                    GlobalState.loginKeyboardRequest = true

                                    loginPopup.longPressCount = 0
                                }
                            }
                        }

                        onPressed: longPressTimer.start()

                        onReleased: longPressTimer.stop()

                        onClicked: {

                            if (userTypeValue.text === "--- Select ---" ||
                                    usernameValue.text === "--- Select ---")
                                return

                            if (loginPopup.devModeActive)
                                return

                            loginPopup.loginRequested(
                                        userTypeValue.text,
                                        usernameValue.text,
                                        passwordInput.text
                                        )
                        }
                    }
                }

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

                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent

                        enabled: !loginPopup.fieldsLocked

                        onClicked: {

                            userTypeValue.text = "--- Select ---"
                            usernameValue.text = "--- Select ---"

                            passwordInput.text = ""

                            loginPopup.devModeActive = false
                            loginPopup.fieldsLocked = false

                            loginPopup.clearRequested()
                        }
                    }
                }
            }
        }
    }
}
