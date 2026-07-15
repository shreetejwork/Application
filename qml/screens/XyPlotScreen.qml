import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCore
import AppState 1.0
import CustomComponents 1.0


import "../components"

Item {
    Typography {
        id: componentTypography
        scale: root.scale || 1.0
    }
    id: root

    anchors.fill: parent

    property var globalTopBar
    property var notify

    property real baseWidth:  1024
    property real baseHeight: 600

    property real scale: Math.min(
                             width  / baseWidth,
                             height / baseHeight
                             )

    // Holds the async grabToImage result so it isn't garbage-collected
    // before the callback fires
    property var pendingGrab: null

    // =========================================================
    // TYPOGRAPHY FOR XY PLOT SCREEN
    // =========================================================

    Typography {
        id: plotTypography
        scale: root.scale
    }


    function exportPdf()
    {
        if (typeof PdfExporter === "undefined" || !PdfExporter) {
            console.log("ERROR: PdfExporter is not available in this screen's context!")
            return
        }

        pendingGrab = graphCard.grabToImage(function(result) {

            if (!result) {
                console.log("Grab failed: result is null")
                pendingGrab = null
                return
            }

            var tempImage =
                    StandardPaths.writableLocation(StandardPaths.TempLocation)
                    + "/xyplot_tmp.png"

            var ok = result.saveToFile(tempImage)
            console.log("Temp image saved:", ok, tempImage)

            if (!ok) {
                console.log("Failed to save temp grab image to:", tempImage)
                pendingGrab = null
                return
            }

            try {
                var sessionInfo = {
                    "loggedInUserName": GlobalState.loggedInUserName,
                    "loggedInUserRole": GlobalState.loggedInUserRole
                }

                var savedPath = PdfExporter.exportXYPlotToPdf(
                        tempImage,
                        productPhaseText.text,
                        signalText.text,
                        amplitudeText.text,
                        sessionInfo
                )
                console.log("XY Plot PDF saved at:", savedPath)

                if (notify) {
                    notify("PDF saved: " + savedPath)
                }
            } catch (e) {
                console.log("EXCEPTION calling exportXYPlotToPdf:", e)
            }

            pendingGrab = null
        })
    }

    property real bodyFont:  13 * scale
    property real smallFont: 11 * scale

    property var magneticFieldData: [
        { x: -90, y: -55 },
        { x: -70, y: -32 },
        { x: -50, y:  -8 },
        { x: -30, y:  18 },
        { x: -10, y:  36 },
        { x:  10, y:  44 },
        { x:  30, y:  28 },
        { x:  50, y:   6 },
        { x:  70, y: -18 },
        { x:  90, y: -42 }
    ]

    Rectangle {
        anchors.fill: parent
        color: "#F5F7FC"
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 10 * root.scale
        anchors.rightMargin: 10 * root.scale
        anchors.topMargin: 10 * root.scale
        anchors.bottomMargin: 10 * root.scale
        spacing: 8 * root.scale

        // =========================================================
        // TOP BAR
        // =========================================================

        RowLayout {
            Layout.fillWidth: true

            Item {
                Layout.fillWidth: true
            }

            Button {
                id: savePdfButton

                text: "Save PDF"

                Layout.preferredWidth: 140 * root.scale
                Layout.preferredHeight: 40 * root.scale

                onClicked: {
                    var path = exportPdf()

                    if (path !== "") {
                        if (globalTopBar && globalTopBar.showNotification) {
                            globalTopBar.showNotification("✓ PDF saved successfully")
                        }
                    }
                }

                contentItem: Text {
                    text: savePdfButton.text
                    font.pixelSize: plotTypography.body
                    color: "#FFFFFF"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    radius: 10 * root.scale
                    color: savePdfButton.pressed ? "#153F94" : "#1A4DB5"
                    border.width: 1
                    border.color: "#DCE5F5"
                }
            }
        }

        // ── MAIN ROW ──────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth:  true
            Layout.fillHeight: true
            spacing: 10 * root.scale

            // ── LEFT PANEL ────────────────────────────────────────────────────
            Rectangle {
                Layout.preferredWidth: 180 * root.scale
                Layout.fillHeight:     true

                radius:       16 * root.scale
                color:        "#FFFFFF"
                border.width: 1
                border.color: "#DCE5F5"

                ColumnLayout {
                    anchors.fill:    parent
                    anchors.margins: 12 * root.scale
                    spacing: 10 * root.scale

                    // ── Product Phase card ─────────────────────────────────────
                    Rectangle {
                        Layout.fillWidth:  true
                        Layout.fillHeight: true

                        radius:       12 * root.scale
                        color:        "#F7F9FD"
                        border.width: 1
                        border.color: "#DCE5F5"

                        ColumnLayout {
                            anchors.fill:    parent
                            anchors.margins: 14 * root.scale
                            spacing: 8 * root.scale

                            Text {
                                text: "Product\nPhase"
                                font.pixelSize: plotTypography.subHeading
                                color: "#1A4DB5"
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                id: productPhaseText
                                text: "40"
                                font.pixelSize: plotTypography.body
                                color: "#1A4DB5"
                            }
                        }
                    }

                    // ── Signal card ────────────────────────────────────────────
                    Rectangle {
                        Layout.fillWidth:  true
                        Layout.fillHeight: true

                        radius:       12 * root.scale
                        color:        "#F7F9FD"
                        border.width: 1
                        border.color: "#DCE5F5"

                        ColumnLayout {
                            anchors.fill:    parent
                            anchors.margins: 14 * root.scale
                            spacing: 8 * root.scale

                            Text {
                                text: "Signal"
                                font.pixelSize: plotTypography.subHeading
                                color: "#1A4DB5"
                            }

                            Text {
                                id: signalText
                                text: "400"
                                font.pixelSize: plotTypography.body
                                color: "#0F8A60"
                            }
                        }
                    }

                    // ── Amplitude card ─────────────────────────────────────────
                    Rectangle {
                        Layout.fillWidth:  true
                        Layout.fillHeight: true

                        radius:       12 * root.scale
                        color:        "#F7F9FD"
                        border.width: 1
                        border.color: "#DCE5F5"

                        ColumnLayout {
                            anchors.fill:    parent
                            anchors.margins: 14 * root.scale
                            spacing: 8 * root.scale

                            Text {
                                text: "Amplitude"
                                font.pixelSize: plotTypography.subHeading
                                color: "#1A4DB5"
                            }

                            Text {
                                id: amplitudeText
                                text: "250"
                                font.pixelSize: plotTypography.body
                                color: "#D64545"
                            }
                        }
                    }
                }
            }

            // ── GRAPH CARD ────────────────────────────────────────────────────
            Rectangle {

                id: graphCard

                Layout.fillWidth:  true
                Layout.fillHeight: true

                radius:       16 * root.scale
                color:        "#FFFFFF"
                border.width: 1
                border.color: "#DCE5F5"

                MagneticFieldPlotItem {
                    id: plot
                    anchors.fill:         parent
                    anchors.leftMargin:   8 * root.scale
                    anchors.rightMargin:  8 * root.scale
                    anchors.topMargin:    8 * root.scale
                    anchors.bottomMargin: 8 * root.scale

                    fieldData:       root.magneticFieldData
                    showPointLabels: false
                }
            }
        }
    }
}
