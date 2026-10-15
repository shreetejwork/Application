import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Item {
    id: root
    anchors.fill: parent

    // ── Scale: keep diagnosis text readable on smaller displays ──────
    property real baseWidth:  1024
    property real baseHeight: 600
    property real scale: Math.max(0.8, Math.min(width / baseWidth, height / baseHeight))

    Typography {
        id: diagnosisTypography
        scale: root.scale
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

    property bool isLoading: false

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
            color: "#F0F3FA"

            ColumnLayout {
                anchors.fill:    parent
                anchors.margins: 20 * root.scale
                spacing:         12 * root.scale

                // ── HEADER ────────────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Column {
                        spacing: 5 * root.scale

                        Text {
                            text: "System Diagnosis"
                            font.pixelSize: diagnosisTypography.title


                            color: "#1A4DB5"
                        }

                        Rectangle {
                            width: 84 * root.scale
                            height: 4 * root.scale
                            radius: 2 * root.scale
                            color: "#1A4DB5"
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        id:             lastUpdated
                        text:           ""
                        font.pixelSize: diagnosisTypography.caption
                        color:          "#9E9E9E"
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Rectangle {
                        width:  120 * root.scale
                        height: 40 * root.scale
                        radius: 8 * root.scale
                        color:  isLoading ? "#1A4DB5" : "#1A4DB5"
                        Layout.alignment: Qt.AlignVCenter

                        Behavior on color { ColorAnimation { duration: 200 } }

                        Row {
                            anchors.centerIn: parent
                            spacing: 6 * root.scale

                            Text {
                                text:           isLoading ? "..." : "▶"
                                color:          "#FFFFFF"
                                font.pixelSize: diagnosisTypography.caption
                            }

                            Text {
                                text:           isLoading ? "Running..." : "Run All"
                                color:          "#FFFFFF"
                                font.pixelSize: diagnosisTypography.bodySmall

                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled:      !isLoading
                            cursorShape:  Qt.PointingHandCursor
                            onClicked: {
                                isLoading = true
                                SystemDiag.update()
                            }
                        }
                    }
                }

                // ── DIVIDER ───────────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color:  "#D8DFF0"
                }

                // ── CARDS GRID ────────────────────────────────────────
                GridLayout {
                    Layout.fillWidth:  true
                    Layout.fillHeight: true
                    columns:       2
                    rowSpacing:    12 * root.scale
                    columnSpacing: 12 * root.scale

                    // RAM ─────────────────────────────────────────────
                    DiagCard {
                        id: ramCard
                        Layout.fillWidth:  true
                        Layout.fillHeight: true

                        title:    "RAM Usage"
                        uiScale:  root.scale

                        property real usage: SystemDiag.ramTotal > 0
                                             ? SystemDiag.ramUsed / SystemDiag.ramTotal : 0

                        progress:  isLoading ? -1 : usage

                        status: isLoading    ? "Checking..."
                              : usage > 0.9  ? "Critical"
                              : usage > 0.75 ? "Warning"
                              : "OK"

                        detail: isLoading ? "— GB / — GB" : SystemDiag.ramUsage

                        cardColor: status === "Critical" ? "#FFF5F5"
                                 : status === "Warning"  ? "#FFFBF0"
                                 : "#F7FBF7"
                    }

                    // MEMORY ──────────────────────────────────────────
                    DiagCard {
                        id: memCard
                        Layout.fillWidth:  true
                        Layout.fillHeight: true

                        title:    "Storage"
                        uiScale:  root.scale

                        property real usage: SystemDiag.memTotal > 0
                                             ? SystemDiag.memUsed / SystemDiag.memTotal : 0

                        progress:  isLoading ? -1 : usage

                        status: isLoading    ? "Checking..."
                              : usage > 0.9  ? "Critical"
                              : usage > 0.6  ? "Warning"
                              : "OK"

                        detail: isLoading ? "— GB / — GB" : SystemDiag.memoryUsage

                        cardColor: status === "Critical" ? "#FFF5F5"
                                 : status === "Warning"  ? "#FFFBF0"
                                 : "#F7FBF7"
                    }

                    // TEMPERATURE ─────────────────────────────────────
                    DiagCard {
                        id: tempCard
                        Layout.fillWidth:  true
                        Layout.fillHeight: true

                        title:    "CPU Temperature"
                        uiScale:  root.scale

                        property real temp: SystemDiag.temperatureValue
                        property real tempProgress: temp > 0 ? Math.min(temp / 100.0, 1.0) : -1

                        progress: isLoading ? -1 : tempProgress

                        status: isLoading ? "Checking..."
                              : temp < 0  ? "Unknown"
                              : temp > 75 ? "Critical"
                              : temp > 60 ? "Warning"
                              : "OK"

                        detail: isLoading ? "— °C" : SystemDiag.temperature

                        cardColor: status === "Critical" ? "#FFF5F5"
                                 : status === "Warning"  ? "#FFFBF0"
                                 : "#F7FBF7"
                    }

                    // INPUT VOLTAGE ─────────────────────────────────
                    DiagCard {
                        id: voltageCard
                        Layout.fillWidth:  true
                        Layout.fillHeight: true

                        title:   "Input Voltage"
                        uiScale: root.scale

                        property real voltage: SystemDiag.inputVoltageValue
                        property bool undervoltage: SystemDiag.undervoltageDetected
                        property bool undervoltageOccurred: SystemDiag.undervoltageOccurred
                        property bool voltageStatusAvailable: SystemDiag.voltageStatusAvailable

                        progress: -1

                        status: isLoading ? "Checking..."
                              : undervoltage || (voltage >= 0 && (voltage < 4.63 || voltage > 5.25)) ? "Critical"
                              : (voltage >= 0 && voltage < 4.75) || undervoltageOccurred ? "Warning"
                              : voltage >= 0 || voltageStatusAvailable ? "OK"
                              : "Unknown"

                        detail: isLoading ? "Checking..."
                              : voltage >= 0 ? SystemDiag.inputVoltage
                              : !voltageStatusAvailable ? "Status unavailable"
                              : undervoltage ? "Low voltage detected"
                              : undervoltageOccurred ? "Low voltage recorded"
                              : "No low voltage detected"

                        subtitle: isLoading ? ""
                                : undervoltage ? "System firmware reports undervoltage now"
                                : voltage >= 0 && voltage < 4.63 ? "Critical: below 4.63 V"
                                : voltage >= 0 && voltage < 4.75 ? "Low: below 4.75 V"
                                : voltage >= 0 && voltage > 5.25 ? "High: above 5.25 V"
                                : undervoltageOccurred ? "System recorded undervoltage since boot"
                                : !voltageStatusAvailable ? "System firmware status unavailable"
                                : voltage >= 0 ? "Input voltage within range (4.75-5.25 V)"
                                : "System firmware reports no undervoltage"

                        cardColor: status === "Critical" ? "#FFF5F5"
                                 : status === "Warning"  ? "#FFFBF0"
                                 : status === "Unknown"  ? "#F4F6F8"
                                 : "#F7FBF7"
                    }
                }
            }
        }
    }

    // ── BACKEND SIGNAL ────────────────────────────────────────────
    Connections {
        target: SystemDiag

        function onDataChanged() {
            isLoading = false
            var now = new Date()
            lastUpdated.text = "Updated " +
                String(now.getHours())  .padStart(2, "0") + ":" +
                String(now.getMinutes()).padStart(2, "0") + ":" +
                String(now.getSeconds()).padStart(2, "0")
        }
    }
}
