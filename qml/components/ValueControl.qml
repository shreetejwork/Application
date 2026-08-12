import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import AppState 1.0

Item {
    id: root

    Typography {
        id: componentTypography
        scale: root.scale || 1.0
    }

    AccessDeniedPopup {
        id: accessDeniedPopup
    }

    // =========================================================
    // SIGNALS
    // =========================================================

    signal valueChangedDelayed(real value)
    signal saveClicked(real value)


    // =========================================================
    // VALUE CONTROL PROPERTIES
    // =========================================================

    /*
        value is controlled by the parent.

        Example:

        ValueControl {
            value: root.ddPower
        }

        The parent remains the source of truth.
    */
    property real value: 10

    property real minValue: 0
    property real maxValue: 100

    property real stepSize: 1
    property int decimals: 0


    // =========================================================
    // INTERNAL VALUE
    // =========================================================

    /*
        internalValue is used while the user is pressing
        + / - buttons.

        This prevents updateValue() from directly destroying
        the parent's binding to value.
    */
    property real internalValue: value


    // =========================================================
    // KEEP INTERNAL VALUE SYNCHRONIZED
    // =========================================================

    onValueChanged: {

        console.log(
            "ValueControl value changed:",
            root.value
        )

        if (root.internalValue !== root.value)
            root.internalValue = root.value
    }


    // =========================================================
    // VALUE UPDATE
    // =========================================================

    function updateValue(delta)
    {
        var newValue = Math.max(
            root.minValue,
            Math.min(
                root.maxValue,
                Number(
                    (
                        root.internalValue + delta
                    ).toFixed(root.decimals)
                )
            )
        )

        if (newValue !== root.internalValue)
        {
            root.internalValue = newValue

            /*
                Notify parent.

                Parent will normally do:

                    root.ddPower = val

                or:

                    root.ddFrequency = val
            */
            root.valueChangedDelayed(
                root.internalValue
            )
        }
    }


    // =========================================================
    // RESPONSIVE SCALE
    // =========================================================

    property real minScale: 0.75
    property real maxScale: 1.0

    property real s: Math.max(
                         minScale,
                         Math.min(
                             maxScale,
                             Math.min(width, height) / 200
                         )
                     )


    // =========================================================
    // TYPOGRAPHY
    // =========================================================

    Typography {
        id: vcTypography
        scale: root.s
    }


    // =========================================================
    // UNUSED SEND TIMER
    // =========================================================

    /*
        Kept from your original code.

        It is intentionally NOT started automatically.
    */

    Timer {
        id: sendTimer

        interval: 100
        repeat: true

        onTriggered: {
            root.valueChangedDelayed(
                root.internalValue
            )
        }
    }


    // =========================================================
    // PLUS AUTO REPEAT
    // =========================================================

    Timer {
        id: plusHoldTimer

        interval: 600
        repeat: false

        onTriggered: {
            plusRepeatTimer.start()
        }
    }


    Timer {
        id: plusRepeatTimer

        interval: 100
        repeat: true

        onTriggered: {

            if (root.internalValue >= root.maxValue) {
                stop()
                return
            }

            root.updateValue(
                root.stepSize
            )
        }
    }


    // =========================================================
    // MINUS AUTO REPEAT
    // =========================================================

    Timer {
        id: minusHoldTimer

        interval: 600
        repeat: false

        onTriggered: {
            minusRepeatTimer.start()
        }
    }


    Timer {
        id: minusRepeatTimer

        interval: 100
        repeat: true

        onTriggered: {

            if (root.internalValue <= root.minValue) {
                stop()
                return
            }

            root.updateValue(
                -root.stepSize
            )
        }
    }


    // =========================================================
    // UI
    // =========================================================

    RowLayout {
        anchors.fill: parent
        spacing: 20


        // =====================================================
        // VALUE DISPLAY
        // =====================================================

        Rectangle {

            Layout.preferredWidth: 90
            Layout.preferredHeight: 50

            radius: 10

            color: "#F3F4F6"

            border.color: "#D1D5DB"
            border.width: 1


            Text {
                anchors.centerIn: parent

                text: root.decimals > 0
                      ? Number(
                            root.internalValue
                        ).toFixed(
                            root.decimals
                        )
                      : Math.round(
                            root.internalValue
                        ).toString()

                font.pixelSize:
                    vcTypography.heading

                color: "#1F2937"
            }
        }


        // =====================================================
        // LEFT SPACER
        // =====================================================

        Item {
            Layout.fillWidth: true
        }


        // =====================================================
        // PLUS / MINUS
        // =====================================================

        Row {

            spacing: 25


            // =================================================
            // PLUS BUTTON
            // =================================================

            Rectangle {

                width: 45
                height: 50

                radius: 10

                property bool pressed: false

                property bool disabled:
                    root.internalValue >=
                    root.maxValue


                color: disabled
                       ? "#D1D5DB"
                       : "#1A4DB5"

                opacity:
                    disabled
                    ? 0.5
                    : 1.0


                Text {
                    anchors.centerIn: parent

                    text: "+"

                    font.pixelSize:
                        vcTypography.heading

                    color: "white"
                }


                MouseArea {

                    anchors.fill: parent

                    enabled:
                        !parent.disabled


                    onPressed: {

                        parent.pressed = true

                        plusHoldTimer.start()
                    }


                    onReleased: {

                        parent.pressed = false


                        if (plusHoldTimer.running)
                        {
                            plusHoldTimer.stop()

                            root.updateValue(
                                root.stepSize
                            )
                        }


                        plusRepeatTimer.stop()
                    }


                    onCanceled: {

                        parent.pressed = false

                        plusHoldTimer.stop()

                        plusRepeatTimer.stop()
                    }
                }


                scale:
                    pressed
                    ? 0.94
                    : 1.0


                Behavior on scale {

                    NumberAnimation {
                        duration: 120
                    }
                }
            }


            // =================================================
            // MINUS BUTTON
            // =================================================

            Rectangle {

                width: 45
                height: 50

                radius: 10

                property bool pressed: false

                property bool disabled:
                    root.internalValue <=
                    root.minValue


                color:
                    disabled
                    ? "#D1D5DB"
                    : "#1A4DB5"

                opacity:
                    disabled
                    ? 0.5
                    : 1.0


                Text {

                    anchors.centerIn: parent

                    text: "−"

                    font.pixelSize:
                        vcTypography.heading

                    color: "white"
                }


                MouseArea {

                    anchors.fill: parent

                    enabled:
                        !parent.disabled


                    onPressed: {

                        parent.pressed = true

                        minusHoldTimer.start()
                    }


                    onReleased: {

                        parent.pressed = false


                        if (minusHoldTimer.running)
                        {
                            minusHoldTimer.stop()

                            root.updateValue(
                                -root.stepSize
                            )
                        }


                        minusRepeatTimer.stop()
                    }


                    onCanceled: {

                        parent.pressed = false

                        minusHoldTimer.stop()

                        minusRepeatTimer.stop()
                    }
                }


                scale:
                    pressed
                    ? 0.94
                    : 1.0


                Behavior on scale {

                    NumberAnimation {
                        duration: 120
                    }
                }
            }
        }


        // =====================================================
        // RIGHT SPACER
        // =====================================================

        Item {
            Layout.fillWidth: true
        }


        // =====================================================
        // SAVE BUTTON
        // =====================================================

        Rectangle {

            Layout.preferredWidth: 60
            Layout.preferredHeight: 50

            radius: 10

            color: "#1A4DB5"

            property bool pressed: false


            Text {

                anchors.centerIn: parent

                text: "Save"

                font.pixelSize:
                    vcTypography.subHeading

                color: "white"
            }


            MouseArea {

                anchors.fill: parent


                onPressed: {
                    parent.pressed = true
                }


                onReleased: {
                    parent.pressed = false
                }


                onClicked: {

                    /*
                        Save the value currently displayed.
                    */
                    root.saveClicked(
                        root.internalValue
                    )
                }
            }


            scale:
                pressed
                ? 0.94
                : 1.0


            Behavior on scale {

                NumberAnimation {
                    duration: 120
                }
            }
        }
    }
}
