import QtQuick

Rectangle {
    id: root

    property Item boundary
    property real edgePadding: 12
    property int refreshInterval: 1000
    property real nearestEdge: 0

    width: 130
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

    function snapToNearestEdge() {
        if (!boundary)
            return

        var leftDistance = x
        var rightDistance = boundary.width - width - x
        var topDistance = y
        var bottomDistance = boundary.height - height - y
        var nearest = Math.min(leftDistance, rightDistance,
                               topDistance, bottomDistance)

        if (nearest === leftDistance)
            x = edgePadding
        else if (nearest === rightDistance)
            x = boundary.width - width - edgePadding
        else if (nearest === topDistance)
            y = edgePadding
        else
            y = boundary.height - height - edgePadding
    }

    Timer {
        interval: root.refreshInterval
        repeat: true
        running: true
        onTriggered: root.refreshRam()
    }

    Component.onCompleted: refreshRam()

    Rectangle {
        width: 4
        height: parent.height - 16
        radius: 2
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        color: "#1A4DB5"
        opacity: 0.85
    }

    Column {
        anchors.left: parent.left
        anchors.leftMargin: 20
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1

        Text {
            text: "RAM USAGE"
            color: "#687386"
            font.pixelSize: 9

        }

        Text {
            text: SystemDiag.ramUsage
            color: "#17243A"
            font.pixelSize: 13

        }
    }

    MouseArea {
        anchors.fill: parent
        drag.target: root
        drag.minimumX: 0
        drag.maximumX: root.boundary ? root.boundary.width - root.width : 0
        drag.minimumY: 0
        drag.maximumY: root.boundary ? root.boundary.height - root.height : 0
        onReleased: root.snapToNearestEdge()
    }
}
