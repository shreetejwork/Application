import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import AppState 1.0

Popup {
    id: editPasswordPopup

    property real baseWidth: 1024
    property real baseHeight: 600



    signal updatePasswordRequested(string userType, string username, string newPassword)
    signal clearRequested()

    modal: true
    focus: true
    closePolicy: Popup.CloseOnPressOutside

    width: 520 * scale
    height: 460 * scale

    x: (Overlay.overlay.width - width) / 2

    property real baseY: (Overlay.overlay.height - height) / 2 - (40 * scale)

                                  ? (keyboardHeight / 2 + 40 * scale)
                                  : 0

    y: baseY - keyboardOffset

    onOpened: {
        userTypeValue.text = "--- Select ---"
        usernameValue.text = "--- Select ---"
        newPasswordInput.text = ""
        confirmPasswordInput.text = ""


        if (selectionPopup.visible)
            selectionPopup.close()
    }

    onClosed: {
        newPasswordInput.focus = false
        confirmPasswordInput.focus = false
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
        anchors.margins: 28 * scale

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
                text: "Edit Password"
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
                    font.pixelSize: Math.max(14, 18 * scale)
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent

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
                    font.pixelSize: Math.max(14, 18 * scale)
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent

                    onClicked: {
                        selectionPopup.title = "Select Username"
                        selectionPopup.modelData = ["John Doe","Jane Smith","Bob Johnson"]
                        selectionPopup.onSelectCallback = function(val) {
                            usernameValue.text = val
                        }
                        selectionPopup.open()
                    }
                }
            }

            // NEW PASSWORD
            Rectangle {
                Layout.fillWidth: true
                height: 58 * scale
                radius: 10 * scale
                color: "#F2F2F2"
                border.color: "#1A4DB5"

                TextField {
                    id: newPasswordInput

                    anchors.left: parent.left
                    anchors.right: toggle.left
                    anchors.leftMargin: 18 * scale
                    anchors.rightMargin: 8 * scale
                    anchors.verticalCenter: parent.verticalCenter

                    property bool isPasswordField: true

                    echoMode: TextInput.Password
                    font.pixelSize: Math.max(25, 21 * scale)
                    font.bold: true
                    color: "#000000"

                    inputMethodHints: Qt.ImhNone

                    background: null
                    padding: 0

                    activeFocusOnPress: true

                    onActiveFocusChanged: {
                        if (activeFocus) {
                            GlobalState.activeInputField = newPasswordInput
                            GlobalState.loginKeyboardRequest = true

                            if (flick)
                                flick.adjustView(newPasswordInput)
                        } else {
                            GlobalState.loginKeyboardRequest = false
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onPressed: newPasswordInput.forceActiveFocus()
                    }

                    onAccepted: {
                        GlobalState.loginKeyboardRequest = false
                        focus = false
                    }
                }

                // PLACEHOLDER
                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 18 * scale
                    anchors.verticalCenter: parent.verticalCenter

                    text: "New Password"
                    color: "#AAAAAA"
                    font.pixelSize: Math.max(14, 18 * scale)
                    font.bold: true

                    visible: newPasswordInput.text.length === 0
                }

                //  SHOW / HIDE
                Rectangle {
                    id: toggle

                    anchors.right: parent.right
                    anchors.rightMargin: 12 * scale
                    anchors.verticalCenter: parent.verticalCenter

                    width: 50 * scale
                    height: 32 * scale
                    color: "transparent"

                    visible: newPasswordInput.text.length > 0

                    Text {
                        anchors.centerIn: parent
                        text: newPasswordInput.echoMode === TextInput.Password ? "Show" : "Hide"
                        font.pixelSize: 16 * scale
                        color: "#1A4DB5"
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            newPasswordInput.echoMode =
                                    newPasswordInput.echoMode === TextInput.Password
                                    ? TextInput.Normal
                                    : TextInput.Password
                        }
                    }
                }

                // CLICK HANDLER
                MouseArea {
                    anchors.fill: parent
                    onClicked: newPasswordInput.forceActiveFocus()
                }
            }

            // CONFIRM PASSWORD
            Rectangle {
                Layout.fillWidth: true
                height: 58 * scale
                radius: 10 * scale
                color: "#F2F2F2"
                border.color: "#1A4DB5"

                TextField {
                    id: confirmPasswordInput

                    anchors.left: parent.left
                    anchors.right: toggle.left
                    anchors.leftMargin: 18 * scale
                    anchors.rightMargin: 8 * scale
                    anchors.verticalCenter: parent.verticalCenter

                    property bool isPasswordField: true

                    echoMode: TextInput.Password

                    font.pixelSize: Math.max(25, 21 * scale)
                    font.bold: true
                    color: "#000000"

                    inputMethodHints: Qt.ImhNone

                    background: null
                    padding: 0

                    activeFocusOnPress: true

                    onActiveFocusChanged: {
                        if (activeFocus) {
                            GlobalState.activeInputField = confirmPasswordInput
                            GlobalState.loginKeyboardRequest = true

                            if (flick)
                                flick.adjustView(confirmPasswordInput)
                        } else {
                            GlobalState.loginKeyboardRequest = false
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onPressed: confirmPasswordInput.forceActiveFocus()
                    }

                    onAccepted: {
                        GlobalState.loginKeyboardRequest = false
                        focus = false
                    }
                }

                //  PLACEHOLDER
                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 18 * scale
                    anchors.verticalCenter: parent.verticalCenter

                    text: "Confirm"
                    color: "#AAAAAA"
                    font.pixelSize: Math.max(14, 18 * scale)
                    font.bold: true

                    visible: confirmPasswordInput.text.length === 0
                }

                //  SHOW / HIDE
                Rectangle {
                    id: toggle2

                    anchors.right: parent.right
                    anchors.rightMargin: 12 * scale
                    anchors.verticalCenter: parent.verticalCenter

                    width: 50 * scale
                    height: 32 * scale
                    color: "transparent"

                    visible: confirmPasswordInput.text.length > 0

                    Text {
                        anchors.centerIn: parent
                        text: confirmPasswordInput.echoMode === TextInput.Password ? "Show" : "Hide"
                        font.pixelSize: 16 * scale
                        color: "#1A4DB5"
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            confirmPasswordInput.echoMode =
                                    confirmPasswordInput.echoMode === TextInput.Password
                                    ? TextInput.Normal
                                    : TextInput.Password
                        }
                    }
                }

                // CLICK HANDLER
                MouseArea {
                    anchors.fill: parent
                    onClicked: confirmPasswordInput.forceActiveFocus()
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
                        text: "Update"
                        color: "white"
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent

                        onClicked: {
                            if (userTypeValue.text === "--- Select ---" ||
                                usernameValue.text === "--- Select ---" ||
                                newPasswordInput.text === "" ||
                                confirmPasswordInput.text === "")
                                return

                            if (newPasswordInput.text !== confirmPasswordInput.text)
                                return


                            editPasswordPopup.updatePasswordRequested(
                                userTypeValue.text,
                                usernameValue.text,
                                newPasswordInput.text
                            )
                            editPasswordPopup.close()
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

                        onClicked: {
                            userTypeValue.text = "--- Select ---"
                            usernameValue.text = "--- Select ---"
                            newPasswordInput.text = ""
                            confirmPasswordInput.text = ""

                            editPasswordPopup.clearRequested()
                        }
                    }
                }
            }
        }
    }
}
