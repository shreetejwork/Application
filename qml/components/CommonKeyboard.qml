import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import AppState 1.0

Rectangle {
    Typography {
        id: componentTypography
        scale: root.scale || 1.0
    }
    id: keyboard

    width: parent.width
    height: parent.height * 0.5

    // =====================================================
    // DRAWER ANIMATION
    // =====================================================

    y: parent.height
    visible: false

    property bool _shown: false

    // OPEN animation — values set at call time
    NumberAnimation {
        id: slideIn
        target: keyboard
        property: "y"
        duration: 550
        easing.type: Easing.OutCubic
        onStopped: {
            // nothing needed after open
        }
    }

    // CLOSE animation — values set at call time
    NumberAnimation {
        id: slideOut
        target: keyboard
        property: "y"
        duration: 450
        easing.type: Easing.InCubic
        onStopped: {
            if (!keyboard._shown) {
                keyboard.visible  = false
                numberMode        = false
                capsPersistent    = false
                shiftOnce         = false
                backspaceHeld     = false
            }
        }
    }

    // Watch GlobalState for show/hide
    Connections {
        target: GlobalState

        function onLoginKeyboardRequestChanged() {
            if (GlobalState.loginKeyboardRequest) {

                slideOut.stop()

                // Apply initial state BEFORE showing
                let input = GlobalState.activeInputField
                let isPassword = input && input.isPasswordField === true

                numberMode     = false
                capsLock       = !isPassword
                autoCapitalize = !isPassword
                capsPersistent = false
                shiftOnce      = false

                keyboard._shown  = true
                keyboard.visible = true

                // Read parent height NOW at runtime
                var ph = keyboard.parent.height
                slideIn.from = ph
                slideIn.to   = ph * 0.5
                slideIn.start()

            } else {

                slideIn.stop()
                keyboard._shown = false

                // Read parent height NOW at runtime
                var ph = keyboard.parent.height
                slideOut.from = ph * 0.5
                slideOut.to   = ph
                slideOut.start()
            }
        }
    }

    // =====================================================
    // ORIGINAL PROPERTIES
    // =====================================================

    property real baseHeight: 600
    property real scale: height / baseHeight

    property int keyFontSize: 40
    property int specialKeyFontSize: 45

    color: "#F4F6FB"
    border.color: "#DADDE5"

    z: 10000

    focus: false
    activeFocusOnTab: false

    // =====================================================
    // SHIFT STATES
    // =====================================================

    property bool capsLock: false
    property bool shiftOnce: false
    property bool capsPersistent: false

    property bool numberMode: false
    property bool autoCapitalize: true
    property bool backspaceHeld: false

    // =====================================================
    // BACKSPACE TIMER
    // =====================================================

    Timer {
        id: backspaceTimer

        interval: 80
        repeat: true

        running: keyboard._shown && backspaceHeld

        onTriggered: keyboard.sendKey("⌫")
    }

    // =====================================================
    // KEY MAPS
    // =====================================================

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

    // =====================================================
    // HELPERS
    // =====================================================

    function replaceSelection(input, textToInsert) {

        let start = Math.min(input.selectionStart, input.selectionEnd)
        let end   = Math.max(input.selectionStart, input.selectionEnd)

        input.remove(start, end)
        input.insert(start, textToInsert)

        input.cursorPosition = start + textToInsert.length
    }

    // =====================================================
    // KEY HANDLER
    // =====================================================

    function sendKey(key) {

        let input = GlobalState.activeInputField

        if (!input || !input.visible)
            return

        Qt.callLater(function() {

            if (GlobalState.loginKeyboardRequest && input)
                input.forceActiveFocus()
        })

        switch (key) {

        case "⌫":

            if (input.selectedText
                    && input.selectedText.length > 0) {

                let start = Math.min(
                            input.selectionStart,
                            input.selectionEnd)

                let end = Math.max(
                            input.selectionStart,
                            input.selectionEnd)

                input.remove(start, end)
                input.cursorPosition = start
            }

            else if (input.cursorPosition > 0) {

                input.remove(
                            input.cursorPosition - 1,
                            input.cursorPosition)
            }

            break

        case "Space":

            if (input.selectedText
                    && input.selectedText.length > 0) {

                replaceSelection(input, " ")
            }

            else {

                input.insert(input.cursorPosition, " ")
            }

            autoCapitalize = true
            capsLock = true
            shiftOnce = false

            break

        case "↩":

            input.focus = false

            autoCapitalize = true
            capsLock = true
            shiftOnce = false

            GlobalState.loginKeyboardRequest = false

            break

        case "@123":
            numberMode = true
            break

        case "ABC":
            numberMode = false
            break

        case "⌄":

            GlobalState.loginKeyboardRequest = false

            Qt.callLater(function() {

                if (input)
                    input.focus = false

                GlobalState.activeInputField = null
            })

            break

        default:

            let charToInsert = key
            let isPassword = input.isPasswordField === true

            if (!isPassword
                    && autoCapitalize
                    && key.length === 1) {

                charToInsert = key.toUpperCase()

                autoCapitalize = false
                capsLock = false
            }

            else if (capsLock) {

                charToInsert = key.toUpperCase()
            }

            if (input.selectedText
                    && input.selectedText.length > 0) {

                replaceSelection(input, charToInsert)
            }

            else {

                input.insert(
                            input.cursorPosition,
                            charToInsert)
            }

            if (shiftOnce && !capsPersistent) {

                capsLock = false
                shiftOnce = false
            }

            break
        }
    }

    // =====================================================
    // UI
    // =====================================================

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12 * scale

        spacing: 10 * scale

        ColumnLayout {

            Layout.fillWidth: true
            Layout.fillHeight: true

            visible: !numberMode

            spacing: 8 * scale

            KeyRow { keys: capsLock ? upper[0] : lower[0] }

            KeyRow {
                keys: capsLock ? upper[1] : lower[1]
                sidePadding: 20
            }

            RowLayout {

                Layout.fillWidth: true
                Layout.preferredHeight: 1

                spacing: 8 * scale

                SpecialKey {

                    text: "⇧"

                    iconSource: "qrc:/qt/qml/Application/assets/images/capslock.png"

                    active: capsLock
                    widthRatio: 2.2

                    MouseArea {

                        anchors.fill: parent

                        propagateComposedEvents: false
                        preventStealing: true

                        onClicked: {

                            if (keyboard.capsPersistent) {

                                keyboard.capsPersistent = false
                                keyboard.capsLock = false
                                keyboard.shiftOnce = false
                            }

                            else if (keyboard.shiftOnce) {

                                keyboard.capsPersistent = true
                                keyboard.capsLock = true
                                keyboard.shiftOnce = false
                            }

                            else {

                                keyboard.shiftOnce = true
                                keyboard.capsLock = true
                            }

                            keyboard.autoCapitalize = false

                            Qt.callLater(function() {

                                if (GlobalState.activeInputField)
                                    GlobalState.activeInputField.forceActiveFocus()
                            })
                        }

                        onPressed: parent.scale = 0.92
                        onReleased: parent.scale = 1.0
                        onCanceled: parent.scale = 1.0
                    }
                }

                Repeater {
                    model: capsLock ? upper[2] : lower[2]
                    delegate: Key {}
                }

                SpecialKey {
                    id: backspaceKey

                    text: "⌫"
                    iconSource: "qrc:/qt/qml/Application/assets/images/backspaceBlue.png"
                    widthRatio: 2.2

                    MouseArea {
                        anchors.fill: parent

                        onPressed: {
                            backspaceKey.pressedState = true

                            keyboard.backspaceHeld = true
                            keyboard.sendKey("⌫")
                        }

                        onReleased: {
                            backspaceKey.pressedState = false
                            keyboard.backspaceHeld = false
                        }

                        onCanceled: {
                            backspaceKey.pressedState = false
                            keyboard.backspaceHeld = false
                        }
                    }
                }
            }

            RowLayout {

                Layout.fillWidth: true
                Layout.preferredHeight: 1.2

                spacing: 8 * scale

                SpecialKey {
                    text: "@123"
                    widthRatio: 2.0
                }

                Item { Layout.fillWidth: true }

                Key {
                    text: "Space"
                    Layout.preferredWidth: 160 * keyboard.scale
                }

                SpecialKey {
                    text: "⌄"
                    widthRatio: 1.6
                }

                SpecialKey {
                    text: "↩"
                    widthRatio: 2.0
                }
            }
        }

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
                    id: numberBackspaceKey

                    text: "⌫"
                    iconSource: "qrc:/qt/qml/Application/assets/images/backspaceBlue.png"
                    widthRatio: 2.0

                    MouseArea {
                        anchors.fill: parent

                        onPressed: {
                            numberBackspaceKey.pressedState = true

                            keyboard.backspaceHeld = true
                            keyboard.sendKey("⌫")
                        }

                        onReleased: {
                            numberBackspaceKey.pressedState = false
                            keyboard.backspaceHeld = false
                        }

                        onCanceled: {
                            numberBackspaceKey.pressedState = false
                            keyboard.backspaceHeld = false
                        }
                    }
                }
            }

            RowLayout {

                Layout.fillWidth: true
                Layout.preferredHeight: 1.2

                spacing: 8 * scale

                SpecialKey {
                    text: "ABC"
                    widthRatio: 2.0
                }

                Item { Layout.fillWidth: true }

                Key {
                    text: "Space"
                    Layout.preferredWidth: 160 * keyboard.scale
                }

                SpecialKey {
                    text: "⌄"
                    widthRatio: 1.6
                }

                SpecialKey {
                    text: "↩"
                    widthRatio: 2.0
                }
            }
        }
    }

    // =====================================================
    // KEY ROW
    // =====================================================

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

    // =====================================================
    // NORMAL KEY
    // =====================================================

    component Key: Rectangle {

        property string text: modelData

        Layout.fillWidth: true
        Layout.fillHeight: true

        implicitHeight: 70 * keyboard.scale

        radius: 10

        color: mouse.pressed
               ? "#DCE5FF"
               : "#FFFFFF"

        border.color: "#C9CED8"

        activeFocusOnTab: false
        focus: false

        Text {
            anchors.centerIn: parent

            text: parent.text

            font.pixelSize: keyboard.keyFontSize * keyboard.scale


            color: "#1A4DB5"
        }

        MouseArea {
            id: mouse

            anchors.fill: parent

            propagateComposedEvents: false
            preventStealing: true

            onClicked: keyboard.sendKey(parent.text)

            onPressed: parent.scale = 0.92
            onReleased: parent.scale = 1.0
            onCanceled: parent.scale = 1.0
        }

        Behavior on scale {
            NumberAnimation { duration: 70 }
        }
    }

    // =====================================================
    // SPECIAL KEY
    // =====================================================

    component SpecialKey: Rectangle {

        property string text: ""
        property string iconSource: ""
        property bool active: false
        property real widthRatio: 1

        property bool pressedState: false

        Layout.fillHeight: true

        Layout.preferredWidth:
            110 * widthRatio * keyboard.scale

        implicitHeight: 70 * keyboard.scale

        radius: 10

        color: mouseArea.pressed
               ? (modelData === "⌫" ? "#FFCC99"
                                    : "#CCCCCC")
               : (modelData === "⌫" ? "#FFE0B2"
                                    : "#F0F0F0")

        border.color: "#C9CED8"

        Image {
            anchors.centerIn: parent

            visible: iconSource !== ""

            source: iconSource

            width: 68 * keyboard.scale
            height: 68 * keyboard.scale

            fillMode: Image.PreserveAspectFit
        }

        Text {
            anchors.centerIn: parent

            visible: iconSource === ""

            text: parent.text

            font.pixelSize:
                keyboard.specialKeyFontSize * keyboard.scale

            color: "#1A4DB5"
        }

        MouseArea {
            id: mouseArea

            anchors.fill: parent

            onPressed: {
                parent.pressedState = true
                parent.scale = 0.92
            }

            onReleased: {
                parent.pressedState = false
                parent.scale = 1.0
            }

            onCanceled: {
                parent.pressedState = false
                parent.scale = 1.0
            }

            onClicked: keyboard.sendKey(parent.text)
        }
    }
}
