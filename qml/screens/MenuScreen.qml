import QtQuick
import QtQuick.Controls

import "../components"

Item {
    anchors.fill: parent

    Rectangle {
        anchors.fill: parent
        color: "#F5F7FC"

        Grid {
            id: menuGrid
            anchors.centerIn: parent
            columns: 3
            rowSpacing: 36
            columnSpacing: 48



            MenuTile {
                iconSource: "qrc:/qt/qml/Application/assets/images/UserCircle.png"
                label: "User"
                iconSize: 88
                onTileClicked: console.log("User tapped")
            }

            MenuTile {
                iconSource: "qrc:/qt/qml/Application/assets/images/ProductLib.png"
                label: "Product Library"
                iconSize: 88
                onTileClicked: console.log("Product Library tapped")
            }

            MenuTile {
                iconSource: "qrc:/qt/qml/Application/assets/images/AuditTrail.png"
                label: "Audit Trial"
                iconSize: 88
                onTileClicked: console.log("Audit Trial tapped")
            }

            MenuTile {
                iconSource: "qrc:/qt/qml/Application/assets/images/FactorySettings.png"
                label: "Factory Settings"
                iconSize: 88
                onTileClicked: console.log("Factory Settings tapped")
            }

            MenuTile {
                iconSource: "qrc:/qt/qml/Application/assets/images/Settings.png"
                label: "System Settings"
                iconSize: 88
                onTileClicked: console.log("System Settings tapped")
            }

            MenuTile {
                iconSource: "qrc:/qt/qml/Application/assets/images/More.png"
                label: "More"
                iconSize: 88
                onTileClicked: console.log("More tapped")
            }
        }
    }
}
