import QtQuick

 Item {
    width: 200
    height: 200

    property string iconSource: ""
    property string label: ""
    property real iconSize: 88
    signal tileClicked()

    Column {
        anchors.centerIn: parent
        spacing: 10

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
            font.pixelSize: 18
            font.bold: true
            color: "#1A1A2E"
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
