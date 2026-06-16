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

    // flags: Qt.FramelessWindowHint
    // visibility: Window.FullScreen

    Timer {
        id: navigateHomeTimer
        interval: 1000
        repeat: false

        onTriggered: {
            navigateToHome()
        }
    }

    Connections {
        target: GlobalState

        function onLoggedInUserRoleChanged() {
            if (GlobalState.loggedInUserRole === "") {
                navigateHomeTimer.restart()
            }
        }
    }

    function navigateToHome() {

        // Close any menu screen
        menuLoader.visible = false
        menuLoader.source = ""

        // Reset menu navigation
        currentMenuScreen = ""
        menuStack = []

        swipeView.interactive = true

        // Show home page
        swipeView.visible = true
        swipeView.currentIndex = 0

        // Reset top bar
        mainTopBar.showBackButton = false
    }


    // =========================================================
    // TYPOGRAPHY SYSTEM
    // =========================================================

    Typography {
        id: typography
        scale: 1.0  // Base scale for main window
    }

    // Expose typography globally for child components
    property alias appTypography: typography

    // =========================================================
    // FONT LOADING
    // =========================================================

    FontLoader {
        id: appRegularFont
        source: "qrc:/qt/qml/Application/assets/images/RobotoCondensed-Regular.ttf"
    }

    FontLoader {
        id: appBoldFont
        source: "qrc:/qt/qml/Application/assets/images/RobotoCondensed-Bold.ttf"
    }

    // =========================================================
    // GLOBAL FONT
    // =========================================================

    property string regularFontFamily:
        appRegularFont.status === FontLoader.Ready
        && appRegularFont.name !== ""
        ? appRegularFont.name
        : "Sans Serif"

    property string boldFontFamily:
        appBoldFont.status === FontLoader.Ready
        && appBoldFont.name !== ""
        ? appBoldFont.name
        : "Sans Serif"

    font.family: regularFontFamily
    font.pixelSize: 20  // Set default base size for entire app


    // =========================================================
    // RECURSIVE FONT APPLICATION TO ALL CHILDREN
    // =========================================================
    // This ensures all Text and Controls inherit the root font

    function applyFontToAllChildren(item) {
        if (item === null) return

        if (item.font !== undefined) {
            item.font.family = root.regularFontFamily
        }

        if (item.children !== undefined) {
            for (var i = 0; i < item.children.length; i++) {
                applyFontToAllChildren(item.children[i])
            }
        }
    }

    // Apply fonts whenever regularFontFamily changes
    onRegularFontFamilyChanged: {
        applyFontToAllChildren(contentItem)

        if (Overlay.overlay)
                applyFontToAllChildren(Overlay.overlay)
    }

    // =========================================================
    // SWIPEVIEW SMOOTHNESS TUNING
    // =========================================================
    // SwipeView's Basic style implementation is backed internally by a
    // ListView (its `contentItem`). Tuning that ListView's flick/­highlight
    // properties is what actually controls how the drag/­release animation
    // feels - SwipeView itself exposes no easing/­velocity API directly.
    function tuneSwipeViewSmoothness() {
        var flick = swipeView.contentItem
        if (!flick) return

        // Snappier, consistent settle animation instead of the 250ms default
        if ("highlightMoveDuration" in flick)
            flick.highlightMoveDuration = 220

        // Let a fast finger flick travel further/faster without feeling capped
        if ("maximumFlickVelocity" in flick)
            flick.maximumFlickVelocity = 2500

        // Higher deceleration = page settles faster, feels less "floaty"
        if ("flickDeceleration" in flick)
            flick.flickDeceleration = 1500

        // Removes the ~150ms delay before a touch is recognized as a press,
        // which otherwise makes the very start of every swipe feel laggy
        if ("pressDelay" in flick)
            flick.pressDelay = 0

        // Never rubber-band past the first/last page
        if ("boundsBehavior" in flick)
            flick.boundsBehavior = Flickable.StopAtBounds
    }

    Component.onCompleted: {

        applyFontToAllChildren(root.contentItem)

        if (Overlay.overlay)
            applyFontToAllChildren(Overlay.overlay)

        tuneSwipeViewSmoothness()
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
            height: Math.max(63, root.height * 0.08)

            userName: "Rahul1234567789"
            userRole: "Supervisor"

            onMenuClicked: {
                swipeView.interactive = false
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
                    swipeView.interactive = true
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
                    // Apply fonts to newly loaded screen
                    root.applyFontToAllChildren(item)

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
            enabled: visible
            clip: true
            currentIndex: 0

            // ===== SMOOTHNESS TWEAKS =====
            interactive: true

            // Preload neighboring pages so swipe doesn't lag on first transition
            LayoutMirroring.enabled: false

            // Re-apply tuning any time the internal contentItem is recreated
            // (e.g. if the application style changes at runtime)
            onContentItemChanged: root.tuneSwipeViewSmoothness()

            HomeScreen {
                id: homePage
                showTopBar: false
                globalTopBar: mainTopBar
                // Cache this page as a texture: while SwipeView is panning,
                // the GPU just slides the cached bitmap instead of repainting
                // the whole Home screen tree every frame.
                layer.enabled: true
                layer.smooth: true
                navigateTo: function(screen) {
                    if (root.currentMenuScreen !== "")
                        root.menuStack.push(root.currentMenuScreen)
                    root.currentMenuScreen = screen
                    menuLoader.source = "screens/" + screen + "Screen.qml"
                    menuLoader.visible = true
                    swipeView.interactive = false
                    swipeView.visible = false
                    mainTopBar.showBackButton = true
                }
            }

            Loader {
                id: batchOrDDusterPage
                property bool showDDuster: GlobalState.showDDuster
                sourceComponent: showDDuster ? ddusterComp : batchComp
                asynchronous: true
                layer.enabled: true
                layer.smooth: true
            }

            AutoLearnScreen  {
                showTopBar: false
                globalTopBar: mainTopBar
                layer.enabled: true
                layer.smooth: true
            }
            CoilOutputScreen {
                showTopBar: false
                globalTopBar: mainTopBar
                layer.enabled: true
                layer.smooth: true
            }
            SysDetailsScreen {
                showTopBar: false
                globalTopBar: mainTopBar
                layer.enabled: true
                layer.smooth: true
            }

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
                GlobalState.showDDuster ? "Batch & DD" : "Batch Menu",
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
