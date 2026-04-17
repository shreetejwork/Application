import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: popupRoot
    anchors.fill: parent
    visible: true
    z: 999

    property var globalTopBar: null

    // ===== MAIN POPUP =====
    Rectangle {
        id: popup
        visible: false
        z: 101
        width: Math.min(parent.width * 0.35, 420)
        height: Math.min(parent.height * 0.70, 650)
        radius: 16
        color: "#FFFFFF"
        anchors.centerIn: parent

        Rectangle {
            anchors.fill: popup
            anchors.margins: -4
            radius: popup.radius
            color: "transparent"
            border.color: "#10000000"
            border.width: 1
            z: 0
        }

        property string fieldName: ""
        property var onSaveCallback
        property int minValue: 0
        property int maxValue: 100
        property string errorText: ""
        property bool hasError: false

        function open(title, value, callback, minVal = 0, maxVal = 100) {
            fieldName = title

            inputField.text = ""

            onSaveCallback = callback
            minValue = minVal
            maxValue = maxVal
            errorText = ""
            hasError = false
            visible = true

            inputField.forceActiveFocus()
            inputField.cursorPosition = inputField.text.length
        }

        scale: visible ? 1 : 0.95
        opacity: visible ? 1 : 0

        Behavior on scale { NumberAnimation { duration: 150 } }
        Behavior on opacity { NumberAnimation { duration: 150 } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 12

            // ===== TITLE =====
            Text {
                text: popup.fieldName
                font.pixelSize: 22
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                color: "#1A4DB5"
                Layout.fillWidth: true
            }

            // ===== INPUT =====
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                radius: 12
                border.color: popup.hasError ? "#FF5252" : "#D0D0D0"
                border.width: popup.hasError ? 2 : 1
                color: "#F8F9FB"

                Behavior on border.color { ColorAnimation { duration: 150 } }

                TextInput {
                    id: inputField
                    anchors.fill: parent
                    anchors.margins: 12
                    font.pixelSize: 28
                    font.bold: true
                    color: "#333"
                    horizontalAlignment: TextInput.AlignHCenter
                    verticalAlignment: TextInput.AlignVCenter

                    readOnly: true
                    focus: true
                    inputMethodHints: Qt.ImhNoPredictiveText

                    onTextChanged: {
                        if (popup.hasError) {
                            popup.errorText = ""
                            popup.hasError = false
                        }
                    }
                }
            }

            // ===== MIN MAX =====
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 35
                radius: 8
                color: "#E8EEFB"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10

                    Text {
                        text: "Min: " + popup.minValue
                        color: "#1A4DB5"
                        font.pixelSize: 13
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    Rectangle { width: 1; height: parent.height * 0.6; color: "#D0D0D0" }

                    Text {
                        text: "Max: " + popup.maxValue
                        color: "#1A4DB5"
                        font.pixelSize: 13
                        font.bold: true
                        Layout.fillWidth: true
                    }
                }
            }

            // ===== ERROR =====
            Text {
                text: popup.errorText
                color: "#FF5252"
                font.pixelSize: 13
                font.bold: true
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                visible: popup.hasError
                Layout.preferredHeight: visible ? 20 : 0
            }

            // ===== KEYPAD =====
            GridLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 160
                columns: 3
                rowSpacing: 6
                columnSpacing: 6

                Repeater {
                    model: ["1","2","3","4","5","6","7","8","9",".","0","⌫"]

                    delegate: Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 10
                        color: mouseArea.pressed ? "#CCCCCC" : "#F0F0F0"
                        border.color: "#E0E0E0"
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            font.pixelSize: 14
                            font.bold: true
                            color: "#333"
                        }

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent

                            onClicked: {
                                if (modelData === "⌫") {
                                    inputField.text = inputField.text.slice(0, -1)
                                } else {
                                    inputField.text += modelData
                                }
                            }
                        }
                    }
                }
            }

            // ===== BUTTONS =====
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                spacing: 10

                // CANCEL
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 10
                    color: cancelMouseArea.pressed ? "#CCCCCC" : "#E8E8E8"

                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        font.bold: true
                    }

                    MouseArea {
                        id: cancelMouseArea
                        anchors.fill: parent
                        onClicked: popup.visible = false
                    }
                }

                // SAVE
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 10
                    color: saveMouseArea.pressed ? "#0D3BA8" : "#1A4DB5"

                    Text {
                        anchors.centerIn: parent
                        text: "Save"
                        color: "white"
                        font.bold: true
                    }

                    MouseArea {
                        id: saveMouseArea
                        anchors.fill: parent

                        onClicked: {
                            var inputText = inputField.text.trim()

                            if (inputText === "") {
                                popup.errorText = "Please enter a value"
                                popup.hasError = true
                                return
                            }

                            var val = parseFloat(inputText)

                            if (isNaN(val)) {
                                popup.errorText = "Enter valid number"
                                popup.hasError = true
                                return
                            }

                            if (val < popup.minValue) {
                                popup.errorText = "Too low! Min: " + popup.minValue
                                popup.hasError = true
                                return
                            }

                            if (val > popup.maxValue) {
                                popup.errorText = "Too high! Max: " + popup.maxValue
                                popup.hasError = true
                                return
                            }

                            // ===== UPDATE VALUE =====
                            if (popup.onSaveCallback) {
                                popup.onSaveCallback(val)
                            }

                            // ===== NOTIFICATION =====
                            if (popupRoot.globalTopBar && popupRoot.globalTopBar.showNotification) {
                                popupRoot.globalTopBar.showNotification(
                                    "✓ " + popup.fieldName + " updated to " + val
                                )
                            } else {
                                console.log("Notification:", popup.fieldName, val)
                            }

                            popup.visible = false
                            popup.errorText = ""
                            popup.hasError = false
                        }
                    }
                }
            }
        }
    }

    // ===== OVERLAY =====
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        visible: popup.visible
        opacity: popup.visible ? 0.4 : 0
        z: 100

        Behavior on opacity { NumberAnimation { duration: 200 } }

        MouseArea {
            anchors.fill: parent
            enabled: popup.visible
            onClicked: popup.visible = false
        }
    }

    function open(title, value, callback, minVal = 0, maxVal = 100) {
        popup.open(title, value, callback, minVal, maxVal)
    }
}
