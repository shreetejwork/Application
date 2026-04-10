import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import AppState 1.0

Popup {
    id: editPasswordPopup

    property real baseWidth: 1024
    property real baseHeight: 600

    property real keyboardHeight: Qt.inputMethod.visible
                                  ? Qt.inputMethod.keyboardRectangle.height
                                  : 0

    signal updatePasswordRequested(string userType, string username, string newPassword)
    signal clearRequested()

    modal: true
    focus: true
    closePolicy: Popup.CloseOnPressOutside

    width: 520 * scale
    height: 460 * scale

    x: (Overlay.overlay.width - width) / 2

    y: {
        if (!Qt.inputMethod.visible)
            return (Overlay.overlay.height - height) / 2 - (40 * scale)

        //  STRONG push above keyboard
        return Math.max(
            5 * scale,   // top safety margin
            Overlay.overlay.height
            - height
            - keyboardHeight
            - (500 * scale)
        )
    }

    onOpened: {
        userTypeValue.text = "--- Select ---"
        usernameValue.text = "--- Select ---"
        newPasswordInput.text = ""
        confirmPasswordInput.text = ""

        Qt.inputMethod.hide()

        if (selectionPopup.visible)
            selectionPopup.close()
    }

    onClosed: {
        Qt.inputMethod.hide()
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

                TextInput {
                    id: newPasswordInput
                    anchors.left: parent.left
                    anchors.leftMargin: 18 * scale
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * 0.7

                    echoMode: TextInput.Password
                    font.pixelSize: Math.max(15, 21 * scale)
                    font.bold: true

                    onActiveFocusChanged: {
                        if (activeFocus) {
                            Qt.inputMethod.show()
                            flick.adjustView(newPasswordInput)
                            GlobalState.loginKeyboardRequest = true
                        }else {
                            GlobalState.loginKeyboardRequest = false
                            Qt.inputMethod.hide()
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: newPasswordInput.forceActiveFocus()
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 18 * scale
                    anchors.verticalCenter: parent.verticalCenter
                    text: "New Password"
                    color: "#AAAAAA"
                    font.pixelSize: Math.max(14, 18 * scale)
                    font.bold: true
                }
            }

            // CONFIRM PASSWORD
            Rectangle {
                Layout.fillWidth: true
                height: 58 * scale
                radius: 10 * scale
                color: "#F2F2F2"
                border.color: "#1A4DB5"

                TextInput {
                    id: confirmPasswordInput
                    anchors.left: parent.left
                    anchors.leftMargin: 18 * scale
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * 0.7

                    echoMode: TextInput.Password

                    font.pixelSize: Math.max(15, 21 * scale)
                    font.bold: true

                    onActiveFocusChanged: {
                        if (activeFocus) {
                            Qt.inputMethod.show()
                            flick.adjustView(confirmPasswordInput)
                            GlobalState.loginKeyboardRequest = true
                        }else {
                            GlobalState.loginKeyboardRequest = false
                            Qt.inputMethod.hide()
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: confirmPasswordInput.forceActiveFocus()
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 18 * scale
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Confirm"
                    color: "#AAAAAA"
                    font.pixelSize: Math.max(14, 18 * scale)
                    font.bold: true
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

                            Qt.inputMethod.hide()

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

                            Qt.inputMethod.hide()
                            editPasswordPopup.clearRequested()
                        }
                    }
                }
            }
        }
    }
}
