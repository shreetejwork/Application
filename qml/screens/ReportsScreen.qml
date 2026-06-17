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
}
