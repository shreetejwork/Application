import QtQuick
import QtQuick.Controls
import "../components"

Item {
    id: root
    anchors.fill: parent


    property real baseWidth: 1024
    property real baseHeight: 600


    property real scale: Math.min(width / baseWidth, height / baseHeight)

    // function injected from Main.qml
    property var navigateTo

    Rectangle {
        anchors.fill: parent
        color: "#F5F7FC"

        Grid {
            anchors.centerIn: parent
            columns: 3


            rowSpacing: 36 * root.scale
            columnSpacing: 65 * root.scale

            MenuTile {
                iconSource: "qrc:/qt/qml/Application/assets/images/UserCircle.png"
                label: "User"
                iconSize: 100 * root.scale

                onTileClicked: {
                    console.log("User tapped")
                    navigateTo("User")
                }
            }

            MenuTile {
                iconSource: "qrc:/qt/qml/Application/assets/images/ProductLib.png"
                label: "Product\nLibrary"
                iconSize: 100 * root.scale
            }

            MenuTile {
                iconSource: "qrc:/qt/qml/Application/assets/images/AuditTrail.png"
                label: "Audit Trial\nReport"
                iconSize: 100 * root.scale
            }

            MenuTile {
                iconSource: "qrc:/qt/qml/Application/assets/images/FactorySettings.png"
                label: "Factory\nSettings"
                iconSize: 100 * root.scale
                onTileClicked: {
                    navigateTo("FactorySettings")
                }
            }

            MenuTile {
                iconSource: "qrc:/qt/qml/Application/assets/images/Settings.png"
                label: "System\nSettings"
                iconSize: 100 * root.scale
            }

            MenuTile {
                iconSource: "qrc:/qt/qml/Application/assets/images/More.png"
                label: "Product/Batch\nReport"
                iconSize: 100 * root.scale
            }
        }
    }
}
