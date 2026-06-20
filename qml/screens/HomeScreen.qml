import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import AppState 1.0

import Backend 1.0

import "../components"


Item {
    id: homeScreen
    property bool showTopBar: true
    property var globalTopBar: null
    property var navigateTo


    Rectangle {
    Typography {
        id: screenTypography
        scale: root.scale || 1.0
    }
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

        AccessDeniedPopup {
            id: accessDeniedPopup
        }

        // ================= POPUP =================
        Rectangle {
            id: popup

            visible: isOpen || animScale > 0.01
            z: 101
            width: Math.min(parent.width * 0.40, 450)
            height: Math.min(parent.height * 0.95, 730)
            radius: 16
            color: "#FFFFFF"
            anchors.centerIn: parent

            // =====================================================
            // ANIMATION
            // =====================================================

            property real animScale: 0.0
            property real animOpacity: 0.0
            property bool isOpen: false

            transform: Scale {
                origin.x: popup.width / 2
                origin.y: popup.height / 2
                xScale: popup.animScale
                yScale: popup.animScale
            }

            opacity: popup.animOpacity

            Behavior on animScale {
                NumberAnimation {
                    duration: popup.isOpen ? 350 : 280
                    easing.type: popup.isOpen ? Easing.OutQuad : Easing.InQuad
                }
            }

            Behavior on animOpacity {
                NumberAnimation {
                    duration: popup.isOpen ? 350 : 280
                    easing.type: popup.isOpen ? Easing.OutQuad : Easing.InQuad
                }
            }

            onAnimOpacityChanged: {

                if (animOpacity <= 0.01 && !isOpen)
                    visible = false
            }

            function openPopup() {

                visible = true

                isOpen = true

                animScale = 1.0
                animOpacity = 1.0
            }

            function closePopup() {

                isOpen = false

                animScale = 0.0
                animOpacity = 0.0
            }
            // =====================================================

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

                openPopup()

                inputField.forceActiveFocus()
                inputField.selectAll()
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 12

                // ===== TITLE =====
                Text {
                    text: popup.fieldName
                    font.pixelSize: 22

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

                        color: "#333"
                        horizontalAlignment: TextInput.AlignHCenter
                        verticalAlignment: TextInput.AlignVCenter

                        readOnly: true
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
                        spacing: 15

                        Text {
                            text: "Min: " + popup.minValue
                            color: "#1A4DB5"
                            font.pixelSize: 13

                            Layout.fillWidth: true
                        }

                        Rectangle { width: 1; height: parent.height * 0.6; color: "#D0D0D0" }

                        Text {
                            text: "Max: " + popup.maxValue
                            color: "#1A4DB5"
                            font.pixelSize: 13

                            Layout.fillWidth: true
                        }
                    }
                }

                // ===== ERROR =====
                Text {
                    text: popup.errorText
                    color: "#FF5252"
                    font.pixelSize: 13

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

                            color: mouseArea.pressed
                                   ? (modelData === "C" ? "#FF9999"
                                                        : modelData === "⌫" ? "#FFCC99"
                                                                             : "#CCCCCC")
                                   : (modelData === "C" ? "#FFCDD2"
                                                        : modelData === "⌫" ? "#FFE0B2"
                                                                             : "#F0F0F0")

                            border.color: "#E0E0E0"
                            border.width: 1

                            Item {
                                anchors.fill: parent

                                Image {
                                    anchors.centerIn: parent

                                    visible: modelData === "⌫"

                                    source: "qrc:/qt/qml/Application/assets/images/backspace.png"

                                    width: parent.width * 0.7
                                    height: parent.height * 0.7

                                    fillMode: Image.PreserveAspectFit
                                }

                                Text {
                                    anchors.centerIn: parent

                                    visible: modelData !== "⌫"

                                    text: modelData

                                    font.pixelSize: 18
                                    color: "#333"
                                }
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
                                        if (inputField.text.length > 0)
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
                    Layout.topMargin: 5
                    spacing: 10

                    // CANCEL
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

                            font.pixelSize: 23
                            color: "#333"
                        }

                        MouseArea {
                            id: cancelMouseArea
                            anchors.fill: parent
                            onClicked: {
                                popup.closePopup()
                                popup.errorText = ""
                                popup.hasError = false
                            }
                        }
                    }

                    // SAVE
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

                            font.pixelSize: 23
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

                                if (popup.onSaveCallback)
                                    popup.onSaveCallback(val)

                                if (globalTopBar)
                                    globalTopBar.showNotification("✓ " + popup.fieldName + " updated to " + val)
                                else
                                    topBar.showNotification("✓ " + popup.fieldName + " updated to " + val)

                                popup.closePopup()
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

                    onMachinePhaseClicked: {

                        if (GlobalState.loggedInUserRole === "") {

                            accessDeniedPopup.popupTitle = "Access Denied !"

                            accessDeniedPopup.popupMessage =
                                    "Please login first"

                            accessDeniedPopup.open()

                            return
                        }


                        popup.open(

                            "Machine Phase",

                            GlobalState.machinePhase,

                            function(val){

                                // 12.5 -> 125
                                var phase = Math.round(val * 10)

                                SerialManager.setMachinePhase(phase)

                                GlobalState.machinePhase = val

                            },

                            0,

                            180

                        )

                    }
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

                Column {
                    width: parent.width

                    // MOVE ENTIRE SECTION UP
                    anchors.top: parent.top
                    anchors.topMargin: 10

                    anchors.horizontalCenter: parent.horizontalCenter

                    spacing: 18

                    // =====================================================
                    // ACTIVE PRODUCT CARD
                    // =====================================================

                    Rectangle {
                        width: parent.width * 0.50
                        height: 65

                        anchors.horizontalCenter: parent.horizontalCenter

                        radius: 14

                        color: "#FFFFFF"

                        border.color: "#D0D8EC"
                        border.width: 1

                        property bool hovered: false
                        property bool pressed: false

                        Column {
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter

                                text: "Active Product"

                                font.pixelSize: 14


                                color: "#6B7280"
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter

                                // Replace with actual active product
                                text: "Paracetamol 650"

                                font.pixelSize: 18


                                color: "#1A4DB5"
                            }
                        }
                        MouseArea {
                            anchors.fill: parent

                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onEntered: parent.hovered = true
                            onExited: parent.hovered = false

                            onPressed: parent.pressed = true
                            onReleased: parent.pressed = false

                            onClicked: {

                                if (GlobalState.loggedInUserRole !== "Admin")
                                {
                                    accessDeniedPopup.popupTitle = "Access Denied !"

                                    accessDeniedPopup.popupMessage =
                                            "Only Admin can access"

                                    accessDeniedPopup.open()
                                    return
                                }

                                if (GlobalState.showProductLib)
                                    navigateTo("ProductLibrary")
                            }
                        }

                        scale: pressed ? 0.96 : 1.0

                        Behavior on scale {
                            NumberAnimation {
                                duration: 120
                            }
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }
                        }

                        states: [

                            State {
                                name: "hovered"
                                when: parent.hovered && !parent.pressed

                                PropertyChanges {
                                    target: parent
                                    color: "#F7F9FF"
                                }
                            },

                            State {
                                name: "pressed"
                                when: parent.pressed

                                PropertyChanges {
                                    target: parent
                                    color: "#EEF2FF"
                                }
                            }
                        ]
                    }

                    // =====================================================
                    // SIGNAL GAUGE
                    // =====================================================

                    CircularGauge {
                        id: signalGauge

                        anchors.horizontalCenter: parent.horizontalCenter

                        width: parent.width * 0.85
                        height: width

                        value: SerialManager.signal

                        label: "Signal"

                        threshold: GlobalState.signalThreshold
                        thresholdLabel: "Thr-S"

                        maxValue: 1200

                        onThresholdClicked: {

                            if (GlobalState.loggedInUserRole === "") {

                                accessDeniedPopup.popupTitle = "Access Denied !"
                                accessDeniedPopup.popupMessage = "Please login first"
                                accessDeniedPopup.open()
                                return
                            }

                            popup.open(

                                "Thr-S",

                                signalGauge.threshold,

                                function(val){

                                    SerialManager.setSignalThreshold(val)

                                    GlobalState.signalThreshold = val

                                },

                                100,
                                1500
                            )
                        }
                    }
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

                Column {
                    width: parent.width * 0.85

                    anchors.top: parent.top
                    anchors.topMargin: 10

                    anchors.horizontalCenter: parent.horizontalCenter

                    spacing: 40

                    // =====================================================
                    // MANUAL VALIDATION BUTTON
                    // =====================================================

                    Rectangle {
                        width: parent.width * 0.50
                        height: 65

                        anchors.horizontalCenter: parent.horizontalCenter

                        radius: 14

                        color: "#FFFFFF"

                        border.color: "#D0D8EC"
                        border.width: 1

                        property bool hovered: false
                        property bool pressed: false

                        Column {
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter

                                text: "Manual"

                                font.pixelSize: 15


                                color: "#1A4DB5"
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter

                                text: "Validation"

                                font.pixelSize: 15


                                color: "#1A4DB5"
                            }
                        }

                        MouseArea {
                            anchors.fill: parent

                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onEntered: parent.hovered = true
                            onExited: parent.hovered = false

                            onPressed: parent.pressed = true
                            onReleased: parent.pressed = false

                            onClicked: {
                                globalTopBar.showNotification(
                                    "✓ Manual Validation ON"
                                )
                            }
                        }

                        scale: pressed ? 0.96 : 1.0

                        Behavior on scale {
                            NumberAnimation {
                                duration: 120
                            }
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }
                        }

                        states: [

                            State {
                                name: "hovered"
                                when: parent.hovered && !parent.pressed

                                PropertyChanges {
                                    target: parent
                                    color: "#F7F9FF"
                                }
                            },

                            State {
                                name: "pressed"
                                when: parent.pressed

                                PropertyChanges {
                                    target: parent
                                    color: "#EEF2FF"
                                }
                            }
                        ]
                    }

                    // =====================================================
                    // CIRCULAR GAUGE
                    // =====================================================

                    CircularGauge {

                        id: ampGauge

                        anchors.horizontalCenter: parent.horizontalCenter

                        width: parent.width
                        height: width


                        value: SerialManager.amplitude


                        label: "Amplitude"


                        threshold: GlobalState.amplitudeThreshold


                        thresholdLabel: "Thr-A"


                        maxValue: 1200



                        onThresholdClicked: {

                            if (GlobalState.loggedInUserRole === "") {

                                accessDeniedPopup.popupTitle = "Access Denied !"

                                accessDeniedPopup.popupMessage =
                                        "Please login first"

                                accessDeniedPopup.open()

                                return
                            }



                            popup.open(

                                "Thr-A",

                                ampGauge.threshold,


                                function(val){

                                    SerialManager.setAmplitudeThreshold(val)

                                    GlobalState.amplitudeThreshold = val

                                },

                                50,

                                1500

                            )

                        }

                    }
                }
            }
        }
    }
}

