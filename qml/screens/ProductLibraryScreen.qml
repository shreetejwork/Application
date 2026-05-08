import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic
import QtQuick.Layouts

import "../components"

import AppState 1.0

Item {
    id: root
    anchors.fill: parent

    property real baseWidth: 1024
    property real baseHeight: 600
    property real scale: Math.max(0.75, Math.min(width / baseWidth, height / baseHeight))

    property int currentGroup: 1
    property int activeSr: 1
    property bool selectionMode: false

    // ===== COLUMN WIDTHS =====

    property real colSpacing: 12 * root.scale

    property real colSelect: 22 * root.scale
    property real colActive: 22 * root.scale
    property real colSr: 90 * root.scale
    property real colCode: 170 * root.scale

    // ===== SHARED LAYOUT HELPERS =====
    property real rowFixedSpacing: 16 * root.scale * 3
    property real rowSelectExtra:  root.colSelect + 16 * root.scale

    function nameColWidth(totalWidth) {
        return totalWidth
                - root.colActive
                - root.colSr
                - root.colCode
                - rowFixedSpacing
                - (selectionMode ? rowSelectExtra : 0)
    }

    // ================= MODELS =================

    ListModel {
        id: group01Model
        ListElement {
            selected: false
            active: true
            sr: 1
            name: "Default Product"
            code: "DEF-001"
            fixedItem: true
        }
    }

    ListModel { id: group02Model }
    ListModel { id: group03Model }
    ListModel { id: group04Model }
    ListModel { id: group05Model }
    ListModel { id: group06Model }
    ListModel { id: group07Model }
    ListModel { id: group08Model }
    ListModel { id: group09Model }
    ListModel { id: group10Model }

    property var groupModels: [
        group01Model, group02Model, group03Model, group04Model, group05Model,
        group06Model, group07Model, group08Model, group09Model, group10Model
    ]

    function currentModel() {
        return groupModels[currentGroup - 1]
    }

    function getFreeSrNo(model) {
        for (var srNo = 1; srNo <= 100; srNo++) {
            var found = false
            for (var i = 0; i < model.count; i++) {
                if (model.get(i).sr === srNo) {
                    found = true
                    break
                }
            }
            if (!found)
                return srNo
        }
        return -1
    }

    function addProduct() {
        var model = currentModel()
        var srNo = getFreeSrNo(model)
        if (srNo === -1)
            return

        model.append({
                         selected: false,
                         active: false,
                         sr: srNo,
                         name: "Product " + srNo,
                         code: "PRD-" + currentGroup + "-" + srNo,
                         fixedItem: false
                     })

        for (var i = 0; i < model.count; i++) {
            for (var j = i + 1; j < model.count; j++) {
                if (model.get(i).sr > model.get(j).sr) {
                    var tempI = {
                        selected: model.get(i).selected, active: model.get(i).active,
                        sr: model.get(i).sr, name: model.get(i).name,
                        code: model.get(i).code, fixedItem: model.get(i).fixedItem
                    }
                    var tempJ = {
                        selected: model.get(j).selected, active: model.get(j).active,
                        sr: model.get(j).sr, name: model.get(j).name,
                        code: model.get(j).code, fixedItem: model.get(j).fixedItem
                    }
                    model.set(i, tempJ)
                    model.set(j, tempI)
                }
            }
        }
    }

    function deleteSelectedProducts() {
        var model = currentModel()
        for (var i = model.count - 1; i >= 0; i--) {
            var item = model.get(i)
            if (item.selected && !item.fixedItem) {
                model.remove(i)
            }
        }
    }

    function setActiveProduct(srNo) {
        activeSr = srNo
        var model = currentModel()
        for (var i = 0; i < model.count; i++) {
            model.setProperty(i, "active", model.get(i).sr === srNo)
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#F5F7FC"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20 * root.scale
            spacing: 12 * root.scale

            // ================= TITLE =================

            Column {
                spacing: 6 * root.scale

                Text {
                    text: "Product Library"
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

            // ================= TOP BAR =================

            Rectangle {
                Layout.fillWidth: true
                height: 60 * root.scale
                color: "#FFFFFF"
                radius: 12 * root.scale
                border.color: "#C8D4EE"
                border.width: 1

                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 2 * root.scale
                    radius: 12 * root.scale
                    color: "#E8EEF9"
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14 * root.scale
                    anchors.rightMargin: 14 * root.scale
                    anchors.topMargin: 10 * root.scale
                    anchors.bottomMargin: 10 * root.scale
                    spacing: 10 * root.scale

                    // ================= GROUP COMBO =================

                    ComboBox {
                        id: groupCombo

                        Layout.preferredWidth: 210 * root.scale
                        Layout.preferredHeight: 38 * root.scale
                        Layout.alignment: Qt.AlignVCenter

                        model: [
                            "GROUP 01", "GROUP 02", "GROUP 03", "GROUP 04", "GROUP 05",
                            "GROUP 06", "GROUP 07", "GROUP 08", "GROUP 09", "GROUP 10"
                        ]

                        currentIndex: 0

                        onCurrentIndexChanged: {
                            currentGroup = currentIndex + 1
                        }

                        font.pixelSize: 15 * root.scale

                        delegate: ItemDelegate {
                            width: groupCombo.width
                            height: 40 * root.scale

                            background: Rectangle {
                                color: highlighted ? "#E3EDFF" : "#FFFFFF"
                            }

                            contentItem: Text {
                                text: modelData
                                color: highlighted ? "#1A4DB5" : "#2A3550"
                                font.pixelSize: 15 * root.scale
                                font.weight: highlighted ? Font.Medium : Font.Normal
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: 14 * root.scale
                            }
                        }

                        indicator: Text {
                            text: "▼"
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right
                            anchors.rightMargin: 14 * root.scale
                            font.pixelSize: 12 * root.scale
                            color: "#1A4DB5"
                        }

                        contentItem: Text {
                            text: groupCombo.displayText
                            color: "#2A3550"
                            font.pixelSize: 15 * root.scale
                            font.weight: Font.Medium
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: 14 * root.scale
                            rightPadding: 34 * root.scale
                        }

                        background: Rectangle {
                            radius: 8 * root.scale
                            color: "#EDF1FA"
                            border.width: 1
                            border.color: groupCombo.popup.visible ? "#1A4DB5" : "#C8D4EE"
                        }

                        popup: Popup {
                            y: groupCombo.height + 4 * root.scale
                            width: groupCombo.width
                            padding: 0

                            background: Rectangle {
                                radius: 10 * root.scale
                                color: "#FFFFFF"
                                border.color: "#C8D4EE"
                                border.width: 1
                            }

                            contentItem: ListView {
                                clip: true
                                implicitHeight: contentHeight
                                model: groupCombo.popup.visible ? groupCombo.delegateModel : null
                                currentIndex: groupCombo.highlightedIndex
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // ================= BUTTONS =================

                    Repeater {
                        model: ["LOAD", "ADD", "SELECT", "DELETE"]

                        delegate: Rectangle {
                            property bool isSelectButton: modelData === "SELECT"
                            property bool activeButton: isSelectButton && selectionMode

                            width: 100 * root.scale
                            height: 38 * root.scale
                            radius: 8 * root.scale

                            color: activeButton ? "#1A4DB5" : "#FFFFFF"
                            border.width: 1
                            border.color: modelData === "DELETE" ? "#C62828" : "#1A4DB5"

                            Behavior on color { ColorAnimation { duration: 120 } }

                            Text {
                                anchors.centerIn: parent
                                text: activeButton ? "Cancel" : modelData
                                font.pixelSize: 15 * root.scale
                                font.weight: Font.Medium
                                color: activeButton ? "#FFFFFF" : (modelData === "DELETE" ? "#C62828" : "#1A4DB5")
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor

                                onClicked: {

                                    if (modelData === "LOAD") {

                                        // add load logic
                                    }

                                    else if (modelData === "ADD") {

                                        addProductPopup.open()
                                    }

                                    else if (modelData === "SELECT") {

                                        // CANCEL SELECTION
                                        if (selectionMode) {

                                            var model = currentModel()

                                            for (var i = 0; i < model.count; i++) {

                                                model.setProperty(i, "selected", false)
                                            }

                                            selectionMode = false
                                        }
                                        // ENABLE SELECTION
                                        else {

                                            selectionMode = true
                                        }
                                    }

                                    else if (modelData === "DELETE") {

                                        deleteSelectedProducts()
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ================= MAIN CONTENT =================

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 10 * root.scale

                // ================= TABLE =================

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

                        // ══════════════════════════════════════════════════════
                        // TABLE HEADER
                        // ══════════════════════════════════════════════════════

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
                                anchors.leftMargin: 12 * root.scale
                                anchors.rightMargin: 12 * root.scale
                                anchors.topMargin: 12 * root.scale
                                anchors.bottomMargin: 12 * root.scale
                                spacing: 16 * root.scale

                                // SELECT SPACE
                                Item {
                                    visible: selectionMode
                                    width: root.colSelect
                                    height: 1
                                }

                                // ACTIVE
                                Item {
                                    width: root.colActive
                                    height: parent.height

                                    Text {
                                        anchors.centerIn: parent
                                        text: "A"
                                        color: "#FFFFFF"
                                        font.bold: true
                                        font.pixelSize: 20 * root.scale
                                    }
                                }

                                // SR
                                Text {
                                    text: "SR No"
                                    width: root.colSr
                                    verticalAlignment: Text.AlignVCenter
                                    color: "#FFFFFF"
                                    font.bold: true
                                    font.pixelSize: 20 * root.scale
                                }

                                // PRODUCT NAME
                                Text {
                                    text: "Product Name"
                                    width: root.nameColWidth(
                                               parent.width
                                               - parent.anchors.leftMargin
                                               - parent.anchors.rightMargin
                                               )
                                    verticalAlignment: Text.AlignVCenter
                                    color: "#FFFFFF"
                                    font.bold: true
                                    font.pixelSize: 20 * root.scale
                                    elide: Text.ElideRight
                                }

                                // PRODUCT CODE
                                Text {
                                    text: "Product Code"
                                    width: root.colCode
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    color: "#FFFFFF"
                                    font.bold: true
                                    font.pixelSize: 20 * root.scale
                                }
                            }
                        }

                        // ══════════════════════════════════════════════════════
                        // LIST
                        // ══════════════════════════════════════════════════════

                        ListView {
                            id: productList

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 0
                            boundsBehavior: Flickable.StopAtBounds
                            model: currentModel()

                            ScrollBar.vertical: ScrollBar {
                                policy: ScrollBar.AsNeeded
                                width: 8 * root.scale
                            }

                            delegate: Rectangle {
                                id: rowRect

                                width: productList.width
                                height: visible ? 42 * root.scale : 0

                                property bool isSelected: selected === true

                                color: isSelected
                                       ? "#E3EDFF"
                                       : (index % 2 === 0 ? "#FFFFFF" : "#F4F7FF")

                                Behavior on color { ColorAnimation { duration: 120 } }

                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    height: 1
                                    color: "#E4EAF5"
                                }

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12 * root.scale
                                    anchors.rightMargin: 12 * root.scale
                                    anchors.topMargin: 10 * root.scale
                                    anchors.bottomMargin: 10 * root.scale
                                    spacing: 16 * root.scale

                                    // ═════════ SELECT ═════════

                                    Rectangle {
                                        visible: selectionMode
                                        width: root.colSelect
                                        height: root.colSelect
                                        radius: 4 * root.scale
                                        color: isSelected ? "#1A4DB5" : "#FFFFFF"
                                        border.color: isSelected ? "#1A4DB5" : "#8BA0CC"
                                        border.width: 1.5

                                        Text {
                                            anchors.centerIn: parent
                                            text: "✓"
                                            visible: isSelected
                                            color: "#FFFFFF"
                                            font.bold: true
                                            font.pixelSize: 12 * root.scale
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                                currentModel().setProperty(index, "selected", !selected)
                                            }
                                        }
                                    }

                                    // ═════════ ACTIVE ═════════

                                    Rectangle {
                                        width: root.colActive
                                        height: root.colActive
                                        radius: width / 2
                                        color: active ? "#1A4DB5" : "#D5DDEE"

                                        Text {
                                            anchors.centerIn: parent
                                            text: active ? "A" : ""
                                            color: "#FFFFFF"
                                            font.bold: true
                                            font.pixelSize: 12 * root.scale
                                        }
                                    }

                                    // ═════════ SR ═════════

                                    Text {
                                        text: sr
                                        width: root.colSr
                                        verticalAlignment: Text.AlignVCenter
                                        font.pixelSize: 18 * root.scale
                                        font.weight: active ? Font.Medium : Font.Normal
                                        color: "#2A3550"
                                    }

                                    // ═════════ PRODUCT NAME ═════════

                                    Text {
                                        text: name
                                        width: root.nameColWidth(
                                                   rowRect.width
                                                   - 12 * root.scale
                                                   - 12 * root.scale
                                                   )
                                        elide: Text.ElideRight
                                        verticalAlignment: Text.AlignVCenter
                                        font.pixelSize: 18 * root.scale
                                        font.weight: active ? Font.Medium : Font.Normal
                                        color: "#2A3550"
                                    }

                                    // ═════════ PRODUCT CODE ═════════

                                    Rectangle {
                                        width: root.colCode
                                        height: 24 * root.scale
                                        radius: 12 * root.scale
                                        color: active ? "#E8F0FF" : "#EDF1FA"

                                        Text {
                                            anchors.centerIn: parent
                                            text: code
                                            font.pixelSize: 18 * root.scale
                                            font.weight: Font.Medium
                                            color: active ? "#1A4DB5" : "#4A5E8A"
                                        }
                                    }
                                }

                                // ═════════ ROW CLICK ═════════

                                MouseArea {
                                    anchors.fill: parent

                                    onClicked: {

                                        if (!selectionMode) {

                                            setActiveProduct(sr)
                                        }

                                        // SELECTION MODE
                                        else {

                                        currentModel().setProperty(
                                            index,
                                            "selected",
                                            !selected)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ================= SIDE PANEL =================

                Rectangle {
                    Layout.preferredWidth: 260 * root.scale
                    Layout.fillHeight: true
                    radius: 10 * root.scale
                    color: "#FFFFFF"
                    border.color: "#D0D8EC"

                    Column {
                        anchors.fill: parent
                        anchors.margins: 14 * root.scale
                        spacing: 10 * root.scale

                        Text {
                            text: "Details"
                            font.pixelSize: 20 * root.scale
                            font.bold: true
                            color: "#1A4DB5"
                        }

                        Rectangle { width: parent.width; height: 2; color: "#E4EAF5" }

                        Text { text: "Phase : 110";       font.pixelSize: 20 * root.scale; color: "#202020" }
                        Text { text: "Signal : 500";      font.pixelSize: 20 * root.scale; color: "#202020" }
                        Text { text: "Amplitude : 14000"; font.pixelSize: 20 * root.scale; color: "#202020" }
                        Text { text: "Digital Gain : 1";  font.pixelSize: 20 * root.scale; color: "#202020" }
                        Text { text: "Analog Gain : 1";   font.pixelSize: 20 * root.scale; color: "#202020" }
                        Text { text: "DD Frequency : 18"; font.pixelSize: 20 * root.scale; color: "#202020" }
                        Text { text: "DD Power : 50";     font.pixelSize: 20 * root.scale; color: "#202020" }

                        Rectangle { width: parent.width; height: 1; color: "#E4EAF5" }

                        Text {
                            text: "Current Group : " + (currentGroup < 10 ? "0" + currentGroup : currentGroup)
                            font.pixelSize: 18 * root.scale
                            color: "#1A1A1A"
                        }

                        Text {
                            text: "Products : " + currentModel().count + " / 100"
                            font.pixelSize: 18 * root.scale
                            color: "#1A1A1A"
                        }

                        Text {
                            text: "Active SR : " + activeSr
                            font.pixelSize: 18 * root.scale
                            color: "#1A1A1A"
                        }
                    }
                }
            }
        }
    }

    AddProductPopup {
        id: addProductPopup

        parent: Overlay.overlay

        scaleFactor: root.scale

        currentModelRef: currentModel()

        getFreeSrNoFunc: getFreeSrNo
    }
}
