import QtQuick
import QtQuick.Controls
import QtQuick.VirtualKeyboard
import AppState 1.0

Item {
    id: root
    anchors.fill: parent

    property real baseWidth: 1024
    property real baseHeight: 600
    property real scale: Math.max(0.85, Math.min(width / baseWidth, height / baseHeight))

    property var globalTopBar
    property var notify

    Rectangle {
        anchors.fill: parent
        color: "#F5F7FC"
    }

    // ===== TITLE =====
    Text {
        id: titleText
        text: "Machine ID Settings"
        font.pixelSize: 26 * root.scale
        font.bold: true
        color: "#1A4DB5"
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: 25 * root.scale
        anchors.topMargin: 20 * root.scale
    }

    Rectangle {
        width: 80 * root.scale
        height: 4 * root.scale
        radius: 2 * root.scale
        color: "#1A4DB5"
        anchors.left: titleText.left
        anchors.top: titleText.bottom
        anchors.topMargin: 6 * root.scale
    }

    // ===== FIELDS ROW =====
    Row {
        id: mainRow

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter

        //  USE ACTUAL KEYBOARD HEIGHT
        anchors.verticalCenterOffset: -(keyboard.visible ? keyboard.height / 2 : 0)

        spacing: 28 * root.scale

        Behavior on anchors.verticalCenterOffset {
            NumberAnimation { duration: 250; easing.type: Easing.OutQuad }
        }

        SettingsCard {
            fieldLabel: "MACHINE ID"
            placeholderText: "Enter machine ID"
            initialValue: GlobalState.machineId ?? "PHMX"
            onConfirmed: (val) => {
                             GlobalState.machineId = val

                             if (root.notify)
                             root.notify("✓ Machine ID Saved")
                         }
        }

        SettingsCard {
            fieldLabel: "USER"
            placeholderText: "Enter user"
            initialValue: GlobalState.userName ?? ""
            onConfirmed: (val) => {
                             GlobalState.userName = val

                             if (root.notify)
                             root.notify("✓ Username Saved")
                         }
        }

        SettingsCard {
            fieldLabel: "LOCATION"
            placeholderText: "Enter location"
            initialValue: GlobalState.location ?? ""
            onConfirmed: (val) => {
                             GlobalState.location = val

                             if (root.notify)
                             root.notify("✓ Location Saved")
                         }
        }
    }

    // ===== CARD COMPONENT =====
    component SettingsCard: Rectangle {
        id: card

        property string fieldLabel: ""
        property string placeholderText: ""
        property string initialValue: ""

        signal confirmed(string value)

        width: 360 * root.scale
        height: 130 * root.scale
        radius: 12 * root.scale
        color: "#FFFFFF"
        border.color: cardInput.activeFocus ? "#1A4DB5" : "#C5D0E8"
        border.width: cardInput.activeFocus ? 2 : 1.5

        Column {
            anchors.fill: parent
            anchors.margins: 14 * root.scale

            Text {
                text: card.fieldLabel
                font.pixelSize: 15 * root.scale
                font.bold: true
                color: "#1A4DB5"
            }

            Row {
                width: parent.width
                height: 36 * root.scale
                spacing: 8 * root.scale

                Item {
                    width: parent.width - confirmBtn.width - 8 * root.scale
                    height: parent.height

                    TextField {
                        id: cardInput
                        anchors.fill: parent

                        text: card.initialValue
                        font.pixelSize: 22 * root.scale
                        font.bold: true
                        color: "#1A4DB5"

                        verticalAlignment: Text.AlignVCenter

                        inputMethodHints: Qt.ImhNone

                        background: null
                        padding: 0
                        leftPadding: 0
                        rightPadding: 0
                        topPadding: 0
                        bottomPadding: 0

                        // AUTO OPEN KEYBOARD
                        onActiveFocusChanged: {
                            if (activeFocus) {
                                GlobalState.loginKeyboardRequest = true
                                Qt.inputMethod.show()
                            }
                        }

                        onAccepted: {
                            card.confirmed(text.trim())
                            Qt.inputMethod.hide()
                            focus = false
                        }

                        property bool showPlaceholder: text.length === 0 && !activeFocus

                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            text: card.placeholderText
                            font.pixelSize: 22 * root.scale
                            color: "#A0AABF"
                            visible: cardInput.showPlaceholder
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            cardInput.forceActiveFocus()
                            GlobalState.loginKeyboardRequest = true
                            Qt.inputMethod.show()
                        }
                    }
                }

                Rectangle {
                    id: confirmBtn
                    width: 32 * root.scale
                    height: 32 * root.scale
                    radius: width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    color: "#1A4DB5"

                    Text {
                        anchors.centerIn: parent
                        text: "✓"
                        color: "white"
                        font.pixelSize: 18 * root.scale
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            card.confirmed(cardInput.text.trim())
                            Qt.inputMethod.hide()
                            cardInput.focus = false
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1.5 * root.scale
                color: cardInput.activeFocus ? "#1A4DB5" : "#E3E7F0"
            }
        }
    }
}
