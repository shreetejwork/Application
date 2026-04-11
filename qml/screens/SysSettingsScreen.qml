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

    function notify(msg) {

        if (globalTopBar && globalTopBar.showNotification)
            globalTopBar.showNotification(msg)
    }

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

                Item {
                    anchors.centerIn: parent
                    width: Math.min(parent.width * 0.9, 900 * root.scale)
                    height: Math.min(parent.height * 0.9, 520 * root.scale)

                    SettingsS1 {
                        anchors.fill: parent

                        notify: root.notify

                        globalTopBar: root.globalTopBar

                        onFieldClicked: function(label) {
                            console.log("Clicked:", label)
                        }
                    }
                }
            }

            // ===== SCREEN 2 =====
            Rectangle {
                color: "#F5F7FC"

                Item {
                    anchors.centerIn: parent
                    width: Math.min(parent.width * 0.9, 900 * root.scale)
                    height: Math.min(parent.height * 0.9, 520 * root.scale)

                    SettingsS2 {
                        anchors.fill: parent
                        notify: root.notify
                        globalTopBar: root.globalTopBar
                    }
                }
            }

            // ===== SCREEN 3 =====
            Rectangle {
                color: "#F5F7FC"

                Item {
                    anchors.centerIn: parent
                    width: Math.min(parent.width * 0.9, 900 * root.scale)
                    height: Math.min(parent.height * 0.9, 520 * root.scale)

                    SettingsS3 {
                        anchors.fill: parent
                        notify: root.notify
                        globalTopBar: root.globalTopBar
                    }
                }
            }

            // ===== SCREEN 4 =====
            Rectangle {
                color: "#F5F7FC"

                Item {
                    anchors.centerIn: parent
                    width: Math.min(parent.width * 0.9, 900 * root.scale)
                    height: Math.min(parent.height * 0.9, 520 * root.scale)

                    SettingsS4 {
                        anchors.fill: parent
                        notify: root.notify
                        globalTopBar: root.globalTopBar
                    }
                }
            }
            // ===== SCREEN 5 =====
            Rectangle {
                color: "#F5F7FC"

                Item {
                    anchors.centerIn: parent
                    width: Math.min(parent.width * 0.9, 900 * root.scale)
                    height: Math.min(parent.height * 0.9, 520 * root.scale)

                    SettingsS5{
                        anchors.fill: parent
                        notify: root.notify
                        globalTopBar: root.globalTopBar
                    }
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

            onPreviousClicked: {
                if (swipeView.currentIndex > 0)
                    swipeView.currentIndex--
            }

            onNextClicked: {
                if (swipeView.currentIndex < pageCount - 1)
                    swipeView.currentIndex++
            }
        }
    }
}
