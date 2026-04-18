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

    property var globalTopBar
    property var notify

    // ✅ UPDATED MODEL (EMPTY)
    ListModel {
        id: networkModel
    }

    // ✅ FUNCTION TO LOAD REAL WIFI
    function scanWifi() {
        networkModel.clear()

        var result = WiFiScanner.scanNetworks()

        for (var i = 0; i < result.length; i++) {
            if (result[i].name !== "") {   // ignore hidden SSIDs
                networkModel.append(result[i])
            }
        }
    }

    // ✅ AUTO REFRESH
    Timer {
        interval: 10000
        running: root.wifiEnabled
        repeat: true
        onTriggered: scanWifi()
    }

    Rectangle {
        anchors.fill: parent
        color: "#F5F7FC"
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 30 * root.scale
        spacing: 20 * root.scale

        Column {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignLeft
            spacing: 6 * root.scale

            Text {
                text: "Network Settings"
                font.pixelSize: 26 * root.scale
                font.bold: true
                font.letterSpacing: 0.5
                color: "#1A4DB5"
            }

            Rectangle {
                width: 90 * root.scale
                height: 4 * root.scale
                radius: 2 * root.scale
                color: "#1A4DB5"
            }
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

                                // ✅ UPDATED TO TRIGGER SCAN
                                onToggledChanged: {
                                    root.wifiEnabled = toggled

                                    if (toggled) {
                                        scanWifi()
                                    } else {
                                        networkModel.clear()
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 16 * root.scale
                        color: "#F8F9FB"
                        border.color: "#E0E0E0"
                        border.width: 1
                        clip: true

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

                        Column {
                            anchors.fill: parent
                            anchors.topMargin: 16 * root.scale
                            anchors.bottomMargin: 8 * root.scale
                            visible: root.wifiEnabled
                            spacing: 0

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

                            Rectangle {
                                width: parent.width
                                height: 2
                                color: "#E8E8E8"
                            }

                            // ✅ SAME UI — NOW FILLED WITH REAL DATA
                            Repeater {
                                model: networkModel

                                delegate: Column {
                                    width: parent ? parent.width : 0

                                    Rectangle {
                                        width: parent.width
                                        height: 50 * root.scale
                                        color: "transparent"

                                        Text {
                                            anchors.left: parent.left
                                            anchors.leftMargin: 14 * root.scale
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: model.secured ? "🔒" : "🌐"
                                            font.pixelSize: 20 * root.scale
                                        }

                                        Text {
                                            anchors.left: parent.left
                                            anchors.leftMargin: 50 * root.scale
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: model.name
                                            font.pixelSize: 18 * root.scale
                                            font.bold: true
                                        }
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
                    spacing: 18 * root.scale

                    Text {
                        text: "LAN"
                        font.pixelSize: 26 * root.scale
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

                        Column {
                            anchors.fill: parent
                            anchors.margins: 20 * root.scale
                            spacing: 18 * root.scale

                            // ===== INPUT FIELD COMPONENT =====
                            function inputField(idRef, placeholder) {
                                return Qt.createQmlObject(`
                                    import QtQuick
                                    Item {
                                        width: parent.width
                                        height: 40

                                        TextField {
                                            id: input
                                            anchors.fill: parent

                                            font.pixelSize: ${22} * root.scale
                                            font.bold: true
                                            color: "#1A4DB5"

                                            background: null
                                            padding: 0

                                            property bool showPlaceholder: text.length === 0 && !activeFocus

                                            Text {
                                                anchors.fill: parent
                                                verticalAlignment: Text.AlignVCenter
                                                text: "${placeholder}"
                                                color: "#A0AABF"
                                                visible: input.showPlaceholder
                                                font.pixelSize: ${22} * root.scale
                                            }
                                        }

                                        Rectangle {
                                            anchors.bottom: parent.bottom
                                            width: parent.width
                                            height: 1.5 * root.scale
                                            color: input.activeFocus ? "#1A4DB5" : "#E3E7F0"
                                        }
                                    }
                                `, parent)
                            }

                            // ===== FIELDS =====
                            Item {
                                id: ipWrapper
                                width: parent.width
                                height: 40 * root.scale

                                TextField {
                                    id: ipField
                                    anchors.fill: parent
                                    font.pixelSize: 22 * root.scale
                                    font.bold: true
                                    color: "#1A4DB5"
                                    background: null
                                    padding: 0

                                    property bool showPlaceholder: text.length === 0 && !activeFocus

                                    Text {
                                        anchors.fill: parent
                                        verticalAlignment: Text.AlignVCenter
                                        text: "IP Address (192.168.1.50)"
                                        color: "#A0AABF"
                                        visible: ipField.showPlaceholder
                                        font.pixelSize: 22 * root.scale
                                    }
                                }

                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    width: parent.width
                                    height: 1.5 * root.scale
                                    color: ipField.activeFocus ? "#1A4DB5" : "#E3E7F0"
                                }
                            }

                            Item {
                                width: parent.width
                                height: 40 * root.scale

                                TextField {
                                    id: subnetField
                                    anchors.fill: parent
                                    font.pixelSize: 22 * root.scale
                                    font.bold: true
                                    color: "#1A4DB5"
                                    background: null
                                    padding: 0

                                    property bool showPlaceholder: text.length === 0 && !activeFocus

                                    Text {
                                        anchors.fill: parent
                                        verticalAlignment: Text.AlignVCenter
                                        text: "Subnet (24)"
                                        color: "#A0AABF"
                                        visible: subnetField.showPlaceholder
                                        font.pixelSize: 22 * root.scale
                                    }
                                }

                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    width: parent.width
                                    height: 1.5 * root.scale
                                    color: subnetField.activeFocus ? "#1A4DB5" : "#E3E7F0"
                                }
                            }

                            Item {
                                width: parent.width
                                height: 40 * root.scale

                                TextField {
                                    id: gatewayField
                                    anchors.fill: parent
                                    font.pixelSize: 22 * root.scale
                                    font.bold: true
                                    color: "#1A4DB5"
                                    background: null
                                    padding: 0

                                    property bool showPlaceholder: text.length === 0 && !activeFocus

                                    Text {
                                        anchors.fill: parent
                                        verticalAlignment: Text.AlignVCenter
                                        text: "Gateway"
                                        color: "#A0AABF"
                                        visible: gatewayField.showPlaceholder
                                        font.pixelSize: 22 * root.scale
                                    }
                                }

                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    width: parent.width
                                    height: 1.5 * root.scale
                                    color: gatewayField.activeFocus ? "#1A4DB5" : "#E3E7F0"
                                }
                            }

                            Item {
                                width: parent.width
                                height: 40 * root.scale

                                TextField {
                                    id: dnsField
                                    anchors.fill: parent
                                    text: "8.8.8.8"
                                    font.pixelSize: 22 * root.scale
                                    font.bold: true
                                    color: "#1A4DB5"
                                    background: null
                                    padding: 0

                                    property bool showPlaceholder: text.length === 0 && !activeFocus

                                    Text {
                                        anchors.fill: parent
                                        verticalAlignment: Text.AlignVCenter
                                        text: "DNS"
                                        color: "#A0AABF"
                                        visible: dnsField.showPlaceholder
                                        font.pixelSize: 22 * root.scale
                                    }
                                }

                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    width: parent.width
                                    height: 1.5 * root.scale
                                    color: dnsField.activeFocus ? "#1A4DB5" : "#E3E7F0"
                                }
                            }

                            // ===== BUTTON =====
                            Rectangle {
                                width: parent.width
                                height: 50 * root.scale
                                radius: 12 * root.scale
                                color: "#1A4DB5"

                                Text {
                                    anchors.centerIn: parent
                                    text: "Apply Static IP"
                                    color: "#FFFFFF"
                                    font.bold: true
                                    font.pixelSize: 20 * root.scale
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        var result = NetworkManager.setStaticIP(
                                            "eth0",
                                            ipField.text,
                                            subnetField.text,
                                            gatewayField.text,
                                            dnsField.text
                                        )

                                        resultText.text = result

                                        if (notify)
                                            notify(result)
                                    }
                                }
                            }

                            Text {
                                id: resultText
                                text: ""
                                color: "#1A4DB5"
                                font.pixelSize: 16 * root.scale
                                wrapMode: Text.Wrap
                            }
                        }
                    }
                }
            }

        }
    }
}
