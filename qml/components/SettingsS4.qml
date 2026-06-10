import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import AppState 1.0

Item {
    id: root
    anchors.fill: parent

    property real baseWidth: 1024
    property real baseHeight: 600
    property real scale: Math.min(width / baseWidth, height / baseHeight)

    Typography {
        id: typo
        scale: root.scale
    }

    property var globalTopBar
    property var notify
    property string activeCardId: ""

    property real keyboardHeight: GlobalState.loginKeyboardRequest ? 340 * root.scale : 0
    property real visibleHeight: root.height - keyboardHeight

    Behavior on keyboardHeight {
        NumberAnimation { duration: 260; easing.type: Easing.OutQuart }
    }

    // ── Background ──────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: "#F4F7FC"
    }

    // ── Header ──────────────────────────────────────────────
    Column {
        id: headerSection
        anchors {
            left: parent.left
            top: parent.top
            leftMargin: 34 * root.scale
            topMargin: 20 * root.scale
        }
        spacing: 4 * root.scale

        Text {
            text: "About Machine"
            color: "#183C8F"
            font.pixelSize: typo.title
        }

        Rectangle {
            width: 80 * root.scale
            height: 4 * root.scale
            radius: 2 * root.scale
            color: "#1A4DB5"
        }
    }

    // ── Main Panel ──────────────────────────────────────────
    Rectangle {
        id: panel
        anchors {
            left: parent.left
            right: parent.right
            top: headerSection.bottom
            bottom: parent.bottom
            leftMargin: 10 * root.scale
            rightMargin: 10 * root.scale
            topMargin: 5 * root.scale
            bottomMargin: 0 * root.scale
        }
        radius: 20 * root.scale
        color: "#FFFFFF"
        border.color: "#D9E2F2"
        border.width: 1

        // ── Inner layout: supplier row + grid ──
        Column {
            anchors.fill: parent
            anchors.margins: 26 * root.scale
            spacing: 18 * root.scale

            // ── Supplier Name card — centered full width ──
            Item {
                width: parent.width
                height: 150 * root.scale

                SettingsCard {
                    cardId: "supplierName"
                    fieldLabel: "Supplier Name"
                    placeholderText: "Enter supplier name"
                    initialValue: GlobalState.supplierName ?? ""
                    width: 550 * root.scale
                    anchors.horizontalCenter: parent.horizontalCenter
                    onConfirmed: (val) => {
                        GlobalState.supplierName = val
                        if (root.notify) root.notify("✓ Supplier Name Saved")
                    }
                }
            }

            // ── 2×2 grid of remaining cards ──
            GridLayout {
                id: cardGrid
                width: parent.width
                columns: 2
                rowSpacing: 22 * root.scale
                columnSpacing: 22 * root.scale

                SettingsCard {
                    cardId: "serialNumber"
                    fieldLabel: "Serial Number"
                    placeholderText: "Enter serial number"
                    initialValue: GlobalState.serialNumber ?? ""
                    onConfirmed: (val) => {
                        GlobalState.serialNumber = val
                        if (root.notify) root.notify("✓ Serial Number Saved")
                    }
                }

                SettingsCard {
                    cardId: "machineId"
                    fieldLabel: "Machine ID"
                    placeholderText: "Enter machine ID"
                    initialValue: GlobalState.machineId ?? "PHMX"
                    onConfirmed: (val) => {
                        GlobalState.machineId = val
                        if (root.notify) root.notify("✓ Machine ID Saved")
                    }
                }

                SettingsCard {
                    cardId: "user"
                    fieldLabel: "User"
                    placeholderText: "Enter user"
                    initialValue: GlobalState.userName ?? ""
                    onConfirmed: (val) => {
                        GlobalState.userName = val
                        if (root.notify) root.notify("✓ User Saved")
                    }
                }

                SettingsCard {
                    cardId: "location"
                    fieldLabel: "Location"
                    placeholderText: "Enter location"
                    initialValue: GlobalState.location ?? ""
                    onConfirmed: (val) => {
                        GlobalState.location = val
                        if (root.notify) root.notify("✓ Location Saved")
                    }
                }
            }
        }
    }

    // ── Single clean full-screen dim ────────────────────────
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: root.activeCardId !== "" ? 0.45 : 0.0
        visible: opacity > 0
        z: 15

        Behavior on opacity {
            NumberAnimation { duration: 220 }
        }

        MouseArea {
            anchors.fill: parent
            enabled: root.activeCardId !== ""
            onClicked: {
                root.activeCardId = ""
                GlobalState.loginKeyboardRequest = false
            }
        }
    }

    // ── Floating Card Loader ────────────────────────────────
    Loader {
        id: floatingLoader
        z: 20

        width: 480 * root.scale
        height: 160 * root.scale
        x: (root.width - width) / 2
        y: (root.visibleHeight - height) / 2

        Behavior on y {
            NumberAnimation { duration: 280; easing.type: Easing.OutQuart }
        }

        active: root.activeCardId !== ""
        visible: active

        property string loadedCardId: ""
        property string loadedLabel: ""
        property string loadedPlaceholder: ""
        property string loadedInitialValue: ""

        onActiveChanged: {
            if (active) {
                var id = root.activeCardId
                loadedCardId = id
                if (id === "supplierName") {
                    loadedLabel        = "Supplier Name"
                    loadedPlaceholder  = "Enter supplier name"
                    loadedInitialValue = GlobalState.supplierName ?? ""
                } else if (id === "machineId") {
                    loadedLabel        = "Machine ID"
                    loadedPlaceholder  = "Enter machine ID"
                    loadedInitialValue = GlobalState.machineId ?? "PHMX"
                } else if (id === "user") {
                    loadedLabel        = "User"
                    loadedPlaceholder  = "Enter user"
                    loadedInitialValue = GlobalState.userName ?? ""
                } else if (id === "location") {
                    loadedLabel        = "Location"
                    loadedPlaceholder  = "Enter location"
                    loadedInitialValue = GlobalState.location ?? ""
                } else if (id === "serialNumber") {
                    loadedLabel        = "Serial Number"
                    loadedPlaceholder  = "Enter serial number"
                    loadedInitialValue = GlobalState.serialNumber ?? ""
                }
            }
        }

        sourceComponent: FloatingCard {
            cardId:          floatingLoader.loadedCardId
            fieldLabel:      floatingLoader.loadedLabel
            placeholderText: floatingLoader.loadedPlaceholder
            initialValue:    floatingLoader.loadedInitialValue

            onDismiss: {
                root.activeCardId = ""
                GlobalState.loginKeyboardRequest = false
            }
            onConfirmed: (id, val) => {
                if (id === "supplierName")      { GlobalState.supplierName  = val; if (root.notify) root.notify("✓ Supplier Name Saved") }
                else if (id === "machineId")    { GlobalState.machineId     = val; if (root.notify) root.notify("✓ Machine ID Saved") }
                else if (id === "user")         { GlobalState.userName       = val; if (root.notify) root.notify("✓ User Saved") }
                else if (id === "location")     { GlobalState.location       = val; if (root.notify) root.notify("✓ Location Saved") }
                else if (id === "serialNumber") { GlobalState.serialNumber   = val; if (root.notify) root.notify("✓ Serial Number Saved") }
                root.activeCardId = ""
                GlobalState.loginKeyboardRequest = false
            }
        }
    }

    // ── Floating Card Component ─────────────────────────────
    component FloatingCard: Rectangle {
        id: floatCard

        property string cardId: ""
        property string fieldLabel: ""
        property string placeholderText: ""
        property string initialValue: ""

        signal confirmed(string id, string value)
        signal dismiss()

        anchors.fill: parent
        radius: 18 * root.scale
        color: "#FFFFFF"
        border.color: "#2A62D5"
        border.width: 2

        opacity: 0
        scale: 0.90
        Component.onCompleted: floatEntrance.start()

        ParallelAnimation {
            id: floatEntrance
            NumberAnimation { target: floatCard; property: "opacity"; from: 0; to: 1; duration: 240; easing.type: Easing.OutCubic }
            NumberAnimation { target: floatCard; property: "scale"; from: 0.90; to: 1.0; duration: 260; easing.type: Easing.OutBack; easing.overshoot: 0.6 }
        }

        Column {
            anchors.fill: parent
            anchors.margins: 22 * root.scale
            spacing: 14 * root.scale

            // Label + close
            Item {
                width: parent.width
                height: 24 * root.scale

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: floatCard.fieldLabel
                    color: "#52627E"
                    font.pixelSize: typo.body
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 26 * root.scale
                    height: 26 * root.scale
                    radius: width / 2
                    color: xHover.containsMouse ? "#F0F4FF" : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        color: "#8898B8"
                        font.pixelSize: typo.heading
                    }

                    HoverHandler { id: xHover }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: floatCard.dismiss()
                    }
                }
            }

            // Input
            Rectangle {
                width: parent.width
                height: 62 * root.scale
                radius: 12 * root.scale
                color: "#F8FBFF"
                border.width: 2
                border.color: "#2A62D5"

                TextField {
                    id: floatInput
                    anchors.fill: parent
                    anchors.leftMargin: 16 * root.scale
                    anchors.rightMargin: 58 * root.scale
                    text: floatCard.initialValue
                    color: "#183C8F"
                    font.pixelSize: typo.body
                    verticalAlignment: Text.AlignVCenter
                    background: null
                    selectByMouse: true
                    activeFocusOnPress: true
                    placeholderText: floatCard.placeholderText
                    placeholderTextColor: "#A0ACC2"
                    inputMethodHints: Qt.ImhNone

                    Component.onCompleted: {
                        forceActiveFocus()
                        GlobalState.activeInputField = floatInput
                        GlobalState.loginKeyboardRequest = true
                    }

                    onAccepted: {
                        var v = text.trim()
                        text = v
                        floatCard.confirmed(floatCard.cardId, v)
                        focus = false
                    }
                }

                Rectangle {
                    id: saveBtn
                    width: 40 * root.scale
                    height: 40 * root.scale
                    radius: width / 2
                    anchors {
                        right: parent.right
                        rightMargin: 10 * root.scale
                        verticalCenter: parent.verticalCenter
                    }
                    color: "#1B56CC"
                    scale: saveMouse.pressed ? 0.88 : 1.0
                    Behavior on scale { NumberAnimation { duration: 100 } }

                    Text {
                        anchors.centerIn: parent
                        text: "✓"
                        color: "white"
                        font.pixelSize: typo.bodySmall
                    }

                    MouseArea {
                        id: saveMouse
                        anchors.fill: parent
                        onClicked: {
                            var v = floatInput.text.trim()
                            floatInput.text = v
                            floatCard.confirmed(floatCard.cardId, v)
                            floatInput.focus = false
                        }
                    }
                }
            }
        }
    }

    // ── Settings Card ────────────────────────────────────────
    component SettingsCard: Rectangle {
        id: card

        property string cardId: ""
        property string fieldLabel: ""
        property string placeholderText: ""
        property string initialValue: ""
        property bool isSaved: false
        property string displayValue: initialValue

        signal confirmed(string value)

        Layout.fillWidth: true
        Layout.preferredWidth: 440 * root.scale
        Layout.preferredHeight: 150 * root.scale

        implicitWidth:  440 * root.scale
        implicitHeight: 150 * root.scale

        radius: 18 * root.scale
        color: cardHover.containsMouse ? "#F4F8FF" : "#FFFFFF"
        border.color: cardHover.containsMouse ? "#5E9BFF" : "#D9E2F2"
        border.width: 1

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        scale: cardHover.containsMouse ? 1.010 : 1.0
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

        HoverHandler { id: cardHover }

        MouseArea {
            anchors.fill: parent
            onClicked: root.activeCardId = card.cardId
        }

        Column {
            anchors.fill: parent
            anchors.margins: 22 * root.scale
            spacing: 16 * root.scale

            Text {
                text: card.fieldLabel
                color: "#52627E"
                font.pixelSize: typo.heading
            }

            Rectangle {
                width: parent.width
                height: 58 * root.scale
                radius: 12 * root.scale
                color: "#F7F9FD"
                border.width: 1
                border.color: "#D6DDEA"

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 16 * root.scale
                    anchors.right: editCircle.left
                    anchors.rightMargin: 8 * root.scale
                    anchors.verticalCenter: parent.verticalCenter
                    text: card.displayValue.length > 0 ? card.displayValue : card.placeholderText
                    color: card.displayValue.length > 0 ? "#183C8F" : "#A0ACC2"
                    font.pixelSize: typo.heading
                    elide: Text.ElideRight
                }

                Rectangle {
                    id: editCircle
                    width: 32 * root.scale
                    height: 32 * root.scale
                    radius: width / 2
                    anchors {
                        right: parent.right
                        rightMargin: 13 * root.scale
                        verticalCenter: parent.verticalCenter
                    }
                    color: "#E4EDFF"

                    Image {
                        anchors.centerIn: parent
                        source: "qrc:/qt/qml/Application/assets/images/edit.png"
                        width: Math.max(14, 16 * root.scale)
                        height: width
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }
                }
            }
        }

        Connections {
            target: floatingLoader.item
            function onConfirmed(id, val) {
                if (id === card.cardId) {
                    card.displayValue = val
                    card.isSaved = true
                    resetTimer.restart()
                }
            }
        }

        Timer {
            id: resetTimer
            interval: 3000
            repeat: false
            onTriggered: card.isSaved = false
        }
    }
}
