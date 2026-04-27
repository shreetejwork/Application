import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../components"

Item {
    id: root
    anchors.fill: parent

    property real baseWidth: 1024
    property real baseHeight: 600
    property real scale: Math.min(width / baseWidth, height / baseHeight)

    property string fromDate: ""
    property string toDate: ""
    property string selectedUser: "All"
    property string searchText: ""
    property date pickerDate: new Date()
    property var activeRemarkFilters: []

    // ===== COLUMN WIDTHS =====
    property real colSpacing: 16 * scale

    property real colSr: 50 * scale
    property real colDate: 130 * scale
    property real colTime: 110 * scale
    property real colUser: 110 * scale
    property real colOld: 150 * scale
    property real colNew: 160 * scale

    function getTableData() {
        let arr = []

        for (let i = 0; i < tableList.model.count; i++) {
            let item = tableList.model.get(i)

            arr.push({
                sr: item.sr,
                date: item.date,
                time: item.time,
                user: item.user,
                old: item.old,
                newVal: item.newVal,
                remark: item.remark
            })
        }

        return arr
    }

    property int visibleCount: {
        var count = 0
        var from = parseDate(root.fromDate)
        var to   = parseDate(root.toDate)
        for (var i = 0; i < tableList.count; i++) {
            var m = tableList.model.get(i)
            var d = parseDate(m.date)
            if (!d) { count++; continue }
            if (from && d < from) continue
            if (to   && d > to)   continue
            var userOk   = root.selectedUser === "All" || m.user === root.selectedUser
            var searchOk = m.remark.toLowerCase().includes(root.searchText.toLowerCase())
            var remarkOk = root.activeRemarkFilters.length === 0 ||
                    root.activeRemarkFilters.some(function(f) {
                        return m.remark.toLowerCase().includes(f.toLowerCase().replace(/\n/g, " "))
                    })
            if (userOk && searchOk && remarkOk) count++
        }
        return count
    }

    // ===== HELPERS =====
    function daysInMonth(month, year) {
        return new Date(year, month + 1, 0).getDate()
    }

    function firstDayOfMonth(month, year) {
        return new Date(year, month, 1).getDay()
    }

    function parseDate(str) {
        if (str === "") return null
        var parts = str.split("/")
        if (parts.length !== 3) return null
        return new Date(parseInt(parts[2]), parseInt(parts[1]) - 1, parseInt(parts[0]))
    }

    function dateInRange(rowDate) {
        var d    = parseDate(rowDate)
        if (!d) return true
        var from = parseDate(root.fromDate)
        var to   = parseDate(root.toDate)
        if (from && d < from) return false
        if (to   && d > to)   return false
        return true
    }

    function remarkInFilter(remark) {
        if (root.activeRemarkFilters.length === 0) return true
        for (var i = 0; i < root.activeRemarkFilters.length; i++) {
            var f = root.activeRemarkFilters[i].replace(/\n/g, " ").toLowerCase()
            if (remark.toLowerCase().includes(f)) return true
        }
        return false
    }

    function resetFilters() {
        root.fromDate            = ""
        root.toDate              = ""
        root.selectedUser        = "All"
        root.searchText          = ""
        root.activeRemarkFilters = []
    }

    Rectangle {
        anchors.fill: parent
        color: "#F5F7FC"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24 * root.scale
            spacing: 16 * root.scale

            // ===== HEADER =====
            Column {
                spacing: 6 * root.scale

                Text {
                    text: "Audit Trail Report"
                    font.pixelSize: 26 * root.scale
                    font.bold: true
                    color: "#1A4DB5"
                }

                Rectangle {
                    width: 80 * root.scale
                    height: 4 * root.scale
                    radius: 2 * root.scale
                    color: "#1A4DB5"
                }
            }

            // ===== FILTER BAR =====
            Rectangle {
                Layout.fillWidth: true
                height: 56 * root.scale
                color: "#FFFFFF"
                radius: 10 * root.scale
                border.color: "#D0D8EC"
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10 * root.scale
                    spacing: 10 * root.scale

                    // FROM DATE
                    Rectangle {
                        width: 150 * root.scale
                        height: 36 * root.scale
                        radius: 6 * root.scale
                        color: "#F0F4FF"
                        border.color: "#B0BEE0"
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 6 * root.scale
                            spacing: 4 * root.scale

                            Text {
                                text: root.fromDate !== "" ? root.fromDate : "From Date"
                                font.pixelSize: 18 * root.scale
                                color: root.fromDate !== "" ? "#1A1A1A" : "#8896B0"
                                Layout.fillWidth: true
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                datePickerPopup.isFrom = true
                                root.pickerDate = new Date()
                                calendar.displayMonth = root.pickerDate.getMonth()
                                calendar.displayYear  = root.pickerDate.getFullYear()
                                datePickerPopup.open()
                            }
                        }
                    }

                    Text { text: "→"; color: "#8896B0"; font.pixelSize: 18 * root.scale }

                    // TO DATE
                    Rectangle {
                        width: 150 * root.scale
                        height: 36 * root.scale
                        radius: 6 * root.scale
                        color: "#F0F4FF"
                        border.color: "#B0BEE0"
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 6 * root.scale
                            spacing: 4 * root.scale

                            Text {
                                text: root.toDate !== "" ? root.toDate : "To Date"
                                font.pixelSize: 18 * root.scale
                                color: root.toDate !== "" ? "#1A1A1A" : "#8896B0"
                                Layout.fillWidth: true
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                datePickerPopup.isFrom = false
                                root.pickerDate = new Date()
                                calendar.displayMonth = root.pickerDate.getMonth()
                                calendar.displayYear  = root.pickerDate.getFullYear()
                                datePickerPopup.open()
                            }
                        }
                    }

                    // USER FILTER
                    ComboBox {
                        Layout.preferredWidth: 110 * root.scale
                        Layout.minimumWidth: 110 * root.scale
                        Layout.maximumWidth: 110 * root.scale

                        height: 36 * root.scale

                        model: ["All", "Admin","Supervisor","Operator"]
                        font.pixelSize: 18 * root.scale

                        onCurrentTextChanged: root.selectedUser = currentText

                        background: Rectangle {
                            color: "#F0F4FF"
                            border.color: "#B0BEE0"
                            border.width: 1
                            radius: 6 * root.scale
                        }

                        contentItem: Text {
                            leftPadding: 8 * root.scale
                            text: parent.displayText
                            font.pixelSize: 18 * root.scale
                            color: "#1A1A1A"
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    // FILTER BUTTON
                    Rectangle {
                        width: 150 * root.scale
                        height: 36 * root.scale
                        radius: 6 * root.scale
                        color: root.activeRemarkFilters.length > 0 ? "#1A4DB5" : "#F0F4FF"
                        border.color: "#1A4DB5"
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 6 * root.scale
                            spacing: 4 * root.scale

                            Text {
                                text: root.activeRemarkFilters.length > 0
                                      ? "Filters (" + root.activeRemarkFilters.length + ")"
                                      : "Filters"
                                font.pixelSize: 18 * root.scale
                                color: root.activeRemarkFilters.length > 0 ? "#FFFFFF" : "#1A1A1A"
                                Layout.fillWidth: true
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: filterPopup.open()
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // ACTION BUTTONS
                    Repeater {
                        model: ["TODAY", "PDF"]

                        delegate: Rectangle {
                            width: 72 * root.scale
                            height: 36 * root.scale
                            radius: 6 * root.scale
                            color: modelData === "TODAY" ? "#1A4DB5" : "#FFFFFF"
                            border.color: "#1A4DB5"
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                font.pixelSize: 18 * root.scale
                                font.weight: Font.Medium
                                color: modelData === "TODAY" ? "#FFFFFF" : "#1A4DB5"
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor

                                onClicked: {
                                    if (modelData === "TODAY") {
                                        let today = Qt.formatDate(new Date(), "dd/MM/yyyy")
                                        root.fromDate = today
                                        root.toDate   = today
                                    }

                                    if (modelData === "PDF") {

                                        var filtered = []

                                        for (var i = 0; i < tableList.model.count; i++) {

                                            var item = tableList.model.get(i)

                                            var userOk   = root.selectedUser === "All" || item.user === root.selectedUser
                                            var searchOk = item.remark.toLowerCase().includes(root.searchText.toLowerCase())
                                            var dateOk   = root.dateInRange(item.date)
                                            var remarkOk = root.remarkInFilter(item.remark)

                                            if (userOk && searchOk && dateOk && remarkOk) {

                                                filtered.push({
                                                    sr: item.sr,
                                                    date: item.date,
                                                    time: item.time,
                                                    user: item.user,
                                                    old: item.old,
                                                    newVal: item.newVal,
                                                    remark: item.remark
                                                })
                                            }
                                        }

                                        if (filtered.length === 0) {
                                            console.log("No data to export")
                                            return
                                        }

                                        // 🔥 THIS IS WHERE YOUR CODE GOES
                                        var tempPath = PdfExporter.exportTempPreviewPdf(
                                            filtered,
                                            root.fromDate,
                                            root.toDate
                                        )

                                        if (tempPath === "") {
                                            console.log("Failed to create temp PDF")
                                            return
                                        }

                                        pdfPreview.filePath = tempPath
                                        pdfPreview.dataModel.clear()

                                        for (var i = 0; i < filtered.length; i++) {
                                            pdfPreview.dataModel.append(filtered[i])
                                        }

                                        pdfPreview.open()
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ===== TABLE =====
            Rectangle {
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
                        height: 44 * root.scale
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

                            Text { text: "Sr";   width: root.colSr;   font.bold: true; color: "#FFF"; font.pixelSize: 20 * root.scale }
                            Text { text: "Date"; width: root.colDate; font.bold: true; color: "#FFF"; font.pixelSize: 20 * root.scale }
                            Text { text: "Time"; width: root.colTime; font.bold: true; color: "#FFF"; font.pixelSize: 20 * root.scale }
                            Text { text: "User"; width: root.colUser; font.bold: true; color: "#FFF"; font.pixelSize: 20 * root.scale }
                            Text { text: "Old";  width: root.colOld;  font.bold: true; color: "#FFF"; font.pixelSize: 20 * root.scale }
                            Text { text: "New";  width: root.colNew;  font.bold: true; color: "#FFF"; font.pixelSize: 20 * root.scale }

                            // remaining space
                            Text {
                                text: "Remark"
                                width: parent.width
                                       - (root.colSr + root.colDate + root.colTime + root.colUser + root.colOld + root.colNew)
                                       - (root.colSpacing * 6)
                                font.bold: true
                                color: "#FFF"
                                font.pixelSize: 20 * root.scale
                            }
                        }
                    }

                    // TABLE ROWS
                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        id: tableList

                        model: ListModel {
                            ListElement { sr: "1";  date: "1/04/2026"; time: "02:22:06"; user: "Supervisor";  old: "----"; newVal: "----";  remark: "M/c Switch ON" }
                            ListElement { sr: "2";  date: "10/04/2026"; time: "02:22:10"; user: "Operator";  old: "----"; newVal: "01-001"; remark: "Last Active Product Loaded" }
                            ListElement { sr: "3";  date: "11/03/2026"; time: "13:27:16"; user: "Admin"; old: "----"; newVal: "----";  remark: "Logged-in" }
                            ListElement { sr: "4";  date: "11/04/2026"; time: "14:10:05"; user: "Admin"; old: "OFF";  newVal: "ON";    remark: "Setting Changed" }
                            ListElement { sr: "5";  date: "11/04/2026"; time: "15:45:30"; user: "Operator";  old: "----"; newVal: "----";  remark: "Logged-in" }
                            ListElement { sr: "6";  date: "10/04/2026"; time: "02:22:06"; user: "Supervisor";  old: "----"; newVal: "----";  remark: "M/c Switch ON" }
                            ListElement { sr: "7";  date: "10/04/2026"; time: "02:22:10"; user: "Operator";  old: "----"; newVal: "01-001"; remark: "Last Active Product Loaded" }
                            ListElement { sr: "8";  date: "10/04/2026"; time: "13:27:16"; user: "Admin"; old: "----"; newVal: "----";  remark: "Logged-in" }
                            ListElement { sr: "9";  date: "10/04/2026"; time: "14:10:05"; user: "Admin"; old: "OFF";  newVal: "ON";    remark: "Setting Changed" }
                            ListElement { sr: "10"; date: "10/04/2026"; time: "15:45:30"; user: "Supervisor";  old: "----"; newVal: "----";  remark: "Logged-in" }
                            ListElement { sr: "11";  date: "14/04/2026"; time: "02:22:06"; user: "Operator";  old: "----"; newVal: "----";  remark: "M/c Switch ON" }
                            ListElement { sr: "12";  date: "14/04/2026"; time: "02:22:10"; user: "Operator";  old: "----"; newVal: "01-001"; remark: "Last Active Product Loaded" }
                            ListElement { sr: "13";  date: "20/04/2026"; time: "13:27:16"; user: "Supervisor"; old: "----"; newVal: "----";  remark: "Logged-in" }
                            ListElement { sr: "14";  date: "21/04/2026"; time: "14:10:05"; user: "Supervisor"; old: "OFF";  newVal: "ON";    remark: "Setting Changed" }
                            ListElement { sr: "15"; date: "13/04/2026"; time: "15:45:30"; user: "Supervisor";  old: "----"; newVal: "----";  remark: "Logged-in" }
                        }

                        delegate: Rectangle {
                            property bool userMatch:   root.selectedUser === "All" || user === root.selectedUser
                            property bool searchMatch: remark.toLowerCase().includes(root.searchText.toLowerCase())
                            property bool dateMatch:   root.dateInRange(date)
                            property bool remarkMatch: root.remarkInFilter(remark)

                            visible: userMatch && searchMatch && dateMatch && remarkMatch
                            width: ListView.view.width
                            height: visible ? 42 * root.scale : 0
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
                                anchors.margins: 12 * root.scale
                                spacing: root.colSpacing   // 👈 MUST MATCH HEADER

                                Text { text: sr;   width: root.colSr;   font.pixelSize: 18 * root.scale; color: "#3A3A3A" }
                                Text { text: date; width: root.colDate; font.pixelSize: 18 * root.scale; color: "#3A3A3A" }
                                Text { text: time; width: root.colTime; font.pixelSize: 18 * root.scale; color: "#3A3A3A" }

                                Rectangle {
                                    width: root.colUser
                                    height: 24 * root.scale
                                    radius: 4 * root.scale

                                    color: user === "Admin" ? "#E8EEFF"
                                          : user === "Operator" ? "#E8F5E9"
                                          : user === "Supervisor" ? "#FFF4E5"
                                          : "transparent"

                                    Text {
                                        anchors.centerIn: parent
                                        text: user
                                        font.pixelSize: 18 * root.scale
                                        font.weight: Font.Medium
                                        color: user === "Admin" ? "#1A4DB5"
                                              : user === "Operator" ? "#2E7D32"
                                              : user === "Supervisor" ? "#E65100"
                                              : "#888888"
                                    }
                                }



                                Text { text: old;    width: root.colOld; font.pixelSize: 18 * root.scale; color: "#888888" }
                                Text { text: newVal; width: root.colNew; font.pixelSize: 18 * root.scale; color: "#1A4DB5"; font.weight: Font.Medium }

                                Text {
                                    text: remark
                                    width: parent.width
                                           - (root.colSr + root.colDate + root.colTime + root.colUser + root.colOld + root.colNew)
                                           - (root.colSpacing * 6)
                                    font.pixelSize: 18 * root.scale
                                    color: "#3A3A3A"
                                }
                            }
                        }

                        // ===== NO DATA OVERLAY =====
                        Item {
                            anchors.fill: parent
                            visible: root.visibleCount === 0

                            Column {
                                anchors.centerIn: parent
                                spacing: 16 * root.scale

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "No data found"
                                    font.pixelSize: 24 * root.scale
                                    font.weight: Font.Medium
                                    color: "#8896B0"
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "No records match the selected filters"
                                    font.pixelSize: 20 * root.scale
                                    color: "#B0BEE0"
                                }

                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 160 * root.scale
                                    height: 48 * root.scale
                                    radius: 12 * root.scale
                                    color: "#1A4DB5"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Reset Filters"
                                        font.pixelSize: 18 * root.scale
                                        font.weight: Font.Medium
                                        color: "#FFFFFF"
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.resetFilters()
                                            searchInput.text = ""
                                            filterRepeater.resetAll()
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

    // ===== DATE PICKER POPUP =====
    Popup {
        id: datePickerPopup
        modal: true
        focus: true
        anchors.centerIn: parent
        width: 460 * root.scale
        height: 420 * root.scale
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        property bool isFrom: true

        background: Rectangle {
            color: "#FFFFFF"
            border.color: "#D0D8EC"
            border.width: 1.5
            radius: 14 * root.scale
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14 * root.scale
            spacing: 10 * root.scale

            Column {
                spacing: 4 * root.scale
                Layout.alignment: Qt.AlignHCenter

                Text {
                    text: datePickerPopup.isFrom ? "Select From Date" : "Select To Date"
                    font.pixelSize: 20 * root.scale
                    font.bold: true
                    color: "#1A4DB5"
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Rectangle {
                    width: 60 * root.scale
                    height: 3 * root.scale
                    radius: 2
                    color: "#1A4DB5"
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 14 * root.scale
                color: "#FFFFFF"
                border.color: "#E3E7F0"
                border.width: 1.5

                Column {
                    id: calendar
                    anchors.fill: parent
                    anchors.margins: 14 * root.scale
                    spacing: 10 * root.scale

                    property int displayMonth: new Date().getMonth()
                    property int displayYear:  new Date().getFullYear()

                    Row {
                        width: parent.width
                        height: 38 * root.scale

                        Rectangle {
                            width: 36 * root.scale
                            height: parent.height
                            radius: 8 * root.scale

                            color: prevMouse.enabled
                                   ? (prevMouse.pressed ? "#D0D8EE" : "#E8ECF3")
                                   : "#F0F2F7"

                            Text {
                                anchors.centerIn: parent
                                text: "<"
                                color: prevMouse.enabled ? "#1A4DB5" : "#AAB3C5"
                                font.bold: true
                                font.pixelSize: 22 * root.scale
                            }

                            MouseArea {
                                id: prevMouse
                                anchors.fill: parent

                                property bool isMinReached: (
                                                                datePickerPopup.isFrom &&
                                                                calendar.displayYear === 2026 &&
                                                                calendar.displayMonth === 0
                                                                )

                                enabled: !isMinReached

                                onClicked: {
                                    if (calendar.displayMonth === 0) {
                                        calendar.displayMonth = 11
                                        calendar.displayYear--
                                    } else {
                                        calendar.displayMonth--
                                    }
                                }
                            }
                        }

                        Item {
                            width: parent.width - 72 * root.scale
                            height: parent.height

                            Text {
                                anchors.centerIn: parent
                                text: Qt.formatDate(new Date(calendar.displayYear, calendar.displayMonth, 1), "MMMM yyyy")
                                font.bold: true
                                font.pixelSize: 20 * root.scale
                                color: "#1A4DB5"
                            }
                        }

                        Rectangle {
                            width: 36 * root.scale
                            height: parent.height
                            radius: 8 * root.scale
                            color: nextMouse.pressed ? "#D0D8EE" : "#E8ECF3"

                            Text {
                                anchors.centerIn: parent
                                text: ">"
                                color: "#1A4DB5"
                                font.bold: true
                                font.pixelSize: 22 * root.scale
                            }

                            MouseArea {
                                id: nextMouse
                                anchors.fill: parent
                                onClicked: {
                                    if (calendar.displayMonth === 11) {
                                        calendar.displayMonth = 0
                                        calendar.displayYear++
                                    } else {
                                        calendar.displayMonth++
                                    }
                                }
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        height: 24 * root.scale

                        Repeater {
                            model: ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]

                            delegate: Item {
                                width: parent.width / 7
                                height: parent.height

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData
                                    font.bold: true
                                    font.pixelSize: 18 * root.scale
                                    color: "#1A4DB5"
                                }
                            }
                        }
                    }

                    Grid {
                        id: dayGrid
                        width: parent.width
                        columns: 7

                        property int totalCells: 42
                        property int firstDay:   root.firstDayOfMonth(calendar.displayMonth, calendar.displayYear)
                        property int daysCount:  root.daysInMonth(calendar.displayMonth, calendar.displayYear)
                        property real cellW: width / 7
                        property real cellH: (parent.height - 38 * root.scale - 24 * root.scale - 20 * root.scale) / 6

                        Repeater {
                            model: dayGrid.totalCells

                            delegate: Rectangle {
                                width:  dayGrid.cellW
                                height: dayGrid.cellH
                                radius: 8 * root.scale

                                property int  dayNum:   index - dayGrid.firstDay + 1
                                property bool validDay: dayNum >= 1 && dayNum <= dayGrid.daysCount

                                // ===== LIMITS =====
                                property date currentDate: new Date(calendar.displayYear, calendar.displayMonth, dayNum)
                                property date minDate: new Date(2026, 0, 1)
                                property date today: new Date()

                                property bool isBeforeMin: currentDate < minDate
                                property bool isAfterToday: currentDate > today

                                property bool isDisabled: {
                                    if (!validDay) return true
                                    if (datePickerPopup.isFrom)
                                        return isBeforeMin
                                    else
                                        return isAfterToday
                                }

                                property bool isSelected:
                                    validDay &&
                                    !isDisabled &&
                                    dayNum                === root.pickerDate.getDate() &&
                                    calendar.displayMonth === root.pickerDate.getMonth() &&
                                    calendar.displayYear  === root.pickerDate.getFullYear()

                                property bool isToday: {
                                    var t = new Date()
                                    return validDay &&
                                            dayNum                === t.getDate() &&
                                            calendar.displayMonth === t.getMonth() &&
                                            calendar.displayYear  === t.getFullYear()
                                }

                                color: isSelected ? "#1A4DB5"
                                                  : cellMouse.containsMouse && !isDisabled ? "#E8EEFB"
                                                                                           : "transparent"

                                border.width: isToday && !isSelected ? 2 : 0
                                border.color: "#1A4DB5"

                                opacity: isDisabled ? 0.3 : 1.0

                                Text {
                                    anchors.centerIn: parent
                                    text: validDay ? dayNum : ""
                                    font.pixelSize: 18 * root.scale
                                    font.bold: isSelected || isToday
                                    color: isSelected ? "#FFFFFF" : "#333333"
                                }

                                MouseArea {
                                    id: cellMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    enabled: validDay && !isDisabled

                                    onClicked: {
                                        root.pickerDate = currentDate
                                    }
                                }
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10 * root.scale

                Rectangle {
                    Layout.fillWidth: true
                    height: 38 * root.scale
                    radius: 6 * root.scale
                    color: "#FFFFFF"
                    border.color: "#1A4DB5"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        font.pixelSize: 18 * root.scale
                        color: "#1A4DB5"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: datePickerPopup.close()
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 38 * root.scale
                    radius: 6 * root.scale
                    color: "#1A4DB5"

                    Text {
                        anchors.centerIn: parent
                        text: "OK"
                        font.pixelSize: 18 * root.scale
                        color: "#FFFFFF"
                        font.weight: Font.Medium
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            let formatted = Qt.formatDate(root.pickerDate, "dd/MM/yyyy")
                            if (datePickerPopup.isFrom)
                                root.fromDate = formatted
                            else
                                root.toDate = formatted
                            datePickerPopup.close()
                        }
                    }
                }
            }
        }
    }

    // ===== FILTER POPUP =====
    Popup {
        id: filterPopup
        modal: true
        focus: true
        anchors.centerIn: parent
        width: 720 * root.scale
        height: 420 * root.scale
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        // Temporary checked state storage (committed only on OK)
        property var pendingChecked: []

        onOpened: {
            // Sync pending state from activeRemarkFilters
            var list = grid.filterList
            var pending = []
            for (var i = 0; i < list.length; i++) {
                var label = list[i].replace(/\n/g, " ").toLowerCase()
                var found = false
                for (var j = 0; j < root.activeRemarkFilters.length; j++) {
                    if (root.activeRemarkFilters[j].replace(/\n/g, " ").toLowerCase() === label) {
                        found = true
                        break
                    }
                }
                pending.push(found)
            }
            filterPopup.pendingChecked = pending
        }

        background: Rectangle {
            color: "#FFFFFF"
            border.color: "#D0D8EC"
            border.width: 1.5
            radius: 14 * root.scale
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16 * root.scale
            spacing: 12 * root.scale

            // ===== TITLE =====
            Column {
                Layout.alignment: Qt.AlignHCenter
                spacing: 4 * root.scale

                Text {
                    text: "Filters"
                    font.pixelSize: 22 * root.scale
                    font.bold: true
                    color: "#1A4DB5"
                }

                Rectangle {
                    width: 60 * root.scale
                    height: 3 * root.scale
                    radius: 2
                    color: "#1A4DB5"
                }
            }

            // ===== CHECKLIST GRID =====
            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentHeight: grid.height
                clip: true

                Grid {
                    id: grid
                    width: parent.width
                    columns: 3

                    rowSpacing: 14 * root.scale
                    columnSpacing: 28 * root.scale

                    property real cellWidth: (width / columns) - columnSpacing

                    property var filterList: [
                        "M/C Switch ON","M/C Switched OFF","RC/Total RC","User Added",
                        "User PW Changed","User Deleted","Loged-in_FP","Loged-in",
                        "Loged-out","THR-S Changed",

                        "Customer Name\nChanged","Customer Location\nChanged","Machine-ID\nChanged",
                        "THR-A Changed","MPHS Changed","Product Loaded",
                        "Product Added","Product Deleted","DD Power\nChanged","DD Frequency\nChanged",

                        "Auto Val-1\nEnabled","Auto Val-1\nDisable","Auto Val-2\nEnabled","Auto Val-2 Disable",
                        "Auto Val-3\nEnabled","Auto Val-3\nDisable","Auto Val-4 Enabled","Auto Val-4\nDisable",
                        "Last Active\nProduct Loaded",

                        "Auto Val-1\nTime Change","Auto Val-2\nTime Change",
                        "Auto Val-3\nTime Change","Auto Val-4\nTime Change"
                    ]

                    Repeater {
                        id: filterRepeater
                        model: grid.filterList

                        function resetAll() {
                            var blank = []
                            for (var i = 0; i < grid.filterList.length; i++) blank.push(false)
                            filterPopup.pendingChecked = blank
                        }

                        delegate: Rectangle {
                            id: filterItem
                            width: grid.cellWidth
                            color: "transparent"
                            implicitHeight: Math.max(labelText.implicitHeight + 12 * root.scale, 48 * root.scale)

                            property bool isChecked: filterPopup.pendingChecked.length > index
                                                     ? filterPopup.pendingChecked[index]
                                                     : false

                            Row {
                                anchors.fill: parent
                                anchors.margins: 6 * root.scale
                                spacing: 12 * root.scale

                                // Custom checkbox rectangle
                                Rectangle {
                                    id: checkRect
                                    width: 22 * root.scale
                                    height: 22 * root.scale
                                    radius: 4 * root.scale
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: filterItem.isChecked ? "#1A4DB5" : "#FFFFFF"
                                    border.color: filterItem.isChecked ? "#1A4DB5" : "#B0BEE0"
                                    border.width: 1.5

                                    Text {
                                        anchors.centerIn: parent
                                        text: "✓"
                                        color: "#FFFFFF"
                                        font.pixelSize: 15 * root.scale
                                        font.bold: true
                                        visible: filterItem.isChecked
                                    }
                                }

                                Text {
                                    id: labelText
                                    text: modelData
                                    font.pixelSize: 20 * root.scale
                                    color: "#2E2E2E"
                                    wrapMode: Text.WordWrap
                                    width: parent.width - (40 * root.scale)
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    var arr = filterPopup.pendingChecked.slice()
                                    while (arr.length <= index) arr.push(false)
                                    arr[index] = !arr[index]
                                    filterPopup.pendingChecked = arr
                                }
                            }
                        }
                    }
                }
            }

            // ===== BUTTONS =====
            RowLayout {
                Layout.fillWidth: true
                spacing: 10 * root.scale

                // RESET
                Rectangle {
                    Layout.fillWidth: true
                    height: 42 * root.scale
                    radius: 6 * root.scale
                    color: "#FFFFFF"
                    border.color: "#1A4DB5"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Reset"
                        font.pixelSize: 18 * root.scale
                        color: "#1A4DB5"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: filterRepeater.resetAll()
                    }
                }

                // OK — commits pending checkboxes to activeRemarkFilters
                Rectangle {
                    Layout.fillWidth: true
                    height: 42 * root.scale
                    radius: 6 * root.scale
                    color: "#1A4DB5"

                    Text {
                        anchors.centerIn: parent
                        text: "OK"
                        font.pixelSize: 18 * root.scale
                        color: "#FFFFFF"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var selected = []
                            var list = grid.filterList
                            for (var i = 0; i < list.length; i++) {
                                if (filterPopup.pendingChecked.length > i && filterPopup.pendingChecked[i]) {
                                    selected.push(list[i])
                                }
                            }
                            root.activeRemarkFilters = selected
                            filterPopup.close()
                        }
                    }
                }
            }
        }
    }

    PdfPreview {
        id: pdfPreview
        anchors.centerIn: parent
        width: parent.width * 0.9
        height: parent.height * 0.9
    }
}
