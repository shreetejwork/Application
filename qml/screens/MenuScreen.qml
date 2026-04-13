import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Item {
    id: root
    anchors.fill: parent

    property real baseWidth: 1024
    property real baseHeight: 600
    property real scale: Math.min(width / baseWidth, height / baseHeight)
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
                    onTileClicked: navigateTo("User")
                }
                MenuTile {
                    iconSource: "qrc:/qt/qml/Application/assets/images/ProductLib.png"
                    label: "Product\nLibrary"
                    iconSize: 100 * root.scale
                    onTileClicked: navigateTo("ProductLibrary")
                }
                MenuTile {
                    iconSource: "qrc:/qt/qml/Application/assets/images/AuditTrail.png"
                    label: "Audit Trial\nReport"
                    iconSize: 100 * root.scale
                    onTileClicked: navigateTo("AuditTrail")
                }
                MenuTile {
                    iconSource: "qrc:/qt/qml/Application/assets/images/More.png"
                    label: "Product/Batch\nReport"
                    iconSize: 100 * root.scale
                    onTileClicked: navigateTo("BatchReport")
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
                    onTileClicked: navigateTo("FactorySettings")
                }
                MenuTile {
                    iconSource: "qrc:/qt/qml/Application/assets/images/Settings.png"
                    label: "System\nSettings"
                    iconSize: 100 * root.scale
                    onTileClicked: navigateTo("SysSettings")
                }
                MenuTile {
                    iconSource: "qrc:/qt/qml/Application/assets/images/diagnosis.png"
                    label: "System\nDiagnosis"
                    iconSize: 100 * root.scale
                    onTileClicked: navigateTo("Diagnosis")
                }
            }
        }
    }
}
