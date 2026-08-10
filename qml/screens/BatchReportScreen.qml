import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import AppState 1.0

Item {
    id: root
    anchors.fill: parent

    property var globalTopBar
    property var navigateTo

    property real baseWidth: 1024
    property real baseHeight: 600
    property real scale: Math.min(width / baseWidth, height / baseHeight)

    function loadBatchReports()
    {
        batchReportModel.clear()

        var reports =
                databaseManager.getBatchReports()

        for (var i = 0; i < reports.length; i++)
        {
            var r = reports[i]

            batchReportModel.append({
                id: r.id,
                sno: i + 1,

                batch: r.batch,
                product: r.product,

                productCode: r.productCode,
                productSno: r.productSno,

                started: r.started,
                ended: r.ended,

                runDuration: formatDuration(r.runDuration),
                pauseDuration: formatDuration(r.pauseDuration),
                totalDuration: formatDuration(r.totalDuration),

                startedBy: r.startedBy,
                endedBy: r.endedBy,

                rejectionCount: r.rejectionCount,

                status: r.status
            })
        }
    }

    function formatDuration(seconds)
    {
        seconds = Number(seconds)

        if (isNaN(seconds) || seconds < 0)
            return "0 Hrs - 0 Mins"

        seconds = Math.floor(seconds)

        var hours = Math.floor(seconds / 3600)
        var minutes = Math.floor((seconds % 3600) / 60)

        return hours + " Hrs - "
               + minutes + " Mins"
    }

    // =====================================================
    // STATIC BACKDROP
    // =====================================================

    Rectangle {
        id: backdrop
        anchors.fill: parent
        color: "#F5F7FC"
    }

    // =====================================================
    // PAGE OPEN ANIMATION
    // =====================================================

    Component.onCompleted: {

        openAnimation.start()

        loadBatchReports()
    }

    // =====================================================
    // OPEN
    // =====================================================

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
            property: "pageScale"

            from: 0.85
            to: 1.0

            duration: 650

            easing.type: Easing.OutBack

            easing.overshoot: 1.05
        }
    }

    // =====================================================
    // CLOSE
    // =====================================================

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
            property: "pageScale"

            from: 1.0
            to: 0.85

            duration: 500

            easing.type: Easing.InOutCubic
        }
    }

    function closePage() {
        closeAnimation.start()
    }

    property string searchText: ""

    // ===== TOUCH-FRIENDLY SIZES =====
    property real rowHeight:    56 * scale
    property real btnHeight:    44 * scale
    property real filterHeight: 64 * scale

    // ===== COLUMN WIDTHS =====
    property real colSpacing: 16 * scale

    property real colSno:     60  * scale
    property real colBatch:   200 * scale
    property real colStarted: 200 * scale
    property real colEnded:   200 * scale
    property real colPdf:     130 * scale

    property real colProduct: {
        var used = colSno + colBatch + colStarted + colEnded + colPdf + (colSpacing * 5)
        return Math.max(100 * scale, tableContainer.width - used - 24 * scale)
    }

    property int visibleCount: {
        var count = 0
        for (var i = 0; i < tableList.count; i++) {
            var m = tableList.model.get(i)
            if (m.batch.toLowerCase().includes(root.searchText.toLowerCase())) count++
        }
        return count
    }

    Item {
        id: content
        anchors.fill: parent

        opacity: 0.0
        property real pageScale: 0.85

        transform: Scale {
            origin.x: content.width / 2
            origin.y: content.height / 2

            xScale: content.pageScale
            yScale: content.pageScale
        }

        Rectangle {
            anchors.fill: parent
            color: "#F5F7FC"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24 * root.scale
            spacing: 16 * root.scale

            // ===== HEADER =====
            // ===== HEADER =====
            Rectangle {
                Layout.fillWidth: true
                height: 54 * root.scale
                color: "transparent"

                RowLayout {
                    anchors.fill: parent
                    spacing: 10 * root.scale

                    // =================================================
                    // TITLE
                    // =================================================
                    Column {
                        Layout.fillWidth: true
                        spacing: 5 * root.scale

                        Text {
                            text: "Batch Report"
                            font.pixelSize: 26
                            font.weight: Font.Medium
                            color: "#1A4DB5"
                        }

                        Rectangle {
                            width: 80 * root.scale
                            height: 4 * root.scale
                            radius: 2 * root.scale
                            color: "#1A4DB5"
                        }
                    }

                    // =================================================
                    // CLEAR DATA BUTTON
                    // =================================================
                    Rectangle {
                        Layout.preferredWidth: 130 * root.scale
                        Layout.preferredHeight: 38 * root.scale

                        visible: GlobalState.developerLogin

                        radius: 6 * root.scale

                        color: clearDataMouse.pressed
                               ? "#D32F2F"
                               : "#FFFFFF"

                        border.color: "#D32F2F"
                        border.width: 1

                        Text {
                            anchors.centerIn: parent

                            text: "Clear Data"

                            font.pixelSize: 18
                            font.weight: Font.Medium

                            color: clearDataMouse.pressed
                                   ? "#FFFFFF"
                                   : "#D32F2F"
                        }

                        MouseArea {
                            id: clearDataMouse

                            anchors.fill: parent

                            cursorShape: Qt.PointingHandCursor

                            onClicked: {

                                // Clear actual database records
                                var success = databaseManager.clearBatchReports()

                                if (success) {

                                    // Clear currently displayed rows
                                    batchReportModel.clear()

                                    // Optional notification
                                    if (globalTopBar &&
                                        globalTopBar.showNotification) {

                                        globalTopBar.showNotification(
                                            "✓ Batch report data cleared"
                                        )
                                    }

                                } else {

                                    if (globalTopBar &&
                                        globalTopBar.showNotification) {

                                        globalTopBar.showNotification(
                                            "✗ Failed to clear batch report data"
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ===== FILTER BAR =====
            Rectangle {
                Layout.fillWidth: true
                height: root.filterHeight

                radius: 10 * root.scale
                color: "#FFFFFF"
                border.color: "#D0D8EC"
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16 * root.scale
                    anchors.rightMargin: 16 * root.scale
                    spacing: 14 * root.scale

                    // SEARCH ICON + FIELD
                    Rectangle {
                        Layout.fillWidth: true
                        height: 42 * root.scale
                        radius: 8 * root.scale
                        color: "#F5F7FC"
                        border.color: searchInput.activeFocus ? "#1A4DB5" : "#D0D8EC"
                        border.width: searchInput.activeFocus ? 2 : 1

                        Behavior on border.color { ColorAnimation { duration: 150 } }
                        Behavior on border.width { NumberAnimation { duration: 150 } }

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 12 * root.scale
                            anchors.right: parent.right
                            anchors.rightMargin: 12 * root.scale
                            spacing: 8 * root.scale

                            // Search icon (magnifier drawn with Canvas)
                            Canvas {
                                id: searchIcon
                                width: 18 * root.scale
                                height: 18 * root.scale
                                anchors.verticalCenter: parent.verticalCenter

                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.clearRect(0, 0, width, height)
                                    ctx.strokeStyle = searchInput.activeFocus ? "#1A4DB5" : "#7A86A5"
                                    ctx.lineWidth = 1.8 * root.scale
                                    ctx.lineCap = "round"
                                    var cx = 7 * root.scale
                                    var cy = 7 * root.scale
                                    var r  = 5 * root.scale
                                    ctx.beginPath()
                                    ctx.arc(cx, cy, r, 0, Math.PI * 2)
                                    ctx.stroke()
                                    ctx.beginPath()
                                    ctx.moveTo(cx + r * 0.707, cy + r * 0.707)
                                    ctx.lineTo(cx + r * 0.707 + 4 * root.scale, cy + r * 0.707 + 4 * root.scale)
                                    ctx.stroke()
                                }

                                Connections {
                                    target: searchInput
                                    function onActiveFocusChanged() { searchIcon.requestPaint() }
                                }
                            }

                            TextField {
                                id: searchInput

                                width: parent.width - 26 * root.scale - parent.spacing
                                height: 42 * root.scale

                                background: null

                                placeholderText: "Search batch..."
                                placeholderTextColor: "#9AA6C1"

                                font.pixelSize: 15
                                color: "#1A1A1A"

                                verticalAlignment: TextInput.AlignVCenter

                                focus: true

                                property bool isPasswordField: false

                                onPressed: {
                                    GlobalState.activeInputField = searchInput
                                    GlobalState.loginKeyboardRequest = true
                                    forceActiveFocus()
                                }

                                onActiveFocusChanged: {
                                    if (activeFocus)
                                        GlobalState.activeInputField = searchInput
                                }

                                onTextChanged: {
                                    root.searchText = text
                                }

                                // CLOSE KEYBOARD ON ENTER
                                onAccepted: {
                                    if (text.trim().length > 0) {
                                        GlobalState.loginKeyboardRequest = false
                                        focus = false
                                    }
                                }

                                inputMethodHints: Qt.ImhNoPredictiveText
                            }
                        }
                    }

                    // RECORD COUNT BADGE
                    Rectangle {
                        width: 80 * root.scale
                        height: 42 * root.scale
                        radius: 8 * root.scale
                        color: "#EEF2FF"
                        border.color: "#C7D2F5"
                        border.width: 1

                        Column {
                            anchors.centerIn: parent
                            spacing: 0

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: root.visibleCount
                                font.pixelSize: 17
                                font.weight: Font.Normal
                                color: "#1A4DB5"
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "records"
                                font.pixelSize: 11
                                color: "#5B6FA8"
                            }
                        }
                    }

                    // CLEAR BUTTON
                    Rectangle {
                        width: 90 * root.scale
                        height: 42 * root.scale
                        radius: 8 * root.scale
                        color: root.searchText.length > 0 ? "#1A4DB5" : "#EEF2FF"
                        border.color: root.searchText.length > 0 ? "#1A4DB5" : "#C7D2F5"
                        border.width: 1
                        opacity: root.searchText.length > 0 ? 1.0 : 0.6

                        Behavior on color   { ColorAnimation { duration: 150 } }
                        Behavior on opacity { NumberAnimation { duration: 150 } }

                        Row {
                            anchors.centerIn: parent
                            spacing: 6 * root.scale

                            // X icon via Canvas
                            Canvas {
                                id: clearIcon
                                width:  14 * root.scale
                                height: 14 * root.scale
                                anchors.verticalCenter: parent.verticalCenter

                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.clearRect(0, 0, width, height)
                                    ctx.strokeStyle = root.searchText.length > 0 ? "#FFFFFF" : "#1A4DB5"
                                    ctx.lineWidth = 1.8 * root.scale
                                    ctx.lineCap = "round"
                                    var p = 2 * root.scale
                                    ctx.beginPath()
                                    ctx.moveTo(p, p)
                                    ctx.lineTo(width - p, height - p)
                                    ctx.stroke()
                                    ctx.beginPath()
                                    ctx.moveTo(width - p, p)
                                    ctx.lineTo(p, height - p)
                                    ctx.stroke()
                                }

                                Connections {
                                    target: root
                                    function onSearchTextChanged() { clearIcon.requestPaint() }
                                }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Clear"
                                font.pixelSize: 14
                                font.weight: Font.Medium
                                color: root.searchText.length > 0 ? "#FFFFFF" : "#1A4DB5"
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            enabled: root.searchText.length > 0
                            onClicked: {
                                searchInput.text = ""
                                root.searchText = ""
                            }
                        }
                    }
                }
            }

            // ===== TABLE =====
            Rectangle {
                id: tableContainer
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 10 * root.scale
                color: "#FFFFFF"
                border.color: "#D0D8EC"
                border.width: 1
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // TABLE HEADER
                    Rectangle {
                        Layout.fillWidth: true
                        height: 52 * root.scale
                        color: "#1A4DB5"
                        radius: 10 * root.scale

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 10 * root.scale
                            color: "#1A4DB5"
                        }

                        Row {
                            anchors.fill: parent
                            anchors.margins: 12 * root.scale
                            spacing: root.colSpacing

                            Text { text: "S/No";       width: root.colSno;     color: "#FFF"; font.pixelSize: 20; verticalAlignment: Text.AlignVCenter; height: parent.height }
                            Text { text: "Batch";      width: root.colBatch;   color: "#FFF"; font.pixelSize: 20; verticalAlignment: Text.AlignVCenter; height: parent.height }
                            Text { text: "Product";    width: root.colProduct; color: "#FFF"; font.pixelSize: 20; verticalAlignment: Text.AlignVCenter; height: parent.height }
                            Text { text: "Started At"; width: root.colStarted; color: "#FFF"; font.pixelSize: 20; verticalAlignment: Text.AlignVCenter; height: parent.height }
                            Text { text: "Ended At";   width: root.colEnded;   color: "#FFF"; font.pixelSize: 20; verticalAlignment: Text.AlignVCenter; height: parent.height }
                            Text { text: "Save PDF";   width: root.colPdf;     color: "#FFF"; font.pixelSize: 20; verticalAlignment: Text.AlignVCenter; height: parent.height }
                        }
                    }

                    // TABLE ROWS
                    ListView {
                        id: tableList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true

                        model: ListModel {
                            id: batchReportModel
                        }

                        delegate: Rectangle {
                            property bool searchOk: batch.toLowerCase().includes(root.searchText.toLowerCase())

                            visible: searchOk
                            width: ListView.view.width
                            height: visible ? root.rowHeight : 0
                            color: index % 2 === 0 ? "#FFFFFF" : "#F4F7FF"

                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                anchors.right: parent.right
                                height: 1
                                color: "#E4EAF5"
                            }

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin:  12 * root.scale
                                anchors.rightMargin: 12 * root.scale
                                anchors.topMargin:   0
                                anchors.bottomMargin: 0
                                spacing: root.colSpacing

                                Text {
                                    text: sno
                                    width: root.colSno
                                    height: parent.height
                                    font.pixelSize: 18
                                    color: "#3A3A3A"
                                    verticalAlignment: Text.AlignVCenter
                                }

                                Text {
                                    text: batch
                                    width: root.colBatch
                                    height: parent.height
                                    font.pixelSize: 18
                                    color: "#1A4DB5"
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                    verticalAlignment: Text.AlignVCenter
                                }

                                Text {
                                    text: product
                                    width: root.colProduct
                                    height: parent.height
                                    font.pixelSize: 18
                                    color: "#3A3A3A"
                                    elide: Text.ElideRight
                                    verticalAlignment: Text.AlignVCenter
                                }

                                Text {
                                    text: started
                                    width: root.colStarted
                                    height: parent.height
                                    font.pixelSize: 18
                                    color: "#3A3A3A"
                                    verticalAlignment: Text.AlignVCenter
                                }

                                Text {
                                    text: ended
                                    width: root.colEnded
                                    height: parent.height
                                    font.pixelSize: 18
                                    color: ended === "---" ? "#8896B0" : "#3A3A3A"
                                    verticalAlignment: Text.AlignVCenter
                                }

                                // ===== SAVE PDF BUTTON  =====
                                Item {
                                    width: root.colPdf
                                    height: parent.height

                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: root.colPdf - 8 * root.scale
                                        height: root.btnHeight
                                        radius: 8 * root.scale
                                        color: saveMouse.pressed ? "#1A4DB5" : "#FFFFFF"
                                        border.color: "#1A4DB5"
                                        border.width: 1.5

                                        Text {
                                            anchors.centerIn: parent
                                            text: "Create PDF"
                                            font.pixelSize: 17
                                            font.weight: Font.Medium
                                            color: saveMouse.pressed ? "#FFFFFF" : "#1A4DB5"
                                        }

                                        MouseArea {
                                            id: saveMouse
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                // Pass the batch row data
                                                var batchInfo = {

                                                    "id": id,

                                                    "sno": sno,

                                                    "batch": batch,

                                                    "product": product,

                                                    "productCode": productCode,

                                                    "productSno": productSno,

                                                    "started": started,

                                                    "ended": ended,

                                                    "runDuration": runDuration,

                                                    "pauseDuration": pauseDuration,

                                                    "totalDuration": totalDuration,

                                                    "startedBy": startedBy,

                                                    "endedBy": endedBy,

                                                    "rejectionCount": rejectionCount
                                                }

                                                // Pass rejection rows
                                                var batchEvents =
                                                        databaseManager.getBatchReportEvents(id)

                                                var sessionInfo = {
                                                    "loggedInUserName": GlobalState.loggedInUserName,
                                                    "loggedInUserRole": GlobalState.loggedInUserRole
                                                }

                                                var savedPath =
                                                    PdfExporter.exportBatchToPdf(
                                                        batchInfo,
                                                        batchEvents,
                                                        sessionInfo,
                                                        ""
                                                    )


                                                if (globalTopBar && globalTopBar.showNotification)
                                                    globalTopBar.showNotification("✓ Batch PDF saved")


                                                // ADD TO REPORT LOG

                                                GlobalState.reportsLogModel.append({
                                                    sr: GlobalState.reportsLogModel.count + 1,
                                                    type: "Batch Report",
                                                    date: Qt.formatDate(new Date(), "dd/MM/yyyy"),
                                                    from: started ? started : "-",
                                                    to: ended ? ended : "-",
                                                    by: GlobalState.getCurrentUser(),
                                                    filePath: savedPath
                                                })

                                                GlobalState.saveLogs()
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // ===== NO DATA =====
                        Item {
                            anchors.fill: parent
                            visible: root.visibleCount === 0

                            Column {
                                anchors.centerIn: parent
                                spacing: 16 * root.scale

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "No data found"
                                    font.pixelSize: 24
                                    font.weight: Font.Medium
                                    color: "#8896B0"
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "No records match the selected filters"
                                    font.pixelSize: 20
                                    color: "#B0BEE0"
                                }

                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 160 * root.scale
                                    height: 52 * root.scale
                                    radius: 12 * root.scale
                                    color: "#1A4DB5"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Reset Filters"
                                        font.pixelSize: 18
                                        font.weight: Font.Medium
                                        color: "#FFFFFF"
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            searchInput.text = ""
                                            root.searchText = ""
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    }
}
