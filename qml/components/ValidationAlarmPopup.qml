import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {

    id: validationAlarmPopup

    Typography {
        id: popupTypography
        scale: 1.0
    }

    property string popupTitle: "Validation Reminder"
    property string popupMessage: "This is reminder for Validation"

    property real baseWidth: 1024
    property real baseHeight: 600

    property real uiScale: Math.min(
                                  Overlay.overlay.width / baseWidth,
                                  Overlay.overlay.height / baseHeight
                              )

    modal: true
    focus: true
    dim: true

    closePolicy: Popup.NoAutoClose

    Overlay.modal: Rectangle {
        color: "#66000000"
    }

    width: 520 * uiScale
    height: 360 * uiScale

    x: (Overlay.overlay.width - width) / 2

    // Move slightly downward
    y: (Overlay.overlay.height - height) / 2 + (35 * uiScale)

    //------------------------------------------------------
    // Open animation
    //------------------------------------------------------

    enter: Transition {

        ParallelAnimation {

            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: 350
                easing.type: Easing.OutQuad
            }

            NumberAnimation {
                property: "scale"
                from: 0.85
                to: 1.0
                duration: 350
                easing.type: Easing.OutBack
            }
        }
    }

    //------------------------------------------------------
    // Close animation
    //------------------------------------------------------

    exit: Transition {

        ParallelAnimation {

            NumberAnimation {
                property: "opacity"
                from: 1
                to: 0
                duration: 250
                easing.type: Easing.InQuad
            }

            NumberAnimation {
                property: "scale"
                from: 1
                to: 0.85
                duration: 250
                easing.type: Easing.InQuad
            }
        }
    }

    //------------------------------------------------------
    // Remove Popup default background
    //------------------------------------------------------

    background: Item {

        id: popupContent

        implicitWidth: validationAlarmPopup.width
        implicitHeight: validationAlarmPopup.height

        transformOrigin: Item.Center

        //--------------------------------------------------
        // Glow Border
        //--------------------------------------------------

        Rectangle {

            id: glowBorder

            anchors.centerIn: parent

            width: parent.width + 12 * uiScale
            height: parent.height + 12 * uiScale

            radius: 26 * uiScale

            color: "transparent"

            border.color: "#1A4DB5"
            border.width: 3

            opacity: 0.15
        }

        //--------------------------------------------------
        // Main Background
        //--------------------------------------------------

        Rectangle {

            anchors.fill: parent

            radius: 20 * uiScale

            color: "#EBEBEB"

            border.color: "#C8C8C8"
            border.width: 1
        }

        //--------------------------------------------------
        // Content
        //--------------------------------------------------

        ColumnLayout {

            anchors.fill: parent

            anchors.margins: 24 * uiScale

            spacing: 18 * uiScale

            Text {

                Layout.alignment: Qt.AlignHCenter

                Layout.bottomMargin: 35 * uiScale

                text: validationAlarmPopup.popupTitle

                font.pixelSize: popupTypography.title

                color: "#1A4DB5"
            }

            Rectangle {

                Layout.fillWidth: true

                height: 82 * uiScale

                radius: 10 * uiScale

                color: "#F2F2F2"

                border.color: "#1A4DB5"

                Text {

                    anchors.centerIn: parent

                    width: parent.width * 0.9

                    text: validationAlarmPopup.popupMessage

                    wrapMode: Text.WordWrap

                    horizontalAlignment: Text.AlignHCenter

                    font.pixelSize: popupTypography.body

                    color: "#1A1A2E"
                }
            }

            Item {
                Layout.fillHeight: true
            }

            Row {

                Layout.alignment: Qt.AlignHCenter

                spacing: 30 * uiScale

                Rectangle {

                    width: 140 * uiScale
                    height: 50 * uiScale

                    radius: 10 * uiScale

                    color: "white"

                    border.color: "#1A4DB5"
                    border.width: 2

                    Text {

                        anchors.centerIn: parent

                        text: "Skip"

                        color: "#1A4DB5"

                        font.pixelSize: popupTypography.body
                    }

                    MouseArea {

                        anchors.fill: parent

                        onClicked: validationAlarmPopup.close()
                    }
                }

                Rectangle {

                    width: 140 * uiScale
                    height: 50 * uiScale

                    radius: 10 * uiScale

                    color: "#1A4DB5"

                    Text {

                        anchors.centerIn: parent

                        text: "Continue"

                        color: "white"

                        font.pixelSize: popupTypography.body
                    }

                    MouseArea {

                        anchors.fill: parent

                        onClicked: {

                            validationAlarmPopup.close()

                            console.log("Validation Started")
                        }
                    }
                }
            }
        }
    }

    //------------------------------------------------------
    // Heartbeat Animation
    //------------------------------------------------------

    SequentialAnimation {

        running: validationAlarmPopup.visible

        loops: Animation.Infinite

        NumberAnimation {

            target: popupContent

            property: "scale"

            from: 1.0
            to: 1.02

            duration: 650

            easing.type: Easing.InOutSine
        }

        NumberAnimation {

            target: popupContent

            property: "scale"

            from: 1.02
            to: 1.0

            duration: 650

            easing.type: Easing.InOutSine
        }

        PauseAnimation {
            duration: 400
        }
    }

    //------------------------------------------------------
    // Glow Animation
    //------------------------------------------------------

    SequentialAnimation {

        running: validationAlarmPopup.visible

        loops: Animation.Infinite

        NumberAnimation {

            target: glowBorder

            property: "opacity"

            from: 0.12
            to: 0.35

            duration: 700

            easing.type: Easing.InOutQuad
        }

        NumberAnimation {

            target: glowBorder

            property: "opacity"

            from: 0.35
            to: 0.12

            duration: 700

            easing.type: Easing.InOutQuad
        }
    }
}
