import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import AppState 1.0

Popup {
    id: root
    property real uiScale: 1
    property var draftPermissions: ({})

    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape
    parent: Overlay.overlay
    anchors.centerIn: parent
    width: Math.min(parent.width - 32 * uiScale, 860 * uiScale)
    height: Math.min(parent.height - 32 * uiScale, 540 * uiScale)

    property var parameters: [
        { id: "machinePhase", name: "Machine Phase" },
        { id: "signalThreshold", name: "Signal Threshold" },
        { id: "amplitudeThreshold", name: "Amplitude Threshold" },
        { id: "lpf", name: "LCF" },
        { id: "hpf", name: "HCF" },
        { id: "filterTaps", name: "Filter Taps" },
        { id: "operateDelay", name: "Operate Delay" },
        { id: "holdDelay", name: "Hold Delay" },
        { id: "relayDelay", name: "Relay Delay" },
        { id: "digitalGain", name: "Digital Gain" },
        { id: "analogGain", name: "Analog Gain" },
        { id: "ddPower", name: "D-Duster Power" },
        { id: "ddFrequency", name: "D-Duster Frequency" },
        { id: "trackingCount", name: "Tracking Count" },
        { id: "trackingThreshold", name: "Tracking Threshold" },
        { id: "trackingTolerance", name: "Tracking Tolerance" },
        { id: "productAdd", name: "Product Library - Add Product" },
        { id: "productLoad", name: "Product Library - Load Product" },
        { id: "productDelete", name: "Product Library - Delete Product" },
        { id: "trackingToggle", name: "AutoLearn - Tracking On / Off" },
        { id: "batchStart", name: "Batch Menu - Batch Start" },
        { id: "batchPauseResume", name: "Batch Menu - Batch Pause / Resume" },
        { id: "batchEnd", name: "Batch Menu - Batch End" },
        { id: "ddToggle", name: "D-Duster - DD On / Off" },
        { id: "auditTrailPdf", name: "Audit Trail - Generate PDF" },
        { id: "batchReportPdf", name: "Batch Report - Generate PDF" },
        { id: "reportFileView", name: "Reports Folder - View File" },
        { id: "reportFileCopyUsb", name: "Reports Folder - Copy to USB" },
        { id: "reportFilePrint", name: "Reports Folder - Print" },
        { id: "reportFileDelete", name: "Reports Folder - Delete File" }
    ]

    function setDraftValue(role, parameterId, allowed) {
        var copy = JSON.parse(JSON.stringify(draftPermissions))
        if (!copy[role])
            copy[role] = {}
        copy[role][parameterId] = allowed
        draftPermissions = copy
    }

    onOpened: {
        try {
            draftPermissions = JSON.parse(GlobalState.parameterAccessJson || "{}")
        } catch (error) {
            console.error("Could not load parameter permissions:", error)
            draftPermissions = ({})
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
            text: "Give User Authority"
            color: "#1A4DB5"
            font.pixelSize: Math.max(20, 25 * root.uiScale)

            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            Layout.fillWidth: true
            text: "Choose which parameters each role can view and change."
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
                    text: "Parameter"
                    color: "#294675"
                    font.pixelSize: Math.max(13, 18 * root.uiScale)

                }

                Text {
                    Layout.preferredWidth: 130 * root.uiScale
                    text: "Supervisor"
                    color: "#294675"
                    font.pixelSize: Math.max(13, 18 * root.uiScale)

                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    Layout.preferredWidth: 110 * root.uiScale
                    text: "Operator"
                    color: "#294675"
                    font.pixelSize: Math.max(13, 18 * root.uiScale)

                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: parameterRows.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { }

            Column {
                id: parameterRows
                width: parent.width
                spacing: 3 * root.uiScale

                Repeater {
                    model: root.parameters

                    delegate: Rectangle {
                        required property var modelData
                        width: parameterRows.width
                        height: 36 * root.uiScale
                        radius: 5 * root.uiScale
                        color: index % 2 === 0 ? "#F8FAFE" : "#FFFFFF"
                        border.color: "#EDF1F7"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12 * root.uiScale
                            anchors.rightMargin: 8 * root.uiScale
                            spacing: 0

                            Text {
                                Layout.fillWidth: true
                                text: modelData.name
                                color: "#303B50"
                                font.pixelSize: Math.max(12, 17 * root.uiScale)
                            }

                            CheckBox {
                                Layout.preferredWidth: 130 * root.uiScale
                                Layout.alignment: Qt.AlignHCenter
                                checked: !!(root.draftPermissions.Supervisor &&
                                            root.draftPermissions.Supervisor[modelData.id])
                                onClicked: root.setDraftValue(
                                               "Supervisor", modelData.id, checked)
                                indicator: Rectangle {
                                    implicitWidth: 22 * root.uiScale
                                    implicitHeight: 22 * root.uiScale
                                    x: (parent.width - width) / 2
                                    y: (parent.height - height) / 2
                                    radius: 4 * root.uiScale
                                    color: parent.checked ? "#1A4DB5" : "#FFFFFF"
                                    border.color: parent.checked ? "#1A4DB5" : "#AAB9D2"

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

                            CheckBox {
                                Layout.preferredWidth: 110 * root.uiScale
                                Layout.alignment: Qt.AlignHCenter
                                checked: !!(root.draftPermissions.Operator &&
                                            root.draftPermissions.Operator[modelData.id])
                                onClicked: root.setDraftValue(
                                               "Operator", modelData.id, checked)
                                indicator: Rectangle {
                                    implicitWidth: 22 * root.uiScale
                                    implicitHeight: 22 * root.uiScale
                                    x: (parent.width - width) / 2
                                    y: (parent.height - height) / 2
                                    radius: 4 * root.uiScale
                                    color: parent.checked ? "#1A4DB5" : "#FFFFFF"
                                    border.color: parent.checked ? "#1A4DB5" : "#AAB9D2"

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
                color: saveArea.pressed ? "#163E91" : "#1A4DB5"

                Text {
                    anchors.centerIn: parent
                    text: "Save"
                    color: "#FFFFFF"
                    font.pixelSize: Math.max(13, 15 * root.uiScale)
                    font.weight: Font.Medium
                }

                MouseArea {
                    id: saveArea
                    anchors.fill: parent
                    onClicked: {
                        GlobalState.parameterAccessJson =
                                JSON.stringify(root.draftPermissions)
                        root.close()
                    }
                }
            }
        }
    }
}
