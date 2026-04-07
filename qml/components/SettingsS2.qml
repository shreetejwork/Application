import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    anchors.fill: parent

    // ===== RESPONSIVE SCALE =====
    property real baseWidth: 1024
    property real baseHeight: 600
    property real scale: Math.min(width / baseWidth, height / baseHeight)

    property date selectedDate: new Date()

    Rectangle {
        anchors.fill: parent
        color: "#F5F7FC"
    }

    Column {
        anchors.centerIn: parent
        spacing: 20 * root.scale

        // ===== TITLE =====
        Text {
            text: "Pick Date and Time"
            font.pixelSize: 22 * root.scale
            font.bold: true
            color: "#333"
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Row {
            spacing: 40 * root.scale
            anchors.horizontalCenter: parent.horizontalCenter

            // ===== LEFT PANEL =====
            Column {
                spacing: 12 * root.scale

                Repeater {
                    model: [
                        { label: "Year",  get value() { return root.selectedDate.getFullYear() }},
                        { label: "Month", get value() { return root.selectedDate.getMonth() + 1 }},
                        { label: "Hour",  get value() { return root.selectedDate.getHours() }},
                        { label: "Min",   get value() { return root.selectedDate.getMinutes() }}
                    ]

                    delegate: Rectangle {
                        width: 120 * root.scale
                        height: 45 * root.scale
                        radius: 6
                        color: "#E8ECF3"

                        Column {
                            anchors.centerIn: parent
                            spacing: 2

                            Text {
                                text: modelData.label
                                font.pixelSize: 10 * root.scale
                                color: "#666"
                            }

                            Text {
                                text: modelData.value
                                font.pixelSize: 16 * root.scale
                                font.bold: true
                                color: "#333"
                            }
                        }
                    }
                }
            }

            // ===== CALENDAR CARD =====
            Rectangle {
                width: 380 * root.scale
                height: 320 * root.scale
                radius: 12
                color: "#FFFFFF"
                border.color: "#E3E7F0"
                border.width: 1

                Column {
                    id: calendar
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 6 * root.scale

                    property int displayMonth: root.selectedDate.getMonth()
                    property int displayYear: root.selectedDate.getFullYear()

                    // ===== HEADER =====
                    Row {
                        width: parent.width
                        height: 34 * root.scale
                        spacing: 12

                        Rectangle {
                            width: 32 * root.scale
                            height: parent.height
                            radius: 6
                            color: "#E8ECF3"

                            Text {
                                anchors.centerIn: parent
                                text: "<"
                                color: "#1A4DB5"
                                font.bold: true
                            }

                            MouseArea {
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

                        Text {
                            text: Qt.formatDate(new Date(calendar.displayYear, calendar.displayMonth, 1), "MMMM yyyy")
                            font.bold: true
                            font.pixelSize: 15 * root.scale
                            color: "#1A4DB5"
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Rectangle {
                            width: 32 * root.scale
                            height: parent.height
                            radius: 6
                            color: "#E8ECF3"

                            Text {
                                anchors.centerIn: parent
                                text: ">"
                                color: "#1A4DB5"
                                font.bold: true
                            }

                            MouseArea {
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

                    // ===== WEEKDAYS =====
                    DayOfWeekRow {
                        width: parent.width
                        height: 24 * root.scale
                        locale: Qt.locale()

                        delegate: Item {
                            required property int dayOfWeek   // 1 (Mon) → 7 (Sun)

                            width: parent.width / 7
                            height: parent.height

                            Text {
                                anchors.centerIn: parent


                                text: Qt.locale().dayName(dayOfWeek, Locale.ShortFormat)

                                font.pixelSize: 11 * root.scale
                                font.bold: true
                                color: "#1A4DB5"
                            }
                        }
                    }

                    // ===== GRID =====
                    MonthGrid {
                        width: parent.width
                        height: 240 * root.scale

                        month: calendar.displayMonth
                        year: calendar.displayYear

                        delegate: Rectangle {
                            width: parent.width / 7
                            height: parent.height / 6
                            radius: 6

                            property bool isSelected:
                                model.date.getDate() === root.selectedDate.getDate() &&
                                model.date.getMonth() === root.selectedDate.getMonth() &&
                                model.date.getFullYear() === root.selectedDate.getFullYear()

                            property bool isToday: {
                                var today = new Date()
                                return model.date.getDate() === today.getDate() &&
                                       model.date.getMonth() === today.getMonth() &&
                                       model.date.getFullYear() === today.getFullYear()
                            }

                            color: isSelected ? "#1A4DB5"
                                 : mouseArea.containsMouse ? "#E8EEFB"
                                 : "transparent"

                            border.width: isToday ? 2 : 0
                            border.color: "#1A4DB5"

                            Text {
                                anchors.centerIn: parent
                                text: model.day

                                font.pixelSize: 12 * root.scale
                                font.bold: isSelected || isToday

                                color: isSelected ? "#FFFFFF"
                                     : model.month === calendar.displayMonth ? "#333333"
                                     : "#C0C6D4"
                            }

                            MouseArea {
                                id: mouseArea
                                anchors.fill: parent
                                hoverEnabled: true

                                onClicked: {
                                    root.selectedDate = model.date
                                }
                            }
                        }
                    }
                }
            }

            // ===== SET BUTTON =====
            Rectangle {
                width: 100 * root.scale
                height: 40 * root.scale
                radius: 8
                color: setMouse.pressed ? "#0D3BA8" : "#1A4DB5"

                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: "Set"
                    color: "white"
                    font.bold: true
                    font.pixelSize: 14 * root.scale
                }

                MouseArea {
                    id: setMouse
                    anchors.fill: parent

                    onClicked: {
                        console.log("Selected DateTime:", root.selectedDate)
                    }
                }
            }
        }
    }
}
