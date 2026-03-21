import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Screens
import "screens"
import "components"

Window {
    id: root
    visible: true
    width: 1024
    height: 600
    title: "Dashboard"
    color: "#F5F7FC"

    // Uncomment for Raspberry Pi fullscreen
    // visibility: Window.FullScreen

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        TopBar {
            id: mainTopBar
            Layout.fillWidth: true
            height: Math.max(70, root.height * 0.08)
            userName: "Rahul1234567789"
            userRole: "Supervisor"
        }

        SwipeView {
            id: swipeView
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: 0

            HomeScreen {
                showTopBar: false
                globalTopBar: mainTopBar
            }

            DDusterScreen {
                showTopBar: false
                globalTopBar: mainTopBar
            }

            onCurrentIndexChanged: {
                navigator.currentPage = currentIndex
            }
        }

        NavPageIndicator {
            id: navigator
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(32, root.height * 0.015)
            scale: 0.85

            pageCount: 2
            currentPage: swipeView.currentIndex

            onPreviousClicked: {
                if (swipeView.currentIndex > 0) swipeView.currentIndex -= 1
            }
            onNextClicked: {
                if (swipeView.currentIndex < pageCount - 1) swipeView.currentIndex += 1
            }
        }
    }
}
 
