import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {

    Typography {
        id: accessDeniedPopupTypography
        scale: 1.0
    }
    id:  accessDeniedPopup

    property string popupTitle: "Access Denied"
    property string popupMessage: ""

    signal logoutRequested()

    // =========================================================
    // TYPOGRAPHY FOR POPUP
    // =========================================================

    Typography {
        id: popupTypography
    }

    enter: Transition {
        ParallelAnimation {

            NumberAnimation {
                property: "opacity"
                from: 0.0
                to: 1.0
                duration: 350
                easing.type: Easing.OutQuad
            }

            NumberAnimation {
                property: "scale"
                from: 0.0
                to: 1.0
                duration: 350
                easing.type: Easing.OutQuad
            }
        }
    }

    exit: Transition {
        ParallelAnimation {

            NumberAnimation {
                property: "opacity"
                from: 1.0
                to: 0.0
                duration: 280
                easing.type: Easing.InQuad
            }

            NumberAnimation {
                property: "scale"
                from: 1.0
                to: 0.0
                duration: 280
                easing.type: Easing.InQuad
            }
        }
    }

    property real baseWidth: 1024
    property real baseHeight: 600


    modal: true
    focus: true
    dim: true


    Overlay.modal: Rectangle {
        color: "#66000000"
    }

    closePolicy: Popup.CloseOnPressOutside

    width: 520 * scale
    height: 360 * scale

    x: (Overlay.overlay.width - width) / 2
    y: (Overlay.overlay.height - height) / 2 - (70 * scale)

    background: Rectangle {
        color: "#EBEBEB"
        radius: 20 * scale
        border.color: "#C8C8C8"
        border.width: 1
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24 * scale
        spacing: 18 * scale

        // TITLE
        Text {
            text: accessDeniedPopup.popupTitle
            font.pixelSize: popupTypography.title

            color: "#1A4DB5"
            Layout.alignment: Qt.AlignHCenter
        }

        // MESSAGE BOX (like input fields style)
        Rectangle {
            Layout.fillWidth: true
            height: 80 * scale
            radius: 10 * scale
            color: "#F2F2F2"
            border.color: "#1A4DB5"

            Text {
                anchors.centerIn: parent
                text: accessDeniedPopup.popupMessage
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                width: parent.width * 0.9
                font.pixelSize: popupTypography.body

                color: "#1A1A2E"
            }
        }

        // BUTTONS (same style as login)
        Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: 20 * scale

            // CANCEL
            Rectangle {
                width: 140 * scale
                height: 50 * scale
                radius: 10 * scale
                border.color: "#1A4DB5"
                border.width: 2
                color: "white"

                Text {
                    anchors.centerIn: parent
                    text: "Close"
                    color: "#1A4DB5"

                    font.pixelSize: popupTypography.body
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: accessDeniedPopup.close()
                }
            }
        }
    }
}
