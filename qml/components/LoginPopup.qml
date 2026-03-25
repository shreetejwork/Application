import QtQuick
import QtQuick.Controls

Popup {
    id: loginPopup

    property real baseWidth:  1024
    property real baseHeight: 600
    // property real scale: Math.min(
    //     parent ? parent.width  / baseWidth  : 1,
    //     parent ? parent.height / baseHeight : 1
    // )

    signal loginRequested(string userType, string username, string password)
    signal clearRequested()

    anchors.centerIn: Overlay.overlay
    modal:       true
    focus:       true
    closePolicy: Popup.NoAutoClose

    width:  520 * scale
    height: 460 * scale

    background: Rectangle {
        color:        "#EBEBEB"
        radius:       20 * loginPopup.scale
        border.color: "#C8C8C8"
        border.width: 1
    }

    contentItem: Column {
        anchors.fill:    parent
        anchors.margins: 28 * loginPopup.scale
        spacing:         14 * loginPopup.scale

        // ── TITLE ─────────────────────────────────────────────────
        Text {
            text:           "Login"
            font.pixelSize: Math.max(16, 26 * loginPopup.scale)
            font.bold:      true
            color:          "#3D3DB4"
        }

        // ── USER TYPE FIELD ───────────────────────────────────────
        Rectangle {
            id:     userTypeField
            width:  parent.width
            height: 58 * loginPopup.scale
            radius: 10 * loginPopup.scale
            color:  "#F2F2F2"
            border.color: "#3D3DB4"

            Text {
                id: userTypeValue
                anchors { left: parent.left; leftMargin: 18 * loginPopup.scale; verticalCenter: parent.verticalCenter }
                text:           "--- Select ---"
                font.pixelSize: Math.max(12, 18 * loginPopup.scale)
                font.bold:      true
                color:          text === "--- Select ---" ? "#AAAAAA" : "#1A1A2E"
            }

            Text {
                anchors { right: chevron1.left; rightMargin: 8 * loginPopup.scale; verticalCenter: parent.verticalCenter }
                text:           "Usertype"
                font.pixelSize: Math.max(10, 15 * loginPopup.scale)
                color:          "#AAAAAA"
            }

            Text {
                id: chevron1
                anchors { right: parent.right; rightMargin: 14 * loginPopup.scale; verticalCenter: parent.verticalCenter }
                text:           userTypeDropdown.visible ? "▲" : "▼"
                font.pixelSize: Math.max(10, 13 * loginPopup.scale)
                color:          "#888888"
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    usernameDropdown.visible = false
                    userTypeDropdown.visible = !userTypeDropdown.visible
                }
            }
        }

        // UserType dropdown
        Rectangle {
            id:           userTypeDropdown
            width:        parent.width
            height:       3 * 54 * loginPopup.scale
            radius:       10 * loginPopup.scale
            color:        "white"
            border.color: "#3D3DB4"
            border.width: 1
            visible:      false
            z:            10

            Column {
                anchors.fill: parent

                Repeater {
                    model: ["Admin", "Operator", "User"]

                    delegate: Rectangle {
                        width:  userTypeDropdown.width
                        height: 54 * loginPopup.scale
                        color:  dtMouse.containsPress ? "#EEF0FF" : (index % 2 === 0 ? "white" : "#F8F8F8")
                        radius: index === 0 ? 10 * loginPopup.scale
                                            : index === 2 ? 10 * loginPopup.scale : 0

                        Text {
                            anchors { left: parent.left; leftMargin: 18 * loginPopup.scale; verticalCenter: parent.verticalCenter }
                            text:           modelData
                            font.pixelSize: Math.max(12, 18 * loginPopup.scale)
                            font.bold:      true
                            color:          "#1A1A2E"
                        }

                        MouseArea {
                            id: dtMouse
                            anchors.fill: parent
                            onClicked: {
                                userTypeValue.text       = modelData
                                userTypeDropdown.visible = false
                            }
                        }
                    }
                }
            }
        }

        // ── USERNAME FIELD ────────────────────────────────────────
        Rectangle {
            id:     usernameField
            width:  parent.width
            height: 58 * loginPopup.scale
            radius: 10 * loginPopup.scale
            color:  "#F2F2F2"
            border.color: "#3D3DB4"

            Text {
                id: usernameValue
                anchors { left: parent.left; leftMargin: 18 * loginPopup.scale; verticalCenter: parent.verticalCenter }
                text:           "--- Select ---"
                font.pixelSize: Math.max(12, 18 * loginPopup.scale)
                font.bold:      true
                color:          text === "--- Select ---" ? "#AAAAAA" : "#1A1A2E"
            }

            Text {
                anchors { right: chevron2.left; rightMargin: 8 * loginPopup.scale; verticalCenter: parent.verticalCenter }
                text:           "Username"
                font.pixelSize: Math.max(10, 15 * loginPopup.scale)
                color:          "#AAAAAA"
            }

            Text {
                id: chevron2
                anchors { right: parent.right; rightMargin: 14 * loginPopup.scale; verticalCenter: parent.verticalCenter }
                text:           usernameDropdown.visible ? "▲" : "▼"
                font.pixelSize: Math.max(10, 13 * loginPopup.scale)
                color:          "#888888"
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    userTypeDropdown.visible = false
                    usernameDropdown.visible = !usernameDropdown.visible
                }
            }
        }

        // Username dropdown
        Rectangle {
            id:           usernameDropdown
            width:        parent.width
            height:       3 * 54 * loginPopup.scale
            radius:       10 * loginPopup.scale
            color:        "white"
            border.color: "#3D3DB4"
            border.width: 1
            visible:      false
            z:            10

            Column {
                anchors.fill: parent

                Repeater {
                    // Replace with your real user list from backend
                    model: ["John Doe", "Jane Smith", "Bob Johnson"]

                    delegate: Rectangle {
                        width:  usernameDropdown.width
                        height: 54 * loginPopup.scale
                        color:  unMouse.containsPress ? "#EEF0FF" : (index % 2 === 0 ? "white" : "#F8F8F8")
                        radius: index === 0                  ? 10 * loginPopup.scale
                                                             : index === (model.count - 1) ? 10 * loginPopup.scale : 0

                        Text {
                            anchors { left: parent.left; leftMargin: 18 * loginPopup.scale; verticalCenter: parent.verticalCenter }
                            text:           modelData
                            font.pixelSize: Math.max(12, 18 * loginPopup.scale)
                            font.bold:      true
                            color:          "#1A1A2E"
                        }

                        MouseArea {
                            id: unMouse
                            anchors.fill: parent
                            onClicked: {
                                usernameValue.text       = modelData
                                usernameDropdown.visible = false
                            }
                        }
                    }
                }
            }
        }

        // ── PASSWORD FIELD ────────────────────────────────────────
        Rectangle {
            id:     passwordField
            width:  parent.width
            height: 58 * loginPopup.scale
            radius: 10 * loginPopup.scale
            color:  "#F2F2F2"
            border.color: "#3D3DB4"

            TextInput {
                id: passwordInput
                anchors {
                    left:           parent.left
                    leftMargin:     18 * loginPopup.scale
                    verticalCenter: parent.verticalCenter
                }
                width:          parent.width * 0.75
                echoMode:       TextInput.Password
                font.pixelSize: Math.max(12, 18 * loginPopup.scale)
                font.bold:      true
                color:          "#1A1A2E"
                clip:           true

                Text {
                    anchors.fill:      parent
                    text:              "Password"
                    font.pixelSize:    Math.max(12, 18 * loginPopup.scale)
                    color:             "#AAAAAA"
                    visible:           passwordInput.text.length === 0
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Text {
                anchors { right: parent.right; rightMargin: 18 * loginPopup.scale; verticalCenter: parent.verticalCenter }
                text:           "Password"
                font.pixelSize: Math.max(10, 15 * loginPopup.scale)
                color:          "#AAAAAA"
            }

            // Tap on password field closes any open dropdowns
            MouseArea {
                anchors.fill:  parent
                onClicked: {
                    userTypeDropdown.visible = false
                    usernameDropdown.visible = false
                    passwordInput.forceActiveFocus()
                }
            }
        }

        // ── FORGOT PASSWORD ───────────────────────────────────────
        Text {
            anchors.right:  parent.right
            text:           "Forgot Password?"
            font.pixelSize: Math.max(10, 13 * loginPopup.scale)
            color:          "#555555"

            MouseArea {
                anchors.fill: parent
                onClicked:    console.log("Forgot Password tapped")
                // TODO: trigger forgot-password flow
            }
        }

        // ── BUTTONS ───────────────────────────────────────────────
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 20 * loginPopup.scale

            // LOGIN – filled blue
            Rectangle {
                width:  160 * loginPopup.scale
                height: 52  * loginPopup.scale
                radius: 10  * loginPopup.scale
                color:  loginMouse.containsPress ? "#2A2A9A" : "#3D3DB4"
                Behavior on color { ColorAnimation { duration: 100 } }

                Text {
                    anchors.centerIn: parent
                    text:           "Login"
                    font.pixelSize: Math.max(12, 18 * loginPopup.scale)
                    font.bold:      true
                    color:          "white"
                }

                MouseArea {
                    id: loginMouse
                    anchors.fill: parent
                    onClicked: {
                        userTypeDropdown.visible = false
                        usernameDropdown.visible = false
                        loginPopup.loginRequested(
                                    userTypeValue.text,
                                    usernameValue.text,
                                    passwordInput.text
                                    )
                    }
                }
            }

            // CLEAR – outlined blue
            Rectangle {
                width:  160 * loginPopup.scale
                height: 52  * loginPopup.scale
                radius: 10  * loginPopup.scale
                color:  clearMouse.containsPress ? "#EEF0FF" : "white"
                border.color: "#3D3DB4"
                border.width: 2
                Behavior on color { ColorAnimation { duration: 100 } }

                Text {
                    anchors.centerIn: parent
                    text:           "Clear"
                    font.pixelSize: Math.max(12, 18 * loginPopup.scale)
                    font.bold:      true
                    color:          "#3D3DB4"
                }

                MouseArea {
                    id: clearMouse
                    anchors.fill: parent
                    onClicked: {
                        userTypeValue.text       = "--- Select ---"
                        usernameValue.text       = "--- Select ---"
                        passwordInput.text       = ""
                        userTypeDropdown.visible = false
                        usernameDropdown.visible = false
                        loginPopup.clearRequested()
                    }
                }
            }
        }
    }
}
