import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    Typography {
        id: componentTypography
        scale: root.scale || 1.0
    }
    id: root

    property int value: 10
    property int minValue: 0
    property int maxValue: 100

    // ================= RESPONSIVE SCALE  =================
    property real minScale: 0.75
    property real maxScale: 1.0
    property real s: Math.max(minScale, Math.min(maxScale, Math.min(width, height) / 200))
    
    // =========================================================
    // TYPOGRAPHY FOR VALUE CONTROL
    // =========================================================
    
    Typography {
        id: vcTypography
        scale: root.s
    }

    signal saveClicked(int value)

    RowLayout {
        anchors.fill: parent
        spacing: 20

        // ============ VALUE DISPLAY ============
        Rectangle {
            Layout.preferredWidth: 70
            Layout.preferredHeight: 50
            radius: 10
            color: "#F3F4F6"
            border.color: "#D1D5DB"
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: root.value
                font.pixelSize: vcTypography.body
                font.bold: true
                color: "#1F2937"
            }
        }

        Item { Layout.fillWidth: true }

        // ============ PLUS & MINUS GROUP ============
        Row {
            spacing: 25

            //  PLUS BUTTON
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
                    font.bold: true
                    color: "white"
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: !parent.disabled

                    onPressed: parent.pressed = true
                    onReleased: parent.pressed = false
                    onClicked: root.value++
                }

                scale: pressed ? 0.94 : 1.0
                Behavior on scale { NumberAnimation { duration: 120 } }
            }

            //  MINUS BUTTON
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
                    font.bold: true
                    color: "white"
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: !parent.disabled

                    onPressed: parent.pressed = true
                    onReleased: parent.pressed = false
                    onClicked: root.value--
                }

                scale: pressed ? 0.94 : 1.0
                Behavior on scale { NumberAnimation { duration: 120 } }
            }
        }

        Item { Layout.fillWidth: true }

        // ============ SAVE BUTTON ============
        Rectangle {
            Layout.preferredWidth: 60
            Layout.preferredHeight: 50
            radius: 10
            color: "#1A4DB5"

            property bool pressed: false

            Text {
                anchors.centerIn: parent
                text: "Save"
                font.pixelSize: vcTypography.small
                font.bold: true
                color: "white"
            }

            MouseArea {
                anchors.fill: parent
                onPressed: parent.pressed = true
                onReleased: parent.pressed = false
                onClicked: root.saveClicked(root.value)
            }

            scale: pressed ? 0.94 : 1.0
            Behavior on scale { NumberAnimation { duration: 120 } }
        }
    }
}
