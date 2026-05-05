import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import AppState 1.0

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

            // ===== REPORT TILES =====
            RowLayout {
                spacing: 65 * root.scale
                Layout.alignment: Qt.AlignHCenter

                MenuTile {

                    visible: GlobalState.showAuditTrail

                    iconSource: "qrc:/qt/qml/Application/assets/images/AuditTrail.png"
                    label: "Audit Trail\nReport"
                    iconSize: 100 * root.scale
                    onTileClicked: navigateTo("AuditTrail")
                }

                MenuTile {
                    iconSource: "qrc:/qt/qml/Application/assets/images/More.png"
                    label: "Product/Batch\nReport"
                    iconSize: 100 * root.scale
                    onTileClicked: navigateTo("BatchReport")
                }

                MenuTile {
                    iconSource: "qrc:/qt/qml/Application/assets/images/folder.png"
                    label: "Reports\nFolder"
                    iconSize: 100 * root.scale
                    onTileClicked: navigateTo("ReportsFolder")
                }
            }
            RowLayout {
                spacing: 65 * root.scale
                Layout.alignment: Qt.AlignHCenter

                MenuTile {
                    iconSource: "qrc:/qt/qml/Application/assets/images/log.png"
                    label: "Reports\nLog"
                    iconSize: 100 * root.scale
                    onTileClicked: navigateTo("ReportsLog")
                }

                MenuTile {
                    iconSource: "qrc:/qt/qml/Application/assets/images/BatchHistory.png"
                    label: "Batch\nHistory"
                    iconSize: 100 * root.scale
                    onTileClicked: navigateTo("BatchHistory")
                }
            }
        }
    }
}
