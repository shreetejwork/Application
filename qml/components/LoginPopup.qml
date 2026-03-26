import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.VirtualKeyboard   // ✅ IMPORTANT

Popup {
    id: loginPopup

    property real baseWidth: 1024
    property real baseHeight: 600

    signal loginRequested(string userType, string username, string password)
    signal clearRequested()

    anchors.centerIn: Overlay.overlay
    modal: true
    focus: true
    closePolicy: Popup.CloseOnPressOutside | Popup.CloseOnEscape

    width: 520 * scale
    height: 460 * scale

    // RESET FORM
    onOpened: {
        userTypeValue.text = "--- Select ---"
        usernameValue.text = "--- Select ---"
        passwordInput.text = ""
        passwordInput.focus = false
    }

    background: Rectangle {
        color: "#EBEBEB"
        radius: 20 * scale
        border.color: "#C8C8C8"
        border.width: 1
    }

    // =======================
    // MAIN CONTENT
    // =======================
    contentItem: ColumnLayout {
        anchors.fill: parent
        anchors.margins: 28 * scale
        spacing: 14 * scale

        Text {
            text: "Login"
            font.pixelSize: Math.max(16, 26 * scale)
            font.bold: true
            color: "#1A4DB5"
            Layout.alignment: Qt.AlignLeft
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
                color: text === "--- Select ---" ? "#AAAAAA" : "#1A1A2E"
            }

            MouseArea {
                anchors.fill: parent
                onClicked: passwordInput.focus = false
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
                color: text === "--- Select ---" ? "#AAAAAA" : "#1A1A2E"
            }

            MouseArea {
                anchors.fill: parent
                onClicked: passwordInput.focus = false
            }
        }

        // PASSWORD
        Rectangle {
            Layout.fillWidth: true
            height: 58 * scale
            radius: 10 * scale
            color: "#F2F2F2"
            border.color: "#1A4DB5"

            // Click area (placed BELOW input, not blocking typing)
            MouseArea {
                anchors.fill: parent
                z: 0
                onClicked: passwordInput.forceActiveFocus()
            }

            TextInput {
                id: passwordInput
                anchors.left: parent.left
                anchors.leftMargin: 18 * scale
                anchors.right: parent.right
                anchors.rightMargin: 100 * scale   // leave space for label
                anchors.verticalCenter: parent.verticalCenter

                z: 1   // ABOVE MouseArea

                echoMode: TextInput.Password
                font.pixelSize: Math.max(12, 18 * scale)
                font.bold: true
                color: "#1A1A2E"

                focus: false
                activeFocusOnPress: true
                selectByMouse: true

                // ✅ Keyboard config
                inputMethodHints: Qt.ImhPreferLatin
                                  | Qt.ImhNoPredictiveText
                                  | Qt.ImhSensitiveData

                onActiveFocusChanged: {
                    if (activeFocus)
                        Qt.inputMethod.show()
                    else
                        Qt.inputMethod.hide()
                }
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: 18 * scale
                anchors.verticalCenter: parent.verticalCenter
                text: "Password"
                color: "#AAAAAA"
                font.pixelSize: Math.max(10, 15 * scale)
            }
        }

        // SPACE
        Item { Layout.fillHeight: true }

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
                    onClicked: {
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
                    onClicked: {
                        userTypeValue.text = "--- Select ---"
                        usernameValue.text = "--- Select ---"
                        passwordInput.text = ""
                        Qt.inputMethod.hide()
                        loginPopup.clearRequested()
                    }
                }
            }
        }
    }
}
