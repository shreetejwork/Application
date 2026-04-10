import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import AppState 1.0

Item {
    id: root
    anchors.fill: parent

    // ===== RESPONSIVE SCALE =====
    property real baseWidth: 1024
    property real baseHeight: 600
    property real scale: Math.max(0.85, Math.min(width / baseWidth, height / baseHeight))

    // Local editable date
    property date selectedDate: GlobalState.globalDateTime

    Rectangle {
        anchors.fill: parent
        color: "#F5F7FC"
    }

    // ===== TITLE =====
    Text {
        id: titleText
        text: "Time & Date Settings"
        font.pixelSize: 26 * root.scale
        font.bold: true
        color: "#1A4DB5"
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: 10 * root.scale
        anchors.topMargin: 5 * root.scale
    }

    Rectangle {
        width: 80 * root.scale
        height: 4 * root.scale
        radius: 2 * root.scale
        color: "#1A4DB5"
        anchors.left: titleText.left
        anchors.top: titleText.bottom
        anchors.topMargin: 6 * root.scale
    }

    // ===== MAIN CONTENT ROW =====
    Row {
        anchors.top: titleText.bottom
        anchors.topMargin: 40 * root.scale
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 100 * root.scale

        // ===== LEFT PANEL: Hour + Minutes + Set =====
        Column {
            spacing: 20 * root.scale
            anchors.verticalCenter: parent.verticalCenter

            Column {
                spacing: 24 * root.scale

                // ===== COMMON STYLE =====
                Component {
                    id: tumblerDelegate

                    Text {
                        text: modelData < 10 ? "0" + modelData : modelData

                        font.pixelSize: 24 * root.scale
                        font.bold: Tumbler.displacement === 0

                        opacity: 1.0 - Math.abs(Tumbler.displacement) * 0.6
                        scale: 1.0 - Math.abs(Tumbler.displacement) * 0.2

                        color: Tumbler.displacement === 0 ? "#1A4DB5" : "#7A8499"

                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        width: parent.width
                    }
                }

                // ===== HOURS =====
                Rectangle {
                    width: 180 * root.scale
                    height: 180 * root.scale
                    radius: 14 * root.scale
                    color: "#FFFFFF"
                    border.color: "#E3E7F0"
                    border.width: 1.5

                    Column {
                        anchors.fill: parent
                        anchors.margins: 10 * root.scale
                        spacing: 6 * root.scale

                        Text {
                            text: "Hours"
                            font.pixelSize: 20 * root.scale
                            font.bold: true
                            color: "#5A6A85"
                            horizontalAlignment: Text.AlignHCenter
                            width: parent.width
                        }

                        Item {
                            width: parent.width
                            height: parent.height - 30 * root.scale

                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width
                                height: 36 * root.scale
                                radius: 8 * root.scale
                                color: "#E8EEFB"
                            }

                            Tumbler {
                                id: hourTumbler
                                anchors.fill: parent
                                model: 24

                                visibleItemCount: 3
                                wrap: true

                                currentIndex: root.selectedDate.getHours()

                                delegate: tumblerDelegate

                                onCurrentIndexChanged: {
                                    var d = new Date(root.selectedDate)
                                    d.setHours(currentIndex)
                                    root.selectedDate = d
                                }
                            }
                        }
                    }
                }

                // ===== MINUTES =====
                Rectangle {
                    width: 180 * root.scale
                    height: 180 * root.scale
                    radius: 14 * root.scale
                    color: "#FFFFFF"
                    border.color: "#E3E7F0"
                    border.width: 1.5

                    Column {
                        anchors.fill: parent
                        anchors.margins: 10 * root.scale
                        spacing: 6 * root.scale

                        Text {
                            text: "Minutes"
                            font.pixelSize: 20 * root.scale
                            font.bold: true
                            color: "#5A6A85"
                            horizontalAlignment: Text.AlignHCenter
                            width: parent.width
                        }

                        Item {
                            width: parent.width
                            height: parent.height - 30 * root.scale

                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width
                                height: 36 * root.scale
                                radius: 8 * root.scale
                                color: "#E8EEFB"
                            }

                            Tumbler {
                                id: minuteTumbler
                                anchors.fill: parent
                                model: 60

                                visibleItemCount: 3
                                wrap: true

                                currentIndex: root.selectedDate.getMinutes()

                                delegate: tumblerDelegate

                                onCurrentIndexChanged: {
                                    var d = new Date(root.selectedDate)
                                    d.setMinutes(currentIndex)
                                    root.selectedDate = d
                                }
                            }
                        }
                    }
                }
            }

            // Set button (left panel)
            Rectangle {
                width: 160 * root.scale
                height: 48 * root.scale
                radius: 10 * root.scale
                color: leftSetMouse.pressed ? "#0D3BA8" : "#1A4DB5"

                Text {
                    anchors.centerIn: parent
                    text: "Save"
                    color: "#FFFFFF"
                    font.bold: true
                    font.pixelSize: 26 * root.scale
                }

                MouseArea {
                    id: leftSetMouse
                    anchors.fill: parent

                    onClicked: {
                        var d = new Date(root.selectedDate)
                        d.setSeconds(0)
                        d.setMilliseconds(0)

                        GlobalState.globalDateTime = d

                        console.log("Updated Global Date:", GlobalState.globalDateTime)
                    }
                }
            }
        }

        // ===== RIGHT PANEL: Calendar + Set below =====
        Column {
            spacing: 20 * root.scale
            anchors.verticalCenter: parent.verticalCenter

            // Calendar
            Rectangle {
                width: 460 * root.scale
                height: 380 * root.scale
                radius: 14 * root.scale
                color: "#FFFFFF"
                border.color: "#E3E7F0"
                border.width: 1.5

                Column {
                    id: calendar
                    anchors.fill: parent
                    anchors.margins: 14 * root.scale
                    spacing: 16 * root.scale
                    width: parent.width

                    property int displayMonth: root.selectedDate.getMonth()
                    property int displayYear:  root.selectedDate.getFullYear()

                    // HEADER
                    Row {
                        width: parent.width
                        height: 42 * root.scale

                        // Prev button
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
                                font.pixelSize: 26 * root.scale
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

                        // Month + Year label — centered
                        Item {
                            width: parent.width - 72 * root.scale
                            height: parent.height

                            Text {
                                anchors.centerIn: parent
                                text: Qt.formatDate(new Date(calendar.displayYear, calendar.displayMonth, 1), "MMMM yyyy")
                                font.bold: true
                                font.pixelSize: 24 * root.scale
                                color: "#1A4DB5"
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    monthYearPopup.mode = "year"
                                    monthYearPopup.open()
                                }
                            }
                        }

                        // Next button
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
                                font.pixelSize: 26 * root.scale
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
                        height: 28 * root.scale

                        Repeater {
                            model: ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]

                            delegate: Item {
                                width: parent.width / 7
                                height: parent.height

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData
                                    font.bold: true
                                    font.pixelSize: 22 * root.scale
                                    color: "#1A4DB5"
                                }
                            }
                        }
                    }

                    // GRID
                    MonthGrid {
                        width: parent.width
                        height: parent.height - 42 * root.scale - 28 * root.scale - 16 * root.scale

                        month: calendar.displayMonth
                        year:  calendar.displayYear

                        delegate: Rectangle {
                            width:  parent.width / 7
                            height: parent.height / 6
                            radius: 8 * root.scale


                            property bool isSelected:
                                model.date.getDate()     === root.selectedDate.getDate()   &&
                                model.date.getMonth()    === root.selectedDate.getMonth()  &&
                                model.date.getFullYear() === root.selectedDate.getFullYear()


                            property bool isToday: {
                                var today = new Date()
                                return model.date.getDate()     === today.getDate() &&
                                        model.date.getMonth()    === today.getMonth() &&
                                        model.date.getFullYear() === today.getFullYear()
                            }


                            color: isSelected ? "#1A4DB5"
                                              : dayMouse.containsMouse ? "#E8EEFB"
                                                                       : "transparent"


                            border.width: isToday ? 2 : 0
                            border.color: "#1A4DB5"

                            Text {
                                anchors.centerIn: parent
                                text: model.day
                                font.pixelSize: 22 * root.scale
                                font.bold: isSelected || isToday

                                color: isSelected ? "#FFFFFF"
                                                  : model.month === calendar.displayMonth ? "#333333"
                                                                                          : "#C0C6D4"
                            }

                            MouseArea {
                                id: dayMouse
                                anchors.fill: parent
                                hoverEnabled: true

                                onClicked: {
                                    var clickedDate = model.date

                                    var d = new Date(root.selectedDate)
                                    d.setFullYear(clickedDate.getFullYear())
                                    d.setMonth(clickedDate.getMonth())
                                    d.setDate(clickedDate.getDate())
                                    root.selectedDate = d


                                    calendar.displayMonth = clickedDate.getMonth()
                                    calendar.displayYear  = clickedDate.getFullYear()
                                }
                            }
                        }
                    }
                }
            }

            // ===== BUTTON ROW =====
            Item {
                width: parent.width
                height: 48 * root.scale

                Rectangle {
                    width: 160 * root.scale
                    height: parent.height
                    radius: 10 * root.scale
                    anchors.right: parent.right
                    anchors.rightMargin: 0

                    color: calSetMouse.pressed ? "#0D3BA8" : "#1A4DB5"

                    Text {
                        anchors.centerIn: parent
                        text: "Save"
                        color: "#FFFFFF"
                        font.bold: true
                        font.pixelSize: 26 * root.scale
                    }

                    MouseArea {
                        id: calSetMouse
                        anchors.fill: parent
                        onClicked: {
                            var d = new Date(root.selectedDate)
                            d.setSeconds(0)
                            d.setMilliseconds(0)

                            GlobalState.globalDateTime = d
                            console.log("Updated Global Date:", GlobalState.globalDateTime)
                        }
                    }
                }
            }
        }
    }

    Popup {
        id: monthYearPopup
        modal: true
        focus: true

        property string mode: "year"
        property int startYear: calendar.displayYear - (calendar.displayYear % 12)

        // fixed known dimensions
        width:  420 * root.scale
        height: 420 * root.scale
        anchors.centerIn: parent

        padding: 0
        margins: 0

        background: Rectangle {
            color: "#FFFFFF"
            radius: 14 * root.scale
            border.color: "#E3E7F0"
            border.width: 1.5
        }

        Item {
            anchors.fill: parent
            anchors.margins: 20 * root.scale

            // inner usable width & height
            property real innerW: monthYearPopup.width  - 40 * root.scale
            property real innerH: monthYearPopup.height - 40 * root.scale

            // header is 44px tall, gap between header and grid is 16px
            // grid gets the rest: innerH - 44 - 16
            property real gridH: innerH - 44 * root.scale - 16 * root.scale

            // 3 cols, 4 rows, 10px gaps
            property real cellW: (innerW - 10 * root.scale * 2) / 3
            property real cellH: (gridH  - 10 * root.scale * 3) / 4

            // ===== HEADER =====
            Row {
                id: popupHeader
                width: parent.innerW
                height: 44 * root.scale

                Rectangle {
                    width: 44 * root.scale
                    height: parent.height
                    radius: 8 * root.scale
                    color: prevPopupMouse.pressed ? "#D0D8EE" : "#E8ECF3"

                    Text {
                        anchors.centerIn: parent
                        text: "<"
                        font.bold: true
                        font.pixelSize: 26 * root.scale
                        color: "#1A4DB5"
                    }

                    MouseArea {
                        id: prevPopupMouse
                        anchors.fill: parent
                        onClicked: {
                            if (monthYearPopup.mode === "year") {
                                monthYearPopup.startYear -= 12
                            } else {
                                monthYearPopup.mode = "year"
                            }
                        }
                    }
                }

                Item {
                    width: parent.width - 88 * root.scale
                    height: parent.height

                    Text {
                        anchors.centerIn: parent
                        text: monthYearPopup.mode === "year"
                              ? (monthYearPopup.startYear + " — " + (monthYearPopup.startYear + 11))
                              : calendar.displayYear
                        font.bold: true
                        font.pixelSize: 24 * root.scale
                        color: "#1A4DB5"
                    }
                }

                Rectangle {
                    width: 44 * root.scale
                    height: parent.height
                    radius: 8 * root.scale
                    color: nextPopupMouse.pressed ? "#D0D8EE" : "#E8ECF3"

                    Text {
                        anchors.centerIn: parent
                        text: ">"
                        font.bold: true
                        font.pixelSize: 26 * root.scale
                        color: "#1A4DB5"
                    }

                    MouseArea {
                        id: nextPopupMouse
                        anchors.fill: parent
                        onClicked: {
                            if (monthYearPopup.mode === "year") {
                                monthYearPopup.startYear += 12
                            }
                        }
                    }
                }
            }

            // ===== GRID =====
            Grid {
                columns: 3
                spacing: 10 * root.scale
                anchors.top: popupHeader.bottom
                anchors.topMargin: 16 * root.scale

                Repeater {
                    model: 12

                    delegate: Rectangle {
                        width:  parent.parent.cellW
                        height: parent.parent.cellH
                        radius: 10 * root.scale

                        property int yearValue: monthYearPopup.startYear + index

                        border.width: 1
                        border.color: "#E3E7F0"

                        Text {
                            anchors.centerIn: parent
                            text: monthYearPopup.mode === "year"
                                  ? yearValue
                                  : Qt.formatDate(new Date(2000, index, 1), "MMM")
                            font.bold: true
                            font.pixelSize: 22 * root.scale
                            color: parent.color === "#1A4DB5" ? "#FFFFFF" : "#333333"
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (monthYearPopup.mode === "year") {
                                    calendar.displayYear = yearValue
                                    monthYearPopup.mode = "month"
                                } else {
                                    calendar.displayMonth = index
                                    monthYearPopup.close()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
