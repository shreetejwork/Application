import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "screens"
import "components"

Window {
    id: root
    visible: true
    width: 1024
    height: 600
    title: "Dashboard"
    color: "#F5F7FC"

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

            // ===== MENU CLICK =====
            onMenuClicked: {
                menuLoader.source = "screens/MenuScreen.qml"
                menuLoader.visible = true
                swipeView.visible = false
                mainTopBar.showBackButton = true
            }

            // ===== BACK CLICK =====
            onBackClicked: {
                menuLoader.visible = false
                menuLoader.source = ""
                swipeView.visible = true
                swipeView.currentIndex = 0
                mainTopBar.showBackButton = false
            }
        }

        // ===== MENU SCREEN LOADER =====
        Loader {
            id: menuLoader
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: false
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
            }

            DDusterScreen {
                showTopBar: false
                globalTopBar: mainTopBar
            }

            AutoLearnScreen {
                showTopBar: false
                globalTopBar: mainTopBar
            }

            SysDetailsScreen {
                showTopBar: false
                globalTopBar: mainTopBar
            }

            onCurrentIndexChanged: {
                navigator.currentPage = currentIndex
            }
        }

        // ===== NAV INDICATOR =====
        NavPageIndicator {
            id: navigator
            visible: !menuLoader.visible
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(32, root.height * 0.015)

            pageCount: 4
            currentPage: swipeView.currentIndex

            onPreviousClicked: {
                if (swipeView.currentIndex > 0) swipeView.currentIndex--
            }

            onNextClicked: {
                if (swipeView.currentIndex < pageCount - 1) swipeView.currentIndex++
            }
        }
    }
}
