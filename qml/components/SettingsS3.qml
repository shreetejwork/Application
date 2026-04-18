import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    anchors.fill: parent

    property real baseWidth: 1024
    property real baseHeight: 600

    // ✅ ONLY CHANGE: uniform scaling boost (keeps layout identical)
    property real scale: Math.min(width / baseWidth, height / baseHeight) * 1.10

    property var globalTopBar
    property var notify

    Rectangle {
        anchors.fill: parent
        color: "#F5F7FC"
    }

    // ===== MODEL =====
    ListModel {
        id: timeModel
        ListElement { time: "11:15"; enabled: false }
        ListElement { time: "11:30"; enabled: false }
        ListElement { time: "11:45"; enabled: false }
        ListElement { time: "11:00"; enabled: false }
    }

    // ===== MAIN WRAPPER =====
    Item {
        anchors.centerIn: parent
        width: 720 * root.scale
        height: 560 * root.scale

        // ===== TITLE =====
        Column {
            spacing: 10 * root.scale
            anchors.left: parent.left
            anchors.top: parent.top

            Text {
                text: "Validation Time Scheduler"
                font.pixelSize: 26 * root.scale
                font.bold: true
                color: "#1A4DB5"
            }

            Rectangle {
                width: 80 * root.scale
                height: 5 * root.scale
                radius: 2
                color: "#1A4DB5"
            }
        }

        // ===== CARD =====
        Item {
            anchors.top: parent.top
            anchors.topMargin: 60 * root.scale
            width: parent.width
            height: 460 * root.scale

            Rectangle {
                anchors.fill: parent
                radius: 18 * root.scale
                color: "#EEF2FF"
            }

            Rectangle {
                id: card
                anchors.centerIn: parent
                width: parent.width - 6
                height: parent.height - 6
                radius: 18 * root.scale
                color: "#FFFFFF"
                border.color: "#E5E7EB"

                Column {
                    anchors.fill: parent
                    anchors.margins: 30 * root.scale
                    spacing: 20 * root.scale

                    // ===== HEADER =====
                    Row {
                        width: parent.width

                        Item {
                            width: 180 * root.scale
                            height: 40 * root.scale

                            Text {
                                anchors.centerIn: parent
                                text: "Time"
                                font.bold: true
                                font.pixelSize: 24 * root.scale
                                color: "#374151"
                            }
                        }

                        Item {
                            width: 180 * root.scale
                            height: 40 * root.scale

                            Text {
                                anchors.centerIn: parent
                                text: "Edit"
                                font.bold: true
                                font.pixelSize: 24 * root.scale
                                color: "#374151"
                            }
                        }

                        Item {
                            width: 180 * root.scale
                            height: 40 * root.scale

                            Text {
                                anchors.centerIn: parent
                                text: "ON/OFF"
                                font.bold: true
                                font.pixelSize: 24 * root.scale
                                color: "#374151"
                            }
                        }
                    }

                    Rectangle {
                        height: 1
                        width: parent.width
                        color: "#E5E7EB"
                    }

                    // ===== LIST =====
                    Repeater {
                        model: timeModel

                        Rectangle {
                            width: parent.width
                            height: 52 * root.scale
                            radius: 10 * root.scale
                            color: "#FAFBFF"

                            Row {
                                anchors.fill: parent
                                anchors.margins: 12 * root.scale

                                // TIME
                                Item {
                                    width: 180 * root.scale
                                    height: parent.height

                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 140 * root.scale
                                        height: 34 * root.scale
                                        radius: 6
                                        color: "#EEF3FF"

                                        Text {
                                            anchors.centerIn: parent
                                            text: model.time
                                            color: "#1A4DB5"
                                            font.bold: true
                                            font.pixelSize: 24 * root.scale
                                        }
                                    }
                                }

                                // EDIT
                                Item {
                                    width: 180 * root.scale
                                    height: parent.height

                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 110 * root.scale
                                        height: 34 * root.scale
                                        radius: 6
                                        color: "#1A4DB5"

                                        Text {
                                            anchors.centerIn: parent
                                            text: "Edit"
                                            color: "#FFFFFF"
                                            font.pixelSize: 22 * root.scale
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                                timePopup.editIndex = index

                                                var t = model.time.split(":")
                                                var h = parseInt(t[0])
                                                var m = t[1]

                                                hourTumbler.currentIndex = h

                                                var minuteMap = { "00": 0, "15": 1, "30": 2, "45": 3 }
                                                minuteTumbler.currentIndex = minuteMap[m] !== undefined ? minuteMap[m] : 0

                                                timePopup.open()
                                            }
                                        }
                                    }
                                }

                                // TOGGLE
                                Item {
                                    width: 180 * root.scale
                                    height: parent.height

                                    DDButton {
                                        anchors.centerIn: parent
                                        width: 120 * root.scale
                                        height: 44 * root.scale
                                        toggled: model.enabled
                                        knobSize: 35 * root.scale
                                        useSymbols: true

                                        onToggledChanged: {
                                            timeModel.setProperty(index, "enabled", toggled)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // POPUP (unchanged)
                    Popup {
                        id: timePopup
                        modal: true
                        focus: true

                        width: 420 * root.scale
                        height: 420 * root.scale
                        anchors.centerIn: parent

                        property int editIndex: -1

                        background: Rectangle {
                            radius: 18 * root.scale
                            color: "#FFFFFF"
                            border.color: "#E5E7EB"
                        }

                        Column {
                            anchors.fill: parent
                            anchors.margins: 24 * root.scale
                            spacing: 18 * root.scale

                            Component {
                                id: tumblerDelegate

                                Text {
                                    text: modelData < 10 ? "0" + modelData : modelData
                                    font.pixelSize: 26 * root.scale
                                    font.bold: Tumbler.displacement === 0
                                    opacity: 1.0 - Math.abs(Tumbler.displacement) * 0.6
                                    scale: 1.0 - Math.abs(Tumbler.displacement) * 0.25
                                    color: Tumbler.displacement === 0 ? "#1A4DB5" : "#9CA3AF"
                                    horizontalAlignment: Text.AlignHCenter
                                    width: parent.width
                                }
                            }

                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 60 * root.scale

                                Column {
                                    spacing: 10 * root.scale

                                    Text {
                                        text: "Hours"
                                        font.pixelSize: 20 * root.scale
                                        font.bold: true
                                        color: "#5A6A85"
                                        width: parent.width
                                        horizontalAlignment: Text.AlignHCenter
                                    }

                                    Item {
                                        width: 140 * root.scale
                                        height: 200 * root.scale

                                        Rectangle {
                                            anchors.centerIn: parent
                                            width: parent.width
                                            height: 40 * root.scale
                                            radius: 10
                                            color: "#E8EEFB"
                                        }

                                        Tumbler {
                                            id: hourTumbler
                                            anchors.fill: parent
                                            model: 24
                                            visibleItemCount: 3
                                            wrap: true
                                            delegate: tumblerDelegate
                                        }
                                    }
                                }

                                Column {
                                    spacing: 10 * root.scale

                                    Text {
                                        text: "Minutes"
                                        font.pixelSize: 20 * root.scale
                                        font.bold: true
                                        color: "#5A6A85"
                                        width: parent.width
                                        horizontalAlignment: Text.AlignHCenter
                                    }

                                    Item {
                                        width: 140 * root.scale
                                        height: 200 * root.scale

                                        Rectangle {
                                            anchors.centerIn: parent
                                            width: parent.width
                                            height: 40 * root.scale
                                            radius: 10
                                            color: "#E8EEFB"
                                        }

                                        Tumbler {
                                            id: minuteTumbler
                                            anchors.fill: parent
                                            model: ["00", "15", "30", "45"]
                                            visibleItemCount: 3
                                            wrap: true

                                            delegate: Text {
                                                text: modelData
                                                font.pixelSize: 26 * root.scale
                                                font.bold: Tumbler.displacement === 0
                                                opacity: 1.0 - Math.abs(Tumbler.displacement) * 0.6
                                                scale: 1.0 - Math.abs(Tumbler.displacement) * 0.25
                                                color: Tumbler.displacement === 0 ? "#1A4DB5" : "#9CA3AF"
                                                horizontalAlignment: Text.AlignHCenter
                                                width: parent.width
                                            }
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: 50 * root.scale
                                radius: 12
                                color: "#1A4DB5"

                                Text {
                                    anchors.centerIn: parent
                                    text: "Save Time"
                                    color: "#FFFFFF"
                                    font.bold: true
                                    font.pixelSize: 22 * root.scale
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        var h = hourTumbler.currentIndex
                                        var m = minuteTumbler.currentIndex
                                        var minutes = ["00", "15", "30", "45"][m]
                                        var hours = h < 10 ? "0" + h : h
                                        var newTime = hours + ":" + minutes

                                        if (timePopup.editIndex >= 0) {
                                            timeModel.setProperty(timePopup.editIndex, "time", newTime)
                                        }

                                        timePopup.close()
                                    }
                                }
                            }
                        }
                    }
                }

                Row {
                    spacing: 20 * root.scale
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.rightMargin: 165 * root.scale
                    anchors.bottomMargin: 15 * root.scale

                    Rectangle {
                        width: 120 * root.scale
                        height: 46 * root.scale
                        radius: 10
                        color: "#1A4DB5"

                        Text {
                            anchors.centerIn: parent
                            text: "SAVE"
                            color: "#FFFFFF"
                            font.bold: true
                            font.pixelSize: 22 * root.scale
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (notify)
                                    notify("✓ Alarm Set")
                            }
                        }
                    }
                }
            }
        }
    }
}
