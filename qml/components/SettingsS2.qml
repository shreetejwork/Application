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
        text: "Date - Time Settings"
        font.pixelSize: 26 * root.scale
        font.bold: true
        color: "#1A4DB5"

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: 30 * root.scale
        anchors.topMargin: 20 * root.scale
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

    // ===== MAIN CONTENT =====
    Row {
        anchors.centerIn: parent
        spacing: 50 * root.scale

        // ===== LEFT PANEL =====
        Column {
            spacing: 16 * root.scale

            Repeater {
                model: [
                    { label: "Year",  value: root.selectedDate.getFullYear() },
                    { label: "Month", value: root.selectedDate.getMonth() + 1 },
                    { label: "Hour",  value: root.selectedDate.getHours() },
                    { label: "Min",   value: root.selectedDate.getMinutes() }
                ]

                delegate: Rectangle {
                    width: 150 * root.scale
                    height: 60 * root.scale
                    radius: 8
                    color: "#E8ECF3"

                    Column {
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: modelData.label
                            font.pixelSize: 12 * root.scale
                            color: "#333"
                        }

                        Text {
                            text: modelData.value
                            font.pixelSize: 20 * root.scale
                            font.bold: true
                            color: "#1A4DB5"
                        }
                    }
                }
            }
        }

        // ===== CALENDAR =====
        Rectangle {
            width: 460 * root.scale
            height: 380 * root.scale
            radius: 14
            color: "#FFFFFF"
            border.color: "#E3E7F0"

            Column {
                id: calendar
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10 * root.scale

                property int displayMonth: root.selectedDate.getMonth()
                property int displayYear: root.selectedDate.getFullYear()

                // HEADER
                Row {
                    width: parent.width
                    height: 42 * root.scale
                    spacing: 16

                    Rectangle {
                        width: 40 * root.scale
                        height: parent.height
                        radius: 8
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
                        font.pixelSize: 18 * root.scale
                        color: "#1A4DB5"
                    }

                    Rectangle {
                        width: 40 * root.scale
                        height: parent.height
                        radius: 8
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

                // WEEKDAYS
                Row {
                    width: parent.width
                    height: 30 * root.scale

                    Repeater {
                        model: ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]

                        delegate: Item {
                            width: parent.width / 7
                            height: parent.height

                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                font.bold: true
                                color: "#1A4DB5"
                            }
                        }
                    }
                }

                // GRID
                MonthGrid {
                    width: parent.width
                    height: 280 * root.scale

                    month: calendar.displayMonth
                    year: calendar.displayYear

                    delegate: Rectangle {
                        width: parent.width / 7
                        height: parent.height / 6
                        radius: 8

                        property bool isSelected:
                            model.date.getDate() === root.selectedDate.getDate() &&
                            model.date.getMonth() === root.selectedDate.getMonth() &&
                            model.date.getFullYear() === root.selectedDate.getFullYear()

                        color: isSelected ? "#1A4DB5"
                             : mouseArea.containsMouse ? "#E8EEFB"
                             : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: model.day
                            color: isSelected ? "#FFFFFF"
                                 : model.month === calendar.displayMonth ? "#333" : "#C0C6D4"
                        }

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true

                            onClicked: {
                                var d = new Date(root.selectedDate)

                                d.setFullYear(model.date.getFullYear())
                                d.setMonth(model.date.getMonth())
                                d.setDate(model.date.getDate())

                                root.selectedDate = d
                            }
                        }
                    }
                }
            }
        }

        // ===== SET BUTTON =====
        Rectangle {
            width: 130 * root.scale
            height: 50 * root.scale
            radius: 10
            color: setMouse.pressed ? "#0D3BA8" : "#1A4DB5"

            anchors.verticalCenter: parent.verticalCenter

            Text {
                anchors.centerIn: parent
                text: "Set"
                color: "white"
                font.bold: true
            }

            MouseArea {
                id: setMouse
                anchors.fill: parent

                onClicked: {
                    GlobalState.globalDateTime = root.selectedDate
                    console.log("Updated Global Date:", GlobalState.globalDateTime)
                }
            }
        }
    }
}
