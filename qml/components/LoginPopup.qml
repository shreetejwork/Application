import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import AppState 1.0

Popup {
    id: loginPopup

    property real baseWidth: 1024
    property real baseHeight: 600

    property bool isLongPress: false
    property int longPressCount: 0


    property bool devModeActive: false
    property bool fieldsLocked: false

    property string developerPassword: "dev123"
    property string engineerPassword: "eng123"

    property real keyboardHeight: Qt.inputMethod.visible ? Qt.inputMethod.keyboardRectangle.height : 0

    signal loginRequested(string userType, string username, string password)
    signal clearRequested()

    modal: true
    focus: true
    closePolicy: Popup.CloseOnPressOutside

    width: 520 * scale
    height: 460 * scale

    x: (Overlay.overlay.width - width) / 2
    y: Qt.inputMethod.visible
       ? Math.max(20, (Overlay.overlay.height - height - keyboardHeight) / 2)
       : (Overlay.overlay.height - height) / 2

    Behavior on y {
        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
    }

    onOpened: {
        userTypeValue.text = "--- Select ---"
        usernameValue.text = "--- Select ---"
        passwordInput.text = ""

        loginPopup.devModeActive = false
        loginPopup.fieldsLocked = false
        loginPopup.longPressCount = 0

        passwordInput.focus = false
        loginPopup.focus = true

        GlobalState.loginKeyboardRequest = false

        if (selectionPopup.visible)
            selectionPopup.close()

        Qt.inputMethod.hide()
    }

    onClosed: {
        Qt.inputMethod.hide()
        passwordInput.focus = false

        loginPopup.devModeActive = false
        loginPopup.fieldsLocked = false
        GlobalState.loginKeyboardRequest = false
    }

    background: Rectangle {
        color: "#EBEBEB"
        radius: 20 * scale
        border.color: "#C8C8C8"
        border.width: 1
    }

    // ================= SELECTION POPUP =================
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
                    font.pixelSize: 19 * scale
                }
            }

            Rectangle { width: parent.width; height: 1; color: "#E5E7EB" }

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
                                font.pixelSize: 18 * scale
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
                font.pixelSize: Math.max(16, 26 * scale)
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
                    font.pixelSize: Math.max(12, 18 * scale)
                    font.bold: true
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 18 * scale
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Usertype"
                    color: "#AAAAAA"
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: !loginPopup.fieldsLocked

                    onClicked: {
                        selectionPopup.title = "Select User Type"
                        selectionPopup.modelData = ["Admin","Operator","User"]
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
                    font.pixelSize: Math.max(12, 18 * scale)
                    font.bold: true
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 18 * scale
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Username"
                    color: "#AAAAAA"
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: !loginPopup.fieldsLocked

                    onClicked: {
                        selectionPopup.title = "Select Username"
                        selectionPopup.modelData = ["John Doe","Jane Smith","Bob Johnson","John Doe","Jane Smith","Bob Johnson"]
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
                    anchors.leftMargin: 18 * scale
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * 0.75

                    echoMode: TextInput.Password

                    background: null
                    padding: 0
                    leftPadding: 0
                    rightPadding: 0
                    topPadding: 0
                    bottomPadding: 0

                    font.pixelSize: Math.max(15, 21 * scale)
                    font.bold: true

                    inputMethodHints: Qt.ImhPreferLatin
                                      | Qt.ImhNoPredictiveText
                                      | Qt.ImhSensitiveData
                                      | Qt.ImhNone   // ADD for Pi stability

                    onActiveFocusChanged: {
                        if (activeFocus) {
                            GlobalState.loginKeyboardRequest = true
                            Qt.inputMethod.show()
                            flick.adjustView()
                        } else {
                            GlobalState.loginKeyboardRequest = false
                            Qt.inputMethod.hide()
                        }
                    }

                    //  TextField uses onAccepted
                    onAccepted: {
                        card.confirmed(text.trim())
                        Qt.inputMethod.hide()
                        focus = false
                    }

                    // PASSWORD CHECK
                    onTextChanged: {
                        if (!loginPopup.devModeActive)
                            return

                        if (text === loginPopup.developerPassword) {
                            userTypeValue.text = "Developer"
                            usernameValue.text = "Developer"
                            loginPopup.fieldsLocked = true
                            loginPopup.devModeActive = false
                        }

                        if (text === loginPopup.engineerPassword) {
                            userTypeValue.text = "Engineer"
                            usernameValue.text = "Engineer"
                            loginPopup.fieldsLocked = true
                            loginPopup.devModeActive = false
                        }
                    }
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 18 * scale
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Password"
                    color: "#AAAAAA"
                }
            }

            // ================= BUTTONS =================
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
                                    GlobalState.loginKeyboardRequest = true
                                    Qt.inputMethod.show()

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

                            Qt.inputMethod.hide()

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

                            Qt.inputMethod.hide()
                            loginPopup.clearRequested()
                        }
                    }
                }
            }
        }
    }
}
