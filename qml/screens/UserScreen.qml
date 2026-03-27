import QtQuick
import QtQuick.Controls
import "../components"


Item {
    id: root
    anchors.fill: parent

    property real baseWidth: 1024
    property real baseHeight: 600

    property real scale: Math.min(width / baseWidth, height / baseHeight)

    //CREATE USER POPUP INSTANCE
    CreateUserPopup {
        id: createUserPopup
        parent: root
        scale: root.scale

        // OPTIONAL: handle signals
        onCreateUserRequested: (type, username, password) => {
            console.log("CREATE USER:", type, username, password)
            close()
        }

        onClearRequested: {
            console.log("Fields cleared")
        }
    }

    //EDIT PASSWORD POPUP INSTANCE
    EditPasswordPopup {
        id: editPasswordPopup

        onUpdatePasswordRequested: function(newPassword) {
            console.log("New Password:", newPassword)

            editPasswordPopup.close()
        }

        onClearRequested: {
            console.log("Clear clicked")
        }
    }

    //DELETE USER POPUP INSTANCE
    DeleteUserPopup {
        id: deleteUserPopup

        onDeleteUserRequested: function(userType, username) {
            console.log("Delete:", userType, username)
        }

        onClearRequested: {
            console.log("Clear pressed")
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#F5F7FC"

        // ── Responsive Button ─────
        component ActionButton: Rectangle {
            id: btnRoot

            property string label: ""
            signal clicked()

            width: Math.max(140, 220 * root.scale)
            height: Math.max(44, 74 * root.scale)
            radius: height * 0.5

            color: btnMouse.containsPress ? "#F5F7FC" : "white"
            border.color: "#1A4DB5"
            border.width: Math.max(2, 3 * root.scale)

            Behavior on color { ColorAnimation { duration: 100 } }

            scale: btnMouse.containsPress ? 0.96 : 1.0
            Behavior on scale {
                NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
            }

            Text {
                anchors.centerIn: parent
                text: btnRoot.label
                font.pixelSize: Math.max(14, 28 * root.scale)
                font.bold: true
                color: "#1A4DB5"
            }

            MouseArea {
                id: btnMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: btnRoot.clicked()
            }
        }

        // ── MAIN CONTENT ─────────
        Column {
            anchors.centerIn: parent
            spacing: Math.max(20, 40 * root.scale)

            // ── ICON CARD ────────
            Rectangle {
                width: Math.max(100, 160 * root.scale)
                height: width
                radius: width * 0.15
                color: "#F5F7FC"
                anchors.horizontalCenter: parent.horizontalCenter

                Image {
                    source: "qrc:/qt/qml/Application/assets/images/userNew.png"
                    width: parent.width * 0.9
                    height: parent.height * 0.9
                    anchors.centerIn: parent
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: true
                }
            }

            // ── TITLE ───────
            Text {
                text: "User"
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: Math.max(18, 28 * root.scale)
                font.bold: true
                font.family: "Roboto"
                color: "#1A1A2E"
            }

            // ── BUTTON ROW ─────
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Math.max(16, 32 * root.scale)

                ActionButton {
                    label: "Add User"
                    onClicked: {
                        createUserPopup.open()
                    }
                }

                ActionButton {
                    label: "Edit PW"
                    onClicked: editPasswordPopup.open()
                }

                ActionButton {
                    label: "Delete User"
                    onClicked: {
                        deleteUserPopup.open()
                    }
                }
            }
        }
    }
}
