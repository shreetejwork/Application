import QtQuick
import QtQuick.Controls

Item {
    Typography {
        id: componentTypography
        scale: root.scale || 1.0
    }
    id: root
    anchors.fill: parent

    // Base design size
    property real baseWidth: 1024
    property real baseHeight: 600

    // Responsive scale
    property real scale: Math.max(0.85, Math.min(width / baseWidth, height / baseHeight))
    
    // =========================================================
    // TYPOGRAPHY FOR SETTINGS S6
    // =========================================================
    
    Typography {
        id: s6Typography
        scale: root.scale
    }

    Text {
        text: "Version \n v4.0.1"
        anchors.centerIn: parent

        // Responsive font size
        font.pixelSize: s6Typography.title

        color: "#333"   // change if needed
    }
}
