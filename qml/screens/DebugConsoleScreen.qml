import QtQuick
import QtQuick.Controls

import AppState 1.0
import Backend 1.0

import "../components"

Item {
    id: root
    anchors.fill: parent

    property real baseWidth:  1024
    property real baseHeight: 600
    property real scale: Math.min(width / baseWidth, height / baseHeight)

    // =====================================================
    // STATIC BACKDROP
    // =====================================================

    Rectangle {
        id: backdrop
        anchors.fill: parent
        color: "#F5F7FC"
    }

    // =====================================================
    // PAGE OPEN ANIMATION
    // =====================================================

    Component.onCompleted: {
        openAnimation.start()
    }

    // =====================================================
    // OPEN
    // =====================================================

    ParallelAnimation {
        id: openAnimation

        NumberAnimation {
            target: content
            property: "opacity"

            from: 0.0
            to: 1.0

            duration: 650

            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: content
            property: "pageScale"

            from: 0.85
            to: 1.0

            duration: 650

            easing.type: Easing.OutBack

            easing.overshoot: 1.05
        }
    }

    // =====================================================
    // CLOSE
    // =====================================================

    ParallelAnimation {
        id: closeAnimation

        NumberAnimation {
            target: content
            property: "opacity"

            from: 1.0
            to: 0.0

            duration: 500

            easing.type: Easing.InOutCubic
        }

        NumberAnimation {
            target: content
            property: "pageScale"

            from: 1.0
            to: 0.85

            duration: 500

            easing.type: Easing.InOutCubic
        }
    }

    function closePage() {
        closeAnimation.start()
    }

    // function injected from Main.qml
    property var navigateTo

    Item {
        id: content
        anchors.fill: parent

        opacity: 0.0
        property real pageScale: 0.85

        transform: Scale {
            origin.x: content.width / 2
            origin.y: content.height / 2

            xScale: content.pageScale
            yScale: content.pageScale
        }

        Rectangle {
            anchors.fill: parent
            color: "#F5F7FC"

            Text {
                id: title

                text: "UART Debug Console"

                anchors.left: parent.left
                anchors.top: parent.top

                anchors.leftMargin: 25
                anchors.topMargin: 20

                font.pixelSize: 24

                color: "#1A4DB5"
            }

            Rectangle {

                width: 110
                height: 38

                anchors.right: parent.right
                anchors.rightMargin: 25

                anchors.verticalCenter: title.verticalCenter

                radius: 6

                color: "#E53935"

                Text {
                    anchors.centerIn: parent
                    text: "Clear Console"
                    color: "white"
                    font.pixelSize: 18
                }

                MouseArea {

                    anchors.fill: parent

                    onClicked: SerialManager.clearAllLogs()
                }
            }

            Rectangle {

                id: rxPanel

                anchors.left: parent.left
                anchors.top: title.bottom
                anchors.bottom: parent.bottom

                anchors.leftMargin: 25
                anchors.topMargin: 20
                anchors.bottomMargin: 20

                width: parent.width * 0.62

                radius: 10

                color: "white"

                border.width: 1
                border.color: "#D8DDE8"

                Rectangle {

                    width: parent.width
                    height: 42

                    color: "#1A4DB5"

                    radius: 10

                    Rectangle{
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 10
                        color:"#1A4DB5"
                    }

                    Text{
                        anchors.centerIn: parent
                        text:"Received (RX)"
                        color:"white"
                        font.pixelSize:18

                    }
                }

                Flickable {

                    id: rxFlick

                    anchors.top: parent.top
                    anchors.topMargin: 45

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom

                    clip: true

                    contentWidth: width
                    contentHeight: rxText.height + 20

                    boundsBehavior: Flickable.StopAtBounds

                    Text {

                        id: rxText

                        width: rxFlick.width - 20

                        x: 10
                        y: 10

                        text: SerialManager.rawRxLog

                        font.family: "Courier New"
                        font.pixelSize: 24

                        wrapMode: Text.WrapAnywhere

                        color: "#222"

                        onTextChanged: {

                            rxFlick.contentY =
                                    Math.max(0,
                                             rxFlick.contentHeight
                                             - rxFlick.height)
                        }
                    }
                }
            }

            Rectangle{

                id:txPanel

                anchors.right: parent.right
                anchors.top: title.bottom
                anchors.bottom: parent.bottom

                anchors.rightMargin:25
                anchors.topMargin:20
                anchors.bottomMargin:20

                width: parent.width * 0.30

                radius:10

                color:"white"

                border.width:1
                border.color:"#D8DDE8"

                Rectangle{

                    width: parent.width
                    height:42

                    color:"#1A4DB5"

                    radius:10

                    Rectangle{
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height:10
                        color:"#1A4DB5"
                    }

                    Text{
                        anchors.centerIn: parent
                        text:"Transmitted (TX)"
                        color:"white"
                        font.pixelSize:18
                    }
                }

                Flickable {

                    id: txFlick

                    anchors.top: parent.top
                    anchors.topMargin: 45

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom

                    clip: true

                    contentWidth: width
                    contentHeight: txText.height + 20

                    boundsBehavior: Flickable.StopAtBounds

                    Text {

                        id: txText

                        width: txFlick.width - 20

                        x: 10
                        y: 10

                        text: SerialManager.rawTxLog

                        font.family: "Courier New"
                        font.pixelSize: 24

                        wrapMode: Text.WrapAnywhere

                        color: "#222"

                        onTextChanged: {

                            txFlick.contentY =
                                    Math.max(0,
                                             txFlick.contentHeight
                                             - txFlick.height)
                        }
                    }
                }
            }
        }
    }
}
