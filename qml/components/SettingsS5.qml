import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    anchors.fill: parent

    property real baseWidth: 1024
    property real baseHeight: 600
    property real scale: Math.min(width / baseWidth, height / baseHeight)

    property bool wifiEnabled: false

    ListModel {
        id: networkModel
        ListElement { name: "HomeNetwork_5G";  signal: 90; secured: true  }
        ListElement { name: "Office_WiFi";     signal: 75; secured: true  }
        ListElement { name: "GuestNetwork";    signal: 60; secured: false }
        ListElement { name: "Neighbor_2G";     signal: 45; secured: true  }
        ListElement { name: "CoffeeShop_Free"; signal: 30; secured: false }
    }

    Rectangle {
        anchors.fill: parent
        color: "#F5F7FC"
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 30 * root.scale
        spacing: 20 * root.scale

        Text {
            id: titleText
            text: "Network Settings"
            font.pixelSize: 26 * root.scale
            font.bold: true
            color: "#1A4DB5"
            Layout.leftMargin: 25 * root.scale
            Layout.topMargin: 20 * root.scale
        }

        Rectangle {
            width: 80 * root.scale
            height: 4 * root.scale
            radius: 2 * root.scale
            color: "#1A4DB5"
            Layout.leftMargin: 25 * root.scale
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 50 * root.scale

            // ===== WIFI CARD =====
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 24 * root.scale
                color: "#FFFFFF"
                border.color: "#DADADA"
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20 * root.scale
                    spacing: 14 * root.scale

                    // ---- Header: WIFI + Toggle (UNCHANGED) ----
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16 * root.scale

                        Text {
                            text: "WIFI"
                            font.pixelSize: 26 * root.scale
                            font.bold: true
                            color: "#1A4DB5"
                        }

                        Item {
                            width: 120 * root.scale
                            height: 44 * root.scale
                            Layout.leftMargin: 70 * root.scale

                            DDButton {
                                anchors.centerIn: parent
                                width: 120 * root.scale
                                height: 44 * root.scale
                                toggled: root.wifiEnabled
                                knobSize: 35 * root.scale
                                useSymbols: true
                                onToggledChanged: {
                                    root.wifiEnabled = toggled
                                }
                            }
                        }
                    }

                    // ---- Content Area ----
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 16 * root.scale
                        color: "#F8F9FB"
                        border.color: "#E0E0E0"
                        border.width: 1
                        clip: true

                        // WiFi OFF message
                        Column {
                            anchors.centerIn: parent
                            spacing: 10 * root.scale
                            visible: !root.wifiEnabled

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "WiFi is Turned Off"
                                font.pixelSize: 15 * root.scale
                                font.bold: true
                                color: "#AAAAAA"
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "Enable toggle to scan for networks"
                                font.pixelSize: 12 * root.scale
                                color: "#BBBBBB"
                            }
                        }

                        // WiFi ON — Network List
                        Column {
                            anchors.fill: parent
                            anchors.topMargin: 16 * root.scale
                            anchors.bottomMargin: 8 * root.scale
                            visible: root.wifiEnabled
                            spacing: 0

                            // Section header
                            Item {
                                width: parent.width
                                height: 35 * root.scale

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 20 * root.scale
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Available Networks"
                                    font.pixelSize: 20 * root.scale
                                    font.bold: true
                                    font.letterSpacing: 0.6
                                    color: "#1A4DB5"
                                }

                                Text {
                                    anchors.right: parent.right
                                    anchors.rightMargin: 20 * root.scale
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: networkModel.count + " found"
                                    font.pixelSize: 15 * root.scale
                                    color: "#AAAAAA"
                                }
                            }

                            // Header separator
                            Rectangle {
                                width: parent.width
                                height: 2
                                color: "#E8E8E8"
                            }

                            // Network rows
                            Repeater {
                                model: networkModel

                                delegate: Column {
                                    width: parent ? parent.width : 0
                                    spacing: 0

                                    Rectangle {
                                        id: rowBg
                                        width: parent.width
                                        height: 50 * root.scale
                                        color: rowMouse.containsMouse ? "#EEF3FF" : "transparent"

                                        MouseArea {
                                            id: rowMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                        }

                                        // Fixed-position items using anchors for perfect alignment
                                        // Lock icon — fixed left
                                        Text {
                                            id: lockIcon
                                            anchors.left: parent.left
                                            anchors.leftMargin: 14 * root.scale
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: model.secured ? "🔒" : "🌐"
                                            font.pixelSize: 20 * root.scale
                                        }

                                        // Network name + status — fills middle space
                                        Column {
                                            anchors.left: lockIcon.right
                                            anchors.leftMargin: 10 * root.scale
                                            anchors.right: signalRow.left
                                            anchors.rightMargin: 10 * root.scale
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 3 * root.scale

                                            Text {
                                                width: parent.width
                                                text: model.name
                                                font.pixelSize: 19 * root.scale
                                                font.bold: true
                                                color: "#1C1C1C"
                                                elide: Text.ElideRight
                                            }

                                            Text {
                                                text: model.secured ? "Secured" : "Open Network"
                                                font.pixelSize: 18 * root.scale
                                                color: model.secured ? "#4CAF50" : "#FF9800"
                                            }
                                        }

                                        // Signal bars — fixed right of name, left of button
                                        Row {
                                            id: signalRow
                                            anchors.right: connectBtn.left
                                            anchors.rightMargin: 12 * root.scale
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 3 * root.scale

                                            Repeater {
                                                model: 4
                                                delegate: Rectangle {
                                                    property var thresholds: [25, 50, 70, 90]
                                                    property int netSignal: model.signal

                                                    width: 6 * root.scale
                                                    height: (7 + index * 5) * root.scale
                                                    radius: 2 * root.scale
                                                    anchors.bottom: parent ? parent.bottom : undefined
                                                    color: netSignal >= thresholds[index]
                                                           ? "#1A4DB5" : "#DDDDDD"
                                                }
                                            }
                                        }

                                        // Connect button — fixed right edge
                                        Rectangle {
                                            id: connectBtn
                                            anchors.right: parent.right
                                            anchors.rightMargin: 14 * root.scale
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 78 * root.scale
                                            height: 28 * root.scale
                                            radius: 14 * root.scale
                                            color: "#1A4DB5"

                                            Text {
                                                anchors.centerIn: parent
                                                text: "Connect"
                                                font.pixelSize: 16 * root.scale
                                                font.bold: true
                                                color: "#FFFFFF"
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                            }
                                        }
                                    }

                                    // Row divider (skip last)
                                    Rectangle {
                                        visible: index < networkModel.count - 1
                                        width: parent.width - 28 * root.scale
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        height: 2
                                        color: "#EFEFEF"
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ===== LAN CARD =====
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 24 * root.scale
                color: "#FFFFFF"
                border.color: "#DADADA"
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20 * root.scale
                    spacing: 10 * root.scale

                    Text {
                        text: "LAN"
                        font.pixelSize: 24 * root.scale
                        font.bold: true
                        color: "#1A4DB5"
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 16 * root.scale
                        color: "#F8F9FB"
                        border.color: "#E0E0E0"
                        border.width: 1
                    }
                }
            }
        }
    }
}
