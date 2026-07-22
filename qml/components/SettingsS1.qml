import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import AppState 1.0

import Backend 1.0

import "../components"

Item {
    Typography {
        id: componentTypography
        scale: root.scale || 1.0
    }
    id: root
    anchors.fill: parent

    property var globalTopBar
    property var notify

    property real baseWidth: 1024
    property real baseHeight: 600
    property real scale: Math.min(width / baseWidth, height / baseHeight)


    Component.onCompleted: {

        var settings = databaseManager.getS1Settings()

        if(settings.lpf !== undefined)
            updateValue("lpf1", settings.lpf)

        if(settings.hpf !== undefined)
            updateValue("hpf1", settings.hpf)

        if(settings.operateDelay !== undefined)
            updateValue("od", settings.operateDelay)

        if(settings.holdDelay !== undefined)
            updateValue("hd", settings.holdDelay)

        if(settings.relayDelay !== undefined)
            updateValue("rd", settings.relayDelay)

        if(settings.digitalGain !== undefined)
            updateValue("dg", settings.digitalGain)

        if(settings.analogGain !== undefined)
            updateValue("ag", settings.analogGain)
    }

    
    // =========================================================
    // TYPOGRAPHY FOR SETTINGS S1
    // =========================================================
    
    Typography {
        id: s1Typography
        scale: root.scale
    }

    signal fieldClicked(string label, string value)

    Rectangle {
        anchors.fill: parent
        color: "#F5F7FC"
    }

    CustomPopup {
        id: numberPopup
        parent: Overlay.overlay
        anchors.fill: parent
        z: 9999
        globalTopBar: root.globalTopBar
    }

    // ===== MODEL =====
    ListModel {
        id: fieldModel

        ListElement { fieldId: "lpf1"; label: "LPF"; title: "LPF"; value: "10"; unit: "Hz"; min: 10; max: 40 }
        ListElement { fieldId: "hpf1"; label: "HPF"; title: "HPF"; value: "2.0"; unit: "Hz"; min: 1; max: 35 }

        ListElement { fieldId: "od"; label: "O/D"; title: "Operate Delay"; value: "0"; unit: "mSec"; min: 0; max: 20000 }
        ListElement { fieldId: "hd"; label: "H/D"; title: "Hold Delay"; value: "250"; unit: "mSec"; min: 250; max: 2000 }
        ListElement { fieldId: "rd"; label: "R/D"; title: "Relay Delay"; value: "250"; unit: "mSec"; min: 10; max: 1000 }

        ListElement { fieldId: "dg"; label: "D/G"; title: "Digital Gain"; value: "1.0"; unit: ""; min: 0.1; max: 10.0 }
        ListElement { fieldId: "ag"; label: "A/G"; title: "Analog Gain"; value: "1"; unit: ""; min: 1; max: 10 }
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

        GlobalState.loginKeyboardRequest = false

        numberPopup.open(
            item.title,
            "",
                    function(newVal)
                    {
                        updateValue(fieldId,newVal)


                        switch(fieldId)
                        {
                        case "lpf1":
                            SerialManager.setLPF(newVal)
                            break

                        case "hpf1":

                            SerialManager.setHPF(
                                        Math.round(newVal*10))

                            break


                        case "od":
                            SerialManager.setOperateDelay(newVal)
                            break


                        case "hd":
                            SerialManager.setHoldDelay(newVal)
                            break


                        case "rd":
                            SerialManager.setRelayDelay(newVal)
                            break


                        case "dg":

                            SerialManager.setDigitalGain(
                                        Math.round(newVal*10))

                            break


                        case "ag":
                            SerialManager.setAnalogGain(newVal)
                            break
                        }

                        databaseManager.saveS1Settings(

                            Number(displayValue("lpf1")),

                            Number(displayValue("hpf1")),

                            Number(displayValue("od")),

                            Number(displayValue("hd")),

                            Number(displayValue("rd")),

                            Number(displayValue("dg")),

                            Number(displayValue("ag"))

                        )


                        root.notify(
                                    "✓ "
                                    + item.label
                                    + " Saved : "
                                    + newVal
                                    + " "
                                    + item.unit)


                        root.fieldClicked(
                                    item.label,
                                    newVal + (
                                        item.unit !== ""
                                        ? " " + item.unit
                                        : "")
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
                font.pixelSize: s1Typography.title

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
                font.pixelSize: s1Typography.title

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
                font.pixelSize: s1Typography.title

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
                    font.pixelSize: s1Typography.body

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
                    text:
                    {
                        var v = Number(root.displayValue(tile.fieldId))

                        if(tile.fieldId==="hpf1" ||
                           tile.fieldId==="dg")
                            return v.toFixed(1)

                        return v
                    }
                    color: "#1A4DB5"
                    font.pixelSize: s1Typography.heading

                }

                Text {
                    anchors.left: valueText.right
                    anchors.leftMargin: 4 * root.scale
                    anchors.baseline: valueText.baseline
                    text: root.displayUnit(tile.fieldId)
                    color: "#7A96CC"
                    font.pixelSize: s1Typography.caption
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
