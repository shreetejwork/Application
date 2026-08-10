
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import AppState 1.0

Item {
    id: root
    anchors.fill: parent

    property var navigateTo

    property real baseWidth: 1024
    property real baseHeight: 600
    property real scale: Math.min(width / baseWidth,
                                  height / baseHeight)

    // =====================================================
    // COLUMN WIDTHS
    // =====================================================

    property real colSpacing: 16 * scale

    property real colSr:    80  * scale
    property real colBatch: 420 * scale
    property real colDate:  220 * scale
    property real colBy:    220 * scale


    // =====================================================
    // LOAD REAL BATCH HISTORY
    // =====================================================

    function loadBatchHistory()
    {
        batchHistoryModel.clear()

        var reports = databaseManager.getBatchReports()

        if (!reports || reports.length === 0)
            return

        for (var i = 0; i < reports.length; i++)
        {
            var r = reports[i]

            batchHistoryModel.append({
                batchName: r.batch ? r.batch : "---",

                generatedOn: r.started
                        ? r.started
                        : "---",

                generatedBy: r.startedBy
                        ? r.startedBy
                        : "System"
            })
        }
    }


    // =====================================================
    // CLEAR ALL BATCH HISTORY
    // =====================================================

    function clearBatchHistory()
    {
        // =====================================================
        // DELETE FROM SQLITE DATABASE FIRST
        // =====================================================

        var success = databaseManager.deleteAllBatchReports()

        if (!success)
        {
            console.log("Failed to clear batch history from database")
            return
        }


        // =====================================================
        // DATABASE DELETE SUCCESSFUL
        // NOW CLEAR QML MODEL
        // =====================================================

        batchHistoryModel.clear()

        console.log("Batch history permanently deleted")
    }




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

        loadBatchHistory()

        openAnimation.start()
    }


    // =====================================================
    // OPEN ANIMATION
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
    // CLOSE ANIMATION
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


    function closePage()
    {
        closeAnimation.start()
    }


    // =====================================================
    // REAL BATCH HISTORY MODEL
    // =====================================================

    ListModel {
        id: batchHistoryModel
    }


    // =====================================================
    // MAIN CONTENT
    // =====================================================

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


            // =================================================
            // MAIN LAYOUT
            // =================================================

            ColumnLayout {

                anchors.fill: parent

                anchors.margins: 24 * root.scale

                spacing: 16 * root.scale


                // =================================================
                // HEADER
                // =================================================

                Column {

                    spacing: 6 * root.scale


                    Text {
                        text: "Batch History"

                        font.pixelSize: 26

                        color: "#1A4DB5"
                    }


                    Rectangle {
                        width: 80 * root.scale

                        height: 4 * root.scale

                        radius: 2 * root.scale

                        color: "#1A4DB5"
                    }
                }


                // =================================================
                // CLEAR DATA BAR
                // =================================================

                RowLayout {

                    Layout.fillWidth: true

                    spacing: 10 * root.scale


                    // Push Clear Data button to the right
                    Item {
                        Layout.fillWidth: true
                    }


                    // =================================================
                    // CLEAR DATA BUTTON
                    // =================================================

                    Rectangle {

                        Layout.preferredWidth: 130 * root.scale
                        Layout.preferredHeight: 38 * root.scale

                        visible: GlobalState.developerLogin

                        radius: 6 * root.scale

                        color: clearDataMouse.pressed
                               ? "#D32F2F"
                               : "#FFFFFF"

                        border.color: "#D32F2F"
                        border.width: 1


                        Text {
                            anchors.centerIn: parent

                            text: "Clear Data"

                            font.pixelSize: 18
                            font.weight: Font.Medium

                            color: clearDataMouse.pressed
                                   ? "#FFFFFF"
                                   : "#D32F2F"
                        }


                        MouseArea {

                            id: clearDataMouse

                            anchors.fill: parent

                            cursorShape: Qt.PointingHandCursor

                            onClicked: {

                                if (batchHistoryModel.count === 0)
                                {
                                    console.log("No batch history to delete")
                                    return
                                }

                                root.clearBatchHistory()
                            }
                        }
                    }
                }


                // =================================================
                // TABLE
                // =================================================

                Rectangle {

                    Layout.fillWidth: true

                    Layout.fillHeight: true

                    radius: 10 * root.scale

                    color: "#FFFFFF"

                    border.color: "#D0D8EC"

                    border.width: 1

                    clip: true


                    ColumnLayout {

                        anchors.fill: parent

                        spacing: 0


                        // =================================================
                        // TABLE HEADER
                        // =================================================

                        Rectangle {

                            Layout.fillWidth: true

                            height: 52 * root.scale

                            color: "#1A4DB5"

                            radius: 10 * root.scale


                            Rectangle {

                                anchors.left: parent.left

                                anchors.right: parent.right

                                anchors.bottom: parent.bottom

                                height: 10 * root.scale

                                color: "#1A4DB5"
                            }


                            Row {

                                anchors.fill: parent

                                anchors.margins: 12 * root.scale

                                spacing: root.colSpacing


                                Text {

                                    text: "Sr No."

                                    width: root.colSr

                                    height: parent.height

                                    font.pixelSize: 20

                                    color: "#FFFFFF"

                                    verticalAlignment:
                                        Text.AlignVCenter
                                }


                                Text {

                                    text: "Batch Name / ID"

                                    width: root.colBatch

                                    height: parent.height

                                    font.pixelSize: 20

                                    color: "#FFFFFF"

                                    verticalAlignment:
                                        Text.AlignVCenter
                                }


                                Text {

                                    text: "Generated On"

                                    width: root.colDate

                                    height: parent.height

                                    font.pixelSize: 20

                                    color: "#FFFFFF"

                                    verticalAlignment:
                                        Text.AlignVCenter
                                }


                                Text {

                                    text: "Generated By"

                                    width: root.colBy

                                    height: parent.height

                                    font.pixelSize: 20

                                    color: "#FFFFFF"

                                    verticalAlignment:
                                        Text.AlignVCenter
                                }
                            }
                        }


                        // =================================================
                        // TABLE DATA
                        // =================================================

                        ListView {

                            id: tableList

                            Layout.fillWidth: true

                            Layout.fillHeight: true

                            clip: true

                            spacing: 0

                            model: batchHistoryModel


                            delegate: Rectangle {

                                width: ListView.view.width

                                height: 56 * root.scale

                                color: index % 2 === 0
                                       ? "#FFFFFF"
                                       : "#F4F7FF"


                                Rectangle {

                                    anchors.left: parent.left

                                    anchors.right: parent.right

                                    anchors.bottom: parent.bottom

                                    height: 1

                                    color: "#E4EAF5"
                                }


                                Row {

                                    anchors.fill: parent

                                    anchors.leftMargin:
                                        12 * root.scale

                                    anchors.rightMargin:
                                        12 * root.scale

                                    spacing: root.colSpacing


                                    Text {

                                        text: index + 1

                                        width: root.colSr

                                        height: parent.height

                                        font.pixelSize: 18

                                        color: "#3A3A3A"

                                        verticalAlignment:
                                            Text.AlignVCenter
                                    }


                                    Text {

                                        text: batchName

                                        width: root.colBatch

                                        height: parent.height

                                        font.pixelSize: 18

                                        color: "#1A4DB5"

                                        font.weight:
                                            Font.Medium

                                        elide:
                                            Text.ElideRight

                                        verticalAlignment:
                                            Text.AlignVCenter
                                    }


                                    Text {

                                        text: generatedOn

                                        width: root.colDate

                                        height: parent.height

                                        font.pixelSize: 18

                                        color: "#3A3A3A"

                                        elide:
                                            Text.ElideRight

                                        verticalAlignment:
                                            Text.AlignVCenter
                                    }


                                    Text {

                                        text: generatedBy

                                        width: root.colBy

                                        height: parent.height

                                        font.pixelSize: 18

                                        font.weight:
                                            Font.Medium

                                        color: "#1A4DB5"

                                        elide:
                                            Text.ElideRight

                                        verticalAlignment:
                                            Text.AlignVCenter
                                    }
                                }
                            }
                        }


                        // =================================================
                        // NO DATA
                        // =================================================

                        Item {

                            Layout.fillWidth: true

                            Layout.fillHeight: true

                            visible:
                                batchHistoryModel.count === 0


                            Column {

                                anchors.centerIn: parent

                                spacing: 16 * root.scale


                                Text {

                                    anchors.horizontalCenter:
                                        parent.horizontalCenter

                                    text: "No Batch History"

                                    font.pixelSize: 24

                                    font.weight:
                                        Font.Medium

                                    color: "#8896B0"
                                }


                                Text {

                                    anchors.horizontalCenter:
                                        parent.horizontalCenter

                                    text: "No batch records available"

                                    font.pixelSize: 20

                                    color: "#B0BEE0"
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

