import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import AppState 1.0
import "../components"

Item {
    id: root

    anchors.fill: parent

    // =====================================================
    // RESPONSIVE SCALE
    // =====================================================

    property real baseWidth: 1024
    property real baseHeight: 600


    property real uiScale:
        Math.min(width / baseWidth,
                 height / baseHeight)

    property var globalTopBar

    // =====================================================
    // STATIC BACKDROP
    // =====================================================
    // This sits directly on root, fills the whole screen, and is NEVER
    // animated (no opacity/scale on it). It exists purely so that while
    // "content" below is fading/scaling in or out, there is always a solid
    // opaque surface behind it - so whatever screen is sitting underneath
    // (e.g. the Dashboard SwipeView, which is now kept alive in the
    // background for performance) can never peek through the edges during
    // the transition.

    Rectangle {
        id: backdrop
        anchors.fill: parent
        color: "#F5F7FC"
    }

    // =====================================================
    // ANIMATED CONTENT WRAPPER
    // =====================================================
    // Everything that used to animate directly on "root" now animates on
    // this wrapper instead. "root" and "backdrop" stay fully opaque and
    // full-size at all times.

    Item {
        id: content
        anchors.fill: parent

        // =================================================
        // PAGE OPEN ANIMATION
        // =================================================

        opacity: 0.0

        // THIS is Qt built-in transform scale
        scale: 0.85

        // =================================================
        // OPEN ANIMATION
        // =================================================

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
                property: "scale"

                from: 0.85
                to: 1.0

                duration: 650

                easing.type: Easing.OutBack
                easing.overshoot: 1.05
            }
        }

        // =================================================
        // CLOSE ANIMATION
        // =================================================

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
                property: "scale"

                from: 1.0
                to: 0.85

                duration: 500

                easing.type: Easing.InOutCubic
            }
        }

        // =================================================
        // MAIN LAYOUT
        // =================================================

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // =============================================
            // SWIPE VIEW
            // =============================================

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

                onCurrentIndexChanged: {
                    indicator.currentPage = currentIndex
                }
            }

            // =============================================
            // PAGE INDICATOR
            // =============================================

            NavPageIndicator {
                id: indicator

                Layout.fillWidth: true

                Layout.preferredHeight:
                    Math.max(
                        50,
                        root.height * 0.07)

                // =====================================
                // DYNAMIC SCREEN NAMES
                // =====================================

                pageNames: GlobalState.showNetworkScreen
                           ? [
                                 "Parameters",
                                 "XY - Plot",
                                 "Date & Time",
                                 "Validation Time",
                                 "About Machine",
                                 "Network",
                                 "Version"
                             ]
                           : [
                                 "Parameters",
                                 "XY - Plot",
                                 "Date & Time",
                                 "Validation Time",
                                 "About Machine",
                                 "Version"
                             ]

                currentPage: swipeView.currentIndex

                // =====================================
                // NAVIGATION
                // =====================================

                onPreviousClicked: {

                    if (swipeView.currentIndex > 0)
                        swipeView.currentIndex--
                }

                onNextClicked: {

                    if (swipeView.currentIndex < pageCount - 1)
                        swipeView.currentIndex++
                }

                onPageSelected: function(index) {

                    swipeView.currentIndex = index
                }
            }
        }
    }

    Component.onCompleted: {
        openAnimation.start()

        if (globalTopBar)
            globalTopBar.showBackButton = true
    }

    function closePage() {
        closeAnimation.start()
    }

    // =====================================================
    // NOTIFICATION
    // =====================================================

    function notify(msg) {
        if (globalTopBar && globalTopBar.showNotification)
            globalTopBar.showNotification(msg)
    }

    // =====================================================
    // DYNAMIC PAGE MODEL
    // =====================================================

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

    // =====================================================
    // HANDLE GLOBAL TOGGLE
    // =====================================================

    Connections {
        target: GlobalState

        function onShowNetworkScreenChanged() {
            swipeView.currentIndex = 0
        }
    }

    // =====================================================
    // SCREEN 1
    // =====================================================

    Component {
        id: screen1

        Rectangle {
            color: "#F5F7FC"

            Item {
                anchors.centerIn: parent

                width:
                    Math.min(parent.width * 0.9,
                             900 * root.uiScale)

                height:
                    Math.min(parent.height * 0.9,
                             520 * root.uiScale)

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

    // =====================================================
    // SCREEN NEW
    // =====================================================

    Component {
        id: screennew

        Rectangle {
            color: "#F5F7FC"

            Item {
                anchors.centerIn: parent

                width:
                    Math.min(parent.width * 0.9,
                             900 * root.uiScale)

                height:
                    Math.min(parent.height * 0.9,
                             520 * root.uiScale)

                XyPlotScreen {
                    anchors.fill: parent
                }
            }
        }
    }

    // =====================================================
    // SCREEN 2
    // =====================================================

    Component {
        id: screen2

        Rectangle {
            color: "#F5F7FC"

            Item {
                anchors.centerIn: parent

                width:
                    Math.min(parent.width * 0.9,
                             900 * root.uiScale)

                height:
                    Math.min(parent.height * 0.9,
                             520 * root.uiScale)

                SettingsS2 {
                    anchors.fill: parent

                    notify: root.notify
                    globalTopBar: root.globalTopBar
                }
            }
        }
    }

    // =====================================================
    // SCREEN 3
    // =====================================================

    Component {
        id: screen3

        Rectangle {
            color: "#F5F7FC"

            Item {
                anchors.centerIn: parent

                width:
                    Math.min(parent.width * 0.9,
                             900 * root.uiScale)

                height:
                    Math.min(parent.height * 0.9,
                             520 * root.uiScale)

                SettingsS3 {
                    anchors.fill: parent

                    notify: root.notify
                    globalTopBar: root.globalTopBar
                }
            }
        }
    }

    // =====================================================
    // SCREEN 4
    // =====================================================

    Component {
        id: screen4

        Rectangle {
            color: "#F5F7FC"

            Item {
                anchors.centerIn: parent

                width:
                    Math.min(parent.width * 0.9,
                             900 * root.uiScale)

                height:
                    Math.min(parent.height * 0.9,
                             520 * root.uiScale)

                SettingsS4 {
                    anchors.fill: parent

                    notify: root.notify
                    globalTopBar: root.globalTopBar
                }
            }
        }
    }

    // =====================================================
    // SCREEN 5
    // =====================================================

    Component {
        id: screen5

        Rectangle {
            color: "#F5F7FC"

            Item {
                anchors.centerIn: parent

                width:
                    Math.min(parent.width * 0.9,
                             900 * root.uiScale)

                height:
                    Math.min(parent.height * 0.9,
                             520 * root.uiScale)

                SettingsS5 {
                    anchors.fill: parent

                    notify: root.notify
                    globalTopBar: root.globalTopBar
                }
            }
        }
    }

    // =====================================================
    // SCREEN 6
    // =====================================================

    Component {
        id: screen6

        Rectangle {
            color: "#F5F7FC"

            Item {
                anchors.centerIn: parent

                width:
                    Math.min(parent.width * 0.9,
                             900 * root.uiScale)

                height:
                    Math.min(parent.height * 0.9,
                             520 * root.uiScale)

                SettingsS6 {
                    anchors.fill: parent
                }
            }
        }
    }
}
