import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../components"

Item {
    id: ddusterScreen
    property bool showTopBar: true
    property var globalTopBar: null

    Rectangle {
        anchors.fill: parent
        color: "#F5F7FC"

        // placeholder content for now
        Text {
            anchors.centerIn: parent
            text: "DDuster Screen (blank placeholder)"
            color: "#1A4DB5"
            font.pixelSize: 26
            font.bold: true
        }
    }
}
