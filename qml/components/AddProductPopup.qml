import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import AppState 1.0

Popup {
    id: popup

    parent: Overlay.overlay

    modal: true
    focus: true

    anchors.centerIn: parent

    width: 560 * scaleFactor
    height: 420 * scaleFactor

    padding: 0

    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    // =========================================================
    // EXTERNAL PROPERTIES
    // =========================================================

    property real scaleFactor: 1.0

    property string productName: ""
    property string productCode: ""

    property var currentModelRef
    property var getFreeSrNoFunc

    signal productSaved()

    // =========================================================
    // OPEN KEYBOARD AUTOMATICALLY
    // =========================================================

    onOpened: {
        productNameField.forceActiveFocus()
    }

    // =========================================================
    // BACKGROUND
    // =========================================================

    background: Rectangle {
        radius: 18 * popup.scaleFactor
        color: "#FFFFFF"

        border.color: "#C8D4EE"
        border.width: 1

        layer.enabled: true
    }

    // =========================================================
    // CONTENT
    // =========================================================

    Column {
        anchors.fill: parent

        anchors.leftMargin: 28 * popup.scaleFactor
        anchors.rightMargin: 28 * popup.scaleFactor
        anchors.topMargin: 28 * popup.scaleFactor
        anchors.bottomMargin: 24 * popup.scaleFactor

        spacing: 22 * popup.scaleFactor

        // =====================================================
        // TITLE
        // =====================================================

        Column {
            spacing: 6 * popup.scaleFactor

            Text {
                text: "Add Product"
                font.pixelSize: 26 * popup.scaleFactor
                font.bold: true
                color: "#1A4DB5"
            }

            Rectangle {
                width: 80 * popup.scaleFactor
                height: 4 * popup.scaleFactor
                radius: 2 * popup.scaleFactor
                color: "#1A4DB5"
            }
        }

        // =====================================================
        // PRODUCT NAME
        // =====================================================

        Column {
            width: parent.width
            spacing: 8 * popup.scaleFactor

            Rectangle {
                width: parent.width
                height: 60 * popup.scaleFactor

                radius: 12 * popup.scaleFactor

                color: productNameField.activeFocus
                       ? "#EEF3FF"
                       : "#F7F9FF"

                border.color: productNameField.activeFocus
                              ? "#1A4DB5"
                              : "#C8D4EE"

                border.width: productNameField.activeFocus ? 2 : 1

                Behavior on border.color {
                    ColorAnimation { duration: 120 }
                }

                Behavior on color {
                    ColorAnimation { duration: 120 }
                }

                TextField {
                    id: productNameField

                    anchors.fill: parent


                    anchors.leftMargin: 16 * popup.scaleFactor
                    anchors.rightMargin: 16 * popup.scaleFactor

                    background: null

                    font.pixelSize: 22 * popup.scaleFactor
                    font.weight: Font.Medium

                    color: "#1A1A1A"

                    verticalAlignment: Text.AlignVCenter

                    placeholderText: "Enter product name"
                    placeholderTextColor: "#8896B0"

                    selectByMouse: true

                    property bool isPasswordField: false

                    focus: true

                    onPressed: {
                        GlobalState.activeInputField = productNameField
                        GlobalState.loginKeyboardRequest = true
                        forceActiveFocus()
                    }

                    onActiveFocusChanged: {
                        if (activeFocus)
                            GlobalState.activeInputField = productNameField
                    }

                    onAccepted: {
                        GlobalState.loginKeyboardRequest = false
                        productCodeField.forceActiveFocus()
                    }

                    inputMethodHints: Qt.ImhNoPredictiveText

                    onTextChanged: {
                        popup.productName = text
                    }
                }
            }
        }

        // =====================================================
        // PRODUCT CODE
        // =====================================================

        Column {
            width: parent.width
            spacing: 8 * popup.scaleFactor

            Rectangle {
                width: parent.width
                height: 60 * popup.scaleFactor

                radius: 12 * popup.scaleFactor

                color: productCodeField.activeFocus
                       ? "#EEF3FF"
                       : "#F7F9FF"

                border.color: productCodeField.activeFocus
                              ? "#1A4DB5"
                              : "#C8D4EE"

                border.width: productCodeField.activeFocus ? 2 : 1

                Behavior on border.color {
                    ColorAnimation { duration: 120 }
                }

                Behavior on color {
                    ColorAnimation { duration: 120 }
                }

                TextField {
                    id: productCodeField

                    anchors.fill: parent

                    anchors.leftMargin: 16 * popup.scaleFactor
                    anchors.rightMargin: 16 * popup.scaleFactor

                    background: null

                    font.pixelSize: 22 * popup.scaleFactor
                    font.weight: Font.Medium

                    color: "#1A1A1A"

                    verticalAlignment: Text.AlignVCenter

                    placeholderText: "Enter product code"
                    placeholderTextColor: "#8896B0"

                    selectByMouse: true

                    property bool isPasswordField: false

                    onPressed: {
                        GlobalState.activeInputField = productCodeField
                        GlobalState.loginKeyboardRequest = true
                        forceActiveFocus()
                    }

                    onActiveFocusChanged: {
                        if (activeFocus)
                            GlobalState.activeInputField = productCodeField
                    }

                    onAccepted: {
                        GlobalState.loginKeyboardRequest = false
                        focus = false
                    }

                    inputMethodHints: Qt.ImhNoPredictiveText

                    onTextChanged: {
                        popup.productCode = text
                    }
                }
            }
        }

        // =====================================================
        // VALIDATION
        // =====================================================

        Text {
            id: validationMsg

            width: parent.width

            visible: text !== ""

            text: ""

            wrapMode: Text.WordWrap

            font.pixelSize: 17 * popup.scaleFactor
            font.weight: Font.Medium

            color: "#C62828"
        }

        Item {
            width: 1
            height: 1
        }

        // =====================================================
        // BUTTONS
        // =====================================================

        Row {
            width: parent.width

            spacing: 16 * popup.scaleFactor

            // ================= CANCEL =================

            Rectangle {
                width: (parent.width - parent.spacing) / 2
                height: 56 * popup.scaleFactor

                radius: 12 * popup.scaleFactor

                color: cancelHover.containsMouse
                       ? "#EEF3FF"
                       : "#FFFFFF"

                border.color: "#1A4DB5"
                border.width: 1.5

                Text {
                    anchors.centerIn: parent

                    text: "Cancel"

                    font.pixelSize: 20 * popup.scaleFactor
                    font.weight: Font.Medium

                    color: "#1A4DB5"
                }

                MouseArea {
                    id: cancelHover

                    anchors.fill: parent

                    hoverEnabled: true

                    cursorShape: Qt.PointingHandCursor

                    onClicked: {

                        productNameField.text = ""
                        productCodeField.text = ""

                        popup.productName = ""
                        popup.productCode = ""

                        validationMsg.text = ""

                        popup.close()
                    }
                }
            }

            // ================= SAVE =================

            Rectangle {
                width: (parent.width - parent.spacing) / 2
                height: 56 * popup.scaleFactor

                radius: 12 * popup.scaleFactor

                color: saveHover.containsMouse
                       ? "#1640A0"
                       : "#1A4DB5"

                Text {
                    anchors.centerIn: parent

                    text: "Save"

                    font.pixelSize: 20 * popup.scaleFactor
                    font.weight: Font.Medium

                    color: "#FFFFFF"
                }

                MouseArea {
                    id: saveHover

                    anchors.fill: parent

                    hoverEnabled: true

                    cursorShape: Qt.PointingHandCursor

                    onClicked: {

                        if (popup.productName.trim() === "") {
                            validationMsg.text = "Product name is required."
                            productNameField.forceActiveFocus()
                            return
                        }

                        if (popup.productCode.trim() === "") {
                            validationMsg.text = "Product code is required."
                            productCodeField.forceActiveFocus()
                            return
                        }

                        var srNo = popup.getFreeSrNoFunc(
                                       popup.currentModelRef)

                        if (srNo === -1) {
                            validationMsg.text =
                                    "No free slot available (Max 100 products)."
                            return
                        }

                        popup.currentModelRef.append({
                            selected: false,
                            active: false,
                            sr: srNo,
                            name: popup.productName.trim(),
                            code: popup.productCode.trim(),
                            fixedItem: false
                        })

                        GlobalState.loginKeyboardRequest = false

                        popup.productName = ""
                        popup.productCode = ""

                        productNameField.text = ""
                        productCodeField.text = ""

                        validationMsg.text = ""

                        popup.productSaved()

                        popup.close()
                    }
                }
            }
        }
    }
}
