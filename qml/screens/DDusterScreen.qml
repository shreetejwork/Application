import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../components"

Item {
    id: root

    property bool showTopBar: true
    property var globalTopBar

    function notify(msg) {
        if (globalTopBar && globalTopBar.showNotification)
            globalTopBar.showNotification(msg)
    }

    opacity: 0
    Behavior on opacity { NumberAnimation { duration: 400 } }
    Component.onCompleted: opacity = 1

    Rectangle {
        anchors.fill: parent
        color: "#FAFBFC"

        RowLayout {
            anchors.fill: parent
            anchors.topMargin: showTopBar ? topBar.height : 20
            anchors.leftMargin: 35
            anchors.rightMargin: 35
            anchors.bottomMargin: 35
            spacing: 30

            // =========== LEFT SIDE ===========
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                spacing: 10

                //Heading
                Column {
                    spacing: 4

                    Text {
                        text: "Batch Menu"
                        font.pixelSize: 18
                        font.bold: true
                        color: "#1A4DB5"
                    }

                    Rectangle {
                        width: 40
                        height: 3
                        radius: 2
                        color: "#1A4DB5"
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 16
                    color: "#FFFFFF"
                    border.color: "#E5E7EB"
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 24
                        spacing: 40

                        Item { Layout.fillHeight: true }



                        Item { Layout.fillHeight: true }
                    }
                }
            }

            // =========== RIGHT SIDE ===========
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                spacing: 10

                // Heading
                Column {
                    spacing: 4

                    Text {
                        text: "D Duster Menu"
                        font.pixelSize: 18
                        font.bold: true
                        color: "#1A4DB5"
                    }

                    Rectangle {
                        width: 40
                        height: 3
                        radius: 2
                        color: "#1A4DB5"
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 20

                    // DD ON/OFF
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 140
                        radius: 16
                        color: "#FFFFFF"
                        border.color: "#E5E7EB"
                        border.width: 1

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 20
                            spacing: 12

                            Text {
                                text: "DD ON/OFF"
                                font.pixelSize: 13
                                font.bold: true
                                color: "#6B7280"
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Item { Layout.fillHeight: true }

                            DDButton {
                                Layout.alignment: Qt.AlignHCenter

                                onToggledChanged: {
                                    globalTopBar.showNotification(
                                        toggled ? "✓ DD ON" : "✓ DD OFF"
                                    )
                                }
                            }

                            Item { Layout.fillHeight: true }
                        }
                    }


                    // PARAMETER 1
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 16
                        color: "#FFFFFF"
                        border.color: "#E5E7EB"
                        border.width: 1

                        //  Title (Top-Left)
                        Text {
                            text: "Power (Volt)"
                            font.pixelSize: 13
                            font.bold: true
                            color: "#6B7280"

                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.margins: 16
                        }


                        Item {
                            anchors.fill: parent

                            ValueControl {
                                anchors.centerIn: parent
                                anchors.verticalCenterOffset: -parent.height * 0.1
                                width: parent.width * 0.7

                                minValue: 0
                                maxValue: 100
                                value: 0

                                onSaveClicked: (val) =>
                                    root.globalTopBar.showNotification("✓ DD Power Saved " + val)
                            }
                        }
                    }

                    // PARAMETER 2
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 16
                        color: "#FFFFFF"
                        border.color: "#E5E7EB"
                        border.width: 1

                        //  Title (Top-Left)
                        Text {
                            text: "Frequency (Hz)"
                            font.pixelSize: 13
                            font.bold: true
                            color: "#6B7280"

                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.margins: 16
                        }


                        Item {
                            anchors.fill: parent

                            ValueControl {
                                anchors.centerIn: parent
                                anchors.verticalCenterOffset: -parent.height * 0.1
                                width: parent.width * 0.7


                                minValue: 25
                                maxValue: 50
                                value: 25

                                onSaveClicked: (val) =>
                                    root.globalTopBar.showNotification("✓ DD Frequency Saved " + val)
                            }
                        }
                    }
                }
            }
        }
    }
}
