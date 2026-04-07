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

    signal fieldClicked(string label, string value)

    Rectangle {
        anchors.fill: parent
        color: "#F5F7FC"
    }

    CustomPopup {
        id: numberPopup
        anchors.fill: parent

        // IMPORTANT: connect to your top bar
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
        return item.unit !== "" ? item.value + " " + item.unit : item.value
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
    Column {
        anchors.centerIn: parent
        spacing: 60 * root.scale

        Row {
            spacing: 40 * root.scale
            anchors.horizontalCenter: parent.horizontalCenter

            FilterTile { fieldId: "lpf1" }
            FilterTile { fieldId: "hpf1" }
        }

        Row {
            spacing: 60 * root.scale
            anchors.horizontalCenter: parent.horizontalCenter

            FilterTile { fieldId: "od" }
            FilterTile { fieldId: "hd" }
            FilterTile { fieldId: "rd" }
        }

        Row {
            spacing: 40 * root.scale
            anchors.horizontalCenter: parent.horizontalCenter

            FilterTile { fieldId: "dg" }
            FilterTile { fieldId: "ag" }
        }
    }

    // ===== TILE COMPONENT =====
    component FilterTile: Item {
        id: tile
        property string fieldId: ""

        width: 200 * root.scale
        height: 90 * root.scale

        Rectangle {
            id: body
            width: parent.width
            height: parent.height * 0.65
            anchors.bottom: parent.bottom

            radius: height * 0.45
            color: body.pressed ? "#1A4DB5" : "#FFFFFF"

            border.color: "#1A4DB5"
            border.width: 3

            property bool pressed: false

            Text {
                anchors.centerIn: parent
                text: root.displayValue(tile.fieldId)
                color: body.pressed ? "#FFFFFF" : "#1A4DB5"
                font.pixelSize: 18 * root.scale
                font.bold: true
            }

            MouseArea {
                anchors.fill: parent
                onPressed:  body.pressed = true
                onReleased: body.pressed = false
                onCanceled: body.pressed = false
                onClicked:  root.openDialog(tile.fieldId)
            }
        }

        Rectangle {
            width: parent.width * 0.55
            height: parent.height * 0.38

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: body.top
            anchors.bottomMargin: -height * 0.35

            radius: height / 2
            color: "#1A4DB5"

            Text {
                anchors.centerIn: parent
                text: root.getItem(tile.fieldId)?.label || ""
                color: "#FFFFFF"
                font.pixelSize: 14 * root.scale
                font.bold: true
            }
        }
    }
}
