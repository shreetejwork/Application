import QtQuick

 Item {
    property real uiScale: 1

    width: 200 * uiScale
    height: 200 * uiScale

    property string iconSource: ""
    property string label: ""
    property real iconSize: 88
    signal tileClicked()

    Column {
        anchors.centerIn: parent
        spacing: 10 * parent.uiScale

        Image {
            width: iconSize
            height: iconSize
            anchors.horizontalCenter: parent.horizontalCenter


            source: iconSource

            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true

            scale: tileMouseArea.containsPress ? 0.92 : 1.0
            Behavior on scale {
                NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
            }
        }

        Text {
            text: label
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: Math.max(16, 18 * parent.parent.uiScale)
            color: "#000000"
            horizontalAlignment: Text.AlignHCenter
        }
    }

    MouseArea {
        id: tileMouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: tileClicked()
    }
}
