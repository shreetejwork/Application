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

    property var globalTopBar


    Component.onCompleted: {
        if (globalTopBar) {
            globalTopBar.showBackButton = true
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ===== CONTENT SLIDER =====
        SwipeView {
            id: swipeView
            Layout.fillWidth: true
            Layout.fillHeight: true

            currentIndex: 0

            // ===== SCREEN 1 =====
            Rectangle {
                color: "#F5F7FC"

                SettingsS1 {
                    anchors.fill: parent

                    globalTopBar: root.globalTopBar

                    onFieldClicked: function(label) {
                        console.log("Clicked:", label)

                        // future use:
                        // open popup / keypad / change value
                    }
                }
            }

            // ===== SCREEN 2 =====
            Rectangle {
                color: "#F5F7FC"

                SettingsS2 {
                       anchors.fill: parent
                   }
            }

            // ===== SCREEN 3 =====
            Rectangle {
                color: "#F5F7FC"

                Text {
                    anchors.centerIn: parent
                    text: "System Settings - Page 3"
                    font.pixelSize: 28 * root.scale
                }
            }
            // ===== SCREEN 4 =====
            Rectangle {
                color: "#F5F7FC"

                Text {
                    anchors.centerIn: parent
                    text: "System Settings - Page 4"
                    font.pixelSize: 28 * root.scale
                }
            }

            onCurrentIndexChanged: indicator.currentPage = currentIndex
        }

        // ===== PAGE INDICATOR =====
        NavPageIndicator {
            id: indicator
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(32, root.height * 0.015)

            pageCount: swipeView.count
            currentPage: swipeView.currentIndex

            onPreviousClicked: if (swipeView.currentIndex > 0) swipeView.currentIndex--
            onNextClicked: if (swipeView.currentIndex < pageCount - 1) swipeView.currentIndex++
        }
    }
}
