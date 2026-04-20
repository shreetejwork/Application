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
    property bool isConnecting: false

    property var globalTopBar
    property var notify

    // ✅ Load current WiFi on start
    Component.onCompleted: {
        WiFiScanner.scan()
    }

    function scanWifi() {
        WiFiScanner.scan()
    }

    function connectWifi(ssid) {
        passwordField.text = ""
        passwordPopup.ssid = ssid
        passwordPopup.errorMessage = ""
        passwordPopup.successMessage = ""
        passwordPopup.isConnecting = false
        passwordPopup.open()
    }

    Connections {
        target: WiFiScanner
        onNetworksChanged: {
            // Update UI when networks are scanned
            console.log("Networks updated:", WiFiScanner.networks.length)
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
                                    WiFiScanner.enableWifi(toggled)
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

                        // ===== WIFI CONTENT =====
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 16 * root.scale
                            visible: root.wifiEnabled
                            spacing: 14 * root.scale

                            // ===== SCAN BUTTON =====
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 50 * root.scale
                                radius: 8 * root.scale
                                color: "#1A4DB5"

                                Text {
                                    anchors.centerIn: parent
                                    text: "Scan Networks"
                                    font.pixelSize: 16 * root.scale
                                    font.bold: true
                                    color: "#FFFFFF"
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: scanWifi()
                                }
                            }

                            // ===== AVAILABLE NETWORKS LIST =====
                            ListView {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true

                                model: WiFiScanner.networks
                                spacing: 10 * root.scale

                                delegate: Rectangle {
                                    width: ListView.view.width
                                    height: 60 * root.scale
                                    radius: 10 * root.scale

                                    color: "#FFFFFF"
                                    border.color: "#E5E7EB"
                                    border.width: 1

                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 12 * root.scale
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData
                                        font.pixelSize: 16 * root.scale
                                        font.bold: true
                                        color: "#1F2937"
                                        elide: Text.ElideRight
                                        width: parent.width - 100 * root.scale
                                    }

                                    Rectangle {
                                        anchors.right: parent.right
                                        anchors.rightMargin: 12 * root.scale
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 70 * root.scale
                                        height: 32 * root.scale
                                        radius: 8 * root.scale
                                        color: "#1A4DB5"

                                        Text {
                                            anchors.centerIn: parent
                                            text: "Connect"
                                            font.pixelSize: 13 * root.scale
                                            font.bold: true
                                            color: "#FFFFFF"
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            enabled: !root.isConnecting
                                            onClicked: connectWifi(modelData)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ================= LAN CARD =================
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
        width: 400 * root.scale
        height: 320 * root.scale
        closePolicy: Popup.NoAutoClose

        property string ssid: ""
        property string errorMessage: ""
        property string successMessage: ""
        property bool isConnecting: false

        background: Rectangle {
            radius: 16 * root.scale
            color: "#FFFFFF"
            border.color: "#E5E7EB"
            border.width: 1

            Rectangle {
                anchors.fill: parent
                anchors.margins: -3
                radius: parent.radius
                color: "#F8F9FE"
                z: -1
            }
        }

        Column {
            anchors.fill: parent
            anchors.margins: 28 * root.scale
            spacing: 18 * root.scale

            // ===== TITLE =====
            Column {
                spacing: 8 * root.scale

                Text {
                    text: "Connect to WiFi"
                    font.pixelSize: 22 * root.scale
                    font.bold: true
                    color: "#1A4DB5"
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "\"" + ssid + "\""
                    font.pixelSize: 16 * root.scale
                    color: "#1F2937"
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }

            // ===== PASSWORD INPUT =====
            Item {
                width: parent.width
                height: 50 * root.scale

                Rectangle {
                    anchors.fill: parent
                    radius: 8 * root.scale
                    color: "#F3F4F6"
                    border.color: passwordField.activeFocus ? "#1A4DB5" : "#D1D5DB"
                    border.width: passwordField.activeFocus ? 2 : 1
                }

                TextField {
                    id: passwordField
                    anchors.fill: parent
                    anchors.margins: 12 * root.scale
                    font.pixelSize: 16 * root.scale
                    color: "#1F2937"
                    echoMode: TextInput.Password
                    background: null
                    padding: 0

                    property bool showPlaceholder: text.length === 0 && !activeFocus

                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        text: "Enter WiFi password"
                        color: "#9CA3AF"
                        visible: passwordField.showPlaceholder
                        font.pixelSize: 16 * root.scale
                    }
                }

                // Show/Hide toggle
                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: 12 * root.scale
                    anchors.verticalCenter: parent.verticalCenter
                    width: 32 * root.scale
                    height: 32 * root.scale
                    color: "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: passwordField.echoMode === TextInput.Password ? "👁" : "✓"
                        font.pixelSize: 16 * root.scale
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            passwordField.echoMode = passwordField.echoMode === TextInput.Password
                                                   ? TextInput.Normal : TextInput.Password
                        }
                    }
                }
            }

            // ===== ERROR MESSAGE =====
            Rectangle {
                width: parent.width
                height: successText.visible ? 0 : (errorText.visible ? 38 * root.scale : 0)
                radius: 6 * root.scale
                color: "#FEE2E2"
                border.color: "#FECACA"
                border.width: 1
                visible: errorText.visible
                clip: true

                Text {
                    id: errorText
                    anchors.fill: parent
                    anchors.margins: 10 * root.scale
                    text: passwordPopup.errorMessage
                    color: "#DC2626"
                    font.pixelSize: 13 * root.scale
                    wrapMode: Text.Wrap
                    verticalAlignment: Text.AlignVCenter
                }
            }

            // ===== SUCCESS MESSAGE =====
            Rectangle {
                width: parent.width
                height: successText.visible ? 38 * root.scale : 0
                radius: 6 * root.scale
                color: "#DCFCE7"
                border.color: "#86EFAC"
                border.width: 1
                visible: successText.visible
                clip: true

                Text {
                    id: successText
                    anchors.fill: parent
                    anchors.margins: 10 * root.scale
                    text: passwordPopup.successMessage
                    color: "#16A34A"
                    font.pixelSize: 13 * root.scale
                    wrapMode: Text.Wrap
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Item { Layout.fillHeight: true }

            // ===== BUTTON ROW =====
            Row {
                spacing: 12 * root.scale
                anchors.horizontalCenter: parent.horizontalCenter

                Rectangle {
                    width: 110 * root.scale
                    height: 40 * root.scale
                    radius: 8 * root.scale
                    color: "#F3F4F6"
                    border.color: "#D1D5DB"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        color: "#374151"
                        font.pixelSize: 15 * root.scale
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !passwordPopup.isConnecting
                        onClicked: passwordPopup.close()
                    }
                }

                Rectangle {
                    width: 110 * root.scale
                    height: 40 * root.scale
                    radius: 8 * root.scale
                    color: passwordPopup.isConnecting ? "#9CA3AF" : "#1A4DB5"

                    Text {
                        anchors.centerIn: parent
                        text: passwordPopup.isConnecting ? "Connecting..." : "Connect"
                        color: "#FFFFFF"
                        font.pixelSize: 15 * root.scale
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !passwordPopup.isConnecting
                        onClicked: {
                            if (passwordField.text.length === 0) {
                                passwordPopup.errorMessage = "Please enter a password"
                                passwordPopup.successMessage = ""
                                return
                            }

                            passwordPopup.isConnecting = true
                            var success = WiFiScanner.connectTo(passwordPopup.ssid, passwordField.text)

                            if (success) {
                                passwordPopup.successMessage = "✓ Connected successfully!"
                                passwordPopup.errorMessage = ""
                                if (notify) notify("Connected to " + passwordPopup.ssid)
                                closeTimer.start()
                            } else {
                                passwordPopup.errorMessage = "✗ Connection failed"
                                passwordPopup.successMessage = ""
                                if (notify) notify("Connection failed")
                            }

                            passwordPopup.isConnecting = false
                        }
                    }
                }
            }
        }

        Timer {
            id: closeTimer
            interval: 2000
            onTriggered: {
                passwordPopup.close()
            }
        }
    }
}