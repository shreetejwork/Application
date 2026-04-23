import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import AppState 1.0

Popup {
    id: createUserPopup

    // ── Responsive Base ──
    property real baseWidth: 1024
    property real baseHeight: 600



    signal createUserRequested(string userType, string username, string password)
    signal clearRequested()

    modal: true
    focus: true
    closePolicy: Popup.CloseOnPressOutside

    width: 600 * scale
    height: 480 * scale

    x: (Overlay.overlay.width - width) / 2
    property real baseY: (Overlay.overlay.height - height) / 2 - (40 * scale)

                                  ? (keyboardHeight / 2 + 40 * scale)
                                  : 0

    y: baseY - keyboardOffset

    // ── RESET STATE ──
    onOpened: {
        userTypeValue.text = "--- Select ---"
        usernameInput.text = ""
        passwordInput.text = ""

        GlobalState.loginKeyboardRequest = false

        if (selectionPopup.visible)
            selectionPopup.close()
    }

    onClosed: {
        usernameInput.focus = false
        passwordInput.focus = false
    }

    background: Rectangle {
        color: "#EBEBEB"
        radius: 20 * scale
        border.color: "#C8C8C8"
        border.width: 1
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

        width: 320 * scale
        height: (4 * 60 * scale) + (60 * scale)

        background: Rectangle {
            radius: 16 * scale
            color: "white"
            border.color: "#E0E3EB"
        }

        Column {
            anchors.fill: parent

            Text {
                text: selectionPopup.title
                anchors.horizontalCenter: parent.horizontalCenter
                padding: 16 * scale
                font.bold: true
                color: "#1A4DB5"
                font.pixelSize: 20 * scale
            }

            Repeater {
                model: selectionPopup.modelData

                delegate: Rectangle {
                    width: parent.width
                    height: 60 * scale
                    color: mouse.pressed ? "#E8EDFF" : "white"

                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        font.pixelSize: 18 * scale
                        font.bold: true
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
                font.pixelSize: Math.max(20, 32 * scale)
                font.bold: true
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
                    font.pixelSize: Math.max(12, 18 * scale)
                    font.bold: true
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 25 * scale
                    anchors.verticalCenter: parent.verticalCenter
                    text: "User Type"
                    color: "#AAAAAA"
                    font.pixelSize: Math.max(14, 18 * scale)
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent

                    onClicked: {
                        selectionPopup.title = "Select User Type"
                        selectionPopup.modelData = ["Admin", "Operator", "User"]
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
                border.color: "#1A4DB5"

                TextField {
                    id: usernameInput
                    anchors.left: parent.left
                    anchors.leftMargin: 16 * scale
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * 0.7

                    property bool isPasswordField: false

                    font.pixelSize: Math.max(25, 18 * scale)
                    font.bold: true
                    color: "#1A1A2E"

                    inputMethodHints: Qt.ImhNone   // important for Pi
                    background: null
                    padding: 0
                    leftPadding: 0
                    rightPadding: 0
                    topPadding: 0
                    bottomPadding: 0


                    activeFocusOnPress: true


                    onActiveFocusChanged: {
                        if (activeFocus) {
                            GlobalState.activeInputField = usernameInput
                            GlobalState.loginKeyboardRequest = true

                            if (flick)
                                flick.adjustView(usernameInput)
                        } else {
                            GlobalState.loginKeyboardRequest = false
                        }
                    }


                    MouseArea {
                        anchors.fill: parent
                        onPressed: usernameInput.forceActiveFocus()
                    }

                    onAccepted: {
                        GlobalState.loginKeyboardRequest = false
                        focus = false
                    }
                }

                // IMPORTANT CLICK HANDLER
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        usernameInput.forceActiveFocus()
                    }
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 25 * scale
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Username"
                    color: "#AAAAAA"
                    font.pixelSize: Math.max(14, 18 * scale)
                    font.bold: true
                }
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

                    font.pixelSize: Math.max(25, 21 * scale)
                    font.bold: true
                    color: "#000000"

                    background: null
                    padding: 0

                    inputMethodHints: Qt.ImhNone
                    activeFocusOnPress: true

                    onActiveFocusChanged: {
                        if (activeFocus) {
                            GlobalState.activeInputField = passwordInput
                            GlobalState.loginKeyboardRequest = true

                            if (flick)
                                flick.adjustView(passwordInput)
                        } else {
                            GlobalState.loginKeyboardRequest = false
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onPressed: passwordInput.forceActiveFocus()
                    }

                    onAccepted: {
                        GlobalState.loginKeyboardRequest = false
                        focus = false
                    }
                }

                //  PLACEHOLDER
                Text {
                    id: placeholderText

                    anchors.right: parent.right
                    anchors.rightMargin: 25 * scale
                    anchors.verticalCenter: parent.verticalCenter

                    text: "Password"
                    color: "#AAAAAA"
                    font.pixelSize: Math.max(14, 18 * scale)
                    font.bold: true

                    visible: passwordInput.text.length === 0
                }

                // SHOW / HIDE TOGGLE
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
                        text: passwordInput.echoMode === TextInput.Password ? "Show" : "Hide"
                        font.pixelSize: 14 * scale
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

                // CLICK HANDLER (keep)
                MouseArea {
                    anchors.fill: parent
                    onClicked: passwordInput.forceActiveFocus()
                }
            }

            // ── BUTTONS ──
            Row {
                Layout.alignment: Qt.AlignHCenter
                spacing: 20 * scale

                // CREATE
                Rectangle {
                    width: 150 * scale
                    height: 50 * scale
                    radius: 10 * scale
                    color: "#1A4DB5"

                    Text {
                        anchors.centerIn: parent
                        text: "Create"
                        color: "white"
                        font.bold: true
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

                            console.log("Creating user...")

                            createUserPopup.createUserRequested(
                                        userTypeValue.text,
                                        usernameInput.text.trim(),
                                        passwordInput.text
                                        )

                            createUserPopup.close()
                        }
                    }
                }

                // CLEAR
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
                        font.bold: true
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
