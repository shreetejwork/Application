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
    border.color: statusBorderColor()
    border.width: 1.5 * scale

    function statusBorderColor() {
        if (status === "OK")           return "#4CAF50"
        if (status === "Warning")      return "#FF9800"
        if (status === "Checking...") return "#2196F3"
        return "#F44336"
    }

    function statusBadgeBg() {
        if (status === "OK")           return "#E8F5E9"
        if (status === "Warning")      return "#FFF3E0"
        if (status === "Checking...") return "#E3F2FD"
        return "#FFEBEE"
    }

    function statusTextColor() {
        if (status === "OK")           return "#2E7D32"
        if (status === "Warning")      return "#E65100"
        if (status === "Checking...") return "#1565C0"
        return "#B71C1C"
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 10 * card.scale

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 15 * card.scale
            height: 15 * card.scale
            radius: 8 * card.scale
            color: card.statusBorderColor()
        }

        // Title
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: card.title
            font.pixelSize: 22 * card.scale
            font.weight: Font.Bold
            color: "#1A1A1A"
            horizontalAlignment: Text.AlignHCenter
        }

        // Detail text
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: card.detail
            font.pixelSize: 18 * card.scale
            font.weight: Font.Normal
            color: "#555555"
            horizontalAlignment: Text.AlignHCenter
        }

        // Status badge
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: statusLabel.implicitWidth + 24 * card.scale
            height: 26 * card.scale
            radius: 13 * card.scale
            color: card.statusBadgeBg()

            Text {
                id: statusLabel
                anchors.centerIn: parent
                text: card.status
                font.pixelSize: 16 * card.scale
                font.weight: Font.Medium
                color: card.statusTextColor()
            }
        }
    }
}
