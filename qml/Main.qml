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


    // =========================================================
    // NAVIGATE HOME TIMER
    // =========================================================

    Timer {
        id: navigateHomeTimer

        interval: 1000
        repeat: false

        onTriggered: {
            navigateToHome()
        }
    }


    // =========================================================
    // DATABASE CONNECTION
    // =========================================================

    Connections {
        target: databaseManager

        function onMachineParametersChanged()
        {
            var settings =
                    databaseManager.getMachinePhaseSettings()

            if (settings.machinePhase !== undefined)
                GlobalState.machinePhase =
                        Number(settings.machinePhase)

            if (settings.signalThr !== undefined)
                GlobalState.signalThreshold =
                        Number(settings.signalThr)

            if (settings.ampThr !== undefined)
                GlobalState.amplitudeThreshold =
                        Number(settings.ampThr)


            var dd =
                    databaseManager.getDDSettings()

            if (dd.ddPower !== undefined)
                GlobalState.ddPower =
                        Number(dd.ddPower)

            if (dd.ddFreq !== undefined)
                GlobalState.ddFrequency =
                        Number(dd.ddFreq)


            var s1 =
                    databaseManager.getS1Settings()

            if (s1.digitalGain !== undefined)
                GlobalState.digitalGain =
                        Number(s1.digitalGain)

            if (s1.analogGain !== undefined)
                GlobalState.analogGain =
                        Number(s1.analogGain)


            if (GlobalState.sendDataAfterLoad === true) {

                console.log("sendDataAfterLoad = TRUE")
                console.log("Restarting startupTimer...")

                startupTimer.restart()

            } else {

                console.log("sendDataAfterLoad = FALSE")
                console.log("Parameters loaded, not sending to MCU")
            }
        }
    }


    // =========================================================
    // GLOBAL STATE CONNECTION
    // =========================================================

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


    // =========================================================
    // SERIAL MANAGER CONNECTION
    // =========================================================

    Connections {
        target: SerialManager

        function onMcuParameterRequestReceived() {

            console.log("MCU requested parameters")

            startupTimer.restart()
        }
    }


    // =========================================================
    // NAVIGATE TO HOME
    // =========================================================

    function navigateToHome() {

        menuLoader.active = false
        menuLoader.source = ""

        // Reset menu navigation
        currentMenuScreen = ""
        menuStack = []

        // Show home page
        swipeViewLoader.item.currentIndex = 0

        // Reset top bar
        mainTopBar.showBackButton = false
    }


    // =========================================================
    // TYPOGRAPHY SYSTEM
    // =========================================================

    Typography {
        id: typography
        scale: 1.0
    }

    property alias appTypography: typography


    // =========================================================
    // FONT LOADING
    // =========================================================

    FontLoader {
        id: appRegularFont

        source:
            "qrc:/qt/qml/Application/assets/images/RobotoCondensed-Regular.ttf"
    }

    FontLoader {
        id: appBoldFont

        source:
            "qrc:/qt/qml/Application/assets/images/RobotoCondensed-Bold.ttf"
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
    font.pixelSize: 20


    // =========================================================
    // RECURSIVE FONT APPLICATION
    // =========================================================

    function applyFontToAllChildren(item) {

        if (item === null)
            return

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
    // SWIPEVIEW SMOOTHNESS
    // =========================================================

    function tuneSwipeViewSmoothness() {

        var swipe = swipeViewLoader.item

        if (!swipe)
            return

        var flick = swipe.contentItem

        if (!flick)
            return


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


    // =========================================================
    // APPLICATION START
    // =========================================================

    Component.onCompleted: {

        applyFontToAllChildren(root.contentItem)

        if (Overlay.overlay)
            applyFontToAllChildren(Overlay.overlay)

        tuneSwipeViewSmoothness()

        console.log(
            "Count Rejection:",
            GlobalState.countRejection
        )


        // ================= APPLICATION START AUDIT =================

        if (GlobalState.machinePowerState === "Running")
        {
            // power failure happened

            GlobalState.savePowerFailureTime()

            databaseManager.addAuditTrailRecord(
                "---",
                GlobalState.powerFailureDate,
                GlobalState.powerFailureTime,
                "M/C OFF (Power Failure)"
            )
        }


        var auditSaved =
                databaseManager.addAuditTrailRecord(
                    "---",
                    "",
                    "",
                    "M/C Switch ON"
                )


        startupTimer.start()

        GlobalState.setMachineRunning()

        console.log(
            "Machine State:" +
            GlobalState.machinePowerState
        )
    }


    // =========================================================
    // PARAMETER QUEUE
    // =========================================================

    property var parameterQueue: []


    // =========================================================
    // PARAMETER SENDER
    // =========================================================

    Timer {

        id: parameterSender

        interval: 50
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


            var sendFunction =
                    parameterQueue.shift()

            if (sendFunction)
                sendFunction()
        }
    }


    // =========================================================
    // STARTUP TIMER
    // =========================================================

    Timer {

        id: startupTimer

        interval: 1000
        repeat: false

        onTriggered: {

            if (mainTopBar)
                mainTopBar.showNotification(
                    "Sending parameters..."
                )


            parameterQueue = []


            // =====================================================
            // MACHINE SETTINGS
            // =====================================================

            var machineSettings =
                    databaseManager.getMachinePhaseSettings()


            if (machineSettings.machinePhase !== undefined)
            {
                GlobalState.machinePhase =
                        machineSettings.machinePhase


                parameterQueue.push(function() {

                    SerialManager.setMachinePhase(
                        Math.round(
                            GlobalState.machinePhase * 10
                        )
                    )
                })
            }


            if (machineSettings.signalThr !== undefined)
            {
                GlobalState.signalThreshold =
                        machineSettings.signalThr


                parameterQueue.push(function() {

                    SerialManager.setSignalThreshold(
                        GlobalState.signalThreshold
                    )
                })
            }


            if (machineSettings.ampThr !== undefined)
            {
                GlobalState.amplitudeThreshold =
                        machineSettings.ampThr


                parameterQueue.push(function() {

                    SerialManager.setAmplitudeThreshold(
                        GlobalState.amplitudeThreshold
                    )
                })
            }


            // =====================================================
            // S1 SETTINGS
            // =====================================================

            var s1Settings =
                    databaseManager.getS1Settings()


            if (s1Settings.lpf !== undefined)
            {
                parameterQueue.push(function() {

                    SerialManager.setLPF(
                        s1Settings.lpf
                    )
                })
            }


            if (s1Settings.hpf !== undefined)
            {
                parameterQueue.push(function() {

                    SerialManager.setHPF(
                        Math.round(
                            s1Settings.hpf * 10
                        )
                    )
                })
            }


            if (s1Settings.holdDelay !== undefined)
            {
                parameterQueue.push(function() {

                    SerialManager.setHoldDelay(
                        s1Settings.holdDelay
                    )
                })
            }


            if (s1Settings.operateDelay !== undefined)
            {
                parameterQueue.push(function() {

                    SerialManager.setOperateDelay(
                        s1Settings.operateDelay
                    )
                })
            }


            if (s1Settings.relayDelay !== undefined)
            {
                parameterQueue.push(function() {

                    SerialManager.setRelayDelay(
                        s1Settings.relayDelay
                    )
                })
            }


            if (s1Settings.digitalGain !== undefined)
            {
                parameterQueue.push(function() {

                    SerialManager.setDigitalGain(
                        Math.round(
                            s1Settings.digitalGain * 10
                        )
                    )
                })
            }


            if (s1Settings.analogGain !== undefined)
            {
                parameterQueue.push(function() {

                    SerialManager.setAnalogGain(
                        s1Settings.analogGain
                    )
                })
            }


            // =====================================================
            // DD SETTINGS
            // =====================================================

            var ddSettings =
                    databaseManager.getDDSettings()


            if (ddSettings.ddFreq !== undefined)
            {
                parameterQueue.push(function() {

                    SerialManager.setDDFrequency(
                        Math.round(
                            ddSettings.ddFreq * 10
                        )
                    )
                })
            }


            if (ddSettings.ddPower !== undefined)
            {
                parameterQueue.push(function() {

                    SerialManager.setDDPower(
                        ddSettings.ddPower
                    )
                })
            }


            // =====================================================
            // START SENDING
            // =====================================================

            if (parameterQueue.length > 0) {

                parameterSender.start()

            } else if (mainTopBar) {

                mainTopBar.showNotification(
                    "✓ Parameters sent successfully"
                )
            }


            GlobalState.sendDataAfterLoad = false
        }
    }


    // =========================================================
    // VALIDATION ALARM
    // =========================================================

    property string lastTriggeredAlarmTime: ""


    Timer {

        id: validationAlarmTimer

        interval: 1000

        running: true

        repeat: true


        onTriggered: {

            var now = new Date()


            var currentTime =
                    Qt.formatTime(
                        now,
                        "HH:mm"
                    )


            var alarms =
                    GlobalState.getValidationTimers()


            for (var i = 0; i < alarms.length; i++)
            {
                var alarm = alarms[i]


                if (alarm.enabled &&
                    alarm.time === currentTime)
                {

                    if (
                        root.lastTriggeredAlarmTime
                        !== currentTime
                    )
                    {

                        root.lastTriggeredAlarmTime =
                                currentTime

                        GlobalState.triggerValidationAlarm()
                    }


                    break
                }
            }
        }
    }


    // =========================================================
    // DDUSTER COMPONENT
    // =========================================================

    Component {
        id: ddusterComp

        DDusterScreen {
            showTopBar: false
            globalTopBar: mainTopBar
        }
    }


    // =========================================================
    // BATCH COMPONENT
    // =========================================================

    Component {
        id: batchComp

        BatchMenuScreen {
            showTopBar: false
            globalTopBar: mainTopBar
        }
    }


    // =========================================================
    // CURRENT MENU
    // =========================================================

    property string currentMenuScreen: ""

    property var menuStack: []


    // =========================================================
    // MAIN COLUMN
    // =========================================================

    ColumnLayout {

        anchors.fill: parent

        spacing: 0


        // =====================================================
        // TOP BAR
        // =====================================================

        TopBar {

            id: mainTopBar

            Layout.fillWidth: true

            height:
                Math.max(
                    63,
                    root.height * 0.08
                )


            onMenuClicked: {

                currentMenuScreen = "Menu"

                menuLoader.source =
                        "screens/MenuScreen.qml"

                menuLoader.active = true

                mainTopBar.showBackButton = true
            }


            onBackClicked: {

                if (menuStack.length > 0) {

                    var previous =
                            menuStack.pop()

                    currentMenuScreen =
                            previous

                    menuLoader.source =
                            "screens/"
                            + previous
                            + "Screen.qml"

                } else {

                    currentMenuScreen = ""

                    menuLoader.active = false

                    menuLoader.source = ""

                    swipeViewLoader.item.currentIndex = 0

                    mainTopBar.showBackButton = false
                }
            }
        }


        // =====================================================
        // SWIPEVIEW + MENU OVERLAY
        // =====================================================

        Item {

            id: contentArea

            Layout.fillWidth: true

            Layout.fillHeight: true


            Loader {

                id: swipeViewLoader

                anchors.fill: parent

                z: 0

                asynchronous: false


                sourceComponent:
                    GlobalState.showTrackingScreen
                    ? swipeViewWithTracking
                    : swipeViewWithoutTracking


                onLoaded: {

                    console.log(
                        "SwipeView loaded."
                    )

                    console.log(
                        "showTrackingScreen =",
                        GlobalState.showTrackingScreen
                    )

                    root.tuneSwipeViewSmoothness()

                    if (item)
                        item.currentIndex = 0
                }
            }


            // =================================================
            // MENU SCREEN LOADER
            // =================================================

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
                            item.globalTopBar =
                                    mainTopBar


                        if ("navigateTo" in item)
                        {
                            item.navigateTo =
                                    function(screen) {

                                if (
                                    root.currentMenuScreen
                                    !== ""
                                )
                                {
                                    root.menuStack.push(
                                        root.currentMenuScreen
                                    )
                                }


                                root.currentMenuScreen =
                                        screen


                                menuLoader.source =
                                        "screens/"
                                        + screen
                                        + "Screen.qml"
                            }
                        }
                    }
                }
            }
        }


        // =====================================================
        // NAVIGATION INDICATOR
        // =====================================================

        NavPageIndicator {

            id: navigator

            visible: !menuLoader.active

            Layout.fillWidth: true

            Layout.preferredHeight:
                Math.max(
                    32,
                    root.height * 0.015
                )


            // =================================================
            // PAGE NAMES
            // =================================================

            pageNames:
                GlobalState.showTrackingScreen
                ? [
                    "Dashboard",

                    GlobalState.showDDuster
                        ? "Batch & DD"
                        : "Batch Menu",

                    "Tracking Phase",

                    "About Machine"
                ]
                : [
                    "Dashboard",

                    GlobalState.showDDuster
                        ? "Batch & DD"
                        : "Batch Menu",

                    "About Machine"
                ]


            // =================================================
            // CURRENT PAGE
            // =================================================

            currentPage:
                swipeViewLoader.item
                ? swipeViewLoader.item.currentIndex
                : 0


            // =================================================
            // PREVIOUS
            // =================================================

            onPreviousClicked: {

                if (
                    swipeViewLoader.item
                    && swipeViewLoader.item.currentIndex > 0
                )
                {
                    swipeViewLoader.item.currentIndex--
                }
            }


            // =================================================
            // NEXT
            // =================================================

            onNextClicked: {

                if (
                    swipeViewLoader.item
                    &&
                    swipeViewLoader.item.currentIndex
                    <
                    swipeViewLoader.item.count - 1
                )
                {
                    swipeViewLoader.item.currentIndex++
                }
            }


            // =================================================
            // PAGE SELECTED
            // =================================================

            onPageSelected: function(index) {

                if (!swipeViewLoader.item)
                    return


                if (
                    index >= 0
                    &&
                    index < swipeViewLoader.item.count
                )
                {
                    swipeViewLoader.item.currentIndex =
                            index
                }
            }
        }
    }

    Component {

        id: swipeViewWithTracking

        SwipeView {

            id: trackingSwipeView

            anchors.fill: parent

            clip: true

            currentIndex: 0

            enabled: !menuLoader.active

            interactive: true

            LayoutMirroring.enabled: false


            onContentItemChanged: {
                root.tuneSwipeViewSmoothness()
            }


            // =================================================
            // PAGE 0 - HOME
            // =================================================

            HomeScreen {

                id: homePageWithTracking

                showTopBar: false

                globalTopBar: mainTopBar

                validationPopup:
                        validationScreenPopup


                layer.enabled: true

                layer.smooth: true


                navigateTo:
                    function(screen) {

                    if (
                        root.currentMenuScreen
                        !== ""
                    )
                    {
                        root.menuStack.push(
                            root.currentMenuScreen
                        )
                    }


                    root.currentMenuScreen =
                            screen


                    menuLoader.source =
                            "screens/"
                            + screen
                            + "Screen.qml"


                    menuLoader.active = true


                    mainTopBar.showBackButton =
                            true
                }
            }


            // =================================================
            // PAGE 1 - BATCH / DDUSTER
            // =================================================

            Loader {

                id: batchOrDDusterPageWithTracking

                property bool showDDuster:
                        GlobalState.showDDuster


                sourceComponent:
                        showDDuster
                        ? ddusterComp
                        : batchComp


                asynchronous: true

                layer.enabled: true

                layer.smooth: true
            }


            // =================================================
            // PAGE 2 - TRACKING PHASE
            // =================================================

            AutoLearnScreen {

                id: autoLearnScreen

                showTopBar: false

                globalTopBar: mainTopBar

                layer.enabled: true

                layer.smooth: true
            }


            // =================================================
            // PAGE 3 - ABOUT MACHINE
            // =================================================

            SysDetailsScreen {

                id: sysDetailsScreenWithTracking

                showTopBar: false

                globalTopBar: mainTopBar

                layer.enabled: true

                layer.smooth: true
            }
        }
    }

    Component {

        id: swipeViewWithoutTracking

        SwipeView {

            id: normalSwipeView

            anchors.fill: parent

            clip: true

            currentIndex: 0

            enabled: !menuLoader.active

            interactive: true

            LayoutMirroring.enabled: false


            onContentItemChanged: {
                root.tuneSwipeViewSmoothness()
            }


            // =================================================
            // PAGE 0 - HOME
            // =================================================

            HomeScreen {

                id: homePageWithoutTracking

                showTopBar: false

                globalTopBar: mainTopBar

                validationPopup:
                        validationScreenPopup


                layer.enabled: true

                layer.smooth: true


                navigateTo:
                    function(screen) {

                    if (
                        root.currentMenuScreen
                        !== ""
                    )
                    {
                        root.menuStack.push(
                            root.currentMenuScreen
                        )
                    }


                    root.currentMenuScreen =
                            screen


                    menuLoader.source =
                            "screens/"
                            + screen
                            + "Screen.qml"


                    menuLoader.active = true


                    mainTopBar.showBackButton =
                            true
                }
            }


            // =================================================
            // PAGE 1 - BATCH / DDUSTER
            // =================================================

            Loader {

                id: batchOrDDusterPageWithoutTracking

                property bool showDDuster:
                        GlobalState.showDDuster


                sourceComponent:
                        showDDuster
                        ? ddusterComp
                        : batchComp


                asynchronous: true

                layer.enabled: true

                layer.smooth: true
            }


            // =================================================
            // PAGE 2 - ABOUT MACHINE
            // =================================================

            SysDetailsScreen {

                id: sysDetailsScreenWithoutTracking

                showTopBar: false

                globalTopBar: mainTopBar

                layer.enabled: true

                layer.smooth: true
            }
        }
    }


    // =========================================================
    // GLOBAL DATE/TIME
    // =========================================================

    Timer {

        interval: 1000

        running: true

        repeat: true


        onTriggered: {

            GlobalState.globalDateTime =
                    new Date()
        }
    }


    // =========================================================
    // CUSTOM VIRTUAL KEYBOARD
    // =========================================================

    CommonKeyboard {

        id: customKeyboard

        parent: Overlay.overlay

        anchors.left: parent.left

        anchors.right: parent.right

        anchors.bottom: parent.bottom


        z: 10000


        visible:
            GlobalState.loginKeyboardRequest


        y:
            visible
            ? parent.height - height
            : parent.height


        Behavior on y {

            NumberAnimation {

                duration: 220

                easing.type:
                    Easing.OutCubic
            }
        }


        onVisibleChanged: {

            if (!visible) {

                if (
                    GlobalState.activeInputField
                )
                {
                    GlobalState.activeInputField.focus =
                            false

                    GlobalState.activeInputField =
                            null
                }
            }
        }
    }


    // =========================================================
    // GLOBAL VALIDATION ALARM POPUP
    // =========================================================

    ValidationAlarmPopup {

        id: validationAlarmPopup

        onContinueClicked:
            validationScreenPopup.open()
    }


    // =========================================================
    // VALIDATION SCREEN POPUP
    // =========================================================

    ValidationScreenPopup {

        id: validationScreenPopup
    }


    // =========================================================
    // FLOATING VALIDATION WINDOW
    // =========================================================

    Timer {

        id: bubbleAutoCloseTimer

        interval: 15 * 60 * 1000

        repeat: false


        onTriggered: {

            validationAlarmPopup.minimized =
                    false

            validationAlarmPopup.close()
        }
    }


    Rectangle {

        id: validationBubble

        visible:
            validationAlarmPopup.minimized


        onVisibleChanged: {

            if (visible)
                bubbleAutoCloseTimer.restart()
            else
                bubbleAutoCloseTimer.stop()
        }


        width: 68

        height: 68

        radius: width / 2


        color: "#1A4DB5"


        border.width: 3

        border.color: "white"


        anchors.right:
                parent.right

        anchors.bottom:
                parent.bottom


        anchors.rightMargin: 22

        anchors.bottomMargin: 26


        z: 9999


        layer.enabled: true


        Rectangle {

            anchors.fill: parent

            radius: parent.radius

            color: "transparent"

            border.color: "#6EA8FF"

            border.width: 3

            opacity: 0.4
        }


        Image {

            anchors.centerIn: parent


            source:
                "qrc:/qt/qml/Application/assets/images/Bell.png"


            width:
                parent.width * 0.45


            height:
                parent.height * 0.45


            fillMode:
                Image.PreserveAspectFit


            smooth: true

            mipmap: true
        }


        MouseArea {

            anchors.fill: parent


            drag.target:
                    validationBubble


            onClicked: {

                bubbleAutoCloseTimer.stop()


                validationAlarmPopup.minimized =
                        false


                validationAlarmPopup.open()
            }
        }


        SequentialAnimation {

            running:
                validationBubble.visible


            loops:
                Animation.Infinite


            NumberAnimation {

                target:
                    validationBubble

                property:
                    "scale"

                from: 1

                to: 1.1

                duration: 600
            }


            NumberAnimation {

                target:
                    validationBubble

                property:
                    "scale"

                from: 1.1

                to: 1

                duration: 600
            }
        }
    }
}
