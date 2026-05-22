import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtCore
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

    property int readingsPerDay: 288
    property int totalDays: 30

    function monthName(m) {
        var names = ["JAN","FEB","MAR","APR","MAY","JUN",
                     "JUL","AUG","SEP","OCT","NOV","DEC"]
        return names[m - 1]
    }

    ListModel {
        id: histValues
    }

    function jumpToDay(day) {
        var idx = (day - 1) * root.readingsPerDay
        var targetX = idx * histogramCard.barStride + histogramCard.barSpacing

        flickArea.contentX = Math.max(
                    0,
                    Math.min(
                        targetX,
                        flickArea.contentWidth - flickArea.width
                    ))
    }

    Component.onCompleted: {
        loadData()
    }

    function loadData() {
        histValues.clear()

        var sum = 0
        var mn = 999999999
        var mx = 0

        for (var day = 1; day <= totalDays; day++) {

            for (var r = 0; r < readingsPerDay; r++) {

                var totalMin = r * 5
                var hh = Math.floor(totalMin / 60)
                var mm = totalMin % 60

                var hhS = hh < 10 ? "0" + hh : "" + hh
                var mmS = mm < 10 ? "0" + mm : "" + mm
                var dd  = day < 10 ? "0" + day : "" + day

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

        property real minZoomFactor: 0.01
        property real zoomFactor: minZoomFactor
        property real _pinchZoom: minZoomFactor

        property real detailThresh: 0.8
        property bool isDetail: zoomFactor >= detailThresh

        property int selectedIndex: -1
        property real selectedBarX: 0
        property real selectedBarY: 0

        property real barWidth: Math.max(1, 44 * root.scale * zoomFactor)
        property real barSpacing: Math.max(0.5, 6 * root.scale * zoomFactor)
        property real barStride: barWidth + barSpacing

        property int barCount: histValues.count

        property real yMin: 0
        property real yMax: root.statMax > 0 ? root.statMax * 1.1 : 100

        property int ySteps: 5

        property real padH: 20 * root.scale
        property real padV: 16 * root.scale

        property real headerH: 78 * root.scale
        property real yAxisW: 62 * root.scale
        property real xAxisH: 52 * root.scale
        property real navRowH: 54 * root.scale
        property real topPad: 28 * root.scale

        property bool needsNav: {
            var totalW = barCount * barStride + barSpacing * 2
            var plotW = histogramCard.width - padH * 2 - yAxisW
            return totalW > plotW + 10
        }

        property int visibleDay: {
            var firstBar = Math.floor(flickArea.contentX / histogramCard.barStride)

            return Math.max(
                        1,
                        Math.min(
                            root.totalDays,
                            Math.floor(firstBar / root.readingsPerDay) + 1
                        ))
        }

        property real graphTop: {
            var t = padV + headerH + 1

            if (needsNav)
                t += navRowH + 1

            t += 10 * root.scale

            return t
        }

        property real graphH: height - graphTop - padV

        property real plotW: width - padH * 2 - yAxisW

        property real barAreaH: Math.max(
                                    80 * root.scale,
                                    graphH - xAxisH - topPad
                                )

        property real totalBarsW: Math.max(
                                      plotW,
                                      barCount * barStride + barSpacing * 2
                                  )

        PinchHandler {
            target: null

            onActiveChanged: {
                if (active)
                    histogramCard._pinchZoom = histogramCard.zoomFactor
            }

            onActiveScaleChanged: {

                var oldZ = histogramCard.zoomFactor

                var newZ = Math.max(
                            histogramCard.minZoomFactor,
                            Math.min(
                                2.0,
                                histogramCard._pinchZoom * activeScale
                            ))

                if (Math.abs(newZ - oldZ) < 0.005)
                    return

                var cx = flickArea.contentX + flickArea.width / 2

                histogramCard.zoomFactor = newZ

                flickArea.contentX = Math.max(
                            0,
                            cx * (newZ / oldZ) - flickArea.width / 2
                        )
            }
        }

        // HEADER

        Item {
            id: headerItem

            x: histogramCard.padH
            y: histogramCard.padV

            width: histogramCard.width - histogramCard.padH * 2
            height: histogramCard.headerH

            RowLayout {
                anchors.fill: parent
                spacing: 20 * root.scale

                Rectangle {

                    Layout.preferredWidth: 320 * root.scale
                    Layout.preferredHeight: 64 * root.scale

                    radius: 18 * root.scale

                    color: "#F7F9FD"

                    border.width: 1
                    border.color: "#DCE5F5"

                    RowLayout {

                        anchors.fill: parent

                        anchors.leftMargin: 18 * root.scale
                        anchors.rightMargin: 18 * root.scale

                        spacing: 14 * root.scale

                        ColumnLayout {

                            Layout.fillWidth: true

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

                        ColumnLayout {

                            Layout.fillWidth: true

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

                        ColumnLayout {

                            Layout.fillWidth: true

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

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Text {
                        anchors.centerIn: parent
                        text: "Coil Output"
                        font.pixelSize: 30 * root.scale
                        font.bold: true
                        color: "#0E4AB8"
                    }
                }

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

                        // ─────────────────────────────────────────────
                        // ZOOM OUT
                        // ─────────────────────────────────────────────

                        Rectangle {

                            Layout.preferredWidth: 46 * root.scale
                            Layout.preferredHeight: 46 * root.scale

                            radius: 14 * root.scale

                            color: zoomOutMa.pressed
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

                                    var oldZ = histogramCard.zoomFactor

                                    var newZ = Math.max(
                                                histogramCard.minZoomFactor,
                                                oldZ * 0.85
                                            )

                                    if (Math.abs(newZ - oldZ) < 0.001)
                                        return

                                    var cx = flickArea.contentX + flickArea.width / 2

                                    histogramCard.zoomFactor = newZ

                                    flickArea.contentX = Math.max(
                                                0,
                                                cx * (newZ / oldZ) - flickArea.width / 2
                                            )
                                }

                                onClicked: {

                                    if (!holdActive)
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

                                    if (histogramCard.zoomFactor
                                            <= histogramCard.minZoomFactor + 0.001) {

                                        stop()

                                    } else {

                                        zoomOutMa.doZoomOut()
                                    }
                                }
                            }
                        }

                        // ─────────────────────────────────────────────
                        // ZOOM INFO
                        // ─────────────────────────────────────────────

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

                                    anchors.horizontalCenter: parent.horizontalCenter

                                    text: "ZOOM"

                                    font.pixelSize: 9 * root.scale
                                    font.bold: true

                                    color: "#8EA2C8"
                                }

                                Text {

                                    anchors.horizontalCenter: parent.horizontalCenter

                                    text: Math.round(histogramCard.zoomFactor * 100) + "%"

                                    font.pixelSize: 15 * root.scale
                                    font.bold: true

                                    color: "#1A4DB5"
                                }
                            }
                        }

                        // ─────────────────────────────────────────────
                        // ZOOM IN
                        // ─────────────────────────────────────────────

                        Rectangle {

                            Layout.preferredWidth: 46 * root.scale
                            Layout.preferredHeight: 46 * root.scale

                            radius: 14 * root.scale

                            color: zoomInMa.pressed
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

                                function zoomInStep() {

                                    var oldZ = histogramCard.zoomFactor

                                    var newZ = Math.min(
                                                2.0,
                                                oldZ * 1.15
                                            )

                                    if (Math.abs(newZ - oldZ) < 0.001)
                                        return

                                    var cx = flickArea.contentX + flickArea.width / 2

                                    histogramCard.zoomFactor = newZ

                                    flickArea.contentX = Math.max(
                                                0,
                                                cx * (newZ / oldZ) - flickArea.width / 2
                                            )
                                }

                                onClicked: {

                                    zoomInStep()
                                }

                                onPressed: {

                                    zoomInTimer.start()
                                }

                                onReleased: {

                                    zoomInTimer.stop()
                                }

                                onCanceled: {

                                    zoomInTimer.stop()
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
            x: 0
            y: histogramCard.padV + histogramCard.headerH
            width: histogramCard.width
            height: 1
            color: "#E1E8F5"
        }

        // DAY NAVIGATION

        Item {
            id: navRow

            x: histogramCard.padH
            y: histogramCard.padV + histogramCard.headerH + 1

            width: histogramCard.width - histogramCard.padH * 2
            height: histogramCard.needsNav ? histogramCard.navRowH : 0

            visible: histogramCard.needsNav
            clip: true

            Rectangle {
                id: prevBtn

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter

                width: 46 * root.scale
                height: 46 * root.scale

                radius: 14 * root.scale

                color: prevMa.pressed
                       ? "#BFD7FF"
                       : (prevMa.containsMouse ? "#DCEBFF" : "#EDF4FF")

                border.width: 1
                border.color: "#6F95D6"

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
                        if (!holdActive) {
                            var c = histogramCard.visibleDay

                            if (c > 1)
                                root.jumpToDay(c - 1)
                        }
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
                        var c = histogramCard.visibleDay

                        if (c > 1)
                            root.jumpToDay(c - 1)
                        else
                            stop()
                    }
                }
            }

            Rectangle {
                id: nextBtn

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter

                width: 46 * root.scale
                height: 46 * root.scale

                radius: 14 * root.scale

                color: nextMa.pressed
                       ? "#BFD7FF"
                       : (nextMa.containsMouse ? "#DCEBFF" : "#EDF4FF")

                border.width: 1
                border.color: "#6F95D6"

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
                        if (!holdActive) {
                            var c = histogramCard.visibleDay

                            if (c < root.totalDays)
                                root.jumpToDay(c + 1)
                        }
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
                        var c = histogramCard.visibleDay

                        if (c < root.totalDays)
                            root.jumpToDay(c + 1)
                        else
                            stop()
                    }
                }
            }

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

                contentWidth: pillRow.width
                contentHeight: height

                Behavior on contentX {
                    NumberAnimation {
                        duration: 220
                        easing.type: Easing.OutCubic
                    }
                }

                Item {
                    id: pillBg

                    width: pillRow.width
                    height: parent.height

                    Rectangle {
                        id: selHighlight

                        width: 44 * root.scale
                        height: 34 * root.scale

                        radius: 9 * root.scale

                        y: (pillBg.height - height) / 2

                        x: (histogramCard.visibleDay - 1)
                           * ((44 * root.scale) + (7 * root.scale))

                        color: "#1A4DB5"

                        border.width: 1
                        border.color: "#6F95D6"

                        z: 0

                        Behavior on x {
                            NumberAnimation {
                                duration: 180
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    Row {
                        id: pillRow

                        spacing: 7 * root.scale

                        anchors.verticalCenter: parent.verticalCenter

                        Repeater {
                            model: root.totalDays

                            delegate: Item {
                                width: 44 * root.scale
                                height: 34 * root.scale

                                property bool active:
                                    histogramCard.visibleDay === index + 1

                                Text {
                                    anchors.centerIn: parent

                                    text: (index + 1) < 10
                                          ? "0" + (index + 1)
                                          : "" + (index + 1)

                                    font.pixelSize: 12 * root.scale
                                    font.bold: active

                                    color: active
                                           ? "#FFFFFF"
                                           : (pma.containsMouse
                                              ? "#1A4DB5"
                                              : "#3562B8")

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 120
                                        }
                                    }
                                }

                                MouseArea {
                                    id: pma

                                    anchors.fill: parent

                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor

                                    onClicked: {
                                        root.jumpToDay(index + 1)
                                    }
                                }
                            }
                        }
                    }
                }

                Connections {
                    target: histogramCard

                    function onVisibleDayChanged() {

                        var itemWidth =
                                (44 * root.scale) + (7 * root.scale)

                        var targetX =
                                (histogramCard.visibleDay - 1) * itemWidth
                                - dayPillFlick.width / 2
                                + itemWidth / 2

                        dayPillFlick.contentX =
                                Math.max(
                                    0,
                                    Math.min(
                                        targetX,
                                        dayPillFlick.contentWidth
                                        - dayPillFlick.width
                                    )
                                )
                    }
                }
            }
        }

        Rectangle {
            x: 0
            y: navRow.y + navRow.height
            width: histogramCard.width
            height: histogramCard.needsNav ? 1 : 0
            color: "#E1E8F5"
        }

        // Y AXIS

        Item {

            id: yAxisItem

            x: histogramCard.padH
            y: histogramCard.graphTop + histogramCard.topPad

            width: histogramCard.yAxisW
            height: histogramCard.barAreaH

            Rectangle {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 2
                color: "#4A5E8A"
            }

            Repeater {

                model: histogramCard.ySteps + 1

                delegate: Item {

                    width: histogramCard.yAxisW - 4 * root.scale
                    height: 18 * root.scale

                    y: (index / histogramCard.ySteps) * yAxisItem.height - height / 2

                    Text {

                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter

                        anchors.rightMargin: 6 * root.scale

                        property real frac:
                            1.0 - index / histogramCard.ySteps

                        property real labelVal:
                            histogramCard.yMin +
                            frac * (histogramCard.yMax - histogramCard.yMin)

                        text: {
                            if (labelVal >= 1000000)
                                return (labelVal / 1000000).toFixed(1) + "M"

                            if (labelVal >= 1000)
                                return (labelVal / 1000).toFixed(1) + "k"

                            return Math.round(labelVal).toString()
                        }

                        font.pixelSize: Math.max(9, 10 * root.scale)
                        color: "#4A5E8A"
                    }
                }
            }
        }

        // GRAPH AREA

        Flickable {

            id: flickArea

            x: histogramCard.padH + histogramCard.yAxisW
            y: histogramCard.graphTop + histogramCard.topPad

            width: histogramCard.plotW
            height: histogramCard.barAreaH

            clip: true

            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.HorizontalFlick

            contentWidth: histogramCard.totalBarsW
            contentHeight: height

            ScrollBar.horizontal: ScrollBar {
                policy: ScrollBar.AlwaysOff
            }

            WheelHandler {

                acceptedDevices: PointerDevice.Mouse

                onWheel: function(ev) {

                    var oldZ = histogramCard.zoomFactor

                    var factor = ev.angleDelta.y > 0 ? 1.08 : 0.92

                    var newZ = Math.max(
                                histogramCard.minZoomFactor,
                                Math.min(2.0, oldZ * factor)
                            )

                    var mouseX = flickArea.contentX + ev.x

                    histogramCard.zoomFactor = newZ

                    flickArea.contentX = Math.max(
                                0,
                                mouseX * (newZ / oldZ) - ev.x
                            )
                }
            }

            Item {
                id: plotItem

                width: flickArea.contentWidth
                height: flickArea.height

                // =====================================================
                // SINGLE GLOBAL HOVER HANDLER
                // =====================================================

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true

                    onPositionChanged: function(mouse) {

                        var idx = Math.floor(
                                    (mouse.x - histogramCard.barSpacing)
                                    / histogramCard.barStride
                                )

                        if (idx >= 0 && idx < histValues.count) {

                            histogramCard.selectedIndex = idx

                            histogramCard.selectedBarX =
                                    idx * histogramCard.barStride
                                    + histogramCard.barWidth / 2

                            var item = histValues.get(idx)

                            var fraction =
                                    (item.val - histogramCard.yMin)
                                    / (histogramCard.yMax - histogramCard.yMin)

                            histogramCard.selectedBarY =
                                    plotItem.height
                                    - Math.max(2, fraction * plotItem.height)

                        } else {

                            histogramCard.selectedIndex = -1
                        }
                    }

                    onExited: {
                        histogramCard.selectedIndex = -1
                    }
                }

                // =====================================================
                // BAR REPEATER
                // =====================================================

                Repeater {

                    model: histValues

                    delegate: Item {

                        id: barSlot

                        readonly property real slotX:
                            index * histogramCard.barStride
                            + histogramCard.barSpacing

                        readonly property real slotRight:
                            slotX + histogramCard.barWidth

                        readonly property bool inView:
                            slotRight >= flickArea.contentX - 150
                            && slotX <= flickArea.contentX + flickArea.width + 150

                        visible: inView

                        x: slotX

                        width: histogramCard.barWidth
                        height: plotItem.height

                        readonly property real fraction:
                            (model.val - histogramCard.yMin)
                            / (histogramCard.yMax - histogramCard.yMin)

                        readonly property real barH:
                            Math.max(2, fraction * plotItem.height)

                        readonly property bool selected:
                            histogramCard.selectedIndex === index

                        // =================================================
                        // BAR
                        // =================================================

                        Rectangle {

                            anchors.bottom: parent.bottom

                            width: parent.width
                            height: parent.barH

                            radius: Math.min(
                                        4 * root.scale,
                                        width * 0.4
                                    )

                            color:"#1A4DB5"

                            layer.enabled: false
                        }

                        // =================================================
                        // VALUE LABEL
                        // =================================================

                        Text {

                            visible: histogramCard.isDetail && inView

                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: parent.barH + (4 * root.scale)

                            anchors.horizontalCenter: parent.horizontalCenter

                            text: model.val.toLocaleString()

                            font.pixelSize: Math.max(8, 9 * root.scale)
                            font.bold: true

                            color: "#1A4DB5"

                            renderType: Text.NativeRendering
                        }
                    }
                }
            }
        }

        // X AXIS

        Item {

            id: xAxisItem

            x: histogramCard.padH + histogramCard.yAxisW

            y: histogramCard.graphTop
               + histogramCard.topPad
               + histogramCard.barAreaH

            width: histogramCard.plotW
            height: histogramCard.xAxisH

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

                width: histogramCard.totalBarsW
                height: parent.height

                Repeater {

                    model: histValues

                    delegate: Item {

                        x: index * histogramCard.barStride
                           + histogramCard.barSpacing

                        width: histogramCard.barStride
                        height: xAxisItem.height

                        visible: {
                            var left = x
                            var right = left + width

                            return right >= flickArea.contentX - 100
                                    && left <= flickArea.contentX
                                       + flickArea.width + 100
                        }

                        Rectangle {
                            x: parent.width / 2
                            y: 2
                            width: 1
                            height: 5 * root.scale
                            color: "#4A5E8A"
                        }

                        Column {

                            visible: !histogramCard.isDetail
                                     && model.hhmm === "00:05"

                            anchors.top: parent.top
                            anchors.topMargin: 9 * root.scale

                            anchors.horizontalCenter: parent.horizontalCenter

                            spacing: 2 * root.scale

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: model.dd
                                font.pixelSize: Math.max(9, 11 * root.scale)
                                font.bold: true
                                color: "#1A4DB5"
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: root.monthName(model.mon)
                                font.pixelSize: Math.max(8, 9 * root.scale)
                                color: "#4A5E8A"
                            }
                        }

                        Column {

                            visible: histogramCard.isDetail

                            anchors.top: parent.top
                            anchors.topMargin: 9 * root.scale

                            anchors.horizontalCenter: parent.horizontalCenter

                            spacing: 4 * root.scale

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: model.dd
                                font.pixelSize: Math.max(9, 11 * root.scale)
                                font.bold: true
                                color: "#1A4DB5"
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: root.monthName(model.mon)
                                font.pixelSize: Math.max(8, 9 * root.scale)
                                color: "#4A5E8A"
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: model.hhmm
                                font.pixelSize: Math.max(7, 8 * root.scale)
                                color: "#7B8FAD"
                            }
                        }
                    }
                }
            }
        }

        Rectangle {

            x: histogramCard.padH

            y: histogramCard.graphTop
               + histogramCard.topPad
               + histogramCard.barAreaH

            width: histogramCard.yAxisW
            height: histogramCard.xAxisH

            color: "#FFFFFF"

            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 2
                color: "#4A5E8A"
            }
        }

        // TOOLTIP

        Rectangle {

            id: tooltip

            visible:
                histogramCard.selectedIndex >= 0
                && histogramCard.isDetail

            z: 200

            property real curVal:
                histogramCard.selectedIndex >= 0
                ? histValues.get(histogramCard.selectedIndex).val
                : 0

            property real pct:
                (curVal - histogramCard.yMin)
                / (histogramCard.yMax - histogramCard.yMin)
                * 100

            x: Math.min(
                    Math.max(
                        8 * root.scale,
                        histogramCard.selectedBarX - width / 2
                    ),
                    histogramCard.width - width - 8 * root.scale
                )

            y: histogramCard.selectedBarY
               - height
               - 10 * root.scale

            width: Math.max(
                       110 * root.scale,
                       tipCol.implicitWidth + 24 * root.scale
                   )

            height: tipCol.implicitHeight + 18 * root.scale

            radius: 10 * root.scale

            color: "#102B63"

            border.width: 1
            border.color: "#5D86D8"
        }
    }
}
