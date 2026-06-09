import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import AppState 1.0

Popup {

    id: createUserPopup

    // =========================================================
    // TYPOGRAPHY FOR CREATE USER POPUP
    // =========================================================

    Typography {
        id: createUserTypography
        scale: 1.0
    }

    property var globalTopBar: null

    Component.onCompleted: {
        root.applyFontToAllChildren(this)
    }

    property string errorText: ""
    property bool hasError: false

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

    // ── Responsive Base ──
    property real baseWidth: 1024
    property real baseHeight: 600

    signal createUserRequested(string userType, string username, string password)
    signal clearRequested()

    // =====================================================
    // QT 6.5 KEYBOARD FIX
    // =====================================================

    parent: Overlay.overlay

    modal: false
    focus: false

    Overlay.modal: Rectangle {
        color: "#66000000"
    }

    closePolicy: Popup.NoAutoClose

    width: 520 * scale
    height: 460 * scale

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

    // ── RESET STATE ──
    onOpened: {
        userTypeValue.text = "--- Select ---"
        usernameInput.text = ""
        passwordInput.text = ""

        errorText = ""
        hasError = false

        GlobalState.loginKeyboardRequest = false
        GlobalState.activeInputField = null
    }

    onClosed: {
        usernameInput.focus = false
        passwordInput.focus = false

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


            font.pixelSize: 18
        }

        MouseArea {
            id: closeMouse

            anchors.fill: parent

            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onClicked: {

                GlobalState.loginKeyboardRequest = false
                GlobalState.activeInputField = null

                createUserPopup.close()
            }
        }
    }

    // ================= USER TYPE POPUP =================
    Popup {
        id: selectionPopup

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

            // ===== HEADER =====
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

                    font.pixelSize: 20
                    font.bold: true
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: "#E5E7EB"
            }

            // ===== LIST =====
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
                                   : (index % 2 === 0
                                      ? "#FFFFFF"
                                      : "#FAFBFF")

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

                                font.pixelSize: 18
                                color: "#1A1A2E"
                            }

                            MouseArea {
                                id: mouse

                                anchors.fill: parent

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

    // ================= MAIN UI =================
    contentItem: Flickable {
        id: flick

        anchors.fill: parent
        anchors.margins: 24 * scale

        contentHeight: columnContent.height

        clip: true

        function adjustView(item) {

            var itemY = item.mapToItem(columnContent, 0, 0).y

            contentY = Math.max(0, itemY - height * 0.4)
        }

        ColumnLayout {
            id: columnContent

            width: flick.width

            spacing: 14 * scale

            Text {
                text: "Create User"

                font.pixelSize: createUserTypography.title


                color: "#1A4DB5"
            }

            // ── USER TYPE ──
            Rectangle {
                Layout.fillWidth: true

                height: 56 * scale

                radius: 10 * scale

                color: "#F2F2F2"

                border.color: "#1A4DB5"

                Text {
                    id: userTypeValue

                    anchors.left: parent.left
                    anchors.leftMargin: 16 * scale
                    anchors.verticalCenter: parent.verticalCenter

                    text: "--- Select ---"

                    font.pixelSize: createUserTypography.body

                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 25 * scale
                    anchors.verticalCenter: parent.verticalCenter

                    text: "User Type"

                    color: "#AAAAAA"

                    font.pixelSize: createUserTypography.body

                }

                MouseArea {
                    anchors.fill: parent

                    onClicked: {

                        selectionPopup.title = "Select User Type"

                        selectionPopup.modelData = [
                                    "Admin",
                                    "Supervisor",
                                    "Operator"
                                ]

                        selectionPopup.onSelectCallback = function(val) {
                            userTypeValue.text = val
                        }

                        selectionPopup.open()
                    }
                }
            }

            // ── USERNAME ──
            Rectangle {
                Layout.fillWidth: true

                height: 56 * scale

                radius: 10 * scale

                color: "#F2F2F2"

                border.color: createUserPopup.hasError ? "#FF5252" : "#1A4DB5"
                border.width: createUserPopup.hasError ? 2 : 1

                TextField {
                    id: usernameInput

                    anchors.left: parent.left
                    anchors.leftMargin: 16 * scale
                    anchors.verticalCenter: parent.verticalCenter

                    width: parent.width * 0.7

                    property bool isPasswordField: false

                    font.pixelSize: 18


                    color: "#1A1A2E"

                    inputMethodHints: Qt.ImhNone

                    background: null

                    padding: 0
                    leftPadding: 0
                    rightPadding: 0
                    topPadding: 0
                    bottomPadding: 0

                    activeFocusOnPress: true
                    activeFocusOnTab: true

                    onAccepted: {
                        passwordInput.forceActiveFocus()
                    }

                    onActiveFocusChanged: {

                        if (activeFocus) {

                            GlobalState.activeInputField = usernameInput
                            GlobalState.loginKeyboardRequest = true

                            if (flick)
                                flick.adjustView(usernameInput)
                        }
                    }

                    onTextChanged: {
                        createUserPopup.errorText = ""
                        createUserPopup.hasError = false
                    }
                }

                MouseArea {
                    anchors.fill: parent

                    acceptedButtons: Qt.LeftButton

                    onPressed: {

                        usernameInput.forceActiveFocus()

                        GlobalState.activeInputField = usernameInput
                        GlobalState.loginKeyboardRequest = true

                        if (flick)
                            flick.adjustView(usernameInput)

                        mouse.accepted = false
                    }
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 25 * scale
                    anchors.verticalCenter: parent.verticalCenter

                    text: "Username"

                    color: "#AAAAAA"

                    font.pixelSize: createUserTypography.body

                }
            }

            Text {
                Layout.fillWidth: true

                text: createUserPopup.errorText

                color: "#FF3B30"

                font.pixelSize: createUserTypography.bodySmall

                visible: createUserPopup.hasError

                wrapMode: Text.WordWrap
            }

            // ── PASSWORD ──
            Rectangle {
                Layout.fillWidth: true

                height: 56 * scale

                radius: 10 * scale

                color: "#F2F2F2"

                border.color: "#1A4DB5"

                TextField {
                    id: passwordInput

                    anchors.left: parent.left
                    anchors.right: toggle.left

                    anchors.leftMargin: 16 * scale
                    anchors.rightMargin: 8 * scale
                    anchors.verticalCenter: parent.verticalCenter

                    property bool isPasswordField: true

                    echoMode: TextInput.Password

                    font.pixelSize: createUserTypography.heading


                    color: "#000000"

                    background: null

                    padding: 0

                    inputMethodHints: Qt.ImhNone

                    activeFocusOnPress: true
                    activeFocusOnTab: true

                    onAccepted: {

                        GlobalState.loginKeyboardRequest = false
                        createUserPopup.close()
                    }

                    onActiveFocusChanged: {

                        if (activeFocus) {

                            GlobalState.activeInputField = passwordInput
                            GlobalState.loginKeyboardRequest = true

                            if (flick)
                                flick.adjustView(passwordInput)
                        }
                    }
                }

                Text {
                    id: placeholderText

                    anchors.right: parent.right
                    anchors.rightMargin: 25 * scale
                    anchors.verticalCenter: parent.verticalCenter

                    text: "Password"

                    color: "#AAAAAA"

                    font.pixelSize: createUserTypography.body


                    visible: passwordInput.text.length === 0
                }

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

                        font.pixelSize: 14

                        color: "#1A4DB5"


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

                MouseArea {
                    anchors.fill: parent

                    acceptedButtons: Qt.LeftButton

                    onPressed: {

                        passwordInput.forceActiveFocus()

                        GlobalState.activeInputField = passwordInput
                        GlobalState.loginKeyboardRequest = true

                        if (flick)
                            flick.adjustView(passwordInput)

                        mouse.accepted = false
                    }
                }
            }

            // ── BUTTONS ──
            Row {
                Layout.alignment: Qt.AlignHCenter

                spacing: 20 * scale

                Rectangle {
                    width: 150 * scale
                    height: 50 * scale

                    radius: 10 * scale

                    color: "#1A4DB5"

                    Text {
                        anchors.centerIn: parent

                        text: "Create"

                        color: "white"

                        font.pixelSize: createUserTypography.body
                    }

                    MouseArea {
                        anchors.fill: parent

                        onClicked: {

                            if (userTypeValue.text === "--- Select ---" ||
                                    usernameInput.text.trim() === "" ||
                                    passwordInput.text.trim() === "") {

                                console.log("Validation failed")
                                return
                            }

                            var username = usernameInput.text.trim()

                            // Generate simple FPID
                            var fpid =
                                    Math.floor(
                                        1000 + Math.random() * 9000
                                        ).toString()

                            // Generate User ID
                            var id =
                                    Math.floor(
                                        100 + Math.random() * 900
                                        ).toString()

                            var success =
                                    databaseManager.insertUser(
                                        fpid,
                                        id,
                                        username,
                                        passwordInput.text,
                                        userTypeValue.text)

                            if (success)
                            {
                                if (createUserPopup.globalTopBar &&
                                        createUserPopup.globalTopBar.showNotification)
                                {
                                    createUserPopup.globalTopBar.showNotification(
                                        "✓ User created successfully"
                                    )
                                }

                                GlobalState.loginKeyboardRequest = false
                                GlobalState.activeInputField = null

                                createUserPopup.close()
                            }
                            else
                            {
                                createUserPopup.errorText = "Username already exists"
                                createUserPopup.hasError = true

                            }
                        }
                    }
                }

                Rectangle {
                    width: 150 * scale
                    height: 50 * scale

                    radius: 10 * scale

                    border.color: "#1A4DB5"
                    border.width: 2

                    color: "white"

                    Text {
                        anchors.centerIn: parent

                        text: "Clear"

                        color: "#1A4DB5"

                        font.pixelSize: createUserTypography.body
                    }

                    MouseArea {
                        anchors.fill: parent

                        onClicked: {

                            userTypeValue.text = "--- Select ---"

                            usernameInput.text = ""
                            passwordInput.text = ""

                            createUserPopup.clearRequested()
                        }
                    }
                }
            }
        }
    }
}
