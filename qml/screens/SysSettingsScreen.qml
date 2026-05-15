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

    // ===== DYNAMIC PAGE MODEL =====
    property var pageModel: {
        var pages = [
            screen1,
            screennew,
            screen2,
            screen3,
            screen4
        ]

        if (GlobalState.showNetworkScreen)
            pages.push(screen5)

        pages.push(screen6)

        return pages
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

            Repeater {
                model: pageModel

                delegate: Loader {
                    width: swipeView.width
                    height: swipeView.height
                    sourceComponent: modelData
                }
            }

            onCurrentIndexChanged: indicator.currentPage = currentIndex
        }

        // ===== PAGE INDICATOR =====
        NavPageIndicator {
            id: indicator
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(32, root.height * 0.015)

            pageCount: pageModel.length
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

    // ===== HANDLE TOGGLE CHANGE =====
    Connections {
        target: GlobalState

        function onShowNetworkScreenChanged() {
            swipeView.currentIndex = 0
        }
    }

    // ================= COMPONENTS =================

    Component {
        id: screen1
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
    }

    Component {
        id: screennew

        Rectangle {
            color: "#F5F7FC"

            Item {
                anchors.centerIn: parent
                width: Math.min(parent.width * 0.9, 900 * root.scale)
                height: Math.min(parent.height * 0.9, 520 * root.scale)

                XyPlotScreen {
                    anchors.fill: parent
                }
            }
        }
    }

    Component {
        id: screen2
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
    }

    Component {
        id: screen3
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
    }

    Component {
        id: screen4
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
    }

    Component {
        id: screen5
        Rectangle {
            color: "#F5F7FC"

            Item {
                anchors.centerIn: parent
                width: Math.min(parent.width * 0.9, 900 * root.scale)
                height: Math.min(parent.height * 0.9, 520 * root.scale)

                SettingsS5 {
                    anchors.fill: parent
                    notify: root.notify
                    globalTopBar: root.globalTopBar
                }
            }
        }
    }

    Component {
        id: screen6
        Rectangle {
            color: "#F5F7FC"

            Item {
                anchors.centerIn: parent
                width: Math.min(parent.width * 0.9, 900 * root.scale)
                height: Math.min(parent.height * 0.9, 520 * root.scale)

                SettingsS6 {
                    anchors.fill: parent
                }
            }
        }
    }
}
