import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.VirtualKeyboard
import AppState 1.0

import "screens"
import "components"

Window {
    id: root
    visible: true
    width: 1024
    height: 600
    title: "Dashboard"
    color: "#F5F7FC"

    // flags: Qt.FramelessWindowHint
    // visibility: Window.FullScreen

    // Track current menu screen
    property string currentMenuScreen: ""

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
                if (currentMenuScreen !== "" && currentMenuScreen !== "Menu") {
                    currentMenuScreen = "Menu"
                    menuLoader.source = "screens/MenuScreen.qml"

                } else if (currentMenuScreen === "Menu") {
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

            HomeScreen { showTopBar: false; globalTopBar: mainTopBar }
            DDusterScreen { showTopBar: false; globalTopBar: mainTopBar }
            AutoLearnScreen { showTopBar: false; globalTopBar: mainTopBar }
            SysDetailsScreen { showTopBar: false; globalTopBar: mainTopBar }

            onCurrentIndexChanged: navigator.currentPage = currentIndex
        }

        // ===== NAV INDICATOR =====
        NavPageIndicator {
            id: navigator
            visible: !menuLoader.visible
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(32, root.height * 0.015)

            pageCount: 4
            currentPage: swipeView.currentIndex

            onPreviousClicked: if (swipeView.currentIndex > 0) swipeView.currentIndex--
            onNextClicked: if (swipeView.currentIndex < pageCount - 1) swipeView.currentIndex++
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


    // ===== VIRTUAL KEYBOARD =====
        InputPanel {
            id: keyboard

            parent: root

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            z: 9999


            visible: GlobalState.loginKeyboardRequest

            y: visible ? parent.height - height : parent.height

            Behavior on y {
                NumberAnimation { duration: 250 }
            }
        }
}
