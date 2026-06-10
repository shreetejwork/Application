import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import AppState 1.0

Item {
    Typography {
        id: componentTypography
        scale: root.scale || 1.0
    }

    id: root

    AccessDeniedPopup {
        id: accessDeniedPopup
    }

    // =========================================================
    // VALUE CONTROL PROPERTIES
    // =========================================================

    property real value: 10
    property real minValue: 0
    property real maxValue: 100

    // Integer by default
    property real stepSize: 1
    property int decimals: 0

    // ================= RESPONSIVE SCALE =================

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
    // TYPOGRAPHY FOR VALUE CONTROL
    // =========================================================

    Typography {
        id: vcTypography
        scale: root.s
    }

    signal saveClicked(real value)

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
            if (root.value < root.maxValue) {
                root.value = Math.min(
                                 root.maxValue,
                                 Number(
                                     (root.value + root.stepSize)
                                     .toFixed(root.decimals)
                                 )
                             )
            } else {
                stop()
            }
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
            if (root.value > root.minValue) {
                root.value = Math.max(
                                 root.minValue,
                                 Number(
                                     (root.value - root.stepSize)
                                     .toFixed(root.decimals)
                                 )
                             )
            } else {
                stop()
            }
        }
    }

    // =========================================================
    // UI
    // =========================================================

    RowLayout {
        anchors.fill: parent
        spacing: 20

        // ================= VALUE DISPLAY =================

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
                      ? Number(root.value).toFixed(root.decimals)
                      : Math.round(root.value).toString()

                font.pixelSize: vcTypography.heading
                color: "#1F2937"
            }
        }

        Item {
            Layout.fillWidth: true
        }

        // ================= PLUS & MINUS =================

        Row {
            spacing: 25

            // ================= PLUS =================

            Rectangle {
                width: 45
                height: 50
                radius: 10

                property bool pressed: false
                property bool disabled: root.value >= root.maxValue

                color: disabled ? "#D1D5DB" : "#1A4DB5"
                opacity: disabled ? 0.5 : 1.0

                Text {
                    anchors.centerIn: parent
                    text: "+"
                    font.pixelSize: vcTypography.heading
                    color: "white"
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: !parent.disabled

                    onPressed: {
                        parent.pressed = true
                        plusHoldTimer.start()
                    }

                    onReleased: {
                        parent.pressed = false

                        // Short click
                        if (plusHoldTimer.running) {
                            plusHoldTimer.stop()

                            if (root.value < root.maxValue) {
                                root.value = Math.min(
                                                 root.maxValue,
                                                 Number(
                                                     (root.value + root.stepSize)
                                                     .toFixed(root.decimals)
                                                 )
                                             )
                            }
                        }

                        plusRepeatTimer.stop()
                    }

                    onCanceled: {
                        parent.pressed = false
                        plusHoldTimer.stop()
                        plusRepeatTimer.stop()
                    }
                }

                scale: pressed ? 0.94 : 1.0

                Behavior on scale {
                    NumberAnimation {
                        duration: 120
                    }
                }
            }

            // ================= MINUS =================

            Rectangle {
                width: 45
                height: 50
                radius: 10

                property bool pressed: false
                property bool disabled: root.value <= root.minValue

                color: disabled ? "#D1D5DB" : "#1A4DB5"
                opacity: disabled ? 0.5 : 1.0

                Text {
                    anchors.centerIn: parent
                    text: "−"
                    font.pixelSize: vcTypography.heading
                    color: "white"
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: !parent.disabled

                    onPressed: {
                        parent.pressed = true
                        minusHoldTimer.start()
                    }

                    onReleased: {
                        parent.pressed = false

                        // Short click
                        if (minusHoldTimer.running) {
                            minusHoldTimer.stop()

                            if (root.value > root.minValue) {
                                root.value = Math.max(
                                                 root.minValue,
                                                 Number(
                                                     (root.value - root.stepSize)
                                                     .toFixed(root.decimals)
                                                 )
                                             )
                            }
                        }

                        minusRepeatTimer.stop()
                    }

                    onCanceled: {
                        parent.pressed = false
                        minusHoldTimer.stop()
                        minusRepeatTimer.stop()
                    }
                }

                scale: pressed ? 0.94 : 1.0

                Behavior on scale {
                    NumberAnimation {
                        duration: 120
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
        }

        // ================= SAVE BUTTON =================

        Rectangle {
            Layout.preferredWidth: 60
            Layout.preferredHeight: 50

            radius: 10
            color: "#1A4DB5"

            property bool pressed: false

            Text {
                anchors.centerIn: parent
                text: "Save"
                font.pixelSize: vcTypography.subHeading
                color: "white"
            }

            MouseArea {
                anchors.fill: parent

                onPressed: parent.pressed = true
                onReleased: parent.pressed = false

                onClicked: {

                    root.saveClicked(root.value)
                }
            }

            scale: pressed ? 0.94 : 1.0

            Behavior on scale {
                NumberAnimation {
                    duration: 120
                }
            }
        }
    }
}
