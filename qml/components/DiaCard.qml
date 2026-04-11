// DiagCard.qml
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: card

    property string title: ""
    property string status: "OK"
    property string detail: ""
    property real scale: 1

    radius: 12 * scale
    color: "#FFFFFF"
    border.color: statusColor()
    border.width: 1.5

    function statusColor() {
        if (status === "OK") return "#4CAF50"
        if (status === "Warning") return "#FF9800"
        if (status === "Checking...") return "#2196F3"
        return "#F44336"
    }

    function statusTextColor() {
        if (status === "OK") return "#4CAF50"
        if (status === "Warning") return "#FF9800"
        if (status === "Checking...") return "#2196F3"
        return "#F44336"
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 6 * card.scale

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: card.title
            font.pixelSize: 15 * card.scale
            font.weight: Font.Medium
            color: "#000000"
        }

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: statusLabel.implicitWidth + 20 * card.scale
            height: 24 * card.scale
            radius: 12 * card.scale
            color: card.statusColor()
            opacity: 0.15

            Text {
                id: statusLabel
                anchors.centerIn: parent
                text: card.status
                font.pixelSize: 12 * card.scale
                color: card.statusTextColor()
                opacity: 1 / 0.15
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: card.detail
            font.pixelSize: 11 * card.scale
            color: "#888888"
        }
    }
}
