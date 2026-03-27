import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import AppState 1.0

Popup {
    id: deleteUserPopup

    property real baseWidth: 1024
    property real baseHeight: 600

    property bool isLongPress: false
    property int longPressCount: 0

    property bool devModeActive: false
    property bool fieldsLocked: false

    signal deleteUserRequested(string userType, string username)
    signal clearRequested()

    modal: true
    focus: true
    closePolicy: Popup.CloseOnPressOutside

    width: 520 * scale
    height: 380 * scale

    x: (Overlay.overlay.width - width) / 2
    y: (Overlay.overlay.height - height) / 2 - (60 * scale)

    Behavior on y {
        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
    }

    onOpened: {
        userTypeValue.text = "--- Select ---"
        usernameValue.text = "--- Select ---"

        deleteUserPopup.devModeActive = false
        deleteUserPopup.fieldsLocked = false
        deleteUserPopup.longPressCount = 0

        deleteUserPopup.focus = true

        if (selectionPopup.visible)
            selectionPopup.close()
    }

    onClosed: {
        deleteUserPopup.devModeActive = false
        deleteUserPopup.fieldsLocked = false
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
                                enabled: !deleteUserPopup.fieldsLocked

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
    contentItem: Item {
        anchors.fill: parent
        anchors.margins: 28 * scale

        ColumnLayout {
            id: columnContent
            anchors.fill: parent
            spacing: 14 * scale

            // Title row with warning icon
            Row {
                spacing: 10 * scale
                Layout.fillWidth: true

                Text {
                    text: "Delete User"
                    font.pixelSize: Math.max(16, 26 * scale)
                    font.bold: true
                    color: "#1A4DB5"
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // USER TYPE
            Rectangle {
                Layout.fillWidth: true
                height: 58 * scale
                radius: 10 * scale
                color: "#F2F2F2"
                border.color: "#1A4DB5"
                border.width: 1

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
                    enabled: !deleteUserPopup.fieldsLocked

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

            // USERNAME
            Rectangle {
                Layout.fillWidth: true
                height: 58 * scale
                radius: 10 * scale
                color: "#F2F2F2"
                border.color: "#1A4DB5"
                border.width: 1

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
                    enabled: !deleteUserPopup.fieldsLocked

                    onClicked: {
                        selectionPopup.title = "Select Username"
                        selectionPopup.modelData = ["John Doe", "Jane Smith", "Bob Johnson"]
                        selectionPopup.onSelectCallback = function(val) {
                            usernameValue.text = val
                        }
                        selectionPopup.open()
                    }
                }
            }

            // ================= BUTTONS =================
            Row {
                Layout.alignment: Qt.AlignHCenter
                spacing: 20 * scale

                // DELETE USER button
                Rectangle {
                    width: 160 * scale
                    height: 52 * scale
                    radius: 10 * scale
                    color: "#1A4DB5"

                    Text {
                        anchors.centerIn: parent
                        text: "Delete User"
                        color: "white"
                        font.bold: true
                        font.pixelSize: Math.max(10, 15 * scale)
                    }

                    MouseArea {
                        anchors.fill: parent

                        onClicked: {
                            if (userTypeValue.text === "--- Select ---" ||
                                usernameValue.text === "--- Select ---")
                                return

                            deleteUserPopup.deleteUserRequested(
                                userTypeValue.text,
                                usernameValue.text
                            )
                            deleteUserPopup.close()
                        }
                    }
                }

                // CLEAR button
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
                        font.pixelSize: Math.max(10, 15 * scale)
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !deleteUserPopup.fieldsLocked

                        onClicked: {
                            userTypeValue.text = "--- Select ---"
                            usernameValue.text = "--- Select ---"

                            deleteUserPopup.devModeActive = false
                            deleteUserPopup.fieldsLocked = false

                            deleteUserPopup.clearRequested()
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }
        }
    }
}
