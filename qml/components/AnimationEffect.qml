import QtQuick

Item {
    id: root

    anchors.fill: parent

    // =====================================================
    // CONTENT HOLDER
    // =====================================================

    default property alias contentData: contentRoot.data

    // =====================================================
    // SETTINGS
    // =====================================================

    property real startScale: 0.0

    property int openDuration: 350
    property int closeDuration: 280

    // =====================================================
    // ANIMATION STATE
    // =====================================================

    opacity: 0.0

    property real pageScale: startScale

    transform: Scale {
        origin.x: root.width / 2
        origin.y: root.height / 2

        xScale: root.pageScale
        yScale: root.pageScale
    }

    // =====================================================
    // CONTENT ROOT
    // =====================================================

    Item {
        id: contentRoot
        anchors.fill: parent
    }

    // =====================================================
    // OPEN ANIMATION
    // =====================================================

    Component.onCompleted: {
        openAnimation.start()
    }

    ParallelAnimation {
        id: openAnimation

        NumberAnimation {
            target: root
            property: "opacity"

            from: 0.0
            to: 1.0

            duration: root.openDuration

            easing.type: Easing.OutQuad
        }

        NumberAnimation {
            target: root
            property: "pageScale"

            from: root.startScale
            to: 1.0

            duration: root.openDuration

            easing.type: Easing.OutBack
        }
    }

    // =====================================================
    // CLOSE ANIMATION
    // =====================================================

    ParallelAnimation {
        id: closeAnimation

        NumberAnimation {
            target: root
            property: "opacity"

            from: 1.0
            to: 0.0

            duration: root.closeDuration

            easing.type: Easing.InQuad
        }

        NumberAnimation {
            target: root
            property: "pageScale"

            from: 1.0
            to: root.startScale

            duration: root.closeDuration

            easing.type: Easing.InQuad
        }
    }

    // =====================================================
    // FUNCTIONS
    // =====================================================

    function closePage() {
        closeAnimation.start()
    }
}
