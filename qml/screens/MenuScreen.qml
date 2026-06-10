import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import AppState 1.0

import "../components"

Item {
    id: root
    anchors.fill: parent

    property var globalTopBar: null

    property real baseWidth: 1024
    property real baseHeight: 600
    property real scale: Math.min(width / baseWidth, height / baseHeight)

    AccessDeniedPopup {
        id: accessDeniedPopup
    }


    // =====================================================
    // PAGE OPEN ANIMATION
    // =====================================================

    opacity: 0.0

    property real pageScale: 0.85

    transform: Scale {
        origin.x: root.width / 2
        origin.y: root.height / 2

        xScale: root.pageScale
        yScale: root.pageScale
    }

    Component.onCompleted: {
        openAnimation.start()
    }

    // =====================================================
    // OPEN
    // =====================================================

    ParallelAnimation {
        id: openAnimation

        NumberAnimation {
            target: root
            property: "opacity"

            from: 0.0
            to: 1.0

            duration: 650

            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: root
            property: "pageScale"

            from: 0.85
            to: 1.0

            duration: 650

            easing.type: Easing.OutBack

            easing.overshoot: 1.05
        }
    }

    // =====================================================
    // CLOSE
    // =====================================================

    ParallelAnimation {
        id: closeAnimation

        NumberAnimation {
            target: root
            property: "opacity"

            from: 1.0
            to: 0.0

            duration: 500

            easing.type: Easing.InOutCubic
        }

        NumberAnimation {
            target: root
            property: "pageScale"

            from: 1.0
            to: 0.85

            duration: 500

            easing.type: Easing.InOutCubic
        }
    }

    function closePage() {
        closeAnimation.start()
    }

    property var navigateTo

    Rectangle {
        anchors.fill: parent
        color: "#F5F7FC"

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 36 * root.scale

            // Row 1 — 4 tiles
            RowLayout {
                spacing: 65 * root.scale
                Layout.alignment: Qt.AlignHCenter

                MenuTile {
                    iconSource: "qrc:/qt/qml/Application/assets/images/UserCircle.png"
                    label: "User"
                    iconSize: 100 * root.scale
                    onTileClicked: {

                        if (GlobalState.loggedInUserRole !== "Admin")
                        {
                            accessDeniedPopup.popupTitle = "Access Denied !"

                            accessDeniedPopup.popupMessage =
                                    "Only Admin can access"

                            accessDeniedPopup.open()
                            return
                        }

                        navigateTo("User")
                    }
                }
                MenuTile {

                    visible: GlobalState.showProductLib

                    iconSource: "qrc:/qt/qml/Application/assets/images/ProductLib.png"
                    label: "Product\nLibrary"
                    iconSize: 100 * root.scale
                    onTileClicked: {

                        if (GlobalState.loggedInUserRole !== "Admin")
                        {
                            accessDeniedPopup.popupTitle = "Access Denied !"

                            accessDeniedPopup.popupMessage =
                                    "Only Admin can access."

                            accessDeniedPopup.open()
                            return
                        }

                        navigateTo("ProductLibrary")
                    }
                }
                MenuTile {
                    iconSource: "qrc:/qt/qml/Application/assets/images/Reports.png"
                    label: "Reports"
                    iconSize: 100 * root.scale
                    onTileClicked: {

                        if (GlobalState.loggedInUserRole === "")
                        {
                            accessDeniedPopup.popupTitle = "Access Denied !"

                            accessDeniedPopup.popupMessage =
                                    "Please login first"

                            accessDeniedPopup.open()
                            return
                        }

                        navigateTo("Reports")
                    }
                }
            }

            // Row 2 — 3 tiles centered
            RowLayout {
                spacing: 65 * root.scale
                Layout.alignment: Qt.AlignHCenter

                MenuTile {
                    iconSource: "qrc:/qt/qml/Application/assets/images/FactorySettings.png"
                    label: "Factory\nSettings"
                    iconSize: 100 * root.scale
                    onTileClicked: {

                        if (GlobalState.loggedInUserRole !== "Admin")
                        {
                            accessDeniedPopup.popupTitle = "Access Denied !"

                            accessDeniedPopup.popupMessage =
                                    "Only Admin can access"

                            accessDeniedPopup.open()
                            return
                        }

                        navigateTo("FactorySettings")
                    }
                }
                MenuTile {
                    iconSource: "qrc:/qt/qml/Application/assets/images/Settings.png"
                    label: "System\nSettings"
                    iconSize: 100 * root.scale
                    onTileClicked: {

                        if (GlobalState.loggedInUserRole === "")
                        {
                            accessDeniedPopup.popupTitle = "Access Denied !"

                            accessDeniedPopup.popupMessage =
                                    "Please login first"

                            accessDeniedPopup.open()
                            return
                        }

                        navigateTo("SysSettings")
                    }
                }
                MenuTile {
                    iconSource: "qrc:/qt/qml/Application/assets/images/diagnosis.png"
                    label: "System\nDiagnosis"
                    iconSize: 100 * root.scale
                    onTileClicked: {

                        navigateTo("Diagnosis")
                    }
                }
            }
        }
    }
}
