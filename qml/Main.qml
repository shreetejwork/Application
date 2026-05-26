import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import AppState 1.0

import "screens"
import "components"

ApplicationWindow {
    id: root
    visible: true
    width: 1024
    height: 600
    title: "Dashboard"
    color: "#F5F7FC"

    // =========================================================
        // FONT LOADING
        // =========================================================

        FontLoader {
            id: robotoRegular
            source: "qrc:/assets/global/RobotoCondensed-Regular.ttf"

            onStatusChanged: {
                console.log("Roboto Regular Status:", status)
                console.log("Roboto Regular Name:", name)
            }
        }

        FontLoader {
            id: robotoBold
            source: "qrc:/assets/global/RobotoCondensed-Bold.ttf"

            onStatusChanged: {
                console.log("Roboto Bold Status:", status)
                console.log("Roboto Bold Name:", name)
            }
        }


    // flags: Qt.FramelessWindowHint
    // visibility: Window.FullScreen

    Component.onCompleted: {
        // Custom keyboard initialization
    }

    Component {
        id: ddusterComp
        DDusterScreen {
            showTopBar: false
            globalTopBar: mainTopBar
        }
    }

    Component {
        id: batchComp
        BatchMenuScreen {
            showTopBar: false
            globalTopBar: mainTopBar
        }
    }

    // Track current menu screen
    property string currentMenuScreen: ""

    property var menuStack: []

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ===== TOP BAR =====
        TopBar {
            id: mainTopBar
            Layout.fillWidth: true
            height: Math.max(70, root.height * 0.08)

            userName: "Rahul1234567789"
            userRole: "Supervisor"

            onMenuClicked: {
                currentMenuScreen = "Menu"
                menuLoader.source = "screens/MenuScreen.qml"
                menuLoader.visible = true
                swipeView.visible = false
                mainTopBar.showBackButton = true
            }

            onBackClicked: {
                if (menuStack.length > 0) {
                    var previous = menuStack.pop()
                    currentMenuScreen = previous
                    menuLoader.source = "screens/" + previous + "Screen.qml"
                } else {
                    currentMenuScreen = ""
                    menuLoader.visible = false
                    menuLoader.source = ""
                    swipeView.visible = true
                    swipeView.currentIndex = 0
                    mainTopBar.showBackButton = false
                }
            }
        }

        // ===== MENU SCREEN LOADER =====
        Loader {
            id: menuLoader
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: false

            onLoaded: {
                if (item) {
                    if ("globalTopBar" in item)
                        item.globalTopBar = mainTopBar
                    item.navigateTo = function(screen) {
                        if (root.currentMenuScreen !== "")
                            root.menuStack.push(root.currentMenuScreen)

                        root.currentMenuScreen = screen
                        menuLoader.source = "screens/" + screen + "Screen.qml"
                    }
                }
            }
        }

        // ===== MAIN SCREENS =====
        SwipeView {
            id: swipeView
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !menuLoader.visible

            currentIndex: 0

            HomeScreen {
                showTopBar: false
                globalTopBar: mainTopBar

                navigateTo: function(screen) {

                    if (root.currentMenuScreen !== "")
                        root.menuStack.push(root.currentMenuScreen)

                    root.currentMenuScreen = screen

                    menuLoader.source = "screens/" + screen + "Screen.qml"
                    menuLoader.visible = true

                    swipeView.visible = false

                    mainTopBar.showBackButton = true
                }
            }

            Loader {
                property bool showDDuster: GlobalState.showDDuster
                sourceComponent: showDDuster ? ddusterComp : batchComp
            }

            AutoLearnScreen { showTopBar: false; globalTopBar: mainTopBar }
            CoilOutputScreen { showTopBar: false; globalTopBar: mainTopBar}
            SysDetailsScreen { showTopBar: false; globalTopBar: mainTopBar }

            onCurrentIndexChanged: navigator.currentPage = currentIndex
        }

        // ===== NAV INDICATOR =====
        NavPageIndicator {
            id: navigator

            visible: !menuLoader.visible

            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(32, root.height * 0.015)

            pageNames: [
                "Dashboard",
                "Batch & DD",
                "Tracking Phase",
                "Coil Output",
                "About Machine"
            ]

            currentPage: swipeView.currentIndex

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

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            GlobalState.globalDateTime = new Date()
        }
    }

    // ===== CUSTOM VIRTUAL KEYBOARD =====
    CommonKeyboard {
        id: customKeyboard

        parent: Overlay.overlay
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        z: 10000

        visible: GlobalState.loginKeyboardRequest

        y: visible ? parent.height - height : parent.height

        Behavior on y {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutCubic
            }
        }

        onVisibleChanged: {
            if (!visible) {
                if (GlobalState.activeInputField) {
                    GlobalState.activeInputField.focus = false
                    GlobalState.activeInputField = null
                }
            }
        }
    }
}
