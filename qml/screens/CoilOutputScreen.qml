import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import AppState 1.0

import "../components"

Item {
    id: root

    property bool showTopBar: true
    property var globalTopBar

    property real baseHeight: 700
    property real scale: Math.max(0.9, Math.min(1.8, height / baseHeight))

    property int statAvg: 0
    property int statMin: 0
    property int statMax: 0

    function monthName(m) {
        var names = ["JAN","FEB","MAR","APR","MAY","JUN",
                     "JUL","AUG","SEP","OCT","NOV","DEC"]
        return names[m - 1]
    }

    ListModel { id: histValues }

    // jump to a specific day (1-based)
    function jumpToDay(day) {
        var idx = (day - 1) * readingsPerDay
        var targetX = idx * histogramCard.barStride + histogramCard.barSpacing

        flickArea.contentX = Math.max(
            0,
            Math.min(targetX, flickArea.contentWidth - flickArea.width)
        )
    }

    property int readingsPerDay: (24 * 60) / 5
    property int totalDays: 30

    Component.onCompleted: {
        var intervalMinutes = 5
        var sum = 0
        var mn = 10000
        var mx = 0

        for (var day = 1; day <= totalDays; day++) {
            for (var r = 0; r < readingsPerDay; r++) {

                var totalMin = r * intervalMinutes
                var hh = Math.floor(totalMin / 60)
                var mm = totalMin % 60

                var dd  = day < 10 ? "0" + day : "" + day
                var hhS = hh < 10 ? "0" + hh : "" + hh
                var mmS = mm < 10 ? "0" + mm : "" + mm

                var v = Math.round(Math.random() * 10000)

                sum += v

                if (v < mn)
                    mn = v

                if (v > mx)
                    mx = v

                histValues.append({
                    dd: dd,
                    mon: 1,
                    hhmm: hhS + ":" + mmS,
                    val: v
                })
            }
        }

        statAvg = Math.round(sum / histValues.count)
        statMin = mn
        statMax = mx
    }

    Rectangle {
        id: histogramCard

        anchors.fill: parent
        anchors.margins: 20 * root.scale

        radius: 22 * root.scale
        color: "#FFFFFF"

        border.width: 2
        border.color: "#6F95D6"

        clip: true

        // =========================================================
        // IMPROVED INITIAL ZOOM
        // =========================================================

        property real minZoomFactor: 0.010
        property real zoomFactor: minZoomFactor

        property real _pinchStartZoom: minZoomFactor

        property real detailZoomThreshold: 0.8

        property int selectedIndex: -1
        property real selectedBarVal: 0
        property real selectedBarX: 0
        property real selectedBarY: 0
        property real selectedBarW: 0

        // =========================================================
        // PERFORMANCE IMPROVEMENTS
        // =========================================================

        layer.enabled: true
        layer.smooth: true

        PinchHandler {
            id: pinchHandler

            target: null

            onActiveChanged: {
                if (active)
                    histogramCard._pinchStartZoom =
                            histogramCard.zoomFactor
            }

            onActiveScaleChanged: {

                var oldZoom = histogramCard.zoomFactor

                var newZoom = Math.max(
                    histogramCard.minZoomFactor,
                    Math.min(
                        2.0,
                        histogramCard._pinchStartZoom
                        * activeScale
                    )
                )

                if (Math.abs(newZoom - oldZoom) < 0.01)
                    return

                var visibleCenterX =
                        flickArea.contentX
                        + flickArea.width / 2

                histogramCard.zoomFactor = newZoom

                flickArea.contentX = Math.max(
                    0,
                    visibleCenterX
                    * (newZoom / oldZoom)
                    - flickArea.width / 2
                )
            }
        }

        property real barWidth:
            Math.round(Math.max(1, 44 * root.scale * zoomFactor))

        property real barSpacing:
            Math.round(Math.max(0.5, 6 * root.scale * zoomFactor))

        property real barStride: barWidth + barSpacing

        property int barCount: histValues.count

        property bool isDetail:
            zoomFactor >= detailZoomThreshold

        // show nav only when graph exceeds screen width
        property bool needsNavigation:
            graphArea.totalBarsW > graphArea.plotW + 10

        property real yAxisWidth: 10 * root.scale

        property real xAxisHeight:
            isDetail ? 72 * root.scale : 46 * root.scale

        property real titleH: 52 * root.scale
        property real statsH: 40 * root.scale

        property real dayNavH:
            needsNavigation ? 54 * root.scale : 0

        property real padH: 20 * root.scale
        property real padV: 16 * root.scale

        property real yMin: 0
        property real yMax: 10000

        property int ySteps: 5

        property int visibleDay: {

            var firstBarIdx =
                    Math.floor(
                        flickArea.contentX
                        / histogramCard.barStride
                    )

            return Math.max(
                        1,
                        Math.min(
                            root.totalDays,
                            Math.floor(
                                firstBarIdx
                                / root.readingsPerDay
                            ) + 1
                        )
                    )
        }

        onVisibleDayChanged: {

            if (!dayPillFlick.contentWidth)
                return

            var pillWidth =
                    (44 * root.scale)
                    + (7 * root.scale)

            var target =
                    ((visibleDay - 1) * pillWidth)
                    - (dayPillFlick.width / 2)
                    + (pillWidth / 2)

            target = Math.max(
                        0,
                        Math.min(
                            target,
                            dayPillFlick.contentWidth
                            - dayPillFlick.width
                        )
                    )

            dayPillFlick.contentX = target
        }

        Behavior on xAxisHeight {
            NumberAnimation {
                duration: 140
                easing.type: Easing.OutCubic
            }
        }

        Behavior on dayNavH {
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutCubic
            }
        }

        Column {
            anchors.fill: parent

            anchors.leftMargin: histogramCard.padH
            anchors.rightMargin: histogramCard.padH
            anchors.topMargin: histogramCard.padV
            anchors.bottomMargin: histogramCard.padV

            spacing: 0

            // =====================================================
            // HEADER
            // =====================================================

            Item {
                width: parent.width
                height: 78 * root.scale

                RowLayout {
                    anchors.fill: parent

                    spacing: 20 * root.scale

                    // =================================================
                    // STATS PANEL
                    // =================================================

                    Rectangle {
                        Layout.preferredWidth: 320 * root.scale
                        Layout.preferredHeight: 64 * root.scale

                        Layout.alignment: Qt.AlignVCenter

                        radius: 18 * root.scale

                        color: "#F7F9FD"

                        border.width: 1
                        border.color: "#DCE5F5"

                        RowLayout {
                            anchors.fill: parent

                            anchors.leftMargin: 18 * root.scale
                            anchors.rightMargin: 18 * root.scale

                            spacing: 14 * root.scale

                            // =========================================
                            // AVG
                            // =========================================

                            ColumnLayout {
                                Layout.fillWidth: true

                                spacing: 3 * root.scale

                                Text {
                                    Layout.alignment: Qt.AlignHCenter

                                    text: "AVG"

                                    font.pixelSize: 10 * root.scale
                                    font.bold: true

                                    color: "#8EA2C8"
                                }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter

                                    text: root.statAvg.toLocaleString()

                                    font.pixelSize: 17 * root.scale
                                    font.bold: true

                                    color: "#1A4DB5"
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: 1
                                Layout.preferredHeight: 34 * root.scale

                                color: "#DCE5F5"
                            }

                            // =========================================
                            // MIN
                            // =========================================

                            ColumnLayout {
                                Layout.fillWidth: true

                                spacing: 3 * root.scale

                                Text {
                                    Layout.alignment: Qt.AlignHCenter

                                    text: "MIN"

                                    font.pixelSize: 10 * root.scale
                                    font.bold: true

                                    color: "#8EA2C8"
                                }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter

                                    text: root.statMin.toLocaleString()

                                    font.pixelSize: 17 * root.scale
                                    font.bold: true

                                    color: "#0F8A60"
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: 1
                                Layout.preferredHeight: 34 * root.scale

                                color: "#DCE5F5"
                            }

                            // =========================================
                            // MAX
                            // =========================================

                            ColumnLayout {
                                Layout.fillWidth: true

                                spacing: 3 * root.scale

                                Text {
                                    Layout.alignment: Qt.AlignHCenter

                                    text: "MAX"

                                    font.pixelSize: 10 * root.scale
                                    font.bold: true

                                    color: "#8EA2C8"
                                }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter

                                    text: root.statMax.toLocaleString()

                                    font.pixelSize: 17 * root.scale
                                    font.bold: true

                                    color: "#D64545"
                                }
                            }
                        }
                    }

                    // =================================================
                    // TITLE
                    // =================================================

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Text {
                            anchors.centerIn: parent

                            text: "Coil Output Histogram"

                            font.pixelSize: 30 * root.scale
                            font.bold: true

                            color: "#0E4AB8"
                        }
                    }

                    // =================================================
                    // CONTROL TOOLBAR
                    // =================================================

                    Rectangle {
                        Layout.preferredWidth: 250 * root.scale
                        Layout.preferredHeight: 64 * root.scale

                        Layout.alignment: Qt.AlignVCenter

                        radius: 18 * root.scale

                        color: "#F7F9FD"

                        border.width: 1
                        border.color: "#DCE5F5"

                        RowLayout {
                            anchors.fill: parent

                            anchors.leftMargin: 10 * root.scale
                            anchors.rightMargin: 10 * root.scale

                            spacing: 10 * root.scale

                            // =========================================
                            // ZOOM OUT
                            // =========================================

                            Rectangle {
                                Layout.preferredWidth: 46 * root.scale
                                Layout.preferredHeight: 46 * root.scale

                                radius: 14 * root.scale

                                color:
                                    zoomOutMa.pressed
                                    ? "#CFE1FF"
                                    : (zoomOutMa.containsMouse
                                       ? "#E3EEFF"
                                       : "#FFFFFF")

                                border.width: 1
                                border.color: "#6F95D6"

                                scale: zoomOutMa.pressed ? 0.92 : 1.0

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 80
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent

                                    text: "−"

                                    font.pixelSize: 26 * root.scale
                                    font.bold: true

                                    color: "#1A4DB5"
                                }

                                MouseArea {
                                    id: zoomOutMa

                                    anchors.fill: parent

                                    hoverEnabled: true

                                    cursorShape: Qt.PointingHandCursor

                                    property bool holdActive: false

                                    function doZoomOut() {

                                        var oldZoom =
                                                histogramCard.zoomFactor

                                        var newZoom =
                                                Math.max(
                                                    histogramCard.minZoomFactor,
                                                    oldZoom * 0.85
                                                )

                                        if (Math.abs(newZoom - oldZoom) < 0.001)
                                            return

                                        var visibleCenterX =
                                                flickArea.contentX
                                                + flickArea.width / 2

                                        histogramCard.zoomFactor = newZoom

                                        flickArea.contentX = Math.max(
                                            0,
                                            visibleCenterX
                                            * (newZoom / oldZoom)
                                            - flickArea.width / 2
                                        )
                                    }

                                    onClicked: {

                                        if (holdActive)
                                            return

                                        doZoomOut()
                                    }

                                    onPressAndHold: {
                                        holdActive = true
                                        zoomOutTimer.start()
                                    }

                                    onReleased: {
                                        holdActive = false
                                        zoomOutTimer.stop()
                                    }

                                    onCanceled: {
                                        holdActive = false
                                        zoomOutTimer.stop()
                                    }
                                }

                                Timer {
                                    id: zoomOutTimer

                                    interval: 120
                                    repeat: true

                                    onTriggered: {

                                        if (
                                            histogramCard.zoomFactor
                                            <= histogramCard.minZoomFactor + 0.001
                                        ) {
                                            stop()
                                            return
                                        }

                                        zoomOutMa.doZoomOut()
                                    }
                                }
                            }

                            // =========================================
                            // ZOOM DISPLAY
                            // =========================================

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 46 * root.scale

                                radius: 14 * root.scale

                                color: "#FFFFFF"

                                border.width: 1
                                border.color: "#DCE5F5"

                                Column {
                                    anchors.centerIn: parent

                                    spacing: 0

                                    Text {
                                        anchors.horizontalCenter:
                                            parent.horizontalCenter

                                        text: "ZOOM"

                                        font.pixelSize: 9 * root.scale
                                        font.bold: true

                                        color: "#8EA2C8"
                                    }

                                    Text {
                                        anchors.horizontalCenter:
                                            parent.horizontalCenter

                                        text:
                                            Math.round(
                                                histogramCard.zoomFactor * 100
                                            ) + "%"

                                        font.pixelSize: 15 * root.scale
                                        font.bold: true

                                        color: "#1A4DB5"
                                    }
                                }
                            }

                            // =========================================
                            // ZOOM IN
                            // =========================================

                            Rectangle {
                                Layout.preferredWidth: 46 * root.scale
                                Layout.preferredHeight: 46 * root.scale

                                radius: 14 * root.scale

                                color:
                                    zoomInMa.pressed
                                    ? "#CFE1FF"
                                    : (zoomInMa.containsMouse
                                       ? "#E3EEFF"
                                       : "#FFFFFF")

                                border.width: 1
                                border.color: "#6F95D6"

                                scale: zoomInMa.pressed ? 0.92 : 1.0

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 80
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent

                                    text: "+"

                                    font.pixelSize: 24 * root.scale
                                    font.bold: true

                                    color: "#1A4DB5"
                                }

                                MouseArea {
                                    id: zoomInMa

                                    anchors.fill: parent

                                    hoverEnabled: true

                                    cursorShape: Qt.PointingHandCursor

                                    // =====================================================
                                    // SINGLE CLICK
                                    // =====================================================

                                    onClicked: {
                                        zoomInStep()
                                    }

                                    // =====================================================
                                    // LONG PRESS AUTO ZOOM
                                    // =====================================================

                                    onPressed: zoomInTimer.start()

                                    onReleased: zoomInTimer.stop()

                                    onCanceled: zoomInTimer.stop()

                                    function zoomInStep() {

                                        var oldZoom =
                                                histogramCard.zoomFactor

                                        var newZoom =
                                                Math.min(
                                                    2.0,
                                                    oldZoom * 1.15
                                                )

                                        if (Math.abs(newZoom - oldZoom) < 0.001)
                                            return

                                        var visibleCenterX =
                                                flickArea.contentX
                                                + flickArea.width / 2

                                        histogramCard.zoomFactor = newZoom

                                        flickArea.contentX = Math.max(
                                            0,
                                            visibleCenterX
                                            * (newZoom / oldZoom)
                                            - flickArea.width / 2
                                        )
                                    }

                                    Timer {
                                        id: zoomInTimer

                                        interval: 90

                                        repeat: true

                                        running: false

                                        onTriggered: {
                                            zoomInMa.zoomInStep()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: "#E1E8F5"
            }

            // =====================================================
            // DAY NAVIGATION
            // =====================================================

            Item {

                visible: histogramCard.needsNavigation

                width: parent.width
                height: histogramCard.dayNavH

                opacity: visible ? 1 : 0

                Behavior on opacity {
                    NumberAnimation { duration: 150 }
                }

                // =================================================
                // PREV BUTTON
                // =================================================

                Rectangle {
                    id: prevBtn

                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter

                    width: 46 * root.scale
                    height: 46 * root.scale

                    radius: 14 * root.scale

                    color:
                        prevMa.pressed
                        ? "#BFD7FF"
                        : (prevMa.containsMouse
                           ? "#DCEBFF"
                           : "#EDF4FF")

                    border.color: "#6F95D6"
                    border.width: 1

                    scale: prevMa.pressed ? 0.94 : 1.0

                    Behavior on scale {
                        NumberAnimation {
                            duration: 80
                        }
                    }

                    Text {
                        anchors.centerIn: parent

                        text: "‹"

                        font.pixelSize: 24 * root.scale
                        font.bold: true

                        color: "#1A4DB5"
                    }

                    MouseArea {
                        id: prevMa

                        anchors.fill: parent

                        hoverEnabled: true

                        cursorShape: Qt.PointingHandCursor

                        property bool holdActive: false

                        onClicked: {

                            if (holdActive)
                                return

                            var cur = histogramCard.visibleDay

                            if (cur > 1)
                                root.jumpToDay(cur - 1)
                        }

                        onPressAndHold: {
                            holdActive = true
                            prevHoldTimer.start()
                        }

                        onReleased: {
                            holdActive = false
                            prevHoldTimer.stop()
                        }

                        onCanceled: {
                            holdActive = false
                            prevHoldTimer.stop()
                        }
                    }

                    Timer {
                        id: prevHoldTimer

                        interval: 120
                        repeat: true

                        onTriggered: {

                            var cur = histogramCard.visibleDay

                            if (cur > 1)
                                root.jumpToDay(cur - 1)
                            else
                                stop()
                        }
                    }
                }

                // =================================================
                // NEXT BUTTON
                // =================================================

                Rectangle {
                    id: nextBtn

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter

                    width: 46 * root.scale
                    height: 46 * root.scale

                    radius: 14 * root.scale

                    color:
                        nextMa.pressed
                        ? "#BFD7FF"
                        : (nextMa.containsMouse
                           ? "#DCEBFF"
                           : "#EDF4FF")

                    border.color: "#6F95D6"
                    border.width: 1

                    scale: nextMa.pressed ? 0.94 : 1.0

                    Behavior on scale {
                        NumberAnimation {
                            duration: 80
                        }
                    }

                    Text {
                        anchors.centerIn: parent

                        text: "›"

                        font.pixelSize: 24 * root.scale
                        font.bold: true

                        color: "#1A4DB5"
                    }

                    MouseArea {
                        id: nextMa

                        anchors.fill: parent

                        hoverEnabled: true

                        cursorShape: Qt.PointingHandCursor

                        property bool holdActive: false

                        onClicked: {

                            if (holdActive)
                                return

                            var cur = histogramCard.visibleDay

                            if (cur < root.totalDays)
                                root.jumpToDay(cur + 1)
                        }

                        onPressAndHold: {
                            holdActive = true
                            nextHoldTimer.start()
                        }

                        onReleased: {
                            holdActive = false
                            nextHoldTimer.stop()
                        }

                        onCanceled: {
                            holdActive = false
                            nextHoldTimer.stop()
                        }
                    }

                    Timer {
                        id: nextHoldTimer

                        interval: 120
                        repeat: true

                        onTriggered: {

                            var cur = histogramCard.visibleDay

                            if (cur < root.totalDays)
                                root.jumpToDay(cur + 1)
                            else
                                stop()
                        }
                    }
                }

                // =================================================
                // DAY PILLS
                // =================================================

                Flickable {
                    id: dayPillFlick

                    anchors.left: prevBtn.right
                    anchors.right: nextBtn.left

                    anchors.leftMargin: 10 * root.scale
                    anchors.rightMargin: 10 * root.scale

                    anchors.verticalCenter: parent.verticalCenter

                    height: 40 * root.scale

                    clip: true

                    flickableDirection: Flickable.HorizontalFlick
                    boundsBehavior: Flickable.StopAtBounds

                    contentWidth: pillContent.width
                    contentHeight: height

                    interactive: true

                    Behavior on contentX {
                        NumberAnimation {
                            duration: 220
                            easing.type: Easing.OutCubic
                        }
                    }

                    Item {
                        id: pillContent

                        width:
                            (root.totalDays * (44 * root.scale))
                            + ((root.totalDays - 1) * (7 * root.scale))

                        height: parent.height

                        // =====================================================
                        // MOVING SELECTION BACKGROUND
                        // =====================================================

                        Rectangle {
                            id: selectionHighlight

                            width: 44 * root.scale
                            height: 34 * root.scale

                            radius: 9 * root.scale

                            y: (pillContent.height - height) / 2

                            x:
                                (histogramCard.visibleDay - 1)
                                * ((44 * root.scale) + (7 * root.scale))

                            color: "#1A4DB5"

                            border.color: "#6F95D6"
                            border.width: 1

                            z: 0

                            Behavior on x {
                                NumberAnimation {
                                    duration: 180
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        // =====================================================
                        // DAY BUTTONS
                        // =====================================================

                        Row {
                            id: dayPillRow

                            spacing: 7 * root.scale

                            anchors.verticalCenter: parent.verticalCenter

                            Repeater {
                                model: root.totalDays

                                Item {

                                    width: 44 * root.scale
                                    height: 34 * root.scale

                                    readonly property bool active:
                                        histogramCard.visibleDay === index + 1

                                    Text {
                                        anchors.centerIn: parent

                                        text:
                                            (index + 1) < 10
                                            ? "0" + (index + 1)
                                            : "" + (index + 1)

                                        font.pixelSize: 12 * root.scale
                                        font.bold: active

                                        color:
                                            active
                                            ? "#FFFFFF"
                                            : (pillMa.containsMouse
                                               ? "#1A4DB5"
                                               : "#3562B8")

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 120
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: pillMa

                                        anchors.fill: parent

                                        hoverEnabled: true

                                        cursorShape: Qt.PointingHandCursor

                                        onClicked:
                                            root.jumpToDay(index + 1)
                                    }
                                }
                            }
                        }
                    }

                    // =========================================================
                    // AUTO CENTER ACTIVE DAY
                    // =========================================================

                    Connections {
                        target: histogramCard

                        function onVisibleDayChanged() {

                            var itemWidth =
                                    (44 * root.scale)
                                    + (7 * root.scale)

                            var targetX =
                                    ((histogramCard.visibleDay - 1) * itemWidth)
                                    - (dayPillFlick.width / 2)
                                    + (itemWidth / 2)

                            targetX = Math.max(
                                        0,
                                        Math.min(
                                            targetX,
                                            dayPillFlick.contentWidth
                                            - dayPillFlick.width
                                        )
                                    )

                            dayPillFlick.contentX = targetX
                        }
                    }
                }
            }

            Rectangle {
                visible: histogramCard.needsNavigation
                width: parent.width
                height: 1
                color: "#E1E8F5"
            }

            Item {
                width: parent.width
                height:
                    histogramCard.needsNavigation
                    ? 14 * root.scale
                    : 6 * root.scale
            }

            // =====================================================
            // GRAPH AREA
            // =====================================================
            Item {
                id: graphArea

                width: parent.width

                height:
                    parent.height
                    - histogramCard.titleH
                    - histogramCard.statsH
                    - histogramCard.dayNavH
                    - (histogramCard.needsNavigation ? 2 : 1)

                // =========================================================
                // DYNAMIC TOP SPACE FOR LABELS
                // =========================================================

                property real valueLabelHeight:
                    histogramCard.isDetail
                    ? Math.max(28, 34 * root.scale)
                    : 8 * root.scale

                property real topGraphPadding:
                    histogramCard.isDetail
                    ? 18 * root.scale
                    : 6 * root.scale

                property real topLabelPadding:
                    valueLabelHeight + topGraphPadding

                property real plotW:
                    width - histogramCard.yAxisWidth

                property real totalBarsW:
                    Math.max(
                        plotW,
                        histogramCard.barCount
                        * histogramCard.barStride
                        + histogramCard.barSpacing * 2
                    )

                property real barAreaH:
                    Math.max(
                        120 * root.scale,
                        height
                        - histogramCard.xAxisHeight
                        - topLabelPadding
                    )

                // =================================================
                // Y AXIS
                // =================================================

                Item {
                    id: yAxisPanel

                    x: 0
                    y: graphArea.topLabelPadding

                    width: histogramCard.yAxisWidth
                    height: graphArea.barAreaH

                    Rectangle {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom

                        width: 2

                        color: "#4A5E8A"
                    }
                }

                // =================================================
                // X AXIS
                // =================================================

                Item {
                    id: xAxisPanel

                    x: histogramCard.yAxisWidth
                    y: graphArea.topLabelPadding + graphArea.barAreaH

                    width: graphArea.plotW
                    height: histogramCard.xAxisHeight

                    clip: true

                    Rectangle {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right

                        height: 2

                        color: "#4A5E8A"
                    }

                    Item {

                        x: -flickArea.contentX
                        y: 0

                        width: graphArea.totalBarsW
                        height: parent.height

                        Repeater {
                            model: histValues

                            delegate: Item {

                                x:
                                    index
                                    * histogramCard.barStride
                                    + histogramCard.barSpacing

                                y: 0

                                width: histogramCard.barStride
                                height: xAxisPanel.height

                                Rectangle {

                                    x: parent.width / 2 - width / 2
                                    y: 2

                                    width: 1
                                    height: 5 * root.scale

                                    color: "#4A5E8A"
                                }

                                // =========================================
                                // NORMAL MODE LABELS
                                // =========================================

                                Column {

                                    visible:
                                        !histogramCard.isDetail
                                        && model.hhmm === "00:05"

                                    anchors.top: parent.top

                                    anchors.topMargin:
                                        10 * root.scale

                                    anchors.horizontalCenter:
                                        parent.horizontalCenter

                                    spacing: 3 * root.scale

                                    Text {

                                        anchors.horizontalCenter:
                                            parent.horizontalCenter

                                        text: model.dd

                                        font.pixelSize:
                                            Math.max(9,
                                                     12 * root.scale)

                                        font.bold: true

                                        color: "#1A4DB5"

                                        horizontalAlignment:
                                            Text.AlignHCenter
                                    }

                                    Text {

                                        anchors.horizontalCenter:
                                            parent.horizontalCenter

                                        text:
                                            root.monthName(model.mon)

                                        font.pixelSize:
                                            Math.max(8,
                                                     10 * root.scale)

                                        color: "#4A5E8A"

                                        horizontalAlignment:
                                            Text.AlignHCenter
                                    }
                                }

                                // =========================================
                                // DETAIL MODE LABELS
                                // =========================================

                                Column {

                                    visible:
                                        histogramCard.isDetail

                                    anchors.top: parent.top

                                    anchors.topMargin:
                                        10 * root.scale

                                    anchors.horizontalCenter:
                                        parent.horizontalCenter

                                    spacing: 6 * root.scale

                                    Text {

                                        anchors.horizontalCenter:
                                            parent.horizontalCenter

                                        text: model.dd

                                        font.pixelSize:
                                            Math.max(10,
                                                     13 * root.scale)

                                        font.bold: true

                                        color: "#1A4DB5"

                                        horizontalAlignment:
                                            Text.AlignHCenter
                                    }

                                    Text {

                                        anchors.horizontalCenter:
                                            parent.horizontalCenter

                                        text:
                                            root.monthName(model.mon)

                                        font.pixelSize:
                                            Math.max(9,
                                                     12 * root.scale)

                                        color: "#4A5E8A"

                                        horizontalAlignment:
                                            Text.AlignHCenter
                                    }

                                    Text {

                                        anchors.horizontalCenter:
                                            parent.horizontalCenter

                                        text: model.hhmm

                                        font.pixelSize:
                                            Math.max(8,
                                                     11 * root.scale)

                                        color: "#7B8FAD"

                                        horizontalAlignment:
                                            Text.AlignHCenter
                                    }
                                }
                            }
                        }
                    }
                }

                // =================================================
                // FLICK AREA
                // =================================================

                Flickable {
                    id: flickArea

                    x: histogramCard.yAxisWidth
                    y: graphArea.topLabelPadding

                    width: graphArea.plotW
                    height: graphArea.barAreaH

                    clip: true

                    boundsBehavior: Flickable.StopAtBounds

                    interactive: true

                    flickableDirection: Flickable.HorizontalFlick

                    contentWidth: graphArea.totalBarsW
                    contentHeight: height

                    pixelAligned: true

                    WheelHandler {

                        acceptedDevices: PointerDevice.Mouse

                        onWheel: function(event) {

                            var oldZoom =
                                    histogramCard.zoomFactor

                            var factor =
                                    event.angleDelta.y > 0
                                    ? 1.08
                                    : 0.92

                            var newZoom = Math.max(
                                histogramCard.minZoomFactor,
                                Math.min(2.0, oldZoom * factor)
                            )

                            if (Math.abs(newZoom - oldZoom) < 0.01)
                                return

                            var mouseContentX =
                                    flickArea.contentX + event.x

                            histogramCard.zoomFactor = newZoom

                            flickArea.contentX = Math.max(
                                0,
                                mouseContentX
                                * (newZoom / oldZoom)
                                - event.x
                            )
                        }
                    }

                    Item {
                        id: plotItem

                        width: flickArea.contentWidth
                        height: flickArea.height

                        // =========================================
                        // GRID
                        // =========================================

                        Repeater {
                            model: histogramCard.ySteps + 1

                            delegate: Rectangle {

                                x: 0

                                y:
                                    (index / histogramCard.ySteps)
                                    * plotItem.height

                                width: plotItem.width

                                height:
                                    index === histogramCard.ySteps
                                    ? 2
                                    : 1

                                color:
                                    index === histogramCard.ySteps
                                    ? "#4A5E8A"
                                    : "#E1E8F5"
                            }
                        }

                        // =========================================
                        // AVG LINE
                        // =========================================

                        Rectangle {

                            x: 0

                            y:
                                (1 - (
                                     root.statAvg
                                     - histogramCard.yMin
                                     ) / (
                                     histogramCard.yMax
                                     - histogramCard.yMin
                                     )) * plotItem.height

                            width: plotItem.width
                            height: 1

                            color: "#F59E0B"

                            opacity: 0.85
                        }

                        // =========================================
                        // BARS
                        // =========================================

                        Repeater {
                            id: barsRepeater

                            model: histValues

                            delegate: Item {
                                id: barSlot

                                x:
                                    index
                                    * histogramCard.barStride
                                    + histogramCard.barSpacing

                                y: 0

                                width: histogramCard.barWidth
                                height: plotItem.height

                                property bool isSelected:
                                    histogramCard.selectedIndex
                                    === index

                                Rectangle {
                                    id: bar

                                    property real fraction:
                                        (model.val
                                         - histogramCard.yMin)
                                        / (
                                            histogramCard.yMax
                                            - histogramCard.yMin
                                          )

                                    property real usableHeight:
                                        plotItem.height
                                        - graphArea.topGraphPadding

                                    width: parent.width

                                    height:
                                        Math.max(
                                            2,
                                            fraction * usableHeight
                                        )

                                    anchors.bottom: parent.bottom

                                    anchors.horizontalCenter:
                                        parent.horizontalCenter

                                    radius:
                                        Math.min(
                                            6 * root.scale,
                                            width * 0.35
                                        )

                                    antialiasing: false

                                    gradient: Gradient {
                                        GradientStop {
                                            position: 0.0

                                            color:
                                                barSlot.isSelected
                                                ? "#FFB74D"
                                                : "#58A6FF"
                                        }

                                        GradientStop {
                                            position: 1.0

                                            color:
                                                barSlot.isSelected
                                                ? "#F57C00"
                                                : "#1A4DB5"
                                        }
                                    }
                                }

                                // =========================================
                                // VALUE LABEL
                                // =========================================

                                Text {

                                    visible:
                                        histogramCard.isDetail
                                        && histogramCard.zoomFactor >= 0.8

                                    anchors.bottom: bar.top

                                    anchors.bottomMargin:
                                        8 * root.scale

                                    anchors.horizontalCenter:
                                        bar.horizontalCenter

                                    text:
                                        model.val.toLocaleString()

                                    font.pixelSize:
                                        Math.max(10,
                                                 10 * root.scale)

                                    font.bold: true

                                    color: "#1A4DB5"

                                    z: 5

                                    opacity:
                                        bar.height > 24 * root.scale
                                        ? 1
                                        : 0

                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: 120
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // =================================================
                // X/Y INTERSECTION
                // =================================================

                Rectangle {

                    x: 0
                    y:
                        graphArea.topLabelPadding
                        + graphArea.barAreaH

                    width: histogramCard.yAxisWidth
                    height: histogramCard.xAxisHeight

                    color: "#FFFFFF"

                    Rectangle {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right

                        height: 2

                        color: "#4A5E8A"
                    }
                }
            }
        }

        // =========================================================
        // TOOLTIP
        // =========================================================

        Rectangle {
            id: tooltipOverlay

            visible:
                histogramCard.selectedIndex >= 0
                && histogramCard.isDetail

            z: 100

            property real currentVal:
                histogramCard.selectedIndex >= 0
                ? histValues.get(histogramCard.selectedIndex).val
                : 0

            property real percent:
                ((currentVal - histogramCard.yMin)
                 / (histogramCard.yMax - histogramCard.yMin)) * 100

            x:
                Math.min(
                    Math.max(
                        8 * root.scale,
                        histogramCard.selectedBarX - width / 2
                    ),
                    histogramCard.width - width - 8 * root.scale
                )

            y:
                histogramCard.selectedBarY
                - height
                - 10 * root.scale

            width:
                Math.max(
                    110 * root.scale,
                    tooltipColumn.implicitWidth + 24 * root.scale
                )

            height:
                tooltipColumn.implicitHeight + 18 * root.scale

            radius: 10 * root.scale

            color: "#102B63"

            border.width: 1
            border.color: "#5D86D8"

            opacity: visible ? 1 : 0

            scale: visible ? 1.0 : 0.9

            Behavior on opacity {
                NumberAnimation {
                    duration: 120
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: 120
                    easing.type: Easing.OutBack
                }
            }

            Column {
                id: tooltipColumn

                anchors.centerIn: parent

                spacing: 2 * root.scale

                // =============================================
                // VALUE
                // =============================================

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter

                    text: Number(currentVal).toLocaleString()

                    font.pixelSize: 17 * root.scale
                    font.bold: true

                    color: "#FFFFFF"
                }

                // =============================================
                // PERCENTAGE
                // =============================================

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter

                    text:
                        percent.toFixed(1) + "%"

                    font.pixelSize: 11 * root.scale
                    font.bold: true

                    color: "#AFCBFF"
                }

                // =============================================
                // DATE + TIME
                // =============================================

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter

                    text:
                        histValues.get(histogramCard.selectedIndex).dd
                        + " "
                        + root.monthName(
                              histValues.get(
                                  histogramCard.selectedIndex
                              ).mon
                          )
                        + "  "
                        + histValues.get(
                              histogramCard.selectedIndex
                          ).hhmm

                    font.pixelSize: 10 * root.scale

                    color: "#D6E4FF"
                }
            }

            // =====================================================
            // POINTER ARROW
            // =====================================================

            Canvas {
                id: tipArrow

                width: 14 * root.scale
                height: 8 * root.scale

                anchors.top: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter

                onPaint: {

                    var ctx = getContext("2d")

                    ctx.clearRect(0, 0, width, height)

                    ctx.fillStyle = "#102B63"

                    ctx.beginPath()

                    ctx.moveTo(0, 0)
                    ctx.lineTo(width / 2, height)
                    ctx.lineTo(width, 0)

                    ctx.closePath()

                    ctx.fill()
                }
            }
        }
    }
}
