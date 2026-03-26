import QtQuick
import QtQuick.Controls
import "../components"

Item {
    id: root
    anchors.fill: parent

    property real baseWidth:  1024
    property real baseHeight: 600
    property real scale: Math.min(width / baseWidth, height / baseHeight)

    // function injected from Main.qml
    property var navigateTo

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
                    iconSource: "qrc:/qt/qml/Application/assets/images/supplier.png"
                    label:      "Supplier Info"
                    iconSize:   100 * root.scale
                    onTileClicked: {
                        console.log("Supplier Info tapped")
                        // TODO: navigateTo("SupplierInfo")
                    }
                }

                MenuTile {
                    iconSource: "qrc:/qt/qml/Application/assets/images/updated.png"
                    label:      "Software Update"
                    iconSize:   100 * root.scale
                    onTileClicked: {
                        console.log("Software Update tapped")
                        // TODO: navigateTo("SoftwareUpdate")
                    }
                }

                MenuTile {
                    iconSource: "qrc:/qt/qml/Application/assets/images/bug.png"
                    label:      "Debug Console"
                    iconSize:   100 * root.scale
                    onTileClicked: {
                        console.log("Debug Console tapped")
                        // TODO: navigateTo("DebugConsole")
                    }
                }
            }

            // ── Row 2: 3 tiles (col 1 & col 3 reserved for future) ───
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 70 * root.scale

                // ── SLOT 1: Add your future PNG here ───

                MenuTile {
                    iconSource: "qrc:/qt/qml/Application/assets/images/coding.png"
                    label:      "Developer Settings"
                    iconSize:   100 * root.scale
                    visible: true
                    enabled: false
                    onTileClicked: {
                        console.log("Slot 1 tapped")
                        // TODO: navigateTo("YourScreen1")
                    }
                }

                // ── Col 2: USB Software Update ───────
                MenuTile {
                    iconSource: "qrc:/qt/qml/Application/assets/images/usbupdate.png"
                    label:      "USB Software\nUpdate"
                    iconSize:   100 * root.scale
                    onTileClicked: {
                        console.log("USB Software Update tapped")
                        // TODO: navigateTo("UsbSoftwareUpdate")
                    }
                }

                // ── SLOT 3: Add your future PNG here ───────

                MenuTile {
                    iconSource: "qrc:/qt/qml/Application/assets/images/social.png"
                    label:      ""
                    iconSize:   100 * root.scale
                    visible: true
                    enabled: false
                    onTileClicked: {
                        console.log("Slot 3 tapped")
                        // TODO: navigateTo("YourScreen2")
                    }
                }
            }
        }
    }
}
