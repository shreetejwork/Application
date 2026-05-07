import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    anchors.fill: parent

    property real baseWidth: 1024
    property real baseHeight: 600
    property real scale: Math.max(0.75, Math.min(width / baseWidth, height / baseHeight))

    property int currentGroup: 1
    property int activeSr: 1
    property bool selectionMode: false

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
        group01Model,
        group02Model,
        group03Model,
        group04Model,
        group05Model,
        group06Model,
        group07Model,
        group08Model,
        group09Model,
        group10Model
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

        // find first empty SR number
        var srNo = getFreeSrNo(model)

        // no free slot available
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

        // sort model by sr number
        for (var i = 0; i < model.count; i++) {

            for (var j = i + 1; j < model.count; j++) {

                if (model.get(i).sr > model.get(j).sr) {

                    var tempI = {
                        selected: model.get(i).selected,
                        active: model.get(i).active,
                        sr: model.get(i).sr,
                        name: model.get(i).name,
                        code: model.get(i).code,
                        fixedItem: model.get(i).fixedItem
                    }

                    var tempJ = {
                        selected: model.get(j).selected,
                        active: model.get(j).active,
                        sr: model.get(j).sr,
                        name: model.get(j).name,
                        code: model.get(j).code,
                        fixedItem: model.get(j).fixedItem
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

            model.setProperty(
                        i,
                        "active",
                        model.get(i).sr === srNo
                        )
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
                height: 58 * root.scale

                radius: 10 * root.scale

                color: "#E9EEF8"
                border.color: "#D0D8EC"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12 * root.scale
                    anchors.rightMargin: 12 * root.scale

                    spacing: 12 * root.scale

                    // ================= GROUP COMBO =================

                    ComboBox {
                        id: groupCombo

                        Layout.preferredWidth: 210 * root.scale
                        Layout.preferredHeight: 42 * root.scale
                        Layout.alignment: Qt.AlignVCenter

                        model: [
                            "GROUP 01",
                            "GROUP 02",
                            "GROUP 03",
                            "GROUP 04",
                            "GROUP 05",
                            "GROUP 06",
                            "GROUP 07",
                            "GROUP 08",
                            "GROUP 09",
                            "GROUP 10"
                        ]

                        currentIndex: 0

                        onCurrentIndexChanged: {
                            currentGroup = currentIndex + 1
                        }

                        font.pixelSize: 17 * root.scale

                        delegate: ItemDelegate {

                            width: groupCombo.width
                            height: 44 * root.scale

                            background: Rectangle {
                                color: highlighted
                                       ? "#DCE8FF"
                                       : "#FFFFFF"
                            }

                            contentItem: Text {
                                text: modelData

                                color: "#1A1A1A"
                                font.pixelSize: 17 * root.scale
                                font.bold: highlighted

                                verticalAlignment: Text.AlignVCenter

                                leftPadding: 14 * root.scale
                            }
                        }

                        indicator: Text {
                            text: "▼"

                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right
                            anchors.rightMargin: 14 * root.scale

                            font.pixelSize: 14 * root.scale
                            color: "#1A4DB5"
                        }

                        contentItem: Text {
                            text: groupCombo.displayText

                            color: "#1A1A1A"

                            font.pixelSize: 17 * root.scale
                            font.bold: true

                            verticalAlignment: Text.AlignVCenter

                            leftPadding: 14 * root.scale
                            rightPadding: 34 * root.scale
                        }

                        background: Rectangle {
                            radius: 8 * root.scale

                            color: "#FFFFFF"

                            border.width: 2
                            border.color: groupCombo.popup.visible
                                          ? "#1A4DB5"
                                          : "#B8C6E3"
                        }

                        popup: Popup {

                            y: groupCombo.height + 4 * root.scale

                            width: groupCombo.width

                            padding: 0

                            background: Rectangle {
                                radius: 8 * root.scale
                                color: "#FFFFFF"
                                border.color: "#B8C6E3"
                            }

                            contentItem: ListView {
                                clip: true

                                implicitHeight: contentHeight

                                model: groupCombo.popup.visible
                                       ? groupCombo.delegateModel
                                       : null

                                currentIndex: groupCombo.highlightedIndex
                            }
                        }
                    }

                    // ================= SPACER =================

                    Item {
                        Layout.fillWidth: true
                    }

                    // ================= BUTTONS =================

                    Repeater {

                        model: ["LOAD", "ADD", "SELECT", "DELETE"]

                        delegate: Rectangle {

                            Layout.preferredWidth: 110 * root.scale
                            Layout.preferredHeight: 38 * root.scale
                            Layout.alignment: Qt.AlignVCenter

                            radius: 8 * root.scale

                            color: modelData === "SELECT" && selectionMode
                                   ? "#1A4DB5"
                                   : "#FFFFFF"

                            border.width: 2
                            border.color: "#1A4DB5"

                            MouseArea {
                                anchors.fill: parent

                                onClicked: {

                                    if (modelData === "ADD") {
                                        addProduct()
                                    }
                                    else if (modelData === "SELECT") {
                                        selectionMode = !selectionMode
                                    }
                                    else if (modelData === "DELETE") {
                                        deleteSelectedProducts()
                                    }
                                }
                            }

                            Text {
                                anchors.centerIn: parent

                                text: modelData

                                font.pixelSize: 16 * root.scale
                                font.bold: true

                                color: modelData === "SELECT" && selectionMode
                                       ? "#FFFFFF"
                                       : "#1A4DB5"
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

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10 * root.scale
                                spacing: 8 * root.scale

                                Text {
                                    visible: selectionMode
                                    text: "Sel"
                                    Layout.preferredWidth: 50 * root.scale
                                    color: "white"
                                    font.bold: true
                                    font.pixelSize: 18 * root.scale
                                }

                                Text {
                                    text: "Active"
                                    Layout.preferredWidth: 70 * root.scale
                                    color: "white"
                                    font.bold: true
                                    font.pixelSize: 18 * root.scale
                                }

                                Text {
                                    text: "Gr"
                                    Layout.preferredWidth: 60 * root.scale
                                    color: "white"
                                    font.bold: true
                                    font.pixelSize: 18 * root.scale
                                }

                                Text {
                                    text: "Sr No"
                                    Layout.preferredWidth: 80 * root.scale
                                    color: "white"
                                    font.bold: true
                                    font.pixelSize: 18 * root.scale
                                }

                                Text {
                                    text: "Product Name"
                                    Layout.preferredWidth: 260 * root.scale
                                    color: "white"
                                    font.bold: true
                                    font.pixelSize: 18 * root.scale
                                }

                                Text {
                                    text: "Product Code"
                                    Layout.preferredWidth: 220 * root.scale
                                    color: "white"
                                    font.bold: true
                                    font.pixelSize: 18 * root.scale
                                }
                            }
                        }

                        // ================= LIST =================

                        ListView {
                            id: productList

                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            clip: true
                            spacing: 2 * root.scale

                            model: currentModel()

                            delegate: Rectangle {

                                width: productList.width
                                height: 44 * root.scale

                                color: active
                                       ? "#DCE8FF"
                                       : (index % 2 === 0
                                          ? "#FFFFFF"
                                          : "#F4F7FF")

                                border.width: active ? 2 : 0
                                border.color: "#1A4DB5"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10 * root.scale
                                    spacing: 8 * root.scale

                                    // ================= SELECT =================

                                    Item {
                                        visible: selectionMode
                                        Layout.preferredWidth: 50 * root.scale
                                        Layout.fillHeight: true

                                        CheckBox {
                                            anchors.centerIn: parent

                                            enabled: !fixedItem
                                            checked: selected

                                            onCheckedChanged: {

                                                currentModel().setProperty(
                                                            index,
                                                            "selected",
                                                            checked
                                                            )
                                            }
                                        }
                                    }

                                    // ================= ACTIVE =================

                                    Rectangle {
                                        Layout.preferredWidth: 22 * root.scale
                                        Layout.preferredHeight: 22 * root.scale

                                        radius: 11 * root.scale

                                        color: active
                                               ? "#1A4DB5"
                                               : "#D0D8EC"

                                        Text {
                                            anchors.centerIn: parent
                                            text: active ? "A" : ""
                                            color: "white"
                                            font.bold: true
                                            font.pixelSize: 12 * root.scale
                                        }
                                    }

                                    // ================= GROUP =================

                                    Text {
                                        text: currentGroup < 10
                                              ? "0" + currentGroup
                                              : currentGroup

                                        Layout.preferredWidth: 60 * root.scale
                                        font.pixelSize: 18 * root.scale
                                    }

                                    // ================= SR =================

                                    Text {
                                        text: sr
                                        Layout.preferredWidth: 80 * root.scale
                                        font.pixelSize: 18 * root.scale
                                        font.bold: active
                                    }

                                    // ================= NAME =================

                                    Text {
                                        text: name
                                        Layout.preferredWidth: 260 * root.scale
                                        font.pixelSize: 18 * root.scale
                                        font.bold: active
                                        elide: Text.ElideRight
                                    }

                                    // ================= CODE =================

                                    Text {
                                        text: code
                                        Layout.preferredWidth: 220 * root.scale
                                        font.pixelSize: 18 * root.scale
                                        font.bold: active
                                        elide: Text.ElideRight
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent

                                    enabled: !selectionMode

                                    onClicked: {
                                        setActiveProduct(sr)
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

                        Rectangle {
                            width: parent.width
                            height: 2
                            color: "#E4EAF5"
                        }

                        Text {
                            text: "Phase : 110"
                            font.pixelSize: 20 * root.scale
                            color: "#202020"
                        }

                        Text {
                            text: "Signal : 500"
                            font.pixelSize: 20 * root.scale
                            color: "#202020"
                        }

                        Text {
                            text: "Amplitude : 14000"
                            font.pixelSize: 20 * root.scale
                            color: "#202020"
                        }

                        Text {
                            text: "Digital Gain : 1"
                            font.pixelSize: 20 * root.scale
                            color: "#202020"
                        }

                        Text {
                            text: "Analog Gain : 1"
                            font.pixelSize: 20 * root.scale
                            color: "#202020"
                        }

                        Text {
                            text: "DD Frequency : 18"
                            font.pixelSize: 20 * root.scale
                            color: "#202020"
                        }

                        Text {
                            text: "DD Power : 50"
                            font.pixelSize: 20 * root.scale
                            color: "#202020"
                        }

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

                            font.pixelSize: 18 * root.scale
                            color: "#1A1A1A"
                        }

                        Text {
                            text: "Products : "
                                  + currentModel().count
                                  + " / 100"

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
}
