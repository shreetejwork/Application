import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import AppState 1.0

Popup {
    id: logoutPopup

    // =========================================================
    // TYPOGRAPHY
    // =========================================================

    Typography {
        id: popupTypography
        scale: 1.0
    }

    // =========================================================
    // SIGNALS
    // =========================================================

    signal confirmLogout()

    // =========================================================
    // STYLING
    // =========================================================

    property real baseWidth: 1024
    property real baseHeight: 600
    property real scale: Math.min(baseWidth / 1024, baseHeight / 600)

    // =========================================================
    // ANIMATION
    // =========================================================

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

    // =========================================================
    // POPUP SETTINGS
    // =========================================================

    parent: Overlay.overlay
    modal: true
    focus: true
    dim: true

    Overlay.modal: Rectangle {
        color: "#66000000"
    }

    closePolicy: Popup.CloseOnPressOutside

    width: 420 * scale
    height: 280 * scale

    x: (Overlay.overlay.width - width) / 2
    y: (Overlay.overlay.height - height) / 2

    background: Rectangle {
        color: "#FFFFFF"
        radius: 16 * scale
        border.color: "#E0E0E0"
        border.width: 1

        // Subtle shadow
        Rectangle {
            anchors.fill: parent
            anchors.margins: -4
            radius: parent.radius
            color: "transparent"
            border.color: "#10000000"
            border.width: 1
            z: 0
        }
    }

    // =========================================================
    // CLOSE BUTTON
    // =========================================================

    Rectangle {
        width: 32 * scale
        height: 32 * scale
        radius: width / 2
        color: closeMouse.containsMouse ? "#1A4DB5" : "#F5F7FC"

        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 8 * scale
        anchors.rightMargin: 8 * scale

        z: 999

        Text {
            anchors.centerIn: parent
            text: "✕"
            color: closeMouse.containsMouse ? "white" : "#666666"
            font.pixelSize: 16 * scale
        }

        MouseArea {
            id: closeMouse
            anchors.fill: parent
            onClicked: logoutPopup.close()
            cursorShape: Qt.PointingHandCursor
        }
    }

    // =========================================================
    // CONTENT
    // =========================================================

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24 * scale
        spacing: 16 * scale

        // ===== TITLE =====
        Text {
            id: titleText
            text: "Logout"
            font.pixelSize: popupTypography.heading * scale
            font.weight: Font.Bold
            color: "#1A4DB5"
            Layout.alignment: Qt.AlignHCenter
        }

        // ===== MESSAGE =====
        Rectangle {
            color: "transparent"
            Layout.fillHeight: true
            Layout.fillWidth: true

            Text {
                id: messageText
                anchors.fill: parent
                text: "Are you sure you want to logout?"
                font.pixelSize: popupTypography.body * scale
                color: "#333333"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.Wrap
            }
        }

        // ===== BUTTONS =====
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignBottom
            spacing: 12 * scale

            // Cancel Button
            Button {
                id: cancelButton
                Layout.fillWidth: true
                Layout.preferredHeight: 48 * scale

                background: Rectangle {
                    color: cancelMouse.containsMouse ? "#E8F0FE" : "#F5F7FC"
                    radius: 8 * scale
                    border.color: "#1A4DB5"
                    border.width: 2

                    Behavior on color {
                        ColorAnimation { duration: 200 }
                    }
                }

                contentItem: Text {
                    text: "Cancel"
                    font.pixelSize: popupTypography.body * scale
                    font.bold: true
                    color: "#1A4DB5"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                MouseArea {
                    id: cancelMouse
                    anchors.fill: parent
                    onClicked: logoutPopup.close()
                    cursorShape: Qt.PointingHandCursor
                }
            }

            // Logout Button
            Button {
                id: logoutButton
                Layout.fillWidth: true
                Layout.preferredHeight: 48 * scale

                background: Rectangle {
                    color: logoutMouse.containsMouse ? "#0D3A8F" : "#1A4DB5"
                    radius: 8 * scale

                    Behavior on color {
                        ColorAnimation { duration: 200 }
                    }
                }

                contentItem: Text {
                    text: "Logout"
                    font.pixelSize: popupTypography.body * scale
                    font.bold: true
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                MouseArea {
                    id: logoutMouse
                    anchors.fill: parent
                    onClicked: {
                        logoutPopup.confirmLogout()
                        logoutPopup.close()
                    }
                    cursorShape: Qt.PointingHandCursor
                }
            }
        }
    }

    // =========================================================
    // CONVENIENCE FUNCTIONS
    // =========================================================

    function open() {
        logoutPopup.open()
    }
}
