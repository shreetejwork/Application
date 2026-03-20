import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../components"

Item {
    id: root

    property bool showTopBar: true
    property var globalTopBar

    // 🎨 THEME
    QtObject {
        id: theme
        property color bg: "#F5F7FC"
        property color panel: "#FFFFFF"
        property color border: "#E5E7EB"
        property color primary: "#4A6CF7"
        property color success: "#22C55E"
        property color danger: "#EF4444"
        property color text: "#1F2937"
    }

    function notify(msg) {
        if (globalTopBar && globalTopBar.showNotification)
            globalTopBar.showNotification(msg)
    }

    // ✨ Smooth fade-in
    opacity: 0
    Behavior on opacity { NumberAnimation { duration: 400 } }
    Component.onCompleted: opacity = 1

    RowLayout {
        anchors.fill: parent
        anchors.margins: 30
        spacing: 30

        // ================= LEFT PANEL =================
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: parent.width * 0.28

            radius: 24
            color: theme.panel
            border.color: theme.border
            border.width: 1

            Column {
                anchors.centerIn: parent
                spacing: 30

                Text {
                    text: "Controls"
                    font.pixelSize: 18
                    font.bold: true
                    color: theme.text
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                ActionButton {
                    text: "Auto Learn"
                    onClicked: root.notify("Auto Learn triggered")
                }

                ActionButton {
                    text: "Manual Validation"
                    onClicked: root.notify("Manual Validation triggered")
                }
            }
        }

        // ================= RIGHT PANEL =================
        Rectangle {
            Layout.fillHeight: true
            Layout.fillWidth: true

            radius: 24
            color: theme.panel
            border.color: theme.border
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 30
                spacing: 40

                // 🔘 Toggle Section
                Rectangle {
                    Layout.fillWidth: true
                    height: 100
                    radius: 18
                    color: "#F9FAFB"
                    border.color: theme.border

                    DDButton {
                        anchors.centerIn: parent

                        onToggledChanged: {
                            root.notify("DD toggled: " + toggled)
                        }
                    }
                }

                // 🔢 Value 1
                Rectangle {
                    Layout.fillWidth: true
                    height: 110
                    radius: 18
                    color: "#F9FAFB"
                    border.color: theme.border

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 20

                        ValueControl {
                            Layout.fillWidth: true
                            onSaveClicked: (val) => root.notify("Value1 saved: " + val)
                        }
                    }
                }

                // 🔢 Value 2
                Rectangle {
                    Layout.fillWidth: true
                    height: 110
                    radius: 18
                    color: "#F9FAFB"
                    border.color: theme.border

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 20

                        ValueControl {
                            Layout.fillWidth: true
                            onSaveClicked: (val) => root.notify("Value2 saved: " + val)
                        }
                    }
                }
            }
        }
    }
}
