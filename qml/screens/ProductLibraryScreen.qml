import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic
import QtQuick.Layouts

import "../components"

import AppState 1.0

Item {
    id: root
    anchors.fill: parent

    Rectangle {
        id: dimBackground

        anchors.fill: parent

        color: "black"

        opacity: addProductPopup.visible ? 0.4 : 0.0

        visible: opacity > 0

        z: 998

        Behavior on opacity {
            NumberAnimation {
                duration: 250
            }
        }
    }

    property real baseWidth: 1024
    property real baseHeight: 600
    property real scale: Math.max(0.75, Math.min(width / baseWidth, height / baseHeight))

    // =====================================================
    // PAGE OPEN ANIMATION
    // =====================================================

    opacity: 0.0

    property real pageScale: 0.85

    transform: Scale {
        origin.x: root.width / 2
        origin.y: root.height / 2

        xScale: root.pageScale
        yScale: root.pageScale
    }

    Component.onCompleted: {
        openAnimation.start()
    }

    // =====================================================
    // OPEN
    // =====================================================

    ParallelAnimation {
        id: openAnimation

        NumberAnimation {
            target: root
            property: "opacity"

            from: 0.0
            to: 1.0

            duration: 650

            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: root
            property: "pageScale"

            from: 0.85
            to: 1.0

            duration: 650

            easing.type: Easing.OutBack

            easing.overshoot: 1.05
        }
    }

    // =====================================================
    // CLOSE
    // =====================================================

    ParallelAnimation {
        id: closeAnimation

        NumberAnimation {
            target: root
            property: "opacity"

            from: 1.0
            to: 0.0

            duration: 500

            easing.type: Easing.InOutCubic
        }

        NumberAnimation {
            target: root
            property: "pageScale"

            from: 1.0
            to: 0.85

            duration: 500

            easing.type: Easing.InOutCubic
        }
    }

    function closePage() {
        closeAnimation.start()
    }

    property int currentGroup: 1
    property int activeSr: 1

    property var activeModel: group01Model

    // ===== COLUMN WIDTHS =====

    property real colSpacing: 15 * root.scale

    property real colSelect: 22 * root.scale
    property real colActive: 22 * root.scale
    property real colSr: 100 * root.scale
    property real colCode: 170 * root.scale

    property real colStatus: 80 * root.scale

    property real tableHorizontalMargin: 12 * root.scale
    property real tableSpacing: 14 * root.scale

    property real dynamicNameWidth:
        productList.width
        - (tableHorizontalMargin * 2)
        - (tableSpacing * 4)
        - colSelect
        - colStatus
        - colSr
        - colCode



    // ===== SHARED LAYOUT HELPERS =====

    property real rowFixedSpacing: 16 * root.scale * 3
    property real rowSelectExtra: root.colSelect + 16 * root.scale

    // ===== SELECTION STATE =====

    property int selectedCount: getSelectedCount()

    function getSelectedCount() {

        var model = currentModel()
        var count = 0

        for (var i = 0; i < model.count; i++) {

            if (model.get(i).selected)
                count++
        }

        return count
    }

    function clearSelection() {

        var model = currentModel()

        for (var i = 0; i < model.count; i++) {

            model.setProperty(i, "selected", false)
        }

        selectedCount = 0
    }

    function refreshSelectionCount() {

        selectedCount = getSelectedCount()
    }

    function getSingleSelectedSr() {

        var model = currentModel()

        for (var i = 0; i < model.count; i++) {

            if (model.get(i).selected)
                return model.get(i).sr
        }

        return -1
    }

    function nameColWidth(totalWidth) {

        return totalWidth
                - root.colActive
                - root.colSr
                - root.colCode
                - rowFixedSpacing
                - rowSelectExtra
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

        var model = activeModel

        var srNo = getFreeSrNo(model)

        if (srNo === -1)
            return

        var insertIndex = model.count

        for (var i = 0; i < model.count; i++) {

            if (model.get(i).sr > srNo) {

                insertIndex = i
                break
            }
        }

        model.insert(insertIndex, {
                         selected: false,
                         active: false,
                         sr: srNo,
                         name: "Product " + srNo,
                         code: "PRD-" + currentGroup + "-" + srNo,
                         fixedItem: false
                     })

        refreshSelectionCount()
    }

    function deleteSelectedProducts() {

        var model = currentModel()

        for (var i = model.count - 1; i >= 0; i--) {

            var item = model.get(i)

            if (item.selected && !item.fixedItem) {

                model.remove(i)
            }
        }

        refreshSelectionCount()
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
                    font.pixelSize: 26

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
                            activeModel = currentModel()

                            refreshSelectionCount()
                        }

                        font.pixelSize: 15

                        delegate: ItemDelegate {
                            width: groupCombo.width
                            height: 40 * root.scale

                            background: Rectangle {
                                color: highlighted ? "#E3EDFF" : "#FFFFFF"
                            }

                            contentItem: Text {
                                text: modelData
                                color: highlighted ? "#1A4DB5" : "#2A3550"
                                font.pixelSize: 15
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
                            font.pixelSize: 12
                            color: "#1A4DB5"
                        }

                        contentItem: Text {
                            text: groupCombo.displayText
                            color: "#2A3550"
                            font.pixelSize: 15
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
                        model: ["LOAD", "ADD", "DELETE"]

                        delegate: Rectangle {

                            property bool loadDisabled:
                                modelData === "LOAD"
                                && selectedCount !== 1

                            property bool deleteDisabled:
                                modelData === "DELETE"
                                && selectedCount === 0

                            width: 100 * root.scale
                            height: 38 * root.scale
                            radius: 8 * root.scale

                            color: (loadDisabled || deleteDisabled)
                                   ? "#E4EAF5"
                                   : "#FFFFFF"

                            border.width: 1

                            border.color:
                                modelData === "DELETE"
                                ? "#C62828"
                                : "#1A4DB5"

                            opacity: (loadDisabled || deleteDisabled) ? 0.5 : 1.0

                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                font.pixelSize: 15
                                font.weight: Font.Medium

                                color:
                                    modelData === "DELETE"
                                    ? "#C62828"
                                    : "#1A4DB5"
                            }

                            MouseArea {
                                anchors.fill: parent

                                enabled: !(loadDisabled || deleteDisabled)

                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor

                                onClicked: {

                                    if (modelData === "LOAD") {

                                        var srNo = getSingleSelectedSr()

                                        if (srNo !== -1) {

                                            setActiveProduct(srNo)
                                            clearSelection()
                                        }
                                    }

                                    else if (modelData === "ADD") {

                                        addProductPopup.open()
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

                        // ================= HEADER =================

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

                                anchors.leftMargin: root.tableHorizontalMargin
                                anchors.rightMargin: root.tableHorizontalMargin
                                spacing: root.tableSpacing

                                Item {
                                    Layout.preferredWidth: root.colSelect
                                }

                                Text {
                                    text: "Status"

                                    Layout.preferredWidth: root.colStatus

                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter

                                    color: "#FFFFFF"

                                    font.pixelSize: 18
                                }

                                Text {
                                    text: "SR No"

                                    Layout.preferredWidth: root.colSr

                                    horizontalAlignment: Text.AlignLeft
                                    verticalAlignment: Text.AlignVCenter

                                    color: "#FFFFFF"

                                    font.pixelSize: 18
                                }

                                Text {
                                    text: "Product Name"

                                    Layout.preferredWidth: root.dynamicNameWidth

                                    verticalAlignment: Text.AlignVCenter

                                    color: "#FFFFFF"

                                    font.pixelSize: 18

                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: "Product Code"

                                    Layout.preferredWidth: root.colCode

                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter

                                    color: "#FFFFFF"

                                    font.pixelSize: 18
                                }
                            }
                        }

                        // ================= LIST =================

                        ListView {
                            id: productList

                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            clip: true
                            spacing: 0
                            boundsBehavior: Flickable.StopAtBounds

                            model: activeModel

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

                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    height: 1
                                    color: "#E4EAF5"
                                }

                                RowLayout {
                                    anchors.fill: parent

                                    anchors.leftMargin: root.tableHorizontalMargin
                                    anchors.rightMargin: root.tableHorizontalMargin
                                    spacing: root.tableSpacing

                                    // CHECKBOX

                                    Rectangle {
                                        Layout.preferredWidth: root.colSelect
                                        Layout.preferredHeight: root.colSelect

                                        radius: 4 * root.scale

                                        color: isSelected ? "#1A4DB5" : "#FFFFFF"

                                        border.color: isSelected
                                                      ? "#1A4DB5"
                                                      : "#8BA0CC"

                                        border.width: 1.5

                                        Text {
                                            anchors.centerIn: parent
                                            text: "✓"
                                            visible: isSelected
                                            color: "#FFFFFF"

                                            font.pixelSize: 12
                                        }

                                        MouseArea {
                                            anchors.fill: parent

                                            onClicked: {

                                                currentModel().setProperty(
                                                            index,
                                                            "selected",
                                                            !selected)

                                                refreshSelectionCount()
                                            }
                                        }
                                    }

                                    // STATUS

                                    Rectangle {
                                        Layout.preferredWidth: root.colStatus
                                        Layout.preferredHeight: root.colActive

                                        radius: root.colActive / 2

                                        color: active ? "#1A4DB5" : "#D5DDEE"

                                        Text {
                                            anchors.centerIn: parent
                                            text: active ? "A" : ""
                                            color: "#FFFFFF"

                                            font.pixelSize: 12
                                        }
                                    }

                                    // SR

                                    Text {
                                        text: sr

                                        Layout.preferredWidth: root.colSr

                                        verticalAlignment: Text.AlignVCenter

                                        font.pixelSize: 17
                                        font.weight: active ? Font.Medium : Font.Normal

                                        color: "#2A3550"
                                    }

                                    // PRODUCT NAME

                                    Text {
                                        text: name

                                        Layout.preferredWidth: root.dynamicNameWidth

                                        elide: Text.ElideRight

                                        verticalAlignment: Text.AlignVCenter

                                        font.pixelSize: 17
                                        font.weight: active ? Font.Medium : Font.Normal

                                        color: "#2A3550"
                                    }

                                    // PRODUCT CODE

                                    Rectangle {
                                        Layout.preferredWidth: root.colCode
                                        Layout.preferredHeight: 24 * root.scale

                                        radius: 12 * root.scale

                                        color: active ? "#E8F0FF" : "#EDF1FA"

                                        Text {
                                            anchors.centerIn: parent
                                            text: code

                                            font.pixelSize: 16
                                            font.weight: Font.Medium

                                            color: active ? "#1A4DB5" : "#4A5E8A"
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
                            font.pixelSize: 20

                            color: "#1A4DB5"
                        }

                        Rectangle {
                            width: parent.width
                            height: 2
                            color: "#E4EAF5"
                        }

                        Text { text: "Phase : 110";       font.pixelSize: 20; color: "#202020" }
                        Text { text: "Signal : 500";      font.pixelSize: 20; color: "#202020" }
                        Text { text: "Amplitude : 14000"; font.pixelSize: 20; color: "#202020" }
                        Text { text: "Digital Gain : 1";  font.pixelSize: 20; color: "#202020" }
                        Text { text: "Analog Gain : 1";   font.pixelSize: 20; color: "#202020" }
                        Text { text: "DD Frequency : 18"; font.pixelSize: 20; color: "#202020" }
                        Text { text: "DD Power : 50";     font.pixelSize: 20; color: "#202020" }

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: "#E4EAF5"
                        }

                        Text {
                            text: "Current Group : "
                                  + (currentGroup < 10
                                     ? "0" + currentGroup
                                     : currentGroup)

                            font.pixelSize: 18
                            color: "#1A1A1A"
                        }

                        Text {
                            text: "Products : "
                                  + currentModel().count
                                  + " / 100"

                            font.pixelSize: 18
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

        currentModelRef: activeModel

        getFreeSrNoFunc: getFreeSrNo
    }
}
