import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import AppState 1.0

Rectangle {
    id: keyboard
    width: parent.width
    height: parent.height * 0.5
    anchors.bottom: parent.bottom

    property real baseHeight: 600
    property real scale: height / baseHeight

    property int keyFontSize: 35
    property int specialKeyFontSize: 40

    color: "#F4F6FB"
    border.color: "#DADDE5"

    visible: GlobalState.loginKeyboardRequest
    z: 10000

    property bool capsLock: false
    property bool numberMode: false
    property bool autoCapitalize: true
    property bool backspaceHeld: false

    Timer {
        id: backspaceTimer
        interval: 80
        repeat: true
        running: backspaceHeld
        onTriggered: keyboard.sendKey("⌫")
    }

    property var lower: [
        ["q","w","e","r","t","y","u","i","o","p"],
        ["a","s","d","f","g","h","j","k","l"],
        ["z","x","c","v","b","n","m"]
    ]

    property var upper: [
        ["Q","W","E","R","T","Y","U","I","O","P"],
        ["A","S","D","F","G","H","J","K","L"],
        ["Z","X","C","V","B","N","M"]
    ]

    property var num1: ["1","2","3","4","5","6","7","8","9","0"]
    property var num2: ["!","@","#","$","%","&","*","(",")"]
    property var num3: ["-","/",";",":","'","\"",".",",","?","+"]

    function sendKey(key) {
        let input = GlobalState.activeInputField

        if (!input || input.text === undefined)
            return

        let text = input.text
        let pos = input.cursorPosition !== undefined ? input.cursorPosition : text.length

        switch (key) {

        case "⌫":
            if (pos > 0) {
                input.text = text.slice(0, pos - 1) + text.slice(pos)
                input.cursorPosition = pos - 1
            }
            break

        case "Space":
            input.text = text.slice(0, pos) + " " + text.slice(pos)
            input.cursorPosition = pos + 1
            autoCapitalize = true
            break

        case "↩":
            if (input.accepted)
                input.accepted()
            autoCapitalize = true
            break

        case "⇧":
            capsLock = !capsLock
            break

        case "@123":
            numberMode = true
            break

        case "ABC":
            numberMode = false
            break

        case "⌄":
            GlobalState.loginKeyboardRequest = false
            break

        default:
            let charToInsert = key

            if (!capsLock && autoCapitalize && key.length === 1) {
                charToInsert = key.toUpperCase()
                autoCapitalize = false
            } else if (capsLock) {
                charToInsert = key.toUpperCase()
            }

            input.text = text.slice(0, pos) + charToInsert + text.slice(pos)
            input.cursorPosition = pos + charToInsert.length
            break
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12 * scale
        spacing: 10 * scale

        // ===== LETTER MODE =====
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !numberMode
            spacing: 8 * scale

            KeyRow { keys: capsLock ? upper[0] : lower[0] }
            KeyRow { keys: capsLock ? upper[1] : lower[1]; sidePadding: 20 }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                spacing: 8 * scale

                SpecialKey { text: "⇧"; active: capsLock; widthRatio: 2.2 }

                Repeater {
                    model: capsLock ? upper[2] : lower[2]
                    delegate: Key {}
                }

                SpecialKey {
                    text: "⌫"
                    widthRatio: 2.2

                    MouseArea {
                        anchors.fill: parent
                        onPressed: {
                            keyboard.backspaceHeld = true
                            keyboard.sendKey("⌫")
                        }
                        onReleased: keyboard.backspaceHeld = false
                        onCanceled: keyboard.backspaceHeld = false
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 1.2
                spacing: 8 * scale

                SpecialKey { text: "@123"; widthRatio: 2.0 }

                Item { Layout.fillWidth: true }

                Key {
                    text: "Space"
                    Layout.preferredWidth: 160 * keyboard.scale
                }

                SpecialKey { text: "⌄"; widthRatio: 1.6 }
                SpecialKey { text: "↩"; widthRatio: 2.0 }
            }
        }

        // ===== NUMBER MODE =====
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: numberMode
            spacing: 8 * scale

            KeyRow { keys: num1 }
            KeyRow { keys: num2 }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                spacing: 8 * scale

                Repeater {
                    model: num3
                    delegate: Key {}
                }

                SpecialKey {
                    text: "⌫"
                    widthRatio: 2.0

                    MouseArea {
                        anchors.fill: parent
                        onPressed: {
                            keyboard.backspaceHeld = true
                            keyboard.sendKey("⌫")
                        }
                        onReleased: keyboard.backspaceHeld = false
                        onCanceled: keyboard.backspaceHeld = false
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 1.2
                spacing: 8 * scale

                SpecialKey { text: "ABC"; widthRatio: 2.0 }

                Item { Layout.fillWidth: true }

                Key {
                    text: "Space"
                    Layout.preferredWidth: 160 * keyboard.scale
                }

                SpecialKey { text: "⌄"; widthRatio: 1.6 }

                SpecialKey { text: "↩"; widthRatio: 2.0 }
            }
        }
    }

    component KeyRow: RowLayout {
        property var keys: []
        property real sidePadding: 0

        Layout.fillWidth: true
        Layout.preferredHeight: 1
        spacing: 8 * keyboard.scale

        Item { width: sidePadding * keyboard.scale }

        Repeater {
            model: keys
            delegate: Key {}
        }

        Item { width: sidePadding * keyboard.scale }
    }

    component Key: Rectangle {
        property string text: modelData

        Layout.fillWidth: true
        Layout.fillHeight: true
        implicitHeight: 70 * keyboard.scale

        radius: 10
        color: mouse.pressed ? "#DCE5FF" : "#FFFFFF"
        border.color: "#C9CED8"

        Text {
            anchors.centerIn: parent
            text: parent.text
            font.pixelSize: keyboard.keyFontSize * keyboard.scale
            font.bold: true
            color: "#1A4DB5"
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            onClicked: keyboard.sendKey(parent.text)
            onPressed: parent.scale = 0.92
            onReleased: parent.scale = 1.0
            onCanceled: parent.scale = 1.0
        }

        Behavior on scale { NumberAnimation { duration: 70 } }
    }

    component SpecialKey: Rectangle {
        property string text: ""
        property bool active: false
        property real widthRatio: 1

        Layout.fillHeight: true
        Layout.preferredWidth: 110 * widthRatio * keyboard.scale
        implicitHeight: 70 * keyboard.scale

        radius: 10
        color: active ? "#CCD9FF" : "#E6EBF5"
        border.color: "#C9CED8"

        Text {
            anchors.centerIn: parent
            text: parent.text
            font.pixelSize: keyboard.specialKeyFontSize * keyboard.scale
            font.bold: true
            color: "#1A4DB5"
        }

        Rectangle {
            visible: active
            anchors.fill: parent
            radius: parent.radius
            border.width: 2
            border.color: "#1A4DB5"
            color: "transparent"
        }

        MouseArea {
            anchors.fill: parent
            onClicked: keyboard.sendKey(parent.text)
            onPressed: parent.scale = 0.92
            onReleased: parent.scale = 1.0
            onCanceled: parent.scale = 1.0
        }

        Behavior on scale { NumberAnimation { duration: 70 } }
    }
}
