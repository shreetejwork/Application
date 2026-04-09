import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Item {
    id: root
    anchors.fill: parent

    property var globalTopBar

    property real baseWidth: 1024
    property real baseHeight: 600
    property real scale: Math.min(width / baseWidth, height / baseHeight)

    signal fieldClicked(string label, string value)

    Rectangle {
        anchors.fill: parent
        color: "#F5F7FC"
    }

    CustomPopup {
        id: numberPopup
        anchors.fill: parent
        globalTopBar: root.globalTopBar
    }

    // ===== MODEL =====
    ListModel {
        id: fieldModel

        ListElement { fieldId: "lpf1"; label: "LPF"; title: "LPF"; value: "10"; unit: "Hz"; min: 1; max: 100 }
        ListElement { fieldId: "hpf1"; label: "HPF"; title: "HPF"; value: "2"; unit: "Hz"; min: 1; max: 50 }

        ListElement { fieldId: "od"; label: "O/D"; title: "Operate Delay"; value: "0"; unit: "mSec"; min: 0; max: 500 }
        ListElement { fieldId: "hd"; label: "H/D"; title: "Hold Delay"; value: "250"; unit: "mSec"; min: 0; max: 1000 }
        ListElement { fieldId: "rd"; label: "R/D"; title: "Relay Delay"; value: "250"; unit: "mSec"; min: 0; max: 1000 }

        ListElement { fieldId: "dg"; label: "D/G"; title: "Digital Gain"; value: "1"; unit: ""; min: 0; max: 10 }
        ListElement { fieldId: "ag"; label: "A/G"; title: "Analog Gain"; value: "1"; unit: ""; min: 0; max: 10 }
    }

    // ===== HELPERS =====
    function getItem(fieldId) {
        for (var i = 0; i < fieldModel.count; i++) {
            if (fieldModel.get(i).fieldId === fieldId)
                return fieldModel.get(i)
        }
        return null
    }

    function displayValue(fieldId) {
        var item = getItem(fieldId)
        if (!item) return ""
        return item.value
    }

    function displayUnit(fieldId) {
        var item = getItem(fieldId)
        if (!item) return ""
        return item.unit
    }

    function updateValue(fieldId, newVal) {
        for (var i = 0; i < fieldModel.count; i++) {
            if (fieldModel.get(i).fieldId === fieldId) {
                fieldModel.setProperty(i, "value", String(newVal))
                return
            }
        }
    }

    // ===== OPEN POPUP =====
    function openDialog(fieldId) {
        var item = getItem(fieldId)
        if (!item) return

        numberPopup.open(
            "Edit - " + item.title,
            "",
            function(newVal) {
                updateValue(fieldId, newVal)
                root.fieldClicked(
                    item.label,
                    newVal + (item.unit !== "" ? " " + item.unit : "")
                )
            },
            item.min,
            item.max
        )
    }

    // ===== LAYOUT =====
    Row {
        anchors.centerIn: parent
        spacing: 100 * root.scale

        // --- Left panel: Filter ---
        Column {
            spacing: 8 * root.scale

            // ===== TITLE =====
            Text {
                id: filterTitle
                text: "Digital filter Settings"
                font.pixelSize: 26 * root.scale
                font.bold: true
                color: "#1A4DB5"
            }

            Rectangle {
                width: 40 * root.scale
                height: 3 * root.scale
                radius: 2 * root.scale
                color: "#1A4DB5"
            }

            // ===== PANEL =====
            Rectangle {
                width: 280 * root.scale
                height: 460 * root.scale
                radius: 18 * root.scale
                color: "#FFFFFF"
                border.color: "#E5E7EB"
                border.width: 1

                Column {
                    anchors.fill: parent
                    anchors.margins: 20 * root.scale

                    Item {
                        anchors.fill: parent

                        Column {
                            anchors.centerIn: parent
                            spacing: 40 * root.scale

                            FilterTile { fieldId: "lpf1" }
                            FilterTile { fieldId: "hpf1" }
                        }
                    }
                }
            }
        }
        // --- Middle panel: Delay ---
        Column {
            spacing: 8 * root.scale

            // ===== TITLE =====
            Text {
                text: "Delay Settings"
                font.pixelSize: 26 * root.scale
                font.bold: true
                color: "#1A4DB5"
            }

            Rectangle {
                width: 40 * root.scale
                height: 3 * root.scale
                radius: 2 * root.scale
                color: "#1A4DB5"
            }

            // ===== PANEL =====
            Rectangle {
                width: 280 * root.scale
                height: 460 * root.scale
                radius: 18 * root.scale
                color: "#FFFFFF"
                border.color: "#E5E7EB"
                border.width: 1

                Column {
                    anchors.fill: parent
                    anchors.margins: 20 * root.scale

                    Item {
                        anchors.fill: parent

                        Column {
                            anchors.centerIn: parent
                            spacing: 40 * root.scale

                            FilterTile { fieldId: "hd" }
                            FilterTile { fieldId: "od" }
                            FilterTile { fieldId: "rd" }
                        }
                    }
                }
            }
        }

        // --- Right panel: Gain ---
        Column {
            spacing: 8 * root.scale

            // ===== TITLE =====
            Text {
                text: "Gain Settings"
                font.pixelSize: 26 * root.scale
                font.bold: true
                color: "#1A4DB5"
            }

            Rectangle {
                width: 40 * root.scale
                height: 3 * root.scale
                radius: 2 * root.scale
                color: "#1A4DB5"
            }

            // ===== PANEL =====
            Rectangle {
                width: 280 * root.scale
                height: 460 * root.scale
                radius: 18 * root.scale
                color: "#FFFFFF"
                border.color: "#E5E7EB"
                border.width: 1

                Column {
                    anchors.fill: parent
                    anchors.margins: 20 * root.scale

                    Item {
                        anchors.fill: parent

                        Column {
                            anchors.centerIn: parent
                            spacing: 40 * root.scale

                            FilterTile { fieldId: "ag" }
                            FilterTile { fieldId: "dg" }
                        }
                    }
                }
            }
        }
    }

    // ===== TILE COMPONENT =====
    component FilterTile: Item {
        id: tile
        property string fieldId: ""
        property bool pressed: false

        width: 188 * root.scale
        height: 90 * root.scale

        Rectangle {
            id: card
            anchors.fill: parent
            radius: 12 * root.scale
            color: tile.pressed ? "#EEF3FF" : "#FFFFFF"
            border.color: "#D0D9F0"
            border.width: 1

            // Top accent bar
            Rectangle {
                id: accentBar
                width: parent.width
                height: 30 * root.scale
                color: "#1A4DB5"
                radius: card.radius

                Rectangle {
                    width: parent.width
                    height: parent.radius
                    anchors.bottom: parent.bottom
                    color: parent.color
                }

                Text {
                    anchors.centerIn: parent
                    text: root.getItem(tile.fieldId)?.label || ""
                    color: "#FFFFFF"
                    font.pixelSize: 18 * root.scale
                    font.bold: true
                }
            }

            // Value area
            Item {
                anchors.top: accentBar.bottom
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right

                Text {
                    id: valueText
                    anchors.centerIn: parent
                    text: root.displayValue(tile.fieldId)
                    color: "#1A4DB5"
                    font.pixelSize: 25 * root.scale
                    font.bold: true
                }

                Text {
                    anchors.left: valueText.right
                    anchors.leftMargin: 4 * root.scale
                    anchors.baseline: valueText.baseline
                    text: root.displayUnit(tile.fieldId)
                    color: "#7A96CC"
                    font.pixelSize: 16 * root.scale
                    visible: root.displayUnit(tile.fieldId) !== ""
                }
            }

            MouseArea {
                anchors.fill: parent
                onPressed:  tile.pressed = true
                onReleased: tile.pressed = false
                onCanceled: tile.pressed = false
                onClicked:  root.openDialog(tile.fieldId)
            }
        }
    }
}
