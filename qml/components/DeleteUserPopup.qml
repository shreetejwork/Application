import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import AppState 1.0

Popup {

    Typography {
        id: deleteUserTypography
        scale: 1.0
    }
    id: deleteUserPopup

    // =====================================================
    // ANIMATION
    // =====================================================

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

    transformOrigin: Item.Center

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
    dim: true

    Overlay.modal: Rectangle {
        color: "#66000000"
    }

    closePolicy: Popup.CloseOnPressOutside

    width: 520 * scale
    height: 380 * scale

    x: (Overlay.overlay.width - width) / 2
    y: (Overlay.overlay.height - height) / 2 - (60 * scale)

    // =====================================================
    // NO Behavior on y HERE — it was the problem
    // =====================================================

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

        anchors.topMargin: 2 * scale
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

                deleteUserPopup.close()
            }
        }
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

        transformOrigin: Item.Center

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

                    font.pixelSize: 19
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
                                font.pixelSize: 18

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

            Row {
                spacing: 10 * scale
                Layout.fillWidth: true

                Text {
                    text: "Delete User"
                    font.pixelSize: deleteUserTypography.title

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
                    font.pixelSize: deleteUserTypography.body

                    color: text === "--- Select ---" ? "#AAAAAA" : "#1A1A2E"
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 18 * scale
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Usertype"
                    color: "#AAAAAA"
                    font.pixelSize: deleteUserTypography.body

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
                    font.pixelSize: deleteUserTypography.body

                    color: text === "--- Select ---" ? "#AAAAAA" : "#1A1A2E"
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 18 * scale
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Username"
                    color: "#AAAAAA"
                    font.pixelSize: deleteUserTypography.body

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

                Rectangle {
                    width: 160 * scale
                    height: 52 * scale
                    radius: 10 * scale
                    color: "#1A4DB5"

                    Text {
                        anchors.centerIn: parent
                        text: "Delete User"
                        color: "white"

                        font.pixelSize: 15
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

                        font.pixelSize: 15
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
