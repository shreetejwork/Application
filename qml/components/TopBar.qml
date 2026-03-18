import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    color: "#1A4DB5"

    // Notification (single banner; auto-hides after 5s)
    property string notificationText: ""
    property bool notificationVisible: false

    Timer {
        id: notificationTimer
        interval: 5000
        repeat: false
        onTriggered: root.notificationVisible = false
    }

    function showNotification(msg) {
        root.notificationText = (msg || "").toString()
        root.notificationVisible = root.notificationText.length > 0
        notificationTimer.restart()
    }

    property real baseHeight: 90
    property real scale: Math.max(0.6, height / baseHeight)

    property string userName: "Supervisor11"
    property string userRole: "Admin"

    signal bellClicked()

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: parent.width * 0.001
        anchors.rightMargin: parent.width * 0.02
        spacing: Math.max(6, root.width * 0.01)

        //  LEFT (TIME + BELL + MENU)
        Item {
            id: timeBlock
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: Math.min(root.width * 0.45, leftCluster.implicitWidth + root.width * 0.02)

            property string currentTime: ""
            property string currentDate: ""

            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: {
                    var now = new Date()
                    timeBlock.currentTime = Qt.formatTime(now, "HH:mm:ss")
                    timeBlock.currentDate = Qt.formatDate(now, "dd MMM yyyy")
                }
            }

            Row {
                id: leftCluster
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: root.width * 0.01

                spacing: Math.max(10 * root.scale, root.width * 0.015)

                Column {
                    spacing: Math.max(4, root.height * 0.02)

                    Text {
                        text: timeBlock.currentTime
                        color: "white"
                        font.pixelSize: Math.max(12, root.height * 0.30)
                        font.bold: true
                    }

                    Text {
                        text: timeBlock.currentDate
                        color: "white"
                        font.pixelSize: Math.max(10, root.height * 0.25)
                        opacity: 0.9
                    }
                }

                //  BELL BUTTON
                Item {
                    id: bellButton
                    width: Math.max(28 * root.scale, root.height * 0.55)
                    height: root.height * 0.50
                    anchors.verticalCenter: parent.verticalCenter

                    Image {
                        anchors.centerIn: parent
                        source: "qrc:/qt/qml/Application/assets/images/Bell.png"
                        width: parent.width
                        height: parent.height
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.bellClicked()
                    }
                }

                //  MENU BUTTON
                Item {
                    id: menuButton
                    width: Math.max(28 * root.scale, root.height * 0.55)
                    height: root.height * 0.50
                    anchors.verticalCenter: parent.verticalCenter

                    Image {
                        anchors.centerIn: parent
                        source: "qrc:/qt/qml/Application/assets/images/Menu.png"
                        width: parent.width
                        height: parent.height
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }
                }
            }

            Component.onCompleted: {
                var now = new Date()
                timeBlock.currentTime = Qt.formatTime(now, "HH:mm:ss")
                timeBlock.currentDate = Qt.formatDate(now, "dd MMM yyyy")
            }
        }

        //  CENTER (NOTIFICATION BAR - SAME DESIGN)
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Item {
                anchors.centerIn: parent
                width: parent.width * 0.65
                height: parent.height * 0.75

                Rectangle {
                    id: notificationBanner
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: Math.max(34, root.height * 0.28)
                    radius: 8
                    color: "#2C63D6"
                    border.color: "#80FFFFFF"
                    border.width: 1
                    opacity: root.notificationVisible ? 1 : 0
                    visible: opacity > 0

                    Behavior on opacity { NumberAnimation { duration: 220 } }

                    Text {
                        anchors.fill: parent
                        anchors.margins: Math.max(8, root.height * 0.08)
                        text: root.notificationText
                        color: "white"
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: Math.max(12, root.height * 0.20)
                        font.bold: true
                    }
                }

                Rectangle {
                    id: bottomLine
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: Math.max(1, 2 * root.scale)
                    color: "#80FFFFFF"
                }
            }
        }

        //  RIGHT SIDE (USER + COUNTDOWN + POWER)
        RowLayout {
            Layout.fillHeight: true
            spacing: Math.max(6, root.width * 0.012)

            RowLayout {
                spacing: Math.max(4, root.width * 0.008)
                Layout.alignment: Qt.AlignVCenter

                Image {
                    source: "qrc:/qt/qml/Application/assets/images/User.png"
                    Layout.preferredWidth: root.height * 0.55
                    Layout.preferredHeight: root.height * 0.55
                    Layout.alignment: Qt.AlignVCenter
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }

                ColumnLayout {
                    spacing: Math.max(2, root.height * 0.01)
                    Layout.alignment: Qt.AlignVCenter

                    Rectangle {
                        Layout.preferredHeight: root.height * 0.26
                        Layout.preferredWidth: roleText.implicitWidth + root.width * 0.01
                        radius: root.height * 0.05
                        color: "#2C63D6"

                        Text {
                            id: roleText
                            anchors.centerIn: parent
                            text: root.userRole
                            color: "white"
                            font.pixelSize: Math.max(8, root.height * 0.16)
                            font.bold: true
                        }
                    }

                    Text {
                        id: userNameText

                        property bool showFullName: false

                        text: userNameText.showFullName
                              ? root.userName
                              : (root.userName.length > 8
                                 ? root.userName.substring(0, 8) + "..."
                                 : root.userName)

                        color: "white"
                        font.pixelSize: Math.max(10, root.height * 0.34)
                        font.bold: true

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                userNameText.showFullName = true
                                resetTimer.restart()
                            }
                        }

                        Timer {
                            id: resetTimer
                            interval: 5000
                            repeat: false
                            onTriggered: userNameText.showFullName = false
                        }
                    }
                }
            }

            //  COUNTDOWN CIRCLE
            Rectangle {
                id: countdownCircle

                width: Math.max(48 * root.scale, root.height * 0.60)
                height: Math.max(48 * root.scale, root.height * 0.60)
                radius: width / 2

                color: "transparent"
                border.color: "white"
                border.width: Math.max(1, root.height * 0.038)

                property int remainingSeconds: 180
                property bool blink: false

                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    onTriggered: if (countdownCircle.remainingSeconds > 0)
                                     countdownCircle.remainingSeconds--
                }

                Timer {
                    interval: 400
                    repeat: true
                    running: countdownCircle.remainingSeconds <= 20
                    onTriggered: countdownCircle.blink = !countdownCircle.blink
                }

                Text {
                    anchors.centerIn: parent
                    text: countdownCircle.remainingSeconds
                    color: "white"

                    opacity: countdownCircle.remainingSeconds <= 20
                             ? (countdownCircle.blink ? 0.2 : 1)
                             : 1

                    font.pixelSize: Math.max(10, root.height * 0.26)
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: countdownCircle.remainingSeconds = 180
                }
            }

            //  POWER BUTTON
            Item {
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: root.width * 0.01
                Layout.preferredWidth: root.height * 0.65
                Layout.preferredHeight: root.height * 0.65

                Image {
                    anchors.fill: parent
                    source: "qrc:/qt/qml/Application/assets/images/PowerOff.png"
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: console.log("Power button clicked")
                }
            }
        }
    }
}
