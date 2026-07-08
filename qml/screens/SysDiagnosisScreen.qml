import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import AppState 1.0

import "../components"

Item {
    id: root
    anchors.fill: parent

    property bool showTopBar: true
    property var navigateTo

    property real baseWidth: 1024
    property real baseHeight: 600
    property real scale: Math.min(width / baseWidth,
                                  height / baseHeight)

    Rectangle {
        anchors.fill: parent
        color: "#F5F7FC"
    }

    Column {
        anchors.centerIn: parent
        spacing: 35 * root.scale

        Row {
            spacing: 60 * root.scale
            anchors.horizontalCenter: parent.horizontalCenter

            MenuTile {

                iconSource: "qrc:/qt/qml/Application/assets/images/barchart.png"
                label: "Coil Output"
                iconSize: 100 * root.scale

                onTileClicked: navigateTo("CoilOutput")
            }

            MenuTile {
                iconSource: "qrc:/qt/qml/Application/assets/images/axis.png"
                label: "X-Y Plot"
                iconSize: 100 * root.scale

                onTileClicked: navigateTo("XyPlot")
            }

            MenuTile {
                iconSource: "qrc:/qt/qml/Application/assets/images/cpu.png"
                label: "H/W Diagnosis"
                iconSize: 100 * root.scale

                onTileClicked: navigateTo("Diagnosis")
            }
        }
    }
}
