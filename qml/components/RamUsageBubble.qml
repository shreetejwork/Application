import QtQuick

Rectangle {
    id: root

    property int refreshInterval: 5000

    width: 110
    height: 40
    radius: 10
    color: "#EFFFFFFF"
    border.color: "#331A4DB5"
    border.width: 1
    opacity: 0.88
    z: 9999

    function refreshRam() {
        SystemDiag.update()
    }

    Timer {
        interval: root.refreshInterval
        repeat: true
        running: true
        onTriggered: root.refreshRam()
    }

    Component.onCompleted: refreshRam()

    Column {
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1

        Text {
            text: "RAM USAGE"
            color: "#17243A"
            font.pixelSize: 9

        }

        Text {
            text: SystemDiag.ramUsage
            color: "#17243A"
            font.pixelSize: 13

        }
    }

}
