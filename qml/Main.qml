import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import AppState 1.0

import Backend 1.0

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

        function onValidationAlarmTriggered()
        {
            console.log("Main.qml: Alarm Received")

            validationAlarmPopup.open()
        }
    }

    function navigateToHome() {

        menuLoader.active = false
        menuLoader.source = ""

        // Reset menu navigation
        currentMenuScreen = ""
        menuStack = []

        // Show home page
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

    function tuneSwipeViewSmoothness() {
        var flick = swipeView.contentItem
        if (!flick) return

        if ("highlightMoveDuration" in flick)
            flick.highlightMoveDuration = 220

        if ("maximumFlickVelocity" in flick)
            flick.maximumFlickVelocity = 2500

        if ("flickDeceleration" in flick)
            flick.flickDeceleration = 1500

        if ("pressDelay" in flick)
            flick.pressDelay = 0

        if ("boundsBehavior" in flick)
            flick.boundsBehavior = Flickable.StopAtBounds
    }

    Component.onCompleted: {

        applyFontToAllChildren(root.contentItem)

        if (Overlay.overlay)
            applyFontToAllChildren(Overlay.overlay)

        tuneSwipeViewSmoothness()

        startupTimer.start()
    }

    property var parameterQueue: []

    Timer {
        id: parameterSender

        interval: 10
        repeat: true

        onTriggered: {

            if (parameterQueue.length === 0) {
                stop()

                if (mainTopBar)
                    mainTopBar.showNotification(
                        "✓ Parameters sent successfully"
                    )

                return
            }

            var sendFunction = parameterQueue.shift()

            if (sendFunction)
                sendFunction()
        }
    }

    Timer {

        id: startupTimer

        interval: 1000
        repeat: false

        onTriggered: {

            if (mainTopBar)
                mainTopBar.showNotification("Sending parameters...")

            parameterQueue = []

            // ================= MACHINE SETTINGS =================

            var machineSettings =
                    databaseManager.getMachinePhaseSettings()

            if(machineSettings.machinePhase !== undefined)
            {
                GlobalState.machinePhase =
                        machineSettings.machinePhase

                parameterQueue.push(function() {

                    SerialManager.setMachinePhase(
                                Math.round(
                                    GlobalState.machinePhase * 10
                                ))
                })
            }

            if(machineSettings.signalThr !== undefined)
            {
                GlobalState.signalThreshold =
                        machineSettings.signalThr

                parameterQueue.push(function() {

                    SerialManager.setSignalThreshold(
                                GlobalState.signalThreshold)
                })
            }

            if(machineSettings.ampThr !== undefined)
            {
                GlobalState.amplitudeThreshold =
                        machineSettings.ampThr

                parameterQueue.push(function() {

                    SerialManager.setAmplitudeThreshold(
                                GlobalState.amplitudeThreshold)
                })
            }


            // ================= S1 SETTINGS =================

            var s1Settings =
                    databaseManager.getS1Settings()

            if(s1Settings.lpf !== undefined)
            {
                parameterQueue.push(function() {

                    SerialManager.setLPF(
                                s1Settings.lpf)
                })
            }

            if(s1Settings.hpf !== undefined)
            {
                parameterQueue.push(function() {

                    SerialManager.setHPF(
                                Math.round(
                                    s1Settings.hpf * 10))
                })
            }

            if(s1Settings.holdDelay !== undefined)
            {
                parameterQueue.push(function() {

                    SerialManager.setHoldDelay(
                                s1Settings.holdDelay)
                })
            }

            if(s1Settings.operateDelay !== undefined)
            {
                parameterQueue.push(function() {

                    SerialManager.setOperateDelay(
                                s1Settings.operateDelay)
                })
            }

            if(s1Settings.relayDelay !== undefined)
            {
                parameterQueue.push(function() {

                    SerialManager.setRelayDelay(
                                s1Settings.relayDelay)
                })
            }

            if(s1Settings.digitalGain !== undefined)
            {
                parameterQueue.push(function() {

                    SerialManager.setDigitalGain(
                                Math.round(
                                    s1Settings.digitalGain * 10))
                })
            }

            if(s1Settings.analogGain !== undefined)
            {
                parameterQueue.push(function() {

                    SerialManager.setAnalogGain(
                                s1Settings.analogGain)
                })
            }


            // ================= DD SETTINGS =================

            var ddSettings =
                    databaseManager.getDDSettings()

            if(ddSettings.ddFreq !== undefined)
            {
                parameterQueue.push(function() {

                    SerialManager.setDDFrequency(
                                Math.round(
                                    ddSettings.ddFreq * 10))
                })
            }

            if(ddSettings.ddPower !== undefined)
            {
                parameterQueue.push(function() {

                    SerialManager.setDDPower(
                                ddSettings.ddPower)
                })
            }


            // ================= START SENDING =================

            if(parameterQueue.length > 0)
                parameterSender.start()
            else if(mainTopBar)
                mainTopBar.showNotification(
                            "✓ Parameters sent successfully")
        }
    }

    property string lastTriggeredAlarmTime: ""


    Timer {

        id: validationAlarmTimer

        interval: 1000

        running: true

        repeat: true


        onTriggered:
        {

            var now = new Date()


            var currentTime =
                    Qt.formatTime(now,"HH:mm")


            var alarms =
                    GlobalState.getValidationTimers()


            for(var i = 0; i < alarms.length; i++)
            {

                var alarm = alarms[i]


                if(alarm.enabled &&
                   alarm.time === currentTime)
                {


                    if(root.lastTriggeredAlarmTime !== currentTime)
                    {

                        root.lastTriggeredAlarmTime = currentTime


                        GlobalState.triggerValidationAlarm()

                    }


                    break
                }
            }
        }
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
                currentMenuScreen = "Menu"
                menuLoader.source = "screens/MenuScreen.qml"
                menuLoader.active = true
                mainTopBar.showBackButton = true
            }

            onBackClicked: {
                if (menuStack.length > 0) {
                    var previous = menuStack.pop()
                    currentMenuScreen = previous
                    menuLoader.source = "screens/" + previous + "Screen.qml"
                } else {
                    currentMenuScreen = ""
                    menuLoader.active = false
                    menuLoader.source = ""
                    swipeView.currentIndex = 0
                    mainTopBar.showBackButton = false
                }
            }
        }

        // ===== SWIPEVIEW + MENU OVERLAY =====
        Item {
            id: contentArea
            Layout.fillWidth: true
            Layout.fillHeight: true

            // ===== MAIN SCREENS =====
            SwipeView {
                id: swipeView
                anchors.fill: parent
                z: 0
                clip: true
                currentIndex: 0

                enabled: !menuLoader.active

                // ===== SMOOTHNESS TWEAKS =====
                interactive: true


                LayoutMirroring.enabled: false

                onContentItemChanged: root.tuneSwipeViewSmoothness()

                HomeScreen {
                    id: homePage
                    showTopBar: false
                    globalTopBar: mainTopBar

                    layer.enabled: true
                    layer.smooth: true
                    navigateTo: function(screen) {
                        if (root.currentMenuScreen !== "")
                            root.menuStack.push(root.currentMenuScreen)
                        root.currentMenuScreen = screen
                        menuLoader.source = "screens/" + screen + "Screen.qml"
                        menuLoader.active = true
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

                SysDetailsScreen {
                    showTopBar: false
                    globalTopBar: mainTopBar
                    layer.enabled: true
                    layer.smooth: true
                }

                onCurrentIndexChanged: navigator.currentPage = currentIndex
            }

            // ===== MENU SCREEN LOADER =====
            Loader {
                id: menuLoader
                anchors.fill: parent
                z: 1
                active: false
                visible: active

                onLoaded: {
                    if (item) {
                        // Apply fonts to newly loaded screen
                        root.applyFontToAllChildren(item)

                        if ("globalTopBar" in item)
                            item.globalTopBar = mainTopBar

                        if ("navigateTo" in item)
                            item.navigateTo = function(screen) {
                                if (root.currentMenuScreen !== "")
                                    root.menuStack.push(root.currentMenuScreen)
                                root.currentMenuScreen = screen
                                menuLoader.source = "screens/" + screen + "Screen.qml"
                            }
                    }
                }
            }
        }

        // ===== NAV INDICATOR =====
        NavPageIndicator {
            id: navigator

            visible: !menuLoader.active

            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(32, root.height * 0.015)

            pageNames: [
                "Dashboard",
                GlobalState.showDDuster ? "Batch & DD" : "Batch Menu",
                "Tracking Phase",
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

    // ===== GLOBAL VALIDATION ALARM POPUP =====
    ValidationAlarmPopup {

        id: validationAlarmPopup

        parent: Overlay.overlay

        z: 20000

    }
}
