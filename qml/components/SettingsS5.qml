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
    property int connectedSignal: 0
    property bool isConnecting: false

    property var globalTopBar
    property var notify

    ListModel {
        id: networkModel
    }

    // ✅ Load current WiFi on start
    Component.onCompleted: {
        connectedSSID = WiFiScanner.currentConnection()
        updateConnectedSignal()
    }

    // ===== UPDATE CONNECTED SIGNAL =====
    function updateConnectedSignal() {
        if (connectedSSID !== "") {
            var networks = WiFiScanner.scanNetworks()
            for (var i = 0; i < networks.length; i++) {
                if (networks[i].name === connectedSSID) {
                    connectedSignal = networks[i].signal
                    break
                }
            }
        } else {
            connectedSignal = 0
        }
    }
    function scanWifi() {
        networkModel.clear()

        var result = WiFiScanner.scanNetworks()

        for (var i = 0; i < result.length; i++) {
            if (result[i].name !== "")
                networkModel.append(result[i])
        }

        updateConnectedSignal()
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
            passwordField.text = ""
            passwordPopup.ssid = ssid
            passwordPopup.errorMessage = ""
            passwordPopup.successMessage = ""
            passwordPopup.isConnecting = false
            passwordPopup.open()
        } else {
            isConnecting = true
            var res = WiFiScanner.connectToWifi(ssid, "")

            isConnecting = false

            if (res.startsWith("Connected to")) {
                connectedSSID = ssid
                updateConnectedSignal()
                if (notify) notify("Connected to " + ssid)
            } else {
                var errorMsg = getErrorMessage(res)
                if (notify) notify("Connection failed: " + errorMsg)
            }

            scanWifi()
        }
    }

    // ===== GET ERROR MESSAGE =====
    function getErrorMessage(errorCode) {
        switch (errorCode) {
            case "WRONG_PASSWORD":
                return "Incorrect password"
            case "NETWORK_NOT_FOUND":
                return "Network not found"
            case "CONNECTION_TIMEOUT":
                return "Connection timeout"
            case "CONNECTION_FAILED":
                return "Connection failed"
            default:
                return "Unknown error"
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

                        // ===== WIFI CONTENT =====
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12 * root.scale
                            visible: root.wifiEnabled
                            spacing: 0

                            // ===== CONNECTED WIFI SECTION =====
                            Rectangle {
                                Layout.fillWidth: true
                                height: 80 * root.scale
                                radius: 12 * root.scale
                                color: "#E8F5E8"
                                border.color: "#4CAF50"
                                border.width: 2
                                visible: root.connectedSSID !== ""

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12 * root.scale
                                    spacing: 12 * root.scale

                                    Text {
                                        text: "📶"
                                        font.pixelSize: 24 * root.scale
                                    }

                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 4 * root.scale

                                        Text {
                                            text: "Connected"
                                            font.pixelSize: 14 * root.scale
                                            color: "#4CAF50"
                                            font.bold: true
                                        }

                                        Text {
                                            text: root.connectedSSID
                                            font.pixelSize: 18 * root.scale
                                            font.bold: true
                                            color: "#1A4DB5"
                                            elide: Text.ElideRight
                                        }
                                    }

                                    // Signal strength bars for connected network
                                    Row {
                                        spacing: 3 * root.scale

                                        Repeater {
                                            model: 4
                                            delegate: Rectangle {
                                                property var thresholds: [20, 40, 60, 80]

                                                width: 6 * root.scale
                                                height: (7 + index * 5) * root.scale
                                                radius: 2 * root.scale
                                                anchors.bottom: parent.bottom

                                                color: root.connectedSignal >= thresholds[index]
                                                       ? "#4CAF50" : "#DDDDDD"
                                            }
                                        }
                                    }

                                    Rectangle {
                                        width: 70 * root.scale
                                        height: 24 * root.scale
                                        radius: 12 * root.scale
                                        color: "#4CAF50"

                                        Text {
                                            anchors.centerIn: parent
                                            text: "Connected"
                                            font.pixelSize: 12 * root.scale
                                            font.bold: true
                                            color: "#FFFFFF"
                                        }
                                    }
                                }
                            }

                            // Spacer between connected and available sections
                            Item {
                                Layout.fillWidth: true
                                height: 16 * root.scale
                                visible: root.connectedSSID !== ""
                            }

                            // ===== AVAILABLE NETWORKS HEADER =====
                            Item {
                                Layout.fillWidth: true
                                height: 50 * root.scale

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
                                Layout.fillWidth: true
                                height: 2
                                color: "#E8E8E8"
                            }

                            // ===== AVAILABLE NETWORKS LIST =====
                            ListView {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true

                                model: networkModel
                                spacing: 0

                                delegate: Column {
                                    width: ListView.view.width

                                    Rectangle {
                                        width: parent.width
                                        height: 50 * root.scale

                                        color: model.connected
                                               ? "#DFF5E3"
                                               : (mouseArea.containsMouse ? "#EEF3FF" : "transparent")

                                        MouseArea {
                                            id: mouseArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                        }

                                        Text {
                                            anchors.left: parent.left
                                            anchors.leftMargin: 14 * root.scale
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: model.secured ? "🔒" : "🌐"
                                            font.pixelSize: 20 * root.scale
                                        }

                                        Column {
                                            anchors.left: parent.left
                                            anchors.leftMargin: 40 * root.scale
                                            anchors.right: signalRow.left
                                            anchors.rightMargin: 10 * root.scale
                                            anchors.verticalCenter: parent.verticalCenter

                                            Text {
                                                text: model.name
                                                font.pixelSize: 19 * root.scale
                                                font.bold: true
                                                elide: Text.ElideRight
                                            }

                                            Text {
                                                text: model.secured ? "Secured" : "Open Network"
                                                font.pixelSize: 16 * root.scale
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
                                                    property var thresholds: [20, 40, 60, 80]

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

                                            color: model.connected || root.isConnecting ? "#AAAAAA" : "#1A4DB5"

                                            Text {
                                                anchors.centerIn: parent
                                                text: model.connected ? "Connected" : (root.isConnecting ? "Connecting..." : "Connect")
                                                font.pixelSize: 16 * root.scale
                                                font.bold: true
                                                color: "#FFFFFF"
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                enabled: !model.connected && !root.isConnecting
                                                onClicked: {
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
        width: 380 * root.scale
        height: 280 * root.scale
        closePolicy: Popup.NoAutoClose

        property string ssid: ""
        property string errorMessage: ""
        property string successMessage: ""
        property bool isConnecting: false

        background: Rectangle {
            radius: 16 * root.scale
            color: "#FFFFFF"
            border.color: "#DADADA"
            border.width: 1
        }

        Column {
            anchors.fill: parent
            anchors.margins: 24 * root.scale
            spacing: 16 * root.scale

            Text {
                text: "Connect to WiFi Network"
                font.pixelSize: 20 * root.scale
                font.bold: true
                color: "#1A4DB5"
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                text: "Enter password for \"" + ssid + "\""
                font.pixelSize: 16 * root.scale
                color: "#666666"
                anchors.horizontalCenter: parent.horizontalCenter
            }

            // Password input field
            Item {
                width: parent.width
                height: 50 * root.scale

                TextField {
                    id: passwordField
                    anchors.fill: parent
                    font.pixelSize: 18 * root.scale
                    color: "#1A4DB5"
                    echoMode: TextInput.Password
                    background: null
                    padding: 0

                    property bool showPlaceholder: text.length === 0 && !activeFocus

                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        text: "Enter password"
                        color: "#A0AABF"
                        visible: passwordField.showPlaceholder
                        font.pixelSize: 18 * root.scale
                    }
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 2 * root.scale
                    color: passwordField.activeFocus ? "#1A4DB5" : "#E3E7F0"
                }

                // Show/Hide password button
                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 40 * root.scale
                    height: 40 * root.scale
                    color: "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: passwordField.echoMode === TextInput.Password ? "👁️" : "🙈"
                        font.pixelSize: 18 * root.scale
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

            // Error message
            Text {
                id: errorText
                text: passwordPopup.errorMessage
                color: "#F44336"
                font.pixelSize: 14 * root.scale
                visible: text !== ""
                wrapMode: Text.Wrap
                width: parent.width
            }

            // Success message
            Text {
                id: successText
                text: passwordPopup.successMessage
                color: "#4CAF50"
                font.pixelSize: 14 * root.scale
                visible: text !== ""
                wrapMode: Text.Wrap
                width: parent.width
            }

            // Buttons row
            Row {
                spacing: 12 * root.scale
                anchors.horizontalCenter: parent.horizontalCenter

                Rectangle {
                    width: 100 * root.scale
                    height: 40 * root.scale
                    radius: 8 * root.scale
                    color: "#EEEEEE"

                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        color: "#666666"
                        font.pixelSize: 16 * root.scale
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            passwordPopup.close()
                        }
                    }
                }

                Rectangle {
                    width: 100 * root.scale
                    height: 40 * root.scale
                    radius: 8 * root.scale
                    color: passwordPopup.isConnecting ? "#AAAAAA" : "#1A4DB5"

                    Text {
                        anchors.centerIn: parent
                        text: passwordPopup.isConnecting ? "Connecting..." : "Connect"
                        color: "#FFFFFF"
                        font.pixelSize: 16 * root.scale
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
                            passwordPopup.errorMessage = ""
                            passwordPopup.successMessage = ""

                            var res = WiFiScanner.connectToWifi(ssid, passwordField.text)

                            passwordPopup.isConnecting = false

                            if (res.startsWith("Connected to")) {
                                passwordPopup.successMessage = "Connected to " + ssid
                                passwordPopup.errorMessage = ""
                                root.connectedSSID = ssid
                                updateConnectedSignal()
                                scanWifi()

                                // Auto-close after success
                                closeTimer.start()
                            } else {
                                var errorMsg = getErrorMessage(res)
                                passwordPopup.errorMessage = res === "WRONG_PASSWORD"
                                                       ? "Incorrect password, please try again"
                                                       : "Connection failed: " + errorMsg
                                passwordPopup.successMessage = ""
                            }
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
