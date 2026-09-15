import QtQuick
import QtQuick.Controls
import AppState 1.0
import "../components"

Item {
    id: root
    anchors.fill: parent

    property var updatePopup: null

    UsbUpdatePopup {
        id: usbUpdatePopup
        anchors.fill: parent
        z: 1000

        onStartRequested: UsbSoftwareUpdateManager.startUsbUpdate()
        onCancelRequested: UsbSoftwareUpdateManager.cancelUpdate()
        onConfirmRequested: UsbSoftwareUpdateManager.confirmRestart()
        onDeclineRequested: UsbSoftwareUpdateManager.declineRestart()
    }

    Connections {
        target: UsbSoftwareUpdateManager

        function onUpdateStatusChanged() {
            usbUpdatePopup.statusText = UsbSoftwareUpdateManager.updateStatus
        }

        function onUpdateProgressChanged() {
            usbUpdatePopup.progress = UsbSoftwareUpdateManager.updateProgress
        }

        function onUpdateRunningChanged() {
            usbUpdatePopup.isRunning = UsbSoftwareUpdateManager.updateRunning
        }

        function onUpdateFinishedChanged() {
            usbUpdatePopup.canClose = UsbSoftwareUpdateManager.updateFinished
            if (UsbSoftwareUpdateManager.updateFinished && !UsbSoftwareUpdateManager.confirmationRequired && UsbSoftwareUpdateManager.updateError !== "") {
                usbUpdatePopup.showErrorMessage(UsbSoftwareUpdateManager.updateError)
            }
        }

        function onConfirmationRequiredChanged() {
            if (UsbSoftwareUpdateManager.confirmationRequired) {
                usbUpdatePopup.showSuccessConfirmation()
            }
        }

        function onUpdateErrorChanged() {
            if (UsbSoftwareUpdateManager.updateError !== "") {
                usbUpdatePopup.showErrorMessage(UsbSoftwareUpdateManager.updateError)
            }
        }
    }

    property real baseWidth:  1024
    property real baseHeight: 600
    property real scale: Math.min(width / baseWidth, height / baseHeight)

    // =====================================================
    // STATIC BACKDROP
    // =====================================================

    Rectangle {
        id: backdrop
        anchors.fill: parent
        color: "#F5F7FC"
    }

    // =====================================================
    // PAGE OPEN ANIMATION
    // =====================================================

    Component.onCompleted: {
        openAnimation.start()
    }

    // =====================================================
    // OPEN
    // =====================================================

    ParallelAnimation {
        id: openAnimation

        NumberAnimation {
            target: content
            property: "opacity"

            from: 0.0
            to: 1.0

            duration: 650

            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: content
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
            target: content
            property: "opacity"

            from: 1.0
            to: 0.0

            duration: 500

            easing.type: Easing.InOutCubic
        }

        NumberAnimation {
            target: content
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

    // function injected from Main.qml
    property var navigateTo

    Item {
        id: content
        anchors.fill: parent

        opacity: 0.0
        property real pageScale: 0.85

        transform: Scale {
            origin.x: content.width / 2
            origin.y: content.height / 2

            xScale: content.pageScale
            yScale: content.pageScale
        }

        Rectangle {
            anchors.fill: parent
            color: "#F5F7FC"

            Column {
                anchors.centerIn: parent
                spacing: 40 * root.scale

                // ── Row 1: 3 tiles ───────
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 70 * root.scale

                    MenuTile {
                        iconSource: "qrc:/qt/qml/Application/assets/images/updated.png"
                        label:      "Software Update \n(Online)"
                        iconSize:   100 * root.scale
                        onTileClicked: {
                            console.log("Software Update tapped")
                            // TODO: navigateTo("SoftwareUpdate")
                        }
                    }

                    MenuTile {
                        iconSource: "qrc:/qt/qml/Application/assets/images/usbupdate.png"
                        label:      "Software Update \n(USB)"
                        iconSize:   100 * root.scale
                        onTileClicked: {
                            console.log("USB software update tapped")
                            usbUpdatePopup.openUpdate()
                        }
                    }
                }

                // ── Row 2: 3 tiles (col 1 & col 3 reserved for future) ───
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 70 * root.scale

                    // ── SLOT 1: Add your future PNG here ───

                    MenuTile {

                        visible: GlobalState.developerLogin

                        iconSource: "qrc:/qt/qml/Application/assets/images/coding.png"
                        label:      "Developer Settings"
                        iconSize:   100 * root.scale
                        enabled: true
                        onTileClicked: navigateTo("DeveloperSettings")
                    }

                    // ── SLOT 3: Add your future PNG here ───────

                    MenuTile {
                        iconSource: "qrc:/qt/qml/Application/assets/images/social.png"
                        label:      ""
                        iconSize:   100 * root.scale
                        visible: true
                        enabled: true
                        onTileClicked: {
                            console.log("Slot 3 tapped")
                            // TODO: navigateTo("YourScreen2")
                        }
                    }

                    MenuTile {
                        iconSource: "qrc:/qt/qml/Application/assets/images/bug.png"
                        label:      "Debug Console"
                        iconSize:   100 * root.scale
                        visible: true
                        enabled: true
                        onTileClicked: {
                            navigateTo("DebugConsole")
                            console.log("Bug tapped")
                        }
                    }
                }
            }
        }
    }
}
