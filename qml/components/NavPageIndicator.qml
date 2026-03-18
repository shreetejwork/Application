import QtQuick
import QtQuick.Layouts

Item {
    id: root

    // ✅ SAFE SCALE (no visual change)
    property real baseHeight: 60
    property real scale: Math.max(0.6, height / baseHeight)

    property int pageCount: 3
    property int currentPage: 1

    signal previousClicked()
    signal nextClicked()

    property real swipeStartX: 0

    MultiPointTouchArea {
        anchors.fill: parent
        maximumTouchPoints: 1
        onPressed:  { swipeStartX = touchPoints[0].x }
        onReleased: {
            var delta = touchPoints[0].x - swipeStartX

            // ✅ SCALE SAFE SWIPE DISTANCE
            var threshold = 40 * root.scale

            if (delta < -threshold) root.nextClicked()
            else if (delta > threshold) root.previousClicked()
        }
    }

    RowLayout {
        anchors.centerIn: parent

        // ✅ SAFE SPACING
        spacing: Math.max(6, parent.width * 0.04)

        Item {
            width: Math.max(48 * root.scale, root.height * 1.2)
            height: Math.max(48 * root.scale, root.height)

            Rectangle {
                id: leftHighlight
                anchors.fill: parent
                radius: 6 * root.scale
                color: "#1A4DB5"
                opacity: 0
            }

            Text {
                anchors.centerIn: parent
                text: "❮"

                // ✅ SAME DESIGN + SAFE MIN
                font.pixelSize: Math.max(14, root.height * 0.55)
                font.bold: true
                color: "#1A4DB5"
            }

            MultiPointTouchArea {
                anchors.fill: parent
                maximumTouchPoints: 1
                onPressed:  { leftHighlight.opacity = 0.15 }
                onReleased: { leftHighlight.opacity = 0; root.previousClicked() }
                onCanceled: { leftHighlight.opacity = 0 }
            }
        }

        Row {
            spacing: Math.max(4, root.width * 0.025)

            Repeater {
                model: root.pageCount

                Rectangle {
                    width: Math.max(16 * root.scale, root.height * 0.45)
                    height: Math.max(16 * root.scale, root.height * 0.45)
                    radius: width / 2

                    color: index === root.currentPage ? "#1A4DB5" : "transparent"

                    border.color: "#1A4DB5"

                    // ✅ SCALE SAFE BORDER
                    border.width: Math.max(1, root.height * 0.06)
                }
            }
        }

        Item {
            width: Math.max(48 * root.scale, root.height * 1.2)
            height: Math.max(48 * root.scale, root.height)

            Rectangle {
                id: rightHighlight
                anchors.fill: parent
                radius: 6 * root.scale
                color: "#1A4DB5"
                opacity: 0
            }

            Text {
                anchors.centerIn: parent
                text: "❯"

                // ✅ SAME DESIGN + SAFE MIN
                font.pixelSize: Math.max(14, root.height * 0.55)
                font.bold: true
                color: "#1A4DB5"
            }

            MultiPointTouchArea {
                anchors.fill: parent
                maximumTouchPoints: 1
                onPressed:  { rightHighlight.opacity = 0.15 }
                onReleased: { rightHighlight.opacity = 0; root.nextClicked() }
                onCanceled: { rightHighlight.opacity = 0 }
            }
        }
    }
}
