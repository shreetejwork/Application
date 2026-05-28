import QtQuick
import QtQuick.Layouts

Item {
    Typography {
        id: componentTypography
        scale: root.scale || 1.0
    }
    id: root

    // =====================================================
    // RESPONSIVE SCALE
    // =====================================================

    property real baseHeight: 60

    property real scale:
        Math.max(0.65, height / baseHeight)

    // =====================================================
    // NAVIGATION
    // =====================================================

    property int currentPage: 0

    property var pageNames: []

    property int pageCount: pageNames.length

    signal previousClicked()
    signal nextClicked()
    signal pageSelected(int index)

    // =====================================================
    // SWIPE SUPPORT
    // =====================================================

    property real swipeStartX: 0

    MultiPointTouchArea {

        anchors.fill: parent

        maximumTouchPoints: 1

        onPressed: {
            swipeStartX = touchPoints[0].x
        }

        onReleased: {

            var delta =
                    touchPoints[0].x - swipeStartX

            var threshold =
                    40 * root.scale

            if (delta < -threshold)
                root.nextClicked()

            else if (delta > threshold)
                root.previousClicked()
        }
    }

    // =====================================================
    // MAIN NAV BAR
    // =====================================================

    Rectangle {
        id: navBar

        anchors.centerIn: parent

        // =============================================
        // DYNAMIC WIDTH
        // =============================================

        width:
            Math.min(
                navRow.width + (56 * root.scale),
                parent.width * 0.92)

        height:
            Math.max(
                50 * root.scale,
                parent.height * 0.90)

        color: "#F5F7FC"

        // =============================================
        // CENTERED NAV CONTENT
        // =============================================

        Row {
            id: navRow

            anchors.centerIn: parent

            spacing: 22 * root.scale

            Repeater {
                model: root.pageCount

                delegate: Row {

                    spacing: 22 * root.scale

                    // =====================================
                    // PAGE BUTTON
                    // =====================================

                    Item {
                        id: pageButton

                        width:
                            textItem.implicitWidth
                            + (18 * root.scale)

                        height:
                            navBar.height

                        Column {
                            anchors.centerIn: parent

                            spacing: 7 * root.scale

                            // =============================
                            // PAGE TITLE
                            // =============================

                            Text {
                                id: textItem

                                anchors.horizontalCenter:
                                    parent.horizontalCenter

                                text:
                                    root.pageNames[index]
                                    || ("Page " + (index + 1))

                                font.pixelSize:
                                    Math.max(
                                        15,
                                        15 * root.scale)

                                font.weight:
                                    index === root.currentPage
                                    ? Font.Bold
                                    : Font.DemiBold

                                color:
                                    index === root.currentPage
                                    ? "#1450C8"
                                    : "#7B88A8"

                                horizontalAlignment:
                                    Text.AlignHCenter

                                elide: Text.ElideRight

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 180
                                    }
                                }
                            }

                            // =============================
                            // ACTIVE INDICATOR
                            // =============================

                            Rectangle {

                                anchors.horizontalCenter:
                                    parent.horizontalCenter

                                width:
                                    index === root.currentPage
                                    ? 55 * root.scale
                                    : 8 * root.scale

                                height:
                                    5 * root.scale

                                radius:
                                    height / 2

                                color:
                                    index === root.currentPage
                                    ? "#1450C8"
                                    : "#F5F7FC"

                                Behavior on width {
                                    NumberAnimation {
                                        duration: 220

                                        easing.type:
                                            Easing.OutCubic
                                    }
                                }

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 180
                                    }
                                }
                            }
                        }

                        // =============================
                        // TOUCH
                        // =============================

                        MultiPointTouchArea {

                            anchors.fill: parent

                            maximumTouchPoints: 1

                            onReleased: {

                                root.currentPage = index

                                root.pageSelected(index)
                            }
                        }
                    }

                    // =====================================
                    // SEPARATOR
                    // =====================================

                    Rectangle {

                        visible:
                            index < root.pageCount - 1

                        width:
                            2.5 * root.scale

                        height:
                            26 * root.scale

                        radius:
                            width / 2

                        anchors.verticalCenter:
                            parent.verticalCenter

                        color: "#C7D2E8"

                        opacity: 1
                    }
                }
            }
        }
    }
}
