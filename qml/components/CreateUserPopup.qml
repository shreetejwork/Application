import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import AppState 1.0

Popup {
    id: createUserPopup

    // ── Responsive Base ──
    property real baseWidth: 1024
    property real baseHeight: 600

    property real keyboardHeight: Qt.inputMethod.visible
                                  ? Qt.inputMethod.keyboardRectangle.height
                                  : 0

    signal createUserRequested(string userType, string username, string password)
    signal clearRequested()

    modal: true
    focus: true
    closePolicy: Popup.CloseOnPressOutside

    width: 600 * scale
    height: 480 * scale

    x: (Overlay.overlay.width - width) / 2
    y: {
        //  Slightly above center even without keyboard
        if (!Qt.inputMethod.visible)
            return (Overlay.overlay.height - height) / 2 - (40 * scale)

        //  When keyboard is open (already good)
        return Math.max(
                    10 * scale,
                    Overlay.overlay.height
                    - height
                    - keyboardHeight
                    - (60 * scale)
                    )
    }

    // ── RESET STATE ──
    onOpened: {
        userTypeValue.text = "--- Select ---"
        usernameInput.text = ""
        passwordInput.text = ""

        Qt.inputMethod.hide()
        GlobalState.loginKeyboardRequest = false

        if (selectionPopup.visible)
            selectionPopup.close()
    }

    onClosed: {
        Qt.inputMethod.hide()
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

                TextInput {
                    id: usernameInput
                    anchors.left: parent.left
                    anchors.leftMargin: 16 * scale
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * 0.7

                    font.pixelSize: Math.max(12, 18 * scale)
                    color: "#1A1A2E"

                    onActiveFocusChanged: {
                        if (activeFocus) {
                            GlobalState.loginKeyboardRequest = true
                            Qt.inputMethod.show()
                            flick.adjustView(usernameInput)
                        } else {
                            GlobalState.loginKeyboardRequest = false
                            Qt.inputMethod.hide()
                        }
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

                TextInput {
                    id: passwordInput
                    anchors.left: parent.left
                    anchors.leftMargin: 16 * scale
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * 0.7

                    echoMode: TextInput.Password
                    font.pixelSize: Math.max(12, 18 * scale)

                    onActiveFocusChanged: {
                        if (activeFocus) {
                            GlobalState.loginKeyboardRequest = true
                            Qt.inputMethod.show()
                            flick.adjustView(passwordInput)
                        } else {
                            GlobalState.loginKeyboardRequest = false
                            Qt.inputMethod.hide()
                        }
                    }
                }

                // CLICK HANDLER
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        passwordInput.forceActiveFocus()
                    }
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 25 * scale
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Password"
                    color: "#AAAAAA"
                    font.pixelSize: Math.max(14, 18 * scale)
                    font.bold: true

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

                            Qt.inputMethod.hide()

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

                            Qt.inputMethod.hide()
                            createUserPopup.clearRequested()
                        }
                    }
                }
            }
        }
    }
}
