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
        anchors.fill: parent

        color: "#F5F7FC"


        // ========================================================
        // LEFT - ANALOG GAUGE
        // ========================================================

        Item {
            id: leftCol

            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom

            width: parent.width * 0.30


            AnalogGauge {
                id: analogGauge

                anchors.fill: parent

                trackingCountLabel: "Tracking Phase"
                trackingPhase: root.trackingPhase
            }
        }


        // ========================================================
        // RIGHT - TRACKING PARAMETERS
        // ========================================================

        Item {
            id: rightCol

                anchors.left: leftCol.right
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom

                anchors.leftMargin: 102 * root.scale
                anchors.rightMargin: 32 * root.scale
                anchors.topMargin: 30 * root.scale
                anchors.bottomMargin: 30 * root.scale


            // ====================================================
            // HEADER
            // ====================================================

            Column {
                id: parametersHeader

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top

                spacing: 6 * root.scale


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
                    anchors.top: parametersHeader.bottom

                    anchors.topMargin: 22 * root.scale

                    width: parent.width * 0.82

                    spacing: 10 * root.scale


                // =================================================
                // TRACKING PHASE
                // =================================================

                Rectangle {
                    id: phaseBox

                    width: parent.width
                    height: 100 * root.scale

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

                        color: "#1A4DB5"

                        radius: 2
                    }


                    // ---------------------------------------------
                    // NUMBER
                    // ---------------------------------------------

                    Rectangle {
                        id: phaseNumber

                        anchors.left: parent.left
                        anchors.leftMargin: 22 * root.scale

                        anchors.verticalCenter: parent.verticalCenter

                        width: 42 * root.scale
                        height: 42 * root.scale

                        radius: 21 * root.scale

                        color: "#F0F4FB"


                        Text {
                            anchors.centerIn: parent

                            text: "01"

                            font.pixelSize: componentTypography.caption
                            font.weight: Font.Normal

                            color: "#1A4DB5"
                        }
                    }


                    // ---------------------------------------------
                    // DESCRIPTION
                    // ---------------------------------------------

                    Column {
                        anchors.left: phaseNumber.right
                        anchors.leftMargin: 18 * root.scale

                        anchors.verticalCenter: parent.verticalCenter

                        spacing: 3 * root.scale


                        Text {
                            text: "Tracking Phase"

                            font.pixelSize: componentTypography.bodySmall
                            font.weight: Font.Normal

                            color: "#333333"
                        }


                        Text {
                            text: "Current phase position"

                            font.pixelSize: componentTypography.small
                            font.weight: Font.Normal

                            color: "#777777"
                        }
                    }


                    // ---------------------------------------------
                    // VALUE
                    // ---------------------------------------------

                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 35 * root.scale

                        anchors.verticalCenter: parent.verticalCenter

                        text: root.trackingPhase + "°"

                        font.pixelSize: componentTypography.title
                        font.weight: Font.Normal

                        color: "#1A4DB5"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {

                            if (GlobalState.loggedInUserRole !== "Admin"
                                    && !GlobalState.developerLogin
                                    && !GlobalState.engineerLogin)
                            {
                                accessDeniedPopup.popupTitle = "Access Denied!"

                                accessDeniedPopup.popupMessage =
                                        "Only Admin can access"

                                accessDeniedPopup.open()
                                return
                            }

                            numberPopup.open(
                                "Tracking Phase",
                                root.trackingPhase,
                                function(value) {
                                    root.trackingPhase = value
                                },
                                0.0,
                                180.0
                            )
                        }
                    }
                }


                // =================================================
                // TRACKING COUNT
                // =================================================

                Rectangle {
                    id: countBox

                    width: parent.width
                    height: 100 * root.scale

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

                        color: "#1A4DB5"

                        radius: 2
                    }


                    // ---------------------------------------------
                    // NUMBER
                    // ---------------------------------------------

                    Rectangle {
                        id: countNumber

                        anchors.left: parent.left
                        anchors.leftMargin: 22 * root.scale

                        anchors.verticalCenter: parent.verticalCenter

                        width: 42 * root.scale
                        height: 42 * root.scale

                        radius: 21 * root.scale

                        color: "#F0F4FB"


                        Text {
                            anchors.centerIn: parent

                            text: "02"

                            font.pixelSize: componentTypography.caption
                            font.weight: Font.Normal

                            color: "#1A4DB5"
                        }
                    }


                    // ---------------------------------------------
                    // DESCRIPTION
                    // ---------------------------------------------

                    Column {
                        anchors.left: countNumber.right
                        anchors.leftMargin: 18 * root.scale

                        anchors.verticalCenter: parent.verticalCenter

                        spacing: 3 * root.scale


                        Text {
                            text: "Tracking Count"

                            font.pixelSize: componentTypography.bodySmall
                            font.weight: Font.Normal

                            color: "#333333"
                        }


                        Text {
                            text: "Current tracking count"

                            font.pixelSize: componentTypography.small
                            font.weight: Font.Normal

                            color: "#777777"
                        }
                    }


                    // ---------------------------------------------
                    // VALUE
                    // ---------------------------------------------

                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 35 * root.scale

                        anchors.verticalCenter: parent.verticalCenter

                        text: root.trackingCount

                        font.pixelSize: componentTypography.title
                        font.weight: Font.Normal

                        color: "#1A4DB5"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {

                            if (GlobalState.loggedInUserRole !== "Admin"
                                    && !GlobalState.developerLogin
                                    && !GlobalState.engineerLogin)
                            {
                                accessDeniedPopup.popupTitle = "Access Denied!"

                                accessDeniedPopup.popupMessage =
                                        "Only Admin can access"

                                accessDeniedPopup.open()
                                return
                            }

                            numberPopup.open(
                                "Tracking Count",
                                root.trackingCount,
                                function(value) {
                                    root.trackingCount = Math.round(value)
                                },
                                200,
                                90000
                            )
                        }
                    }
                }


                // =================================================
                // TRACKING THRESHOLD
                // =================================================

                Rectangle {
                    id: thresholdBox

                    width: parent.width
                    height: 100 * root.scale

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

                        color: "#1A4DB5"

                        radius: 2
                    }


                    // ---------------------------------------------
                    // NUMBER
                    // ---------------------------------------------

                    Rectangle {
                        id: thresholdNumber

                        anchors.left: parent.left
                        anchors.leftMargin: 22 * root.scale

                        anchors.verticalCenter: parent.verticalCenter

                        width: 42 * root.scale
                        height: 42 * root.scale

                        radius: 21 * root.scale

                        color: "#F0F4FB"


                        Text {
                            anchors.centerIn: parent

                            text: "03"

                            font.pixelSize: componentTypography.caption
                            font.weight: Font.Normal

                            color: "#1A4DB5"
                        }
                    }


                    // ---------------------------------------------
                    // DESCRIPTION
                    // ---------------------------------------------

                    Column {
                        anchors.left: thresholdNumber.right
                        anchors.leftMargin: 18 * root.scale

                        anchors.verticalCenter: parent.verticalCenter

                        spacing: 3 * root.scale


                        Text {
                            text: "Tracking Threshold"

                            font.pixelSize: componentTypography.bodySmall
                            font.weight: Font.Normal

                            color: "#333333"
                        }


                        Text {
                            text: "Maximum tracking threshold"

                            font.pixelSize: componentTypography.small
                            font.weight: Font.Normal

                            color: "#777777"
                        }
                    }


                    // ---------------------------------------------
                    // VALUE
                    // ---------------------------------------------

                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 35 * root.scale


                        anchors.verticalCenter: parent.verticalCenter

                        text: root.trackingThreshold

                        font.pixelSize: componentTypography.title
                        font.weight: Font.Normal

                        color: "#1A4DB5"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {

                            if (GlobalState.loggedInUserRole !== "Admin"
                                    && !GlobalState.developerLogin
                                    && !GlobalState.engineerLogin)
                            {
                                accessDeniedPopup.popupTitle = "Access Denied!"

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
                // TRACKING TOLERANCE
                // =================================================

                Rectangle {
                    id: toleranceBox

                    width: parent.width
                    height: 100 * root.scale

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

                        color: "#1A4DB5"

                        radius: 2
                    }


                    // ---------------------------------------------
                    // NUMBER
                    // ---------------------------------------------

                    Rectangle {
                        id: toleranceNumber

                        anchors.left: parent.left
                        anchors.leftMargin: 22 * root.scale

                        anchors.verticalCenter: parent.verticalCenter

                        width: 42 * root.scale
                        height: 42 * root.scale

                        radius: 21 * root.scale

                        color: "#F0F4FB"


                        Text {
                            anchors.centerIn: parent

                            text: "04"

                            font.pixelSize: componentTypography.caption
                            font.weight: Font.Normal

                            color: "#1A4DB5"
                        }
                    }


                    // ---------------------------------------------
                    // DESCRIPTION
                    // ---------------------------------------------

                    Column {
                        anchors.left: toleranceNumber.right
                        anchors.leftMargin: 18 * root.scale

                        anchors.verticalCenter: parent.verticalCenter

                        spacing: 3 * root.scale


                        Text {
                            text: "Tracking Tolerance"

                            font.pixelSize: componentTypography.bodySmall
                            font.weight: Font.Normal

                            color: "#333333"
                        }


                        Text {
                            text: "Allowed phase deviation"

                            font.pixelSize: componentTypography.small
                            font.weight: Font.Normal

                            color: "#777777"
                        }
                    }


                    // ---------------------------------------------
                    // VALUE
                    // ---------------------------------------------

                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 35 * root.scale

                        anchors.verticalCenter: parent.verticalCenter

                        text: "± " + root.trackingTolerance

                        font.pixelSize: componentTypography.title
                        font.weight: Font.Normal

                        color: "#1A4DB5"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {

                            if (GlobalState.loggedInUserRole !== "Admin"
                                    && !GlobalState.developerLogin
                                    && !GlobalState.engineerLogin)
                            {
                                accessDeniedPopup.popupTitle = "Access Denied!"

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
    // EXISTING POPUP
    // ============================================================

    CustomPopup {
        id: numberPopup
        parent: Overlay.overlay
        anchors.fill: parent
        z: 9999
        globalTopBar: root.globalTopBar
    }
}
