import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Screens
import "screens"

Window {
    id: root
    visible: true
    width: 1024
    height: 600
    title: "Dashboard"
    color: "#F5F7FC"

    // Uncomment for Raspberry Pi fullscreen
    // visibility: Window.FullScreen

    HomeScreen {
        anchors.fill: parent
    }
}
 
