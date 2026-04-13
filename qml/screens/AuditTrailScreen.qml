import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

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
    function resetFilters() {
        root.fromDate     = ""
        root.toDate       = ""
        root.selectedUser = "All"
        root.searchText   = ""
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

                            Text { text: "📅"; font.pixelSize: 18 * root.scale }
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

                            Text { text: "📅"; font.pixelSize: 18 * root.scale }
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
                        width: 110 * root.scale
                        height: 36 * root.scale
                        model: ["All", "ADMIN", "USER"]
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

                    // SEARCH
                    Rectangle {
                        width: 180 * root.scale
                        height: 36 * root.scale
                        radius: 6 * root.scale
                        color: "#F0F4FF"
                        border.color: "#B0BEE0"
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 6 * root.scale
                            spacing: 4 * root.scale

                            Text { text: "🔍"; font.pixelSize: 18 * root.scale }

                            TextInput {
                                Layout.fillWidth: true
                                font.pixelSize: 18 * root.scale
                                color: "#1A1A1A"
                                clip: true
                                onTextChanged: root.searchText = text

                                Text {
                                    anchors.fill: parent
                                    text: "Search remark..."
                                    font.pixelSize: 18 * root.scale
                                    color: "#8896B0"
                                    visible: parent.text === ""
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // ACTION BUTTONS
                    Repeater {
                        model: ["TODAY", "COPY", "PRINT", "PDF"]

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

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10 * root.scale

                            Text { text: "Sr";     Layout.preferredWidth: 40 * root.scale;  font.bold: true; color: "#FFFFFF"; font.pixelSize: 20 * root.scale }
                            Text { text: "Date";   Layout.preferredWidth: 110 * root.scale; font.bold: true; color: "#FFFFFF"; font.pixelSize: 20 * root.scale }
                            Text { text: "Time";   Layout.preferredWidth: 90 * root.scale;  font.bold: true; color: "#FFFFFF"; font.pixelSize: 20 * root.scale }
                            Text { text: "User";   Layout.preferredWidth: 90 * root.scale;  font.bold: true; color: "#FFFFFF"; font.pixelSize: 20 * root.scale }
                            Text { text: "Old";    Layout.preferredWidth: 110 * root.scale; font.bold: true; color: "#FFFFFF"; font.pixelSize: 20 * root.scale }
                            Text { text: "New";    Layout.preferredWidth: 110 * root.scale; font.bold: true; color: "#FFFFFF"; font.pixelSize: 20 * root.scale }
                            Text { text: "Remark"; Layout.fillWidth: true;                  font.bold: true; color: "#FFFFFF"; font.pixelSize: 20 * root.scale }
                        }
                    }

                    // TABLE ROWS
                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        id: tableList

                        model: ListModel {
                            ListElement { sr: "1";  date: "11/04/2026"; time: "02:22:06"; user: "----";  old: "----"; newVal: "----";  remark: "M/c Switch ON" }
                            ListElement { sr: "2";  date: "11/04/2026"; time: "02:22:10"; user: "----";  old: "----"; newVal: "01-001"; remark: "Last Active Product Loaded" }
                            ListElement { sr: "3";  date: "11/04/2026"; time: "13:27:16"; user: "ADMIN"; old: "----"; newVal: "----";  remark: "Logged-in" }
                            ListElement { sr: "4";  date: "11/04/2026"; time: "14:10:05"; user: "ADMIN"; old: "OFF";  newVal: "ON";    remark: "Setting Changed" }
                            ListElement { sr: "5";  date: "11/04/2026"; time: "15:45:30"; user: "USER";  old: "----"; newVal: "----";  remark: "Logged-in" }
                            ListElement { sr: "6";  date: "10/04/2026"; time: "02:22:06"; user: "----";  old: "----"; newVal: "----";  remark: "M/c Switch ON" }
                            ListElement { sr: "7";  date: "10/04/2026"; time: "02:22:10"; user: "----";  old: "----"; newVal: "01-001"; remark: "Last Active Product Loaded" }
                            ListElement { sr: "8";  date: "10/04/2026"; time: "13:27:16"; user: "ADMIN"; old: "----"; newVal: "----";  remark: "Logged-in" }
                            ListElement { sr: "9";  date: "10/04/2026"; time: "14:10:05"; user: "ADMIN"; old: "OFF";  newVal: "ON";    remark: "Setting Changed" }
                            ListElement { sr: "10"; date: "10/04/2026"; time: "15:45:30"; user: "USER";  old: "----"; newVal: "----";  remark: "Logged-in" }
                        }

                        delegate: Rectangle {
                            property bool userMatch:   root.selectedUser === "All" || user === root.selectedUser
                            property bool searchMatch: remark.toLowerCase().includes(root.searchText.toLowerCase())
                            property bool dateMatch:   root.dateInRange(date)

                            visible: userMatch && searchMatch && dateMatch
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

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10 * root.scale

                                Text { text: sr;     Layout.preferredWidth: 40 * root.scale;  font.pixelSize: 18 * root.scale; color: "#3A3A3A" }
                                Text { text: date;   Layout.preferredWidth: 110 * root.scale; font.pixelSize: 18 * root.scale; color: "#3A3A3A" }
                                Text { text: time;   Layout.preferredWidth: 90 * root.scale;  font.pixelSize: 18 * root.scale; color: "#3A3A3A" }

                                Rectangle {
                                    Layout.preferredWidth: 90 * root.scale
                                    height: 24 * root.scale
                                    radius: 4 * root.scale
                                    color: user === "ADMIN" ? "#E8EEFF" : user === "USER" ? "#E8F5E9" : "transparent"

                                    Text {
                                        anchors.centerIn: parent
                                        text: user
                                        font.pixelSize: 18 * root.scale
                                        font.weight: Font.Medium
                                        color: user === "ADMIN" ? "#1A4DB5" : user === "USER" ? "#2E7D32" : "#888888"
                                    }
                                }

                                Text { text: old;    Layout.preferredWidth: 110 * root.scale; font.pixelSize: 18 * root.scale; color: "#888888" }
                                Text { text: newVal; Layout.preferredWidth: 110 * root.scale; font.pixelSize: 18 * root.scale; color: "#1A4DB5"; font.weight: Font.Medium }
                                Text { text: remark; Layout.fillWidth: true;                  font.pixelSize: 18 * root.scale; color: "#3A3A3A" }
                            }
                        }

                        // ===== NO DATA OVERLAY =====
                        Item {
                            anchors.fill: parent
                            visible: {
                                var anyVisible = false
                                for (var i = 0; i < tableList.count; i++) {
                                    var item = tableList.itemAtIndex(i)
                                    if (item && item.visible) { anyVisible = true; break }
                                }
                                return !anyVisible
                            }

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
                                        onClicked: root.resetFilters()
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

            // Popup title
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

            // ===== CALENDAR =====
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

                    // HEADER
                    Row {
                        width: parent.width
                        height: 38 * root.scale

                        Rectangle {
                            width: 36 * root.scale
                            height: parent.height
                            radius: 8 * root.scale
                            color: prevMouse.pressed ? "#D0D8EE" : "#E8ECF3"

                            Text {
                                anchors.centerIn: parent
                                text: "<"
                                color: "#1A4DB5"
                                font.bold: true
                                font.pixelSize: 22 * root.scale
                            }

                            MouseArea {
                                id: prevMouse
                                anchors.fill: parent
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

                    // WEEKDAYS
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

                    // DAY GRID
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

                                property bool isSelected:
                                    validDay &&
                                    dayNum                === root.pickerDate.getDate()      &&
                                    calendar.displayMonth === root.pickerDate.getMonth()     &&
                                    calendar.displayYear  === root.pickerDate.getFullYear()

                                property bool isToday: {
                                    var t = new Date()
                                    return validDay &&
                                           dayNum                === t.getDate()   &&
                                           calendar.displayMonth === t.getMonth()  &&
                                           calendar.displayYear  === t.getFullYear()
                                }

                                color: isSelected                          ? "#1A4DB5"
                                     : cellMouse.containsMouse && validDay ? "#E8EEFB"
                                     : "transparent"

                                border.width: isToday && !isSelected ? 2 : 0
                                border.color: "#1A4DB5"

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
                                    enabled: validDay
                                    onClicked: {
                                        root.pickerDate = new Date(calendar.displayYear, calendar.displayMonth, dayNum)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // OK / Cancel
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
}
