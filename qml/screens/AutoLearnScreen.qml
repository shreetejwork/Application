import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import AppState 1.0

import "../components"


Item {
    id: root


    // ============================================================
    // TYPOGRAPHY
    // ============================================================

    Typography {
        id: componentTypography
        scale: root.scale || 1.0
    }


    // ============================================================
    // ACCESS DENIED POPUP
    // ============================================================

    AccessDeniedPopup {
        id: accessDeniedPopup
    }


    // ============================================================
    // PROPERTIES
    // ============================================================

    property bool showTopBar: true
    property var globalTopBar


    // ============================================================
    // TRACKING PARAMETERS
    // ============================================================

    property real trackingPhase: 50
    property real trackingTolerance: 5
    property int trackingCount: 120
    property real trackingThreshold: 75

    property bool trackingEnabled: true


    // ============================================================
    // BASE SIZE
    // ============================================================

    property real baseWidth: 1024
    property real baseHeight: 600

    property real scale: Math.min(
                             width / baseWidth,
                             height / baseHeight
                             )


    // ============================================================
    // BACKGROUND
    // ============================================================

    Rectangle {
        id: mainBackground

        anchors.fill: parent

        color: "#F5F7FC"


        // ========================================================
        // LEFT COLUMN - ANALOG GAUGE
        // ========================================================

        Item {
            id: leftCol

            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom

            // 27% SCREEN WIDTH
            width: parent.width * 0.30


            AnalogGauge {
                id: analogGauge

                anchors.fill: parent

                anchors.margins: 8 * root.scale

                trackingCountLabel: "Tracking Phase"

                trackingPhase: root.trackingPhase
            }
        }


        // ========================================================
        // CENTRE COLUMN - SIGNAL + AMPLITUDE
        // ========================================================

        Item {
            id: centerCol

            anchors.left: leftCol.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom

            // 28% SCREEN WIDTH
            width: parent.width * 0.28


            Column {
                id: gaugesColumn

                anchors.fill: parent

                anchors.topMargin: 18 * root.scale
                anchors.bottomMargin: 18 * root.scale

                anchors.leftMargin: 5 * root.scale
                anchors.rightMargin: 5 * root.scale

                spacing: 12 * root.scale


                // =================================================
                // SIGNAL GAUGE
                // =================================================

                Item {
                    id: signalGaugeContainer

                    width: parent.width

                    height: (gaugesColumn.height
                             - gaugesColumn.spacing) / 2


                    CircularGauge {
                        id: signalGauge

                        anchors.centerIn: parent


                        // Keep circular gauge proportional
                        width: Math.min(
                                   parent.width * 0.90,
                                   parent.height * 0.94
                                   )

                        height: width


                        value: SerialManager.signal


                        label:
                            "Signal "
                            + "<span style='font-size:18px; color:#6B7280;'>"
                            + "(×"
                            + "<span style='font-size:18px;'>"
                            + GlobalState.digitalGain.toFixed(1)
                            + "</span>"
                            + ")"
                            + "</span>"


                        threshold: GlobalState.signalThreshold

                        thresholdLabel: "Threshold-S"

                        maxValue: 1200


                        // ------------------------------------------------
                        // IMPORTANT
                        // NO onThresholdClicked HERE
                        //
                        // Signal gauge is DISPLAY ONLY.
                        // ------------------------------------------------
                    }
                }


                // =================================================
                // AMPLITUDE GAUGE
                // =================================================

                Item {
                    id: amplitudeGaugeContainer

                    width: parent.width

                    height: (gaugesColumn.height
                             - gaugesColumn.spacing) / 2


                    CircularGauge {
                        id: ampGauge

                        anchors.centerIn: parent


                        // Same sizing logic as Signal Gauge
                        width: Math.min(
                                   parent.width * 0.90,
                                   parent.height * 0.94
                                   )

                        height: width


                        value: SerialManager.amplitude


                        label: "Amplitude"


                        threshold: GlobalState.amplitudeThreshold

                        thresholdLabel: "Threshold-A"

                        maxValue: 1200


                        // ------------------------------------------------
                        // IMPORTANT
                        // NO onThresholdClicked HERE
                        //
                        // Amplitude gauge is DISPLAY ONLY.
                        // ------------------------------------------------
                    }
                }
            }
        }


        // ========================================================
        // RIGHT COLUMN - TRACKING PARAMETERS
        // ========================================================

        Item {
            id: rightCol

            anchors.left: centerCol.right
            anchors.right: parent.right

            anchors.top: parent.top
            anchors.bottom: parent.bottom


            // Compact margins
            anchors.leftMargin: 18 * root.scale
            anchors.rightMargin: 22 * root.scale

            anchors.topMargin: 22 * root.scale
            anchors.bottomMargin: 22 * root.scale


            // ====================================================
            // HEADER
            // ====================================================

            Column {
                id: parametersHeader

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top

                spacing: 5 * root.scale


                Text {
                    text: "Tracking Parameters"

                    font.pixelSize: componentTypography.title

                    font.weight: Font.Normal

                    color: "#1A4DB5"
                }


                Rectangle {

                    width: 55 * root.scale
                    height: 3 * root.scale

                    radius: height / 2

                    color: "#1A4DB5"
                }
            }


            // ====================================================
            // PARAMETERS
            // ====================================================

            Column {
                id: parametersColumn

                anchors.left: parent.left
                anchors.right: parent.right

                anchors.top: parametersHeader.bottom

                anchors.topMargin: 20 * root.scale

                spacing: 25 * root.scale


                Rectangle {
                    id: trackingButtonBox

                    width: parent.width
                    height: 88 * root.scale

                    radius: 12 * root.scale

                    color: "#FFFFFF"

                    border.width: 1
                    border.color: "#DCE2EB"


                    // =========================================================
                    // BLUE SIDE INDICATOR
                    // =========================================================

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom

                        width: 5 * root.scale

                        radius: 2

                        color: root.trackingEnabled
                               ? "#1A4DB5"
                               : "#9CA3AF"
                    }


                    // =========================================================
                    // TRACKING ICON / NUMBER
                    // =========================================================

                    Rectangle {
                        id: trackingNumber

                        anchors.left: parent.left
                        anchors.leftMargin: 16 * root.scale

                        anchors.verticalCenter: parent.verticalCenter

                        width: 38 * root.scale
                        height: 38 * root.scale

                        radius: 19 * root.scale

                        color: root.trackingEnabled
                               ? "#E8EEFB"
                               : "#F0F0F0"


                        Text {
                            anchors.centerIn: parent

                            text: root.trackingEnabled ? "ON" : "OFF"

                            font.pixelSize: componentTypography.small


                            color: root.trackingEnabled
                                   ? "#1A4DB5"
                                   : "#777777"
                        }
                    }


                    // =========================================================
                    // DESCRIPTION
                    // =========================================================

                    Column {
                        anchors.left: trackingNumber.right
                        anchors.leftMargin: 12 * root.scale

                        anchors.verticalCenter: parent.verticalCenter

                        spacing: 2 * root.scale


                        Text {
                            text: "Tracking"

                            font.pixelSize: componentTypography.bodySmall
                            font.weight: Font.Normal

                            color: "#333333"
                        }


                        Text {
                            text: root.trackingEnabled
                                  ? "Tracking system is enabled"
                                  : "Tracking system is disabled"

                            font.pixelSize: componentTypography.small

                            color: "#777777"
                        }
                    }


                    // =========================================================
                    // ON / OFF SWITCH
                    // =========================================================

                    Rectangle {
                        id: trackingSwitch

                        anchors.right: parent.right
                        anchors.rightMargin: 20 * root.scale

                        anchors.verticalCenter: parent.verticalCenter

                        width: 90 * root.scale
                        height: 42 * root.scale

                        radius: height / 2

                        color: root.trackingEnabled
                               ? "#1A4DB5"
                               : "#D1D5DB"

                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }
                        }


                        Text {
                            anchors.centerIn: parent

                            text: root.trackingEnabled
                                  ? "ON"
                                  : "OFF"

                            font.pixelSize: componentTypography.bodySmall


                            color: root.trackingEnabled
                                   ? "white"
                                   : "#555555"
                        }
                    }


                    // =========================================================
                    // CLICK
                    // =========================================================

                    MouseArea {
                        anchors.fill: parent

                        cursorShape: Qt.PointingHandCursor


                        onClicked: {

                            // -------------------------------------------------
                            // ACCESS CHECK
                            // -------------------------------------------------

                            if (GlobalState.loggedInUserRole !== "Admin"
                                    && !GlobalState.developerLogin
                                    && !GlobalState.engineerLogin)
                            {
                                accessDeniedPopup.popupTitle =
                                        "Access Denied!"

                                accessDeniedPopup.popupMessage =
                                        "Only Admin can access"

                                accessDeniedPopup.open()

                                return
                            }


                            // -------------------------------------------------
                            // TOGGLE TRACKING
                            // -------------------------------------------------

                            root.trackingEnabled = !root.trackingEnabled


                            // -------------------------------------------------
                            // OPTIONAL NOTIFICATION
                            // -------------------------------------------------

                            if (root.globalTopBar) {

                                root.globalTopBar.showNotification(
                                    root.trackingEnabled
                                    ? "✓ Tracking Enabled"
                                    : "Tracking Disabled"
                                )

                                root.globalTopBar.resetSessionTimer()
                            }
                        }
                    }
                }


                // =================================================
                // 02 - TRACKING COUNT
                // =================================================

                Rectangle {
                    id: countBox

                    width: parent.width
                    height: 88 * root.scale

                    radius: 12 * root.scale

                    color: "#FFFFFF"

                    border.width: 1
                    border.color: "#DCE2EB"


                    // ---------------------------------------------
                    // BLUE SIDE INDICATOR
                    // ---------------------------------------------

                    Rectangle {

                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom

                        width: 5 * root.scale

                        radius: 2

                        color: "#1A4DB5"
                    }


                    // ---------------------------------------------
                    // NUMBER
                    // ---------------------------------------------

                    Rectangle {
                        id: countNumber

                        anchors.left: parent.left

                        anchors.leftMargin: 16 * root.scale

                        anchors.verticalCenter: parent.verticalCenter


                        width: 38 * root.scale
                        height: 38 * root.scale

                        radius: 19 * root.scale


                        color: "#F0F4FB"


                        Text {

                            anchors.centerIn: parent

                            text: "01"

                            font.pixelSize: componentTypography.caption

                            color: "#1A4DB5"
                        }
                    }


                    // ---------------------------------------------
                    // VALUE
                    // ---------------------------------------------

                    Text {
                        id: countValue

                        anchors.right: parent.right

                        anchors.rightMargin: 20 * root.scale

                        anchors.verticalCenter: parent.verticalCenter


                        text: root.trackingCount

                        font.pixelSize: componentTypography.title

                        font.weight: Font.Normal

                        color: "#1A4DB5"
                    }


                    // ---------------------------------------------
                    // DESCRIPTION
                    // ---------------------------------------------

                    Column {

                        anchors.left: countNumber.right

                        anchors.leftMargin: 12 * root.scale

                        anchors.right: countValue.left

                        anchors.rightMargin: 20 * root.scale

                        anchors.verticalCenter: parent.verticalCenter


                        spacing: 2 * root.scale


                        Text {

                            width: parent.width

                            text: "Tracking Count"

                            elide: Text.ElideRight


                            font.pixelSize: componentTypography.bodySmall

                            color: "#333333"
                        }


                        Text {

                            width: parent.width

                            text: "Current tracking count"

                            elide: Text.ElideRight


                            font.pixelSize: componentTypography.small

                            color: "#777777"
                        }
                    }


                    // ---------------------------------------------
                    // CLICK
                    // ---------------------------------------------

                    MouseArea {

                        anchors.fill: parent

                        cursorShape: Qt.PointingHandCursor


                        onClicked: {

                            if (GlobalState.loggedInUserRole !== "Admin"
                                    && !GlobalState.developerLogin
                                    && !GlobalState.engineerLogin)
                            {
                                accessDeniedPopup.popupTitle =
                                        "Access Denied!"

                                accessDeniedPopup.popupMessage =
                                        "Only Admin can access"

                                accessDeniedPopup.open()

                                return
                            }


                            numberPopup.open(

                                "Tracking Count",

                                root.trackingCount,

                                function(value) {

                                    root.trackingCount =
                                            Math.round(value)
                                },

                                200,

                                90000
                            )
                        }
                    }
                }


                // =================================================
                // 03 - TRACKING THRESHOLD
                // =================================================

                Rectangle {
                    id: thresholdBox

                    width: parent.width
                    height: 88 * root.scale

                    radius: 12 * root.scale

                    color: "#FFFFFF"

                    border.width: 1
                    border.color: "#DCE2EB"


                    // ---------------------------------------------
                    // BLUE SIDE INDICATOR
                    // ---------------------------------------------

                    Rectangle {

                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom

                        width: 5 * root.scale

                        radius: 2

                        color: "#1A4DB5"
                    }


                    // ---------------------------------------------
                    // NUMBER
                    // ---------------------------------------------

                    Rectangle {
                        id: thresholdNumber

                        anchors.left: parent.left

                        anchors.leftMargin: 16 * root.scale

                        anchors.verticalCenter: parent.verticalCenter


                        width: 38 * root.scale
                        height: 38 * root.scale

                        radius: 19 * root.scale


                        color: "#F0F4FB"


                        Text {

                            anchors.centerIn: parent

                            text: "02"

                            font.pixelSize: componentTypography.caption

                            color: "#1A4DB5"
                        }
                    }


                    // ---------------------------------------------
                    // VALUE
                    // ---------------------------------------------

                    Text {
                        id: thresholdValue

                        anchors.right: parent.right

                        anchors.rightMargin: 20 * root.scale

                        anchors.verticalCenter: parent.verticalCenter


                        text: root.trackingThreshold

                        font.pixelSize: componentTypography.title

                        font.weight: Font.Normal

                        color: "#1A4DB5"
                    }


                    // ---------------------------------------------
                    // DESCRIPTION
                    // ---------------------------------------------

                    Column {

                        anchors.left: thresholdNumber.right

                        anchors.leftMargin: 12 * root.scale

                        anchors.right: thresholdValue.left

                        anchors.rightMargin: 20 * root.scale

                        anchors.verticalCenter: parent.verticalCenter


                        spacing: 2 * root.scale


                        Text {

                            width: parent.width

                            text: "Tracking Threshold"

                            elide: Text.ElideRight


                            font.pixelSize: componentTypography.bodySmall

                            color: "#333333"
                        }


                        Text {

                            width: parent.width

                            text: "Maximum tracking threshold"

                            elide: Text.ElideRight


                            font.pixelSize: componentTypography.small

                            color: "#777777"
                        }
                    }


                    // ---------------------------------------------
                    // CLICK
                    // ---------------------------------------------

                    MouseArea {

                        anchors.fill: parent

                        cursorShape: Qt.PointingHandCursor


                        onClicked: {

                            if (GlobalState.loggedInUserRole !== "Admin"
                                    && !GlobalState.developerLogin
                                    && !GlobalState.engineerLogin)
                            {
                                accessDeniedPopup.popupTitle =
                                        "Access Denied!"

                                accessDeniedPopup.popupMessage =
                                        "Only Admin can access"

                                accessDeniedPopup.open()

                                return
                            }


                            numberPopup.open(

                                "Tracking Threshold",

                                root.trackingThreshold,

                                function(value) {

                                    root.trackingThreshold = value
                                },

                                200,

                                6000
                            )
                        }
                    }
                }


                // =================================================
                // 04 - TRACKING TOLERANCE
                // =================================================

                Rectangle {
                    id: toleranceBox

                    width: parent.width
                    height: 88 * root.scale

                    radius: 12 * root.scale

                    color: "#FFFFFF"

                    border.width: 1
                    border.color: "#DCE2EB"


                    // ---------------------------------------------
                    // BLUE SIDE INDICATOR
                    // ---------------------------------------------

                    Rectangle {

                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom

                        width: 5 * root.scale

                        radius: 2

                        color: "#1A4DB5"
                    }


                    // ---------------------------------------------
                    // NUMBER
                    // ---------------------------------------------

                    Rectangle {
                        id: toleranceNumber

                        anchors.left: parent.left

                        anchors.leftMargin: 16 * root.scale

                        anchors.verticalCenter: parent.verticalCenter


                        width: 38 * root.scale
                        height: 38 * root.scale

                        radius: 19 * root.scale


                        color: "#F0F4FB"


                        Text {

                            anchors.centerIn: parent

                            text: "03"

                            font.pixelSize: componentTypography.caption

                            color: "#1A4DB5"
                        }
                    }


                    // ---------------------------------------------
                    // VALUE
                    // ---------------------------------------------

                    Text {
                        id: toleranceValue

                        anchors.right: parent.right

                        anchors.rightMargin: 20 * root.scale

                        anchors.verticalCenter: parent.verticalCenter


                        text: "± " + root.trackingTolerance

                        font.pixelSize: componentTypography.title

                        font.weight: Font.Normal

                        color: "#1A4DB5"
                    }


                    // ---------------------------------------------
                    // DESCRIPTION
                    // ---------------------------------------------

                    Column {

                        anchors.left: toleranceNumber.right

                        anchors.leftMargin: 12 * root.scale

                        anchors.right: toleranceValue.left

                        anchors.rightMargin: 20 * root.scale

                        anchors.verticalCenter: parent.verticalCenter


                        spacing: 2 * root.scale


                        Text {

                            width: parent.width

                            text: "Tracking Tolerance"

                            elide: Text.ElideRight


                            font.pixelSize: componentTypography.bodySmall

                            color: "#333333"
                        }


                        Text {

                            width: parent.width

                            text: "Allowed phase deviation"

                            elide: Text.ElideRight


                            font.pixelSize: componentTypography.small

                            color: "#777777"
                        }
                    }


                    // ---------------------------------------------
                    // CLICK
                    // ---------------------------------------------

                    MouseArea {

                        anchors.fill: parent

                        cursorShape: Qt.PointingHandCursor


                        onClicked: {

                            if (GlobalState.loggedInUserRole !== "Admin"
                                    && !GlobalState.developerLogin
                                    && !GlobalState.engineerLogin)
                            {
                                accessDeniedPopup.popupTitle =
                                        "Access Denied!"

                                accessDeniedPopup.popupMessage =
                                        "Only Admin can access"

                                accessDeniedPopup.open()

                                return
                            }


                            numberPopup.open(

                                "Tracking Tolerance",

                                root.trackingTolerance,

                                function(value) {

                                    root.trackingTolerance = value
                                },

                                0.5,

                                5.0
                            )
                        }
                    }
                }
            }
        }
    }


    // ============================================================
    // COMMON NUMBER EDIT POPUP
    // ============================================================

    CustomPopup {
        id: numberPopup

        parent: Overlay.overlay

        anchors.fill: parent

        z: 9999

        globalTopBar: root.globalTopBar
    }
}
