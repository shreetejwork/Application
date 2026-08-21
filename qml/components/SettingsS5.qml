import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import AppState 1.0

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
    property bool nmcliAvailable: false
    property bool lanAvailable: false
    property bool lanConnected: false

    property var globalTopBar
    property var notify

    // =========================================================
    // LAN EDIT POPUP STATE
    // =========================================================

    property string activeLanFieldId: ""

    property real lanKeyboardHeight:
        GlobalState.loginKeyboardRequest
        ? 340 * root.scale
        : 0

    property real lanVisibleHeight:
        root.height - lanKeyboardHeight

    property string lanIpAddress: ""
    property string lanSubnet: ""
    property string lanGateway: ""
    property string lanDns: "8.8.8.8"

    property string activeTab:
        GlobalState.networkSelectedTab === "LAN"
        ? "LAN"
        : "WiFi"

    Typography {
        id: componentTypography
        scale: root.scale || 1.0
    }

    Typography {
        id: s5Typography
        scale: root.scale
    }

    // =========================================================
    // WIFI NETWORK MODELS
    // =========================================================

    ListModel {
        id: networkModel
    }

    ListModel {
        id: availableNetworkModel
    }

    // =========================================================
    // INITIALIZATION
    // =========================================================

    // =========================================================
    // LOAD LAN SETTINGS
    // =========================================================

    function loadLanSettings() {

        lanAvailable =
            NetworkManager.isEthernetAvailable("eth0")

        lanConnected =
            NetworkManager.isEthernetConnected("eth0")

        if (!lanAvailable) {

            lanIpAddress = ""
            lanSubnet = ""
            lanGateway = ""
            lanDns = "8.8.8.8"

            return
        }

        lanIpAddress =
            NetworkManager.getIPAddress("eth0")

        lanSubnet =
            NetworkManager.getSubnet("eth0")

        lanGateway =
            NetworkManager.getGateway("eth0")

        var dns =
            NetworkManager.getDns("eth0")

        if (dns !== "")
            lanDns = dns
        else
            lanDns = "8.8.8.8"
    }

    Component.onCompleted: {

        // =========================================
        // WIFI INITIALIZATION
        // =========================================

        nmcliAvailable =
            WiFiScanner.isNmcliAvailable()

        if (nmcliAvailable) {

            wifiEnabled =
                WiFiScanner.isWifiEnabled()

            if (wifiEnabled) {

                WiFiScanner.currentConnectionAsync()

                WiFiScanner.scanNetworksAsync()
            }
        }

        // =========================================
        // LAN INITIALIZATION
        // =========================================

        loadLanSettings()
    }

    // =========================================================
    // WIFI CONNECTION STATUS
    // =========================================================

    Connections {
        target: WiFiScanner

        function onCurrentConnectionReady(ssid) {
            connectedSSID = ssid
            refreshAvailableNetworks()
            updateConnectedSignal()
        }

        function onNetworksScanned(networks) {
            networkModel.clear()
            availableNetworkModel.clear()

            for (var i = 0; i < networks.length; i++) {
                if (networks[i].name === "")
                    continue

                networkModel.append(networks[i])
            }

            refreshAvailableNetworks()
            updateConnectedSignal()
        }
    }

    // =========================================================
    // LAN NETWORK CONFIGURATION CHANGED
    // =========================================================

    Connections {

        target: NetworkManager

        function onNetworkConfigurationChanged() {

            root.loadLanSettings()

            root.lanAvailable =
                NetworkManager.isEthernetAvailable("eth0")

            root.lanConnected =
                NetworkManager.isEthernetConnected("eth0")
        }
    }

    // =========================================================
    // REFRESH AVAILABLE NETWORKS
    // =========================================================

    function refreshAvailableNetworks() {
        availableNetworkModel.clear()

        for (var i = 0; i < networkModel.count; i++) {

            var network = networkModel.get(i)

            if (network.name !== connectedSSID
                    && !network.connected) {

                availableNetworkModel.append(network)
            }
        }
    }

    // =========================================================
    // UPDATE CONNECTED SIGNAL
    // =========================================================

    function updateConnectedSignal() {

        if (connectedSSID !== "") {

            for (var i = 0; i < networkModel.count; i++) {

                if (networkModel.get(i).name === connectedSSID) {

                    connectedSignal =
                            networkModel.get(i).signal

                    break
                }
            }

        } else {

            connectedSignal = 0
        }
    }

    // =========================================================
    // SCAN WIFI
    // =========================================================

    function scanWifi() {

        if (!nmcliAvailable) {

            networkModel.clear()
            availableNetworkModel.clear()

            return
        }

        WiFiScanner.scanNetworksAsync()
    }

    // =========================================================
    // START WIFI CONNECTION
    // =========================================================

    function startWifiConnect(ssid, password) {

        isConnecting = true

        passwordPopup.isConnecting = true
        passwordPopup.errorMessage = ""
        passwordPopup.successMessage = ""

        WiFiScanner.connectToWifiAsync(
                    ssid,
                    password
                    )
    }

    // =========================================================
    // PERIODIC WIFI SCAN
    // =========================================================

    Timer {
        interval: 10000
        running: root.wifiEnabled
        repeat: true

        onTriggered: root.scanWifi()
    }

    // =========================================================
    // CONNECT WIFI
    // =========================================================

    function connectWifi(ssid, secured) {

        if (!nmcliAvailable) {

            if (notify)
                notify(
                            "WiFi management not available on this system"
                            )

            return
        }

        startWifiConnect(
                    ssid,
                    ""
                    )
    }

    // =========================================================
    // WIFI CONNECTION RESULT
    // =========================================================

    Connections {
        target: WiFiScanner

        function onConnectionResult(resultSsid, result) {

            isConnecting = false
            passwordPopup.isConnecting = false

            scanWifi()

            if (result.startsWith("Connected to")) {

                connectedSSID = resultSsid

                updateConnectedSignal()

                passwordPopup.successMessage =
                        "Connected successfully"

                passwordPopup.errorMessage = ""

                if (notify)
                    notify(
                                "Connected to "
                                + resultSsid
                                )

                if (passwordPopup.visible
                        && passwordPopup.ssid === resultSsid) {

                    closeTimer.start()
                }

            }
            else if (result === "NEEDS_PASSWORD") {

                passwordField.text = ""

                passwordPopup.ssid =
                        resultSsid

                passwordPopup.errorMessage = ""
                passwordPopup.successMessage = ""

                passwordPopup.isConnecting = false

                passwordPopup.open()

                passwordField.forceActiveFocus()

            }
            else {

                var errorMsg =
                        getErrorMessage(result)

                if (passwordPopup.visible
                        && passwordPopup.ssid === resultSsid) {

                    passwordPopup.errorMessage =
                            result === "WRONG_PASSWORD"
                            ? "Incorrect password. Please try again."
                            : "Connection failed: "
                              + errorMsg

                    passwordPopup.successMessage = ""
                }

                if (notify)
                    notify(
                                "Connection failed: "
                                + errorMsg
                                )
            }
        }
    }

    // =========================================================
    // ERROR MESSAGE
    // =========================================================

    function getErrorMessage(errorCode) {

        switch (errorCode) {

        case "WRONG_PASSWORD":
            return "Incorrect password"

        case "NEEDS_PASSWORD":
            return "Password required"

        case "NETWORK_NOT_FOUND":
            return "Network not found"

        case "CONNECTION_TIMEOUT":
            return "Connection timeout"

        case "CONNECTION_FAILED":
            return "Connection failed"

        case "NO_WIFI_DEVICE":
            return "No WiFi device found"

        default:
            return "Unknown error"
        }
    }

    // =========================================================
    // BACKGROUND
    // =========================================================

    Rectangle {
        anchors.fill: parent
        color: "#F5F7FC"
    }

    // =========================================================
    // MAIN CONTENT
    // =========================================================

    ColumnLayout {
        anchors.fill: parent

        anchors.leftMargin: 30 * root.scale
        anchors.rightMargin: 30 * root.scale

        anchors.topMargin: 22 * root.scale
        anchors.bottomMargin: 18 * root.scale

        spacing: 14 * root.scale

        // =====================================================
        // PAGE HEADER
        // =====================================================

        Column {
            Layout.fillWidth: true

            spacing: 4 * root.scale

            Text {
                text: "Network Settings"

                font.pixelSize:
                    27 * root.scale

                color: "#1A4DB5"
            }


            Rectangle {
                width: 90 * root.scale
                height: 3 * root.scale

                radius: 2 * root.scale

                color: "#1A4DB5"
            }
        }

        // =====================================================
        // TAB CONTAINER
        // =====================================================

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 62 * root.scale

            radius: 12 * root.scale

            color: "#FFFFFF"

            border.color: "#D9E1EF"
            border.width: 1

            Row {
                anchors.fill: parent

                anchors.leftMargin: 10 * root.scale
                anchors.rightMargin: 10 * root.scale

                anchors.topMargin: 8 * root.scale
                anchors.bottomMargin: 8 * root.scale

                spacing: 10 * root.scale

                // =============================================
                // WIFI TAB
                // =============================================

                Rectangle {
                    width:
                        (parent.width - 10 * root.scale)
                        / 2

                    height: parent.height

                    radius: 9 * root.scale

                    property bool selected:
                        root.activeTab === "WiFi"

                    color:
                        selected
                        ? "#1A4DB5"
                        : "transparent"

                    Text {
                        anchors.centerIn: parent

                        text: "WiFi"

                        font.pixelSize:
                            22 * root.scale

                        color:
                            parent.selected
                            ? "#FFFFFF"
                            : "#64748B"
                    }

                    MouseArea {
                        anchors.fill: parent

                        onClicked: {

                            if (root.activeTab !== "WiFi") {

                                GlobalState.networkSelectedTab =
                                        "WiFi"
                            }
                        }
                    }
                }

                // =============================================
                // LAN TAB
                // =============================================

                Rectangle {
                    width:
                        (parent.width - 10 * root.scale)
                        / 2

                    height: parent.height

                    radius: 9 * root.scale

                    property bool selected:
                        root.activeTab === "LAN"

                    color:
                        selected
                        ? "#1A4DB5"
                        : "transparent"

                    Text {
                        anchors.centerIn: parent

                        text: "LAN"

                        font.pixelSize:
                            22 * root.scale

                        color:
                            parent.selected
                            ? "#FFFFFF"
                            : "#64748B"
                    }

                    MouseArea {
                        anchors.fill: parent

                        onClicked: {

                            if (root.activeTab !== "LAN") {

                                GlobalState.networkSelectedTab =
                                        "LAN"
                            }
                        }
                    }
                }
            }
        }

        // =====================================================
        // MAIN CARD
        // =====================================================

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true

            radius: 18 * root.scale

            color: "#FFFFFF"

            border.color: "#D9E1EF"
            border.width: 1

            clip: true

            // =================================================
            // WIFI PAGE
            // =================================================

            Item {
                anchors.fill: parent

                visible:
                    root.activeTab === "WiFi"

                ColumnLayout {
                    anchors.fill: parent

                    anchors.margins:
                        22 * root.scale

                    spacing:
                        14 * root.scale

                    // =========================================
                    // WIFI HEADER
                    // =========================================

                    RowLayout {
                        Layout.fillWidth: true

                        spacing:
                            14 * root.scale

                        Rectangle {
                            Layout.preferredWidth:
                                52 * root.scale

                            Layout.preferredHeight:
                                52 * root.scale

                            radius:
                                12 * root.scale

                            color:
                                "#EAF0FF"

                            Text {
                                anchors.centerIn: parent

                                text: "WiFi"

                                font.pixelSize:
                                    20 * root.scale

                                color:
                                    "#1A4DB5"
                            }
                        }

                        Column {
                            Layout.fillWidth: true

                            spacing:
                                3 * root.scale

                            Text {
                                text:
                                    "WiFi Connection"

                                font.pixelSize:
                                    25 * root.scale

                                color:
                                    "#1F3F77"
                            }
                        }

                        // =====================================
                        // WIFI TOGGLE
                        // =====================================

                        Item {
                            Layout.preferredWidth:
                                130 * root.scale

                            Layout.preferredHeight:
                                48 * root.scale

                            DDButton {
                                anchors.centerIn: parent

                                width:
                                    120 * root.scale

                                height:
                                    44 * root.scale

                                toggled:
                                    root.wifiEnabled

                                knobSize:
                                    35 * root.scale

                                useSymbols: true

                                onToggledChanged: {

                                    if (toggled
                                            && root.nmcliAvailable) {

                                        root.wifiEnabled =
                                                WiFiScanner.enableWifi(
                                                    true
                                                    )

                                        if (root.wifiEnabled) {

                                            WiFiScanner.currentConnectionAsync()

                                            root.scanWifi()
                                        }

                                    }
                                    else {

                                        root.wifiEnabled =
                                                false

                                        WiFiScanner.enableWifi(
                                                    false
                                                    )

                                        root.connectedSSID =
                                                ""

                                        root.connectedSignal =
                                                0

                                        networkModel.clear()

                                        availableNetworkModel.clear()
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true

                        height:
                            1 * root.scale

                        color:
                            "#E5EAF2"
                    }

                    // =========================================
                    // WIFI DISABLED / NOT AVAILABLE
                    // =========================================

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        visible:
                            !root.wifiEnabled
                            || !root.nmcliAvailable

                        Column {
                            anchors.centerIn: parent

                            spacing:
                                12 * root.scale

                            Rectangle {

                                width:
                                    76 * root.scale

                                height:
                                    76 * root.scale

                                radius:
                                    18 * root.scale

                                anchors.horizontalCenter:
                                    parent.horizontalCenter

                                color:
                                    root.nmcliAvailable
                                    ? "#EEF2F7"
                                    : "#FFF0ED"

                                Text {

                                    anchors.centerIn:
                                        parent

                                    text:
                                        root.nmcliAvailable
                                        ? "WiFi"
                                        : "!"

                                    font.pixelSize:
                                        23 * root.scale

                                    color:
                                        root.nmcliAvailable
                                        ? "#7A8BA5"
                                        : "#D65A4A"
                                }
                            }

                            Text {

                                anchors.horizontalCenter:
                                    parent.horizontalCenter

                                text:
                                    root.nmcliAvailable
                                    ? "WiFi is turned off"
                                    : "WiFi Management Not Available"

                                font.pixelSize:
                                    22 * root.scale

                                color:
                                    root.nmcliAvailable
                                    ? "#52627B"
                                    : "#D65A4A"
                            }

                            Text {

                                anchors.horizontalCenter:
                                    parent.horizontalCenter

                                text:
                                    root.nmcliAvailable
                                    ? "Enable WiFi using the switch above"
                                    : "NetworkManager is required"

                                font.pixelSize:
                                    16 * root.scale

                                color:
                                    "#8B98AB"
                            }
                        }
                    }

                    // =========================================
                    // ACTIVE WIFI CONTENT
                    // =========================================

                    ColumnLayout {

                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        visible:
                            root.wifiEnabled
                            && root.nmcliAvailable

                        spacing:
                            12 * root.scale

                        // =====================================
                        // CONNECTED NETWORK
                        // =====================================

                        Rectangle {

                            Layout.fillWidth:
                                true

                            Layout.preferredHeight:
                                78 * root.scale

                            visible:
                                root.connectedSSID !== ""

                            radius:
                                12 * root.scale

                            color:
                                "#F4F7FF"

                            border.color:
                                "#B8C9F0"

                            border.width:
                                1

                            RowLayout {

                                anchors.fill:
                                    parent

                                anchors.margins:
                                    14 * root.scale

                                spacing:
                                    14 * root.scale

                                Rectangle {

                                    Layout.preferredWidth:
                                        46 * root.scale

                                    Layout.preferredHeight:
                                        46 * root.scale

                                    radius:
                                        10 * root.scale

                                    color:
                                        "#E1F5E8"

                                    Text {

                                        anchors.centerIn:
                                            parent

                                        text:
                                            "✓"

                                        font.pixelSize:
                                            27 * root.scale

                                        color:
                                            "#259653"
                                    }
                                }

                                Column {

                                    Layout.fillWidth:
                                        true

                                    spacing:
                                        4 * root.scale

                                    Text {

                                        text:
                                            "Connected Network"

                                        font.pixelSize:
                                            20 * root.scale

                                        color:
                                            "#6B7B93"
                                    }

                                    Text {

                                        text:
                                            root.connectedSSID

                                        width:
                                            parent.width

                                        font.pixelSize:
                                            24 * root.scale

                                        color:
                                            "#1A4DB5"

                                        elide:
                                            Text.ElideRight
                                    }
                                }

                                Row {

                                    spacing:
                                        3 * root.scale

                                    Repeater {

                                        model: 4

                                        delegate:
                                            Rectangle {

                                            property var thresholds:
                                                [20, 40, 60, 80]

                                            width:
                                                5 * root.scale

                                            height:
                                                (8 + index * 5)
                                                * root.scale

                                            radius:
                                                2 * root.scale

                                            anchors.bottom:
                                                parent.bottom

                                            color:
                                                root.connectedSignal
                                                >= thresholds[index]
                                                ? "#1A4DB5"
                                                : "#D7DEEA"
                                        }
                                    }
                                }

                                Rectangle {

                                    Layout.preferredWidth:
                                        100 * root.scale

                                    Layout.preferredHeight:
                                        36 * root.scale

                                    radius:
                                        8 * root.scale

                                    color:
                                        "#E1F5E8"

                                    Text {

                                        anchors.centerIn:
                                            parent

                                        text:
                                            "Connected"

                                        font.pixelSize:
                                            20 * root.scale

                                        color:
                                            "#259653"
                                    }
                                }
                            }
                        }

                        // =====================================
                        // NETWORK LIST HEADER
                        // =====================================

                        RowLayout {

                            Layout.fillWidth:
                                true

                            Text {

                                text:
                                    "Available Networks"

                                font.pixelSize:
                                    22 * root.scale

                                color:
                                    "#253A5E"
                            }

                            Text {

                                text:
                                    "("
                                    + availableNetworkModel.count
                                    + ")"

                                font.pixelSize:
                                    22 * root.scale

                                color:
                                    "#8A98AE"
                            }

                            Item {
                                Layout.fillWidth:
                                    true
                            }

                            Rectangle {

                                Layout.preferredWidth:
                                    115 * root.scale

                                Layout.preferredHeight:
                                    38 * root.scale

                                radius:
                                    8 * root.scale

                                color:
                                    refreshMouse.pressed
                                    ? "#163F8E"
                                    : "#EAF0FF"

                                border.color:
                                    "#C5D2EC"

                                border.width:
                                    1

                                Text {

                                    anchors.centerIn:
                                        parent

                                    text:
                                        "Refresh"

                                    font.pixelSize:
                                        21 * root.scale

                                    color:
                                        "#1A4DB5"
                                }

                                MouseArea {

                                    id:
                                        refreshMouse

                                    anchors.fill:
                                        parent

                                    enabled:
                                        !root.isConnecting

                                    onClicked:
                                        root.scanWifi()
                                }
                            }
                        }

                        // =====================================
                        // NETWORK LIST
                        // =====================================

                        Rectangle {

                            Layout.fillWidth:
                                true

                            Layout.fillHeight:
                                true

                            radius:
                                12 * root.scale

                            color:
                                "#F8FAFD"

                            border.color:
                                "#E0E6F0"

                            border.width:
                                1

                            clip:
                                true

                            ListView {

                                id:
                                    networkList

                                anchors.fill:
                                    parent

                                anchors.margins:
                                    10 * root.scale

                                clip:
                                    true

                                spacing:
                                    8 * root.scale

                                model:
                                    availableNetworkModel

                                ScrollBar.vertical:
                                    ScrollBar {
                                    }

                                delegate:
                                    Rectangle {

                                    width:
                                        networkList.width

                                    height:
                                        68 * root.scale

                                    radius:
                                        10 * root.scale

                                    color:
                                        networkMouse.pressed
                                        ? "#EDF2FB"
                                        : "#FFFFFF"

                                    border.color:
                                        "#E1E7F0"

                                    border.width:
                                        1

                                    RowLayout {

                                        anchors.fill:
                                            parent

                                        anchors.leftMargin:
                                            14 * root.scale

                                        anchors.rightMargin:
                                            12 * root.scale

                                        spacing:
                                            12 * root.scale

                                        Rectangle {

                                            Layout.preferredWidth:
                                                42 * root.scale

                                            Layout.preferredHeight:
                                                42 * root.scale

                                            radius:
                                                9 * root.scale

                                            color:
                                                model.secured
                                                ? "#FFF4E8"
                                                : "#EAF7EE"

                                            Text {

                                                anchors.centerIn:
                                                    parent

                                                text:
                                                    model.secured
                                                    ? "Lock"
                                                    : "Open"

                                                font.pixelSize:
                                                    18 * root.scale

                                                color:
                                                    model.secured
                                                    ? "#D97706"
                                                    : "#239650"
                                            }
                                        }

                                        Column {

                                            Layout.fillWidth:
                                                true

                                            spacing:
                                                3 * root.scale

                                            Text {

                                                width:
                                                    parent.width

                                                text:
                                                    model.name

                                                font.pixelSize:
                                                    22 * root.scale

                                                color:
                                                    "#26364E"

                                                elide:
                                                    Text.ElideRight
                                            }

                                            Text {

                                                text:
                                                    model.secured
                                                    ? "Secured network"
                                                    : "Open network"

                                                font.pixelSize:
                                                    19 * root.scale

                                                color:
                                                    model.secured
                                                    ? "#8A6B3E"
                                                    : "#549169"
                                            }
                                        }

                                        Row {

                                            spacing:
                                                3 * root.scale

                                            Repeater {

                                                model:
                                                    4

                                                delegate:
                                                    Rectangle {

                                                    property var thresholds:
                                                        [20, 40, 60, 80]

                                                    width:
                                                        6 * root.scale

                                                    height:
                                                        (9 + index * 6)
                                                        * root.scale

                                                    radius:
                                                        2 * root.scale

                                                    anchors.bottom:
                                                        parent.bottom

                                                    color:
                                                        model.signal
                                                        >= thresholds[index]
                                                        ? "#1A4DB5"
                                                        : "#D5DCE8"
                                                }
                                            }
                                        }

                                        Rectangle {

                                            Layout.preferredWidth:
                                                100 * root.scale

                                            Layout.preferredHeight:
                                                42 * root.scale

                                            radius:
                                                8 * root.scale

                                            color:
                                                root.isConnecting
                                                ? "#AAB5C8"
                                                : "#1A4DB5"

                                            Text {

                                                anchors.centerIn:
                                                    parent

                                                text:
                                                    "Connect"

                                                font.pixelSize:
                                                    21 * root.scale

                                                color:
                                                    "#FFFFFF"
                                            }

                                            MouseArea {

                                                id:
                                                    networkMouse

                                                anchors.fill:
                                                    parent

                                                enabled:
                                                    !root.isConnecting

                                                onClicked:
                                                    root.connectWifi(
                                                        model.name,
                                                        model.secured
                                                        )
                                            }
                                        }
                                    }
                                }
                            }

                            // =================================
                            // NO NETWORK FOUND
                            // =================================

                            Item {

                                anchors.fill:
                                    parent

                                visible:
                                    availableNetworkModel.count === 0

                                Column {

                                    anchors.centerIn:
                                        parent

                                    spacing:
                                        8 * root.scale

                                    Text {

                                        anchors.horizontalCenter:
                                            parent.horizontalCenter

                                        text:
                                            "No networks found"

                                        font.pixelSize:
                                            23 * root.scale

                                        color:
                                            "#71809A"
                                    }

                                    Text {

                                        anchors.horizontalCenter:
                                            parent.horizontalCenter

                                        text:
                                            "Tap Refresh to scan again"

                                        font.pixelSize:
                                            18 * root.scale

                                        color:
                                            "#A0ACBD"
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // =================================================
            // LAN PAGE
            // =================================================

            Item {
                id: lanPage

                anchors.fill: parent

                visible:
                    root.activeTab === "LAN"

                ColumnLayout {
                    anchors.fill: parent

                    anchors.margins:
                        26 * root.scale

                    spacing:
                        16 * root.scale

                    // =========================================
                    // LAN HEADER
                    // =========================================

                    RowLayout {

                        Layout.fillWidth: true

                        spacing:
                            14 * root.scale

                        Rectangle {

                            Layout.preferredWidth:
                                52 * root.scale

                            Layout.preferredHeight:
                                52 * root.scale

                            radius:
                                12 * root.scale

                            color:
                                "#EAF0FF"

                            Text {

                                anchors.centerIn: parent

                                text:
                                    "LAN"

                                font.pixelSize:
                                    20 * root.scale

                                color:
                                    "#1A4DB5"
                            }
                        }

                        Column {

                            Layout.fillWidth: true

                            spacing:
                                3 * root.scale

                            Text {

                                text:
                                    "LAN Configuration"

                                font.pixelSize:
                                    25 * root.scale

                                color:
                                    "#1F3F77"
                            }
                        }
                    }

                    Rectangle {

                        Layout.fillWidth: true

                        height:
                            1 * root.scale

                        color:
                            "#E5EAF2"
                    }

                    // =========================================
                    // LAN CONFIGURATION CARDS
                    // =========================================

                    GridLayout {

                        Layout.fillWidth: true

                        columns:
                            2

                        columnSpacing:
                            20 * root.scale

                        rowSpacing:
                            18 * root.scale


                        // =====================================
                        // IP ADDRESS
                        // =====================================

                        LanSettingsCard {

                            fieldId:
                                "ip"

                            fieldLabel:
                                "IP Address"

                            placeholderText:
                                "192.168.1.50"

                            displayValue:
                                root.lanIpAddress
                        }


                        // =====================================
                        // SUBNET
                        // =====================================

                        LanSettingsCard {

                            fieldId:
                                "subnet"

                            fieldLabel:
                                "Subnet"

                            placeholderText:
                                "24"

                            displayValue:
                                root.lanSubnet
                        }


                        // =====================================
                        // GATEWAY
                        // =====================================

                        LanSettingsCard {

                            fieldId:
                                "gateway"

                            fieldLabel:
                                "Gateway"

                            placeholderText:
                                "192.168.1.1"

                            displayValue:
                                root.lanGateway
                        }


                        // =====================================
                        // DNS
                        // =====================================

                        LanSettingsCard {

                            fieldId:
                                "dns"

                            fieldLabel:
                                "DNS"

                            placeholderText:
                                "8.8.8.8"

                            displayValue:
                                root.lanDns
                        }
                    }


                    Item {
                        Layout.fillHeight:
                            true
                    }


                    // =========================================
                    // RESULT MESSAGE
                    // =========================================

                    Rectangle {

                        Layout.fillWidth:
                            true

                        Layout.preferredHeight:
                            resultText.text !== ""
                            ? 48 * root.scale
                            : 0

                        visible:
                            resultText.text !== ""

                        radius:
                            9 * root.scale

                        color:
                            "#EEF4FF"

                        border.color:
                            "#C7D7F4"

                        border.width:
                            1

                        clip:
                            true

                        Text {

                            id:
                                resultText

                            anchors.fill:
                                parent

                            anchors.leftMargin:
                                14 * root.scale

                            anchors.rightMargin:
                                14 * root.scale

                            verticalAlignment:
                                Text.AlignVCenter

                            text:
                                ""

                            font.pixelSize:
                                19 * root.scale

                            color:
                                "#1A4DB5"

                            elide:
                                Text.ElideRight
                        }
                    }


                    // =========================================
                    // APPLY STATIC IP
                    // =========================================

                    Rectangle {

                        Layout.alignment:
                            Qt.AlignHCenter

                        Layout.preferredWidth:
                            300 * root.scale

                        Layout.preferredHeight:
                            54 * root.scale

                        radius:
                            10 * root.scale

                        color:
                            applyMouse.pressed
                            ? "#143F90"
                            : "#1A4DB5"

                        Text {

                            anchors.centerIn:
                                parent

                            text:
                                "Apply Static IP"

                            font.pixelSize:
                                25 * root.scale

                            color:
                                "#FFFFFF"
                        }

                        MouseArea {

                            id:
                                applyMouse

                            anchors.fill:
                                parent

                            onClicked: {

                                if (root.lanIpAddress.trim() === "") {

                                    resultText.text =
                                            "Please enter IP Address"

                                    return
                                }

                                if (root.lanSubnet.trim() === "") {

                                    resultText.text =
                                            "Please enter Subnet"

                                    return
                                }

                                if (root.lanGateway.trim() === "") {

                                    resultText.text =
                                            "Please enter Gateway"

                                    return
                                }


                                var result =
                                    NetworkManager.setStaticIP(
                                        "eth0",
                                        root.lanIpAddress,
                                        root.lanSubnet,
                                        root.lanGateway,
                                        root.lanDns
                                    )

                                resultText.text =
                                    result

                                if (result === "Static IP configured successfully") {

                                    root.loadLanSettings()

                                    if (root.notify)
                                        root.notify(
                                            "Static IP configured successfully"
                                        )
                                }
                                else {

                                    if (root.notify)
                                        root.notify(result)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // =========================================================
    // LAN EDIT BACKGROUND DIM
    // =========================================================

    Rectangle {

        anchors.fill:
            parent

        z:
            50

        color:
            "#000000"

        opacity:
            root.activeLanFieldId !== ""
            ? 0.45
            : 0.0

        visible:
            opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: 220
            }
        }

        MouseArea {

            anchors.fill:
                parent

            enabled:
                root.activeLanFieldId !== ""

            onClicked: {

                root.activeLanFieldId = ""

                GlobalState.loginKeyboardRequest =
                        false

                GlobalState.activeInputField =
                        null
            }
        }
    }

    // =========================================================
    // LAN FLOATING EDIT POPUP
    // =========================================================

    Loader {

        id:
            lanFloatingLoader

        z:
            60

        width:
            480 * root.scale

        height:
            160 * root.scale

        x:
            (root.width - width) / 2

        y:
            (root.lanVisibleHeight - height) / 2


        Behavior on y {

            NumberAnimation {

                duration:
                    280

                easing.type:
                    Easing.OutQuart
            }
        }


        active:
            root.activeLanFieldId !== ""

        visible:
            active


        property string loadedFieldId: ""
        property string loadedLabel: ""
        property string loadedPlaceholder: ""
        property string loadedInitialValue: ""


        onActiveChanged: {

            if (active) {

                var id =
                        root.activeLanFieldId


                loadedFieldId =
                        id


                // =====================================
                // IP ADDRESS
                // =====================================

                if (id === "ip") {

                    loadedLabel =
                            "IP Address"

                    loadedPlaceholder =
                            "192.168.1.50"

                    loadedInitialValue =
                            root.lanIpAddress
                }


                // =====================================
                // SUBNET
                // =====================================

                else if (id === "subnet") {

                    loadedLabel =
                            "Subnet"

                    loadedPlaceholder =
                            "24"

                    loadedInitialValue =
                            root.lanSubnet
                }


                // =====================================
                // GATEWAY
                // =====================================

                else if (id === "gateway") {

                    loadedLabel =
                            "Gateway"

                    loadedPlaceholder =
                            "192.168.1.1"

                    loadedInitialValue =
                            root.lanGateway
                }


                // =====================================
                // DNS
                // =====================================

                else if (id === "dns") {

                    loadedLabel =
                            "DNS"

                    loadedPlaceholder =
                            "8.8.8.8"

                    loadedInitialValue =
                            root.lanDns
                }
            }
        }


        sourceComponent:

            LanFloatingCard {

            fieldId:
                lanFloatingLoader.loadedFieldId

            fieldLabel:
                lanFloatingLoader.loadedLabel

            placeholderText:
                lanFloatingLoader.loadedPlaceholder

            initialValue:
                lanFloatingLoader.loadedInitialValue


            onDismiss: {

                root.activeLanFieldId =
                        ""

                GlobalState.loginKeyboardRequest =
                        false

                GlobalState.activeInputField =
                        null
            }


            onConfirmed:
                function(id, value) {

                // =================================
                // IP
                // =================================

                if (id === "ip") {

                    root.lanIpAddress =
                            value

                    if (root.notify)
                        root.notify(
                            "✓ IP Address Saved"
                        )
                }


                // =================================
                // SUBNET
                // =================================

                else if (id === "subnet") {

                    root.lanSubnet =
                            value

                    if (root.notify)
                        root.notify(
                            "✓ Subnet Saved"
                        )
                }


                // =================================
                // GATEWAY
                // =================================

                else if (id === "gateway") {

                    root.lanGateway =
                            value

                    if (root.notify)
                        root.notify(
                            "✓ Gateway Saved"
                        )
                }


                // =================================
                // DNS
                // =================================

                else if (id === "dns") {

                    root.lanDns =
                            value

                    if (root.notify)
                        root.notify(
                            "✓ DNS Saved"
                        )
                }


                root.activeLanFieldId =
                        ""

                GlobalState.loginKeyboardRequest =
                        false

                GlobalState.activeInputField =
                        null
            }
        }
    }

    // =========================================================
    // LAN FLOATING CARD COMPONENT
    // =========================================================

    component LanFloatingCard: Rectangle {

        id:
            lanFloatCard


        property string fieldId: ""
        property string fieldLabel: ""
        property string placeholderText: ""
        property string initialValue: ""


        signal confirmed(
            string id,
            string value
        )

        signal dismiss()


        anchors.fill:
            parent


        radius:
            18 * root.scale


        color:
            "#FFFFFF"


        border.color:
            "#2A62D5"


        border.width:
            2


        opacity:
            0


        scale:
            0.90


        Component.onCompleted:
            lanFloatEntrance.start()


        ParallelAnimation {

            id:
                lanFloatEntrance


            NumberAnimation {

                target:
                    lanFloatCard

                property:
                    "opacity"

                from:
                    0

                to:
                    1

                duration:
                    240

                easing.type:
                    Easing.OutCubic
            }


            NumberAnimation {

                target:
                    lanFloatCard

                property:
                    "scale"

                from:
                    0.90

                to:
                    1.0

                duration:
                    260

                easing.type:
                    Easing.OutBack

                easing.overshoot:
                    0.6
            }
        }


        Column {

            anchors.fill:
                parent

            anchors.margins:
                22 * root.scale

            spacing:
                14 * root.scale


            // =====================================
            // LABEL + CLOSE
            // =====================================

            Item {

                width:
                    parent.width

                height:
                    24 * root.scale


                Text {

                    anchors.left:
                        parent.left

                    anchors.verticalCenter:
                        parent.verticalCenter

                    text:
                        lanFloatCard.fieldLabel

                    color:
                        "#52627E"

                    font.pixelSize:
                        s5Typography.body
                }


                Rectangle {

                    anchors.right:
                        parent.right

                    anchors.verticalCenter:
                        parent.verticalCenter

                    width:
                        26 * root.scale

                    height:
                        26 * root.scale

                    radius:
                        width / 2


                    color:
                        lanCloseHover.containsMouse
                        ? "#F0F4FF"
                        : "transparent"


                    Behavior on color {

                        ColorAnimation {
                            duration:
                                120
                        }
                    }


                    Text {

                        anchors.centerIn:
                            parent

                        text:
                            "✕"

                        color:
                            "#8898B8"

                        font.pixelSize:
                            s5Typography.heading
                    }


                    HoverHandler {
                        id:
                            lanCloseHover
                    }


                    MouseArea {

                        anchors.fill:
                            parent

                        onClicked:
                            lanFloatCard.dismiss()
                    }
                }
            }


            // =====================================
            // INPUT
            // =====================================

            Rectangle {

                width:
                    parent.width

                height:
                    62 * root.scale

                radius:
                    12 * root.scale

                color:
                    "#F8FBFF"

                border.width:
                    2

                border.color:
                    "#2A62D5"


                TextField {

                    id:
                        lanFloatingInput


                    anchors.fill:
                        parent


                    anchors.leftMargin:
                        16 * root.scale

                    anchors.rightMargin:
                        58 * root.scale


                    text:
                        lanFloatCard.initialValue


                    color:
                        "#183C8F"


                    font.pixelSize:
                        s5Typography.body


                    verticalAlignment:
                        Text.AlignVCenter


                    background:
                        null


                    selectByMouse:
                        true


                    activeFocusOnPress:
                        true


                    placeholderText:
                        lanFloatCard.placeholderText


                    placeholderTextColor:
                        "#A0ACC2"


                    inputMethodHints:
                        Qt.ImhNone


                    Component.onCompleted: {

                        forceActiveFocus()


                        GlobalState.activeInputField =
                                lanFloatingInput


                        GlobalState.loginKeyboardRequest =
                                true
                    }


                    onAccepted: {

                        var value =
                                text.trim()


                        text =
                                value


                        lanFloatCard.confirmed(
                            lanFloatCard.fieldId,
                            value
                        )


                        focus =
                                false
                    }
                }


                // =================================
                // SAVE BUTTON
                // =================================

                Rectangle {

                    id:
                        lanSaveButton


                    width:
                        40 * root.scale

                    height:
                        40 * root.scale


                    radius:
                        width / 2


                    anchors {

                        right:
                            parent.right

                        rightMargin:
                            10 * root.scale

                        verticalCenter:
                            parent.verticalCenter
                    }


                    color:
                        "#1B56CC"


                    scale:
                        lanSaveMouse.pressed
                        ? 0.88
                        : 1.0


                    Behavior on scale {

                        NumberAnimation {
                            duration:
                                100
                        }
                    }


                    Text {

                        anchors.centerIn:
                            parent

                        text:
                            "✓"

                        color:
                            "white"

                        font.pixelSize:
                            s5Typography.bodySmall
                    }


                    MouseArea {

                        id:
                            lanSaveMouse

                        anchors.fill:
                            parent


                        onClicked: {

                            var value =
                                    lanFloatingInput.text.trim()


                            lanFloatingInput.text =
                                    value


                            lanFloatCard.confirmed(
                                lanFloatCard.fieldId,
                                value
                            )


                            lanFloatingInput.focus =
                                    false
                        }
                    }
                }
            }
        }
    }

    // =========================================================
    // LAN SETTINGS CARD COMPONENT
    // =========================================================

    component LanSettingsCard: Rectangle {

        id:
            lanCard


        property string fieldId: ""

        property string fieldLabel: ""

        property string placeholderText: ""

        property string displayValue: ""


        Layout.fillWidth:
            true


        Layout.preferredHeight:
            145 * root.scale


        implicitHeight:
            145 * root.scale


        radius:
            18 * root.scale


        color:
            lanCardHover.containsMouse
            ? "#F4F8FF"
            : "#FFFFFF"


        border.color:
            lanCardHover.containsMouse
            ? "#5E9BFF"
            : "#D9E2F2"


        border.width:
            1


        Behavior on color {

            ColorAnimation {
                duration:
                    150
            }
        }


        Behavior on border.color {

            ColorAnimation {
                duration:
                    150
            }
        }


        scale:
            lanCardHover.containsMouse
            ? 1.01
            : 1.0


        Behavior on scale {

            NumberAnimation {

                duration:
                    150

                easing.type:
                    Easing.OutQuad
            }
        }


        HoverHandler {

            id:
                lanCardHover
        }


        MouseArea {

            anchors.fill:
                parent


            onClicked: {

                root.activeLanFieldId =
                        lanCard.fieldId
            }
        }


        Column {

            anchors.fill:
                parent

            anchors.margins:
                20 * root.scale

            spacing:
                14 * root.scale


            Text {

                text:
                    lanCard.fieldLabel


                color:
                    "#52627E"


                font.pixelSize:
                    s5Typography.heading
            }


            Rectangle {

                width:
                    parent.width


                height:
                    58 * root.scale


                radius:
                    12 * root.scale


                color:
                    "#F7F9FD"


                border.width:
                    1


                border.color:
                    "#D6DDEA"


                Text {

                    anchors.left:
                        parent.left

                    anchors.leftMargin:
                        16 * root.scale


                    anchors.right:
                        lanEditCircle.left

                    anchors.rightMargin:
                        8 * root.scale


                    anchors.verticalCenter:
                        parent.verticalCenter


                    text:
                        lanCard.displayValue.length > 0
                        ? lanCard.displayValue
                        : lanCard.placeholderText


                    color:
                        lanCard.displayValue.length > 0
                        ? "#183C8F"
                        : "#A0ACC2"


                    font.pixelSize:
                        s5Typography.heading


                    elide:
                        Text.ElideRight
                }


                Rectangle {

                    id:
                        lanEditCircle


                    width:
                        32 * root.scale

                    height:
                        32 * root.scale


                    radius:
                        width / 2


                    anchors {

                        right:
                            parent.right

                        rightMargin:
                            13 * root.scale

                        verticalCenter:
                            parent.verticalCenter
                    }


                    color:
                        "#E4EDFF"


                    Image {

                        anchors.centerIn:
                            parent


                        source:
                            "qrc:/qt/qml/Application/assets/images/edit.png"


                        width:
                            Math.max(
                                14,
                                16 * root.scale
                            )


                        height:
                            width


                        fillMode:
                            Image.PreserveAspectFit


                        smooth:
                            true
                    }
                }
            }
        }
    }

    // =========================================================
    // PASSWORD POPUP
    // =========================================================

    Popup {

        id:
            passwordPopup

        modal:
            true

        focus:
            true

        width:
            440 * root.scale

        height:
            330 * root.scale

        x:
            (root.width - width) / 2

        y:
            (root.height - height) / 2

        closePolicy:
            Popup.NoAutoClose

        property string ssid: ""
        property string errorMessage: ""
        property string successMessage: ""
        property bool isConnecting: false

        background:
            Rectangle {

            radius:
                18 * root.scale

            color:
                "#FFFFFF"

            border.color:
                "#D5DDEA"

            border.width:
                1
        }

        Column {

            anchors.fill:
                parent

            anchors.margins:
                26 * root.scale

            spacing:
                16 * root.scale

            // =============================================
            // TITLE
            // =============================================

            Column {

                width:
                    parent.width

                spacing:
                    5 * root.scale

                Text {

                    anchors.horizontalCenter:
                        parent.horizontalCenter

                    text:
                        "Connect to WiFi"

                    font.pixelSize:
                        23 * root.scale

                    color:
                        "#1A4DB5"
                }

                Text {

                    anchors.horizontalCenter:
                        parent.horizontalCenter

                    width:
                        parent.width

                    horizontalAlignment:
                        Text.AlignHCenter

                    text:
                        passwordPopup.ssid

                    font.pixelSize:
                        17 * root.scale

                    color:
                        "#52627A"

                    elide:
                        Text.ElideRight
                }
            }

            // =============================================
            // PASSWORD FIELD
            // =============================================

            Rectangle {

                width:
                    parent.width

                height:
                    54 * root.scale

                radius:
                    9 * root.scale

                color:
                    "#F8FAFD"

                border.color:
                    passwordField.activeFocus
                    ? "#1A4DB5"
                    : "#D5DDEA"

                border.width:
                    passwordField.activeFocus
                    ? 2
                    : 1

                TextField {

                    id:
                        passwordField

                    anchors.left:
                        parent.left

                    anchors.right:
                        showPasswordButton.left

                    anchors.top:
                        parent.top

                    anchors.bottom:
                        parent.bottom

                    anchors.leftMargin:
                        14 * root.scale

                    anchors.rightMargin:
                        6 * root.scale

                    font.pixelSize:
                        18 * root.scale

                    color:
                        "#26364E"

                    echoMode:
                        TextInput.Password

                    background:
                        null

                    padding:
                        0

                    verticalAlignment:
                        TextInput.AlignVCenter

                    placeholderText:
                        "Enter WiFi password"

                    placeholderTextColor:
                        "#9DA9BA"
                }

                Rectangle {

                    id:
                        showPasswordButton

                    anchors.right:
                        parent.right

                    anchors.rightMargin:
                        8 * root.scale

                    anchors.verticalCenter:
                        parent.verticalCenter

                    width:
                        64 * root.scale

                    height:
                        38 * root.scale

                    radius:
                        7 * root.scale

                    color:
                        "#EAF0FF"

                    Text {

                        anchors.centerIn:
                            parent

                        text:
                            passwordField.echoMode
                            === TextInput.Password
                            ? "Show"
                            : "Hide"

                        font.pixelSize:
                            14 * root.scale

                        color:
                            "#1A4DB5"
                    }

                    MouseArea {

                        anchors.fill:
                            parent

                        onClicked: {

                            passwordField.echoMode =
                                    passwordField.echoMode
                                    === TextInput.Password
                                    ? TextInput.Normal
                                    : TextInput.Password
                        }
                    }
                }
            }

            // =============================================
            // ERROR
            // =============================================

            Rectangle {

                width:
                    parent.width

                height:
                    passwordPopup.errorMessage !== ""
                    ? 42 * root.scale
                    : 0

                visible:
                    passwordPopup.errorMessage !== ""

                radius:
                    7 * root.scale

                color:
                    "#FFF0F0"

                border.color:
                    "#F3C3C3"

                border.width:
                    1

                clip:
                    true

                Text {

                    anchors.fill:
                        parent

                    anchors.leftMargin:
                        12 * root.scale

                    anchors.rightMargin:
                        12 * root.scale

                    verticalAlignment:
                        Text.AlignVCenter

                    text:
                        passwordPopup.errorMessage

                    font.pixelSize:
                        14 * root.scale

                    color:
                        "#C83E3E"

                    wrapMode:
                        Text.Wrap
                }
            }

            // =============================================
            // SUCCESS
            // =============================================

            Rectangle {

                width:
                    parent.width

                height:
                    passwordPopup.successMessage !== ""
                    ? 42 * root.scale
                    : 0

                visible:
                    passwordPopup.successMessage !== ""

                radius:
                    7 * root.scale

                color:
                    "#EAF8EE"

                border.color:
                    "#BFE3C9"

                border.width:
                    1

                clip:
                    true

                Text {

                    anchors.fill:
                        parent

                    anchors.leftMargin:
                        12 * root.scale

                    anchors.rightMargin:
                        12 * root.scale

                    verticalAlignment:
                        Text.AlignVCenter

                    text:
                        passwordPopup.successMessage

                    font.pixelSize:
                        14 * root.scale

                    color:
                        "#21864A"

                    wrapMode:
                        Text.Wrap
                }
            }

            Item {
                width:
                    parent.width

                height:
                    4 * root.scale
            }

            // =============================================
            // BUTTONS
            // =============================================

            Row {

                anchors.horizontalCenter:
                    parent.horizontalCenter

                spacing:
                    14 * root.scale

                // CANCEL

                Rectangle {

                    width:
                        150 * root.scale

                    height:
                        46 * root.scale

                    radius:
                        9 * root.scale

                    color:
                        cancelMouse.pressed
                        ? "#E1E7F0"
                        : "#F3F5F8"

                    border.color:
                        "#D5DDEA"

                    border.width:
                        1

                    Text {

                        anchors.centerIn:
                            parent

                        text:
                            "Cancel"

                        font.pixelSize:
                            17 * root.scale

                        color:
                            "#52627A"
                    }

                    MouseArea {

                        id:
                            cancelMouse

                        anchors.fill:
                            parent

                        enabled:
                            !passwordPopup.isConnecting

                        onClicked:
                            passwordPopup.close()
                    }
                }

                // CONNECT

                Rectangle {

                    width:
                        150 * root.scale

                    height:
                        46 * root.scale

                    radius:
                        9 * root.scale

                    color:
                        passwordPopup.isConnecting
                        ? "#9BA8BC"
                        : connectPasswordMouse.pressed
                          ? "#143F90"
                          : "#1A4DB5"

                    Text {

                        anchors.centerIn:
                            parent

                        text:
                            passwordPopup.isConnecting
                            ? "Connecting..."
                            : "Connect"

                        font.pixelSize:
                            17 * root.scale

                        color:
                            "#FFFFFF"
                    }

                    MouseArea {

                        id:
                            connectPasswordMouse

                        anchors.fill:
                            parent

                        enabled:
                            !passwordPopup.isConnecting

                        onClicked: {

                            if (passwordField.text.length === 0) {

                                passwordPopup.errorMessage =
                                        "Please enter a password"

                                passwordPopup.successMessage =
                                        ""

                                return
                            }

                            passwordPopup.isConnecting =
                                    true

                            startWifiConnect(
                                        passwordPopup.ssid,
                                        passwordField.text
                                        )
                        }
                    }
                }
            }
        }

        Timer {

            id:
                closeTimer

            interval:
                2000

            onTriggered:
                passwordPopup.close()
        }
    }
}
