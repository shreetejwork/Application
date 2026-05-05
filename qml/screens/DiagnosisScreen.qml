import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Item {
    id: root
    anchors.fill: parent

    // ── Scale: never go below 0.72 so text stays readable ──────
    property real baseWidth:  1024
    property real baseHeight: 600
    property real scale: Math.max(0.72, Math.min(width / baseWidth, height / baseHeight))

    property bool isLoading: false

    Rectangle {
        anchors.fill: parent
        color: "#F0F3FA"

        ColumnLayout {
            anchors.fill:    parent
            anchors.margins: 24
            spacing:         16

            // ── HEADER ────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Column {
                    spacing: 6 * root.scale

                    Text {
                        text: "System Diagnosis"
                        font.pixelSize: 26 * root.scale
                        font.bold: true
                        color: "#1A4DB5"
                    }

                    Rectangle {
                        width: 80 * root.scale
                        height: 4 * root.scale
                        radius: 2 * root.scale
                        color: "#1A4DB5"
                    }
                }

                Item { Layout.fillWidth: true }

                Text {
                    id:             lastUpdated
                    text:           ""
                    font.pixelSize: 12
                    color:          "#9E9E9E"
                    Layout.alignment: Qt.AlignVCenter
                }

                Rectangle {
                    width:  110
                    height: 36
                    radius: 8
                    color:  isLoading ? "#1A4DB5" : "#1A4DB5"
                    Layout.alignment: Qt.AlignVCenter

                    Behavior on color { ColorAnimation { duration: 200 } }

                    Row {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text:           isLoading ? "..." : "▶"
                            color:          "#FFFFFF"
                            font.pixelSize: 13
                        }

                        Text {
                            text:           isLoading ? "Running..." : "Run All"
                            color:          "#FFFFFF"
                            font.pixelSize: 14
                            font.weight:    Font.Medium
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
                rowSpacing:    12
                columnSpacing: 12

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

                // OVERALL HEALTH ──────────────────────────────────
                DiagCard {
                    id: summaryCard
                    Layout.fillWidth:  true
                    Layout.fillHeight: true

                    title:    "Overall Health"
                    subtitle: "Aggregated system status"
                    uiScale:  root.scale

                    property string worstStatus: {
                        var s = [ramCard.status, memCard.status, tempCard.status]
                        if (s.indexOf("Critical")    >= 0) return "Critical"
                        if (s.indexOf("Warning")     >= 0) return "Warning"
                        if (s.indexOf("Checking...") >= 0) return "Checking..."
                        return "OK"
                    }

                    status: worstStatus

                    detail: worstStatus === "Critical"    ? "Action Required"
                          : worstStatus === "Warning"     ? "Monitor Closely"
                          : worstStatus === "Checking..." ? "Scanning..."
                          : "All Systems Go"

                    cardColor: status === "Critical" ? "#FFF5F5"
                             : status === "Warning"  ? "#FFFBF0"
                             : "#F7FBF7"
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
