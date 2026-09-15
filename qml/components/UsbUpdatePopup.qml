import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: popupRoot
    modal: true
    focus: true
    dim: true
    closePolicy: Popup.NoAutoClose

    property string statusText: "Checking for USB..."
    property int progress: 0
    property bool isRunning: false
    property bool showError: false
    property bool showConfirmation: false
    property string errorText: ""
    property bool canClose: false

    signal startRequested()
    signal cancelRequested()
    signal confirmRequested()
    signal declineRequested()

    function openUpdate() {
        popupRoot.statusText = "Checking for USB..."
        popupRoot.progress = 0
        popupRoot.showError = false
        popupRoot.showConfirmation = false
        popupRoot.errorText = ""
        popupRoot.canClose = false
        popupRoot.open()
        popupRoot.startRequested()
    }

    function showErrorMessage(message) {
        popupRoot.showError = true
        popupRoot.showConfirmation = false
        popupRoot.errorText = message
        popupRoot.canClose = true
        popupRoot.isRunning = false
    }

    function showSuccessConfirmation() {
        popupRoot.showConfirmation = true
        popupRoot.showError = false
        popupRoot.canClose = false
    }

    width: 460
    height: 280
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2

    background: Rectangle {
        color: "#FFFFFF"
        radius: 16
        border.color: "#C8D4F5"
        border.width: 1
    }

    contentItem: ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        Text {
            text: "Software Update"
            color: "#1A4DB5"
            font.pixelSize: 24
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: 32
        }

        Rectangle {
            visible: !showError && !showConfirmation
            Layout.alignment: Qt.AlignHCenter
            width: 64
            height: 64
            radius: 32
            color: "#EEF4FF"

            BusyIndicator {
                anchors.centerIn: parent
                running: popupRoot.isRunning || !popupRoot.showError
                width: 40
                height: 40
            }
        }

        Rectangle {
            visible: showError
            Layout.alignment: Qt.AlignHCenter
            width: 64
            height: 64
            radius: 32
            color: "#FFECEC"

            Text {
                anchors.centerIn: parent
                text: "!"
                font.pixelSize: 34
                font.bold: true
                color: "#D32F2F"
            }
        }

        Text {
            visible: !showConfirmation
            text: popupRoot.statusText
            color: showError ? "#D32F2F" : "#1A1A2E"
            font.pixelSize: 18
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
            elide: Text.ElideRight
        }

        Text {
            visible: showConfirmation
            text: "Application update completed."
            color: "#1A1A2E"
            font.pixelSize: 18
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }

        Text {
            visible: showConfirmation
            text: "Do you want to start the new application?"
            color: "#1A1A2E"
            font.pixelSize: 16
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }

        Rectangle {
            visible: !showConfirmation && !showError
            Layout.fillWidth: true
            Layout.preferredHeight: 10
            radius: 5
            color: "#EAEFF9"

            Rectangle {
                width: (popupRoot.progress / 100) * parent.width
                height: parent.height
                radius: 5
                color: "#1A4DB5"
            }
        }

        Text {
            visible: !showConfirmation && !showError
            text: "Step 1 of 4"
            color: "#51657B"
            font.pixelSize: 12
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
        }

        Text {
            visible: showError
            text: popupRoot.errorText
            color: "#D32F2F"
            font.pixelSize: 16
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }

        RowLayout {
            visible: !showError && !showConfirmation
            Layout.alignment: Qt.AlignHCenter
            spacing: 16

            Button {
                text: "Cancel"
                visible: popupRoot.isRunning
                onClicked: popupRoot.cancelRequested()
            }
        }

        RowLayout {
            visible: showConfirmation
            Layout.alignment: Qt.AlignHCenter
            spacing: 16

            Button {
                text: "YES"
                onClicked: popupRoot.confirmRequested()
            }

            Button {
                text: "NO"
                onClicked: popupRoot.declineRequested()
            }
        }

        Button {
            visible: showError && popupRoot.canClose
            text: "OK"
            Layout.alignment: Qt.AlignHCenter
            onClicked: popupRoot.close()
        }
    }
}
