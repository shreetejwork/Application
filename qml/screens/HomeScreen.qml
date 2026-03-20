import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../components"

Item {
    id: homeScreen
    property bool showTopBar: true
    property var globalTopBar: null

    Rectangle {
        anchors.fill: parent
        color: "#F5F7FC"

        TopBar {
            id: topBar
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: showTopBar ? Math.max(70, parent.height * 0.08) : 0
            visible: showTopBar

            userName: "Rahul1234567789"
            userRole: "Supervisor"
        }

        // ================= POPUP =================
        Rectangle {
            id: popup
            visible: false
            z: 101
            width: Math.min(parent.width * 0.35, 420)
            height: Math.min(parent.height * 0.85, 650)
            radius: 16
            color: "#FFFFFF"
            anchors.centerIn: parent
            
            // Simple shadow effect using opacity layers
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
                inputField.selectAll()
            }

            scale: visible ? 1 : 0.95
            opacity: visible ? 1 : 0

            Behavior on scale { NumberAnimation { duration: 150 } }
            Behavior on opacity { NumberAnimation { duration: 150 } }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 12

                // Title
                Text {
                    text: popup.fieldName
                    font.pixelSize: 22
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    color: "#1A4DB5"
                    Layout.fillWidth: true
                }

                // Input Field
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
                        inputMethodHints: Qt.ImhDigitsOnly
                        
                        onTextChanged: {
                            if (popup.hasError) {
                                popup.errorText = ""
                                popup.hasError = false
                            }
                        }
                    }
                }

                // Min/Max Display
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 35
                    radius: 8
                    color: "#E8EEFB"
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 15
                        
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

                // Error Text
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

                // KEYPAD
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
                            color: mouseArea.pressed ? (modelData === "C" ? "#FF9999" : modelData === "⌫" ? "#FFCC99" : "#CCCCCC")
                                                     : (modelData === "C" ? "#FFCDD2" : modelData === "⌫" ? "#FFE0B2" : "#F0F0F0")
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
                                    if (modelData === "C") {
                                        inputField.text = ""
                                        popup.errorText = ""
                                        popup.hasError = false
                                    } else if (modelData === "⌫") {
                                        if (inputField.text.length > 0) {
                                            inputField.text = inputField.text.slice(0, -1)
                                        }
                                    } else {
                                        inputField.text += modelData
                                    }
                                }
                            }
                        }
                    }
                }

                // BUTTONS
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    Layout.topMargin: 5
                    spacing: 10

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 10
                        color: cancelMouseArea.pressed ? "#CCCCCC" : "#E8E8E8"
                        border.color: "#D0D0D0"
                        border.width: 1
                        
                        Behavior on color { ColorAnimation { duration: 100 } }

                        Text {
                            anchors.centerIn: parent
                            text: "Cancel"
                            font.bold: true
                            font.pixelSize: 14
                            color: "#333"
                        }

                        MouseArea {
                            id: cancelMouseArea
                            anchors.fill: parent
                            onClicked: {
                                popup.visible = false
                                popup.errorText = ""
                                popup.hasError = false
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 10
                        color: saveMouseArea.pressed ? "#0D3BA8" : "#1A4DB5"
                        
                        Behavior on color { ColorAnimation { duration: 100 } }

                        Text {
                            anchors.centerIn: parent
                            text: "Save"
                            color: "white"
                            font.bold: true
                            font.pixelSize: 14
                        }

                        MouseArea {
                            id: saveMouseArea
                            anchors.fill: parent
                            
                            onClicked: {
                                var inputText = inputField.text.trim()

                                // Validation
                                if (inputText === "") {
                                    popup.errorText = "Please enter a value"
                                    popup.hasError = true
                                    return
                                }

                                var val = parseInt(inputText)

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

                                // Save successful - call callback to update value
                                if (popup.onSaveCallback) {
                                    popup.onSaveCallback(val)
                                }
                                
                                // Show notifications via global top bar if available
                                if (globalTopBar) {
                                    globalTopBar.showNotification("✓ " + popup.fieldName + " updated to " + val)
                                } else {
                                    topBar.showNotification("✓ " + popup.fieldName + " updated to " + val)
                                }
                                
                                // Close popup
                                popup.visible = false
                                
                                // Reset error state
                                popup.errorText = ""
                                popup.hasError = false
                            }
                        }
                    }
                }
            }
        }

        // ================= OVERLAY =================
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


        // ================= CONTENT =================
        Item {
            anchors.top: topBar.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Math.max(12, parent.width * 0.01)

            // LEFT
            Item {
                id: leftCol
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width * 0.30

                AnalogGauge {
                    id: analogGauge
                    anchors.fill: parent

                    onMachinePhaseClicked: popup.open(
                                               "Machine Phase",
                                               analogGauge.machinePhase,
                                               function(val){ analogGauge.machinePhase = val },
                                               0, 180
                                               )
                }
            }

            // CENTER
            Item {
                id: centerCol
                anchors.left: leftCol.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.leftMargin: parent.width * 0.02
                width: parent.width * 0.36

                CircularGauge {
                    id: signalGauge
                    anchors.centerIn: parent
                    width: parent.width * 0.85
                    height: width

                    // Signal Gauge Configuration
                    value: 850
                    label: "Signal"
                    threshold: 500
                    thresholdLabel: "Thr-S"
                    maxValue: 1200

                    onThresholdClicked: popup.open(
                                            "Thr-S",
                                            signalGauge.threshold,
                                            function(val){ signalGauge.threshold = val },
                                            100, 1500
                                            )
                }
            }

            // RIGHT
            Item {
                id: rightCol
                anchors.left: centerCol.right
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.leftMargin: parent.width * 0.02

                CircularGauge {
                    id: ampGauge
                    anchors.centerIn: parent
                    width: parent.width * 0.75
                    height: width

                    // Amplitude Gauge Configuration
                    value: 650
                    label: "Amplitude"
                    threshold: 400
                    thresholdLabel: "Thr-A"
                    maxValue: 1200

                    onThresholdClicked: popup.open(
                                            "Thr-A",
                                            ampGauge.threshold,
                                            function(val){ ampGauge.threshold = val },
                                            50, 1500
                                            )
                }
            }
        }
    }
}

