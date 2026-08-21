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

    property var globalTopBar
    property var notify

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

    Component.onCompleted: {
        nmcliAvailable = WiFiScanner.isNmcliAvailable()

        if (nmcliAvailable) {
            wifiEnabled = WiFiScanner.isWifiEnabled()

            if (wifiEnabled) {
                WiFiScanner.currentConnectionAsync()
                WiFiScanner.scanNetworksAsync()
            }
        }
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
                            20 * root.scale

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
                            20 * root.scale

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
                                    17 * root.scale

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
                                    22 * root.scale

                                color:
                                    "#1F3F77"
                            }

                            Text {

                                text:
                                    !root.nmcliAvailable
                                    ? "WiFi management is not available"
                                    : root.wifiEnabled
                                      ? "Scan and connect to wireless networks"
                                      : "Wireless connection is disabled"

                                font.pixelSize:
                                    15 * root.scale

                                color:
                                    "#71809A"
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
                                    : "NetworkManager (nmcli) is required"

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
                                            24 * root.scale

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
                                            15 * root.scale

                                        color:
                                            "#6B7B93"
                                    }

                                    Text {

                                        text:
                                            root.connectedSSID

                                        width:
                                            parent.width

                                        font.pixelSize:
                                            21 * root.scale

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
                                            15 * root.scale

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
                                    19 * root.scale

                                color:
                                    "#253A5E"
                            }

                            Text {

                                text:
                                    "("
                                    + availableNetworkModel.count
                                    + ")"

                                font.pixelSize:
                                    17 * root.scale

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
                                        16 * root.scale

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
                                                    12 * root.scale

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
                                                    19 * root.scale

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
                                                    14 * root.scale

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
                                                        4 * root.scale

                                                    height:
                                                        (7 + index * 4)
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
                                                    16 * root.scale

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
                                            20 * root.scale

                                        color:
                                            "#71809A"
                                    }

                                    Text {

                                        anchors.horizontalCenter:
                                            parent.horizontalCenter

                                        text:
                                            "Tap Refresh to scan again"

                                        font.pixelSize:
                                            15 * root.scale

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

                anchors.fill:
                    parent

                visible:
                    root.activeTab === "LAN"

                ColumnLayout {

                    anchors.fill:
                        parent

                    anchors.margins:
                        26 * root.scale

                    spacing:
                        16 * root.scale

                    // =========================================
                    // LAN HEADER
                    // =========================================

                    RowLayout {

                        Layout.fillWidth:
                            true

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

                                anchors.centerIn:
                                    parent

                                text:
                                    "LAN"

                                font.pixelSize:
                                    17 * root.scale

                                color:
                                    "#1A4DB5"
                            }
                        }

                        Column {

                            Layout.fillWidth:
                                true

                            spacing:
                                3 * root.scale

                            Text {

                                text:
                                    "LAN Configuration"

                                font.pixelSize:
                                    22 * root.scale

                                color:
                                    "#1F3F77"
                            }

                            Text {

                                text:
                                    "Configure static IP network settings"

                                font.pixelSize:
                                    15 * root.scale

                                color:
                                    "#71809A"
                            }
                        }
                    }

                    Rectangle {

                        Layout.fillWidth:
                            true

                        height:
                            1 * root.scale

                        color:
                            "#E5EAF2"
                    }

                    // =========================================
                    // LAN FORM
                    // =========================================

                    GridLayout {

                        Layout.fillWidth:
                            true

                        columns:
                            2

                        columnSpacing:
                            20 * root.scale

                        rowSpacing:
                            14 * root.scale

                        // =====================================
                        // IP ADDRESS
                        // =====================================

                        ColumnLayout {

                            Layout.fillWidth:
                                true

                            spacing:
                                6 * root.scale

                            Text {

                                text:
                                    "IP Address"

                                font.pixelSize:
                                    16 * root.scale

                                color:
                                    "#52627A"
                            }

                            Rectangle {

                                Layout.fillWidth:
                                    true

                                Layout.preferredHeight:
                                    56 * root.scale

                                radius:
                                    9 * root.scale

                                color:
                                    "#F8FAFD"

                                border.color:
                                    ipField.activeFocus
                                    ? "#1A4DB5"
                                    : "#D5DDEA"

                                border.width:
                                    ipField.activeFocus
                                    ? 2
                                    : 1

                                TextField {

                                    id:
                                        ipField

                                    anchors.fill:
                                        parent

                                    anchors.leftMargin:
                                        14 * root.scale

                                    anchors.rightMargin:
                                        14 * root.scale

                                    font.pixelSize:
                                        20 * root.scale

                                    color:
                                        "#1A4DB5"

                                    background:
                                        null

                                    padding:
                                        0

                                    verticalAlignment:
                                        TextInput.AlignVCenter

                                    placeholderText:
                                        "192.168.1.50"

                                    placeholderTextColor:
                                        "#A7B2C3"
                                }
                            }
                        }

                        // =====================================
                        // SUBNET
                        // =====================================

                        ColumnLayout {

                            Layout.fillWidth:
                                true

                            spacing:
                                6 * root.scale

                            Text {

                                text:
                                    "Subnet"

                                font.pixelSize:
                                    16 * root.scale

                                color:
                                    "#52627A"
                            }

                            Rectangle {

                                Layout.fillWidth:
                                    true

                                Layout.preferredHeight:
                                    56 * root.scale

                                radius:
                                    9 * root.scale

                                color:
                                    "#F8FAFD"

                                border.color:
                                    subnetField.activeFocus
                                    ? "#1A4DB5"
                                    : "#D5DDEA"

                                border.width:
                                    subnetField.activeFocus
                                    ? 2
                                    : 1

                                TextField {

                                    id:
                                        subnetField

                                    anchors.fill:
                                        parent

                                    anchors.leftMargin:
                                        14 * root.scale

                                    anchors.rightMargin:
                                        14 * root.scale

                                    font.pixelSize:
                                        20 * root.scale

                                    color:
                                        "#1A4DB5"

                                    background:
                                        null

                                    padding:
                                        0

                                    verticalAlignment:
                                        TextInput.AlignVCenter

                                    placeholderText:
                                        "24"

                                    placeholderTextColor:
                                        "#A7B2C3"
                                }
                            }
                        }

                        // =====================================
                        // GATEWAY
                        // =====================================

                        ColumnLayout {

                            Layout.fillWidth:
                                true

                            spacing:
                                6 * root.scale

                            Text {

                                text:
                                    "Gateway"

                                font.pixelSize:
                                    16 * root.scale

                                color:
                                    "#52627A"
                            }

                            Rectangle {

                                Layout.fillWidth:
                                    true

                                Layout.preferredHeight:
                                    56 * root.scale

                                radius:
                                    9 * root.scale

                                color:
                                    "#F8FAFD"

                                border.color:
                                    gatewayField.activeFocus
                                    ? "#1A4DB5"
                                    : "#D5DDEA"

                                border.width:
                                    gatewayField.activeFocus
                                    ? 2
                                    : 1

                                TextField {

                                    id:
                                        gatewayField

                                    anchors.fill:
                                        parent

                                    anchors.leftMargin:
                                        14 * root.scale

                                    anchors.rightMargin:
                                        14 * root.scale

                                    font.pixelSize:
                                        20 * root.scale

                                    color:
                                        "#1A4DB5"

                                    background:
                                        null

                                    padding:
                                        0

                                    verticalAlignment:
                                        TextInput.AlignVCenter

                                    placeholderText:
                                        "192.168.1.1"

                                    placeholderTextColor:
                                        "#A7B2C3"
                                }
                            }
                        }

                        // =====================================
                        // DNS
                        // =====================================

                        ColumnLayout {

                            Layout.fillWidth:
                                true

                            spacing:
                                6 * root.scale

                            Text {

                                text:
                                    "DNS"

                                font.pixelSize:
                                    16 * root.scale

                                color:
                                    "#52627A"
                            }

                            Rectangle {

                                Layout.fillWidth:
                                    true

                                Layout.preferredHeight:
                                    56 * root.scale

                                radius:
                                    9 * root.scale

                                color:
                                    "#F8FAFD"

                                border.color:
                                    dnsField.activeFocus
                                    ? "#1A4DB5"
                                    : "#D5DDEA"

                                border.width:
                                    dnsField.activeFocus
                                    ? 2
                                    : 1

                                TextField {

                                    id:
                                        dnsField

                                    anchors.fill:
                                        parent

                                    anchors.leftMargin:
                                        14 * root.scale

                                    anchors.rightMargin:
                                        14 * root.scale

                                    text:
                                        "8.8.8.8"

                                    font.pixelSize:
                                        20 * root.scale

                                    color:
                                        "#1A4DB5"

                                    background:
                                        null

                                    padding:
                                        0

                                    verticalAlignment:
                                        TextInput.AlignVCenter

                                    placeholderText:
                                        "8.8.8.8"

                                    placeholderTextColor:
                                        "#A7B2C3"
                                }
                            }
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
                                16 * root.scale

                            color:
                                "#1A4DB5"

                            elide:
                                Text.ElideRight
                        }
                    }

                    // =========================================
                    // APPLY BUTTON
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
                                20 * root.scale

                            color:
                                "#FFFFFF"
                        }

                        MouseArea {

                            id:
                                applyMouse

                            anchors.fill:
                                parent

                            onClicked: {

                                var result =
                                        NetworkManager.setStaticIP(
                                            "eth0",
                                            ipField.text,
                                            subnetField.text,
                                            gatewayField.text,
                                            dnsField.text
                                            )

                                resultText.text =
                                        result

                                if (notify)
                                    notify(result)
                            }
                        }
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
