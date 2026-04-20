import QtQuick
import QtQuick.Controls

Item {
    id: root
    anchors.fill: parent

    // Base design size
    property real baseWidth: 1024
    property real baseHeight: 600

    // Responsive scale
    property real scale: Math.max(0.85, Math.min(width / baseWidth, height / baseHeight))

    Text {
        text: "Version \n v4.0.1"
        anchors.centerIn: parent

        // Responsive font size
        font.pixelSize: 30 * root.scale

        color: "#333"   // change if needed
    }
}


