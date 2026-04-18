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
    property string connectedSSID: ""

    property var globalTopBar
    property var notify

    ListModel {
        id: networkModel
    }

    // ===== WIFI SCAN =====
    function scanWifi() {
        networkModel.clear()

        var result = WiFiScanner.scanNetworks()

        for (var i = 0; i < result.length; i++) {
            if (result[i].name !== "")
                networkModel.append(result[i])
        }
    }

    // ===== AUTO REFRESH =====
    Timer {
        interval: 10000
        running: root.wifiEnabled
        repeat: true
        onTriggered: scanWifi()
    }

    // ===== CONNECT =====
    function connectWifi(ssid, secured) {
        if (secured) {
            passwordPopup.ssid = ssid
            passwordPopup.open()
        } else {
            var res = WiFiScanner.connectToNetwork(ssid, "")
            connectedSSID = ssid
            if (notify) notify(res)
        }
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
            spacing: 6 * root.scale

            Text {
                text: "Network Settings"
                font.pixelSize: 26 * root.scale
                font.bold: true
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

            // ================= WIFI CARD =================
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

                                onToggledChanged: {
                                    root.wifiEnabled = toggled

                                    if (toggled) scanWifi()
                                    else networkModel.clear()
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

                        // ===== WIFI OFF =====
                        Column {
                            anchors.centerIn: parent
                            spacing: 10 * root.scale
                            visible: !root.wifiEnabled

                            Text {
                                text: "WiFi is Turned Off"
                                font.pixelSize: 15 * root.scale
                                font.bold: true
                                color: "#AAAAAA"
                            }

                            Text {
                                text: "Enable toggle to scan for networks"
                                font.pixelSize: 12 * root.scale
                                color: "#BBBBBB"
                            }
                        }

                        // ===== WIFI LIST =====
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

                            // ===== SCROLLABLE LIST =====
                            // ===== SCROLLABLE LIST =====
                            Flickable {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                anchors.top: divider.bottom   // 👈 IMPORTANT FIX

                                contentWidth: width
                                contentHeight: listColumn.height
                                clip: true

                                Column {
                                    id: listColumn
                                    width: parent.width

                                    Repeater {
                                        model: networkModel

                                        delegate: Column {
                                            width: parent.width

                                            Rectangle {
                                                id: rowBg
                                                width: parent.width
                                                height: 50 * root.scale

                                                color: model.name === root.connectedSSID
                                                       ? "#DFF5E3"
                                                       : (rowMouse.containsMouse ? "#EEF3FF" : "transparent")

                                                MouseArea {
                                                    id: rowMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                }

                                                Text {
                                                    id: lockIcon
                                                    anchors.left: parent.left
                                                    anchors.leftMargin: 14 * root.scale
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: model.secured ? "🔒" : "🌐"
                                                    font.pixelSize: 20 * root.scale
                                                }

                                                Column {
                                                    anchors.left: lockIcon.right
                                                    anchors.leftMargin: 10 * root.scale
                                                    anchors.right: signalRow.left
                                                    anchors.rightMargin: 10 * root.scale
                                                    anchors.verticalCenter: parent.verticalCenter

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

                                                            width: 6 * root.scale
                                                            height: (7 + index * 5) * root.scale
                                                            radius: 2 * root.scale
                                                            anchors.bottom: parent.bottom

                                                            color: model.signal >= thresholds[index]
                                                                   ? "#1A4DB5" : "#DDDDDD"
                                                        }
                                                    }
                                                }

                                                Rectangle {
                                                    id: connectBtn
                                                    anchors.right: parent.right
                                                    anchors.rightMargin: 14 * root.scale
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    width: 78 * root.scale
                                                    height: 28 * root.scale
                                                    radius: 14 * root.scale

                                                    color: model.name === root.connectedSSID
                                                           ? "#4CAF50"
                                                           : "#1A4DB5"

                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: model.name === root.connectedSSID
                                                              ? "Connected"
                                                              : "Connect"
                                                        font.pixelSize: 16 * root.scale
                                                        font.bold: true
                                                        color: "#FFFFFF"
                                                    }

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        onClicked: {
                                                            if (model.name !== root.connectedSSID)
                                                                connectWifi(model.name, model.secured)
                                                        }
                                                    }
                                                }
                                            }

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
                }
            }

            // ================= LAN CARD (UNCHANGED EXACTLY) =================
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

    // ===== PASSWORD POPUP =====
    Popup {
        id: passwordPopup
        modal: true
        focus: true
        width: 320 * root.scale
        height: 200 * root.scale

        property string ssid: ""

        Column {
            anchors.centerIn: parent
            spacing: 12 * root.scale

            Text {
                text: "Enter password for " + ssid
                font.pixelSize: 16 * root.scale
            }

            TextField {
                id: passwordField
                width: 250 * root.scale
                echoMode: TextInput.Password
            }

            Rectangle {
                width: 120 * root.scale
                height: 40 * root.scale
                radius: 10 * root.scale
                color: "#1A4DB5"

                Text {
                    anchors.centerIn: parent
                    text: "Connect"
                    color: "white"
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        var res = WiFiScanner.connectToNetwork(ssid, passwordField.text)
                        root.connectedSSID = ssid

                        if (notify) notify(res)

                        passwordPopup.close()
                    }
                }
            }
        }
    }
}
