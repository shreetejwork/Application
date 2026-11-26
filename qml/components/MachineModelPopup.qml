import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import AppState 1.0

Popup {
    id: root

    property real uiScale: 1
    property string selectedCategory: ""
    property string selectedModel: ""
    property var wrsModels: ["STD", "CLX", "GFMD", "CNMD"]
    property var oemModels: [
        "STD_OEM", "CLX_OEM", "GFMD_OEM", "CNMD_OEM"
    ]

    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape
    parent: Overlay.overlay
    anchors.centerIn: parent
    width: Math.min(parent.width - 32 * uiScale, 560 * uiScale)
    height: Math.min(parent.height - 32 * uiScale, 440 * uiScale)

    function chooseCategory(category, checked) {
        if (checked) {
            selectedCategory = category
            selectedModel = ""
        } else if (selectedCategory === category) {
            selectedCategory = ""
            selectedModel = ""
        }
    }

    function rowsForSelection() {
        var rows = [{ kind: "category", value: "WRS" }]
        if (selectedCategory === "WRS") {
            for (var wrsIndex = 0; wrsIndex < wrsModels.length; ++wrsIndex)
                rows.push({ kind: "model", value: wrsModels[wrsIndex] })
        }

        rows.push({ kind: "category", value: "OEM" })
        if (selectedCategory === "OEM") {
            for (var oemIndex = 0; oemIndex < oemModels.length; ++oemIndex)
                rows.push({ kind: "model", value: oemModels[oemIndex] })
        }
        return rows
    }

    onOpened: {
        var savedModel = GlobalState.machineModel
        if (wrsModels.indexOf(savedModel) !== -1) {
            selectedCategory = "WRS"
            selectedModel = savedModel
        } else if (oemModels.indexOf(savedModel) !== -1) {
            selectedCategory = "OEM"
            selectedModel = savedModel
        } else {
            selectedCategory = ""
            selectedModel = ""
        }
    }

    background: Rectangle {
        radius: 14 * root.uiScale
        color: "#FFFFFF"
        border.color: "#D0D8EC"
        border.width: 1.5
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16 * root.uiScale
        spacing: 10 * root.uiScale

        Text {
            Layout.fillWidth: true
            text: "Machine Model"
            color: "#1A4DB5"
            font.pixelSize: Math.max(20, 25 * root.uiScale)
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            Layout.fillWidth: true
            text: "Choose one machine type and its model."
            color: "#64748B"
            font.pixelSize: Math.max(12, 14 * root.uiScale)
            horizontalAlignment: Text.AlignHCenter
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40 * root.uiScale
            radius: 6 * root.uiScale
            color: "#EAF1FF"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12 * root.uiScale
                anchors.rightMargin: 8 * root.uiScale
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    text: "Machine Type / Model"
                    color: "#294675"
                    font.pixelSize: Math.max(13, 18 * root.uiScale)
                }

                Text {
                    Layout.preferredWidth: 110 * root.uiScale
                    text: "Select"
                    color: "#294675"
                    font.pixelSize: Math.max(13, 18 * root.uiScale)
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        Flickable {
            id: optionsFlickable
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: optionsColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar { }

            Column {
                id: optionsColumn
                width: optionsFlickable.width
                spacing: 3 * root.uiScale

                Repeater {
                    model: root.rowsForSelection()

                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: optionsColumn.width
                        height: (modelData.kind === "category" ? 40 : 36)
                                * root.uiScale
                        radius: 5 * root.uiScale
                        color: modelData.kind === "category"
                               && root.selectedCategory === modelData.value
                               ? "#EAF1FF"
                               : (index % 2 === 0 ? "#F8FAFE" : "#FFFFFF")
                        border.color: "#EDF1F7"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12 * root.uiScale
                            anchors.rightMargin: 8 * root.uiScale
                            spacing: 0

                            Text {
                                Layout.fillWidth: true
                                text: modelData.value
                                color: "#303B50"
                                font.pixelSize: Math.max(12, 17 * root.uiScale)
                            }

                            CheckBox {
                                Layout.preferredWidth: 110 * root.uiScale
                                Layout.alignment: Qt.AlignHCenter
                                checked: modelData.kind === "category"
                                         ? root.selectedCategory === modelData.value
                                         : root.selectedModel === modelData.value
                                onClicked: {
                                    if (modelData.kind === "category") {
                                        root.chooseCategory(modelData.value, checked)
                                    } else {
                                        root.selectedModel =
                                                checked ? modelData.value : ""
                                    }
                                }
                                indicator: Rectangle {
                                    implicitWidth: 22 * root.uiScale
                                    implicitHeight: 22 * root.uiScale
                                    x: (parent.width - width) / 2
                                    y: (parent.height - height) / 2
                                    radius: 4 * root.uiScale
                                    color: parent.checked ? "#1A4DB5" : "#FFFFFF"
                                    border.color: parent.checked
                                                  ? "#1A4DB5" : "#AAB9D2"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "✓"
                                        color: "#FFFFFF"
                                        visible: parent.parent.checked
                                        font.pixelSize: 15 * root.uiScale
                                    }
                                }
                                contentItem: Item { }
                            }
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10 * root.uiScale

            Item { Layout.fillWidth: true }

            Rectangle {
                Layout.preferredWidth: 110 * root.uiScale
                Layout.preferredHeight: 38 * root.uiScale
                radius: 6 * root.uiScale
                color: cancelArea.pressed ? "#EEF4FF" : "#FFFFFF"
                border.color: "#1A4DB5"

                Text {
                    anchors.centerIn: parent
                    text: "Cancel"
                    color: "#1A4DB5"
                    font.pixelSize: Math.max(13, 15 * root.uiScale)
                }

                MouseArea {
                    id: cancelArea
                    anchors.fill: parent
                    onClicked: root.close()
                }
            }

            Rectangle {
                Layout.preferredWidth: 110 * root.uiScale
                Layout.preferredHeight: 38 * root.uiScale
                radius: 6 * root.uiScale
                color: submitArea.enabled
                       ? (submitArea.pressed ? "#163E91" : "#1A4DB5")
                       : "#AAB9D2"

                Text {
                    anchors.centerIn: parent
                    text: "Submit"
                    color: "#FFFFFF"
                    font.pixelSize: Math.max(13, 15 * root.uiScale)
                    font.weight: Font.Medium
                }

                MouseArea {
                    id: submitArea
                    anchors.fill: parent
                    enabled: root.selectedCategory !== ""
                             && root.selectedModel !== ""
                    onClicked: {
                        GlobalState.machineModel = root.selectedModel
                        root.close()
                    }
                }
            }
        }
    }
}
