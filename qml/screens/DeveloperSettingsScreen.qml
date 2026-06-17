import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import AppState 1.0

import "../components"

Item {
    id: root
    anchors.fill: parent

    property real baseWidth: 1024
    property real baseHeight: 600
    property real scale: Math.min(width / baseWidth, height / baseHeight)

    Rectangle {
    Typography {
        id: screenTypography
        scale: root.scale || 1.0
    }
        anchors.fill: parent
        color: "#F5F7FC"

        Column {
            anchors.fill: parent
            anchors.margins: 30 * root.scale
            spacing: 24 * root.scale

            // ===== HEADER =====
            Column {
                spacing: 6

                Text {
                    text: "Developer Settings"
                    font.pixelSize: 28

                    color: "#1A4DB5"
                }

                Rectangle {
                    width: 70 * root.scale
                    height: 4 * root.scale
                    radius: 2 * root.scale
                    color: "#1A4DB5"
                }
            }

            // ===== CARDS =====
            Flow {
                id: flow
                width: parent.width
                spacing: 20 * root.scale


                property real cardWidth: (width - (spacing * 2)) / 3

                // ===== Card 1 =====
                Rectangle {
                    width: flow.cardWidth
                    height: 120 * root.scale
                    radius: 16
                    color: "#FFFFFF"
                    border.color: "#E5E7EB"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 16

                        ColumnLayout {
                            Layout.fillWidth: true

                            Text {
                                text: "D-Duster"
                                font.pixelSize: 20

                                color: "#111827"
                            }

                            Text {
                                text: GlobalState.showDDuster
                                      ? "D-duster Screen On"
                                      : "D-duster Screen Off"
                                font.pixelSize: 16
                                color: "#6B7280"
                            }
                        }

                        DDButton {
                            width: 90 * root.scale
                            height: 36 * root.scale

                            toggled: GlobalState.showDDuster

                            onToggledChanged: {
                                GlobalState.showDDuster = toggled
                            }
                        }
                    }
                }
                // ===== Card 2 =====
                Rectangle {
                    width: flow.cardWidth
                    height: 120 * root.scale
                    radius: 16
                    color: "#FFFFFF"
                    border.color: "#E5E7EB"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 16

                        ColumnLayout {
                            Layout.fillWidth: true

                            Text {
                                text: "N/W Settings"
                                font.pixelSize: 20

                                color: "#111827"
                            }

                            Text {
                                text: GlobalState.showNetworkScreen
                                      ? "N/W Screen On"
                                      : "N/W Screen Off"
                                font.pixelSize: 16
                                color: "#6B7280"
                            }
                        }

                        DDButton {
                            width: 90 * root.scale
                            height: 36 * root.scale

                            toggled: GlobalState.showNetworkScreen

                            onToggledChanged: {
                                GlobalState.showNetworkScreen = toggled
                            }
                        }
                    }
                }
                // ===== Card 3 =====
                Rectangle {
                    width: flow.cardWidth
                    height: 120 * root.scale
                    radius: 16
                    color: "#FFFFFF"
                    border.color: "#E5E7EB"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 16

                        ColumnLayout {
                            Layout.fillWidth: true

                            Text {
                                text: "Audit Trail Report"
                                font.pixelSize: 20

                                color: "#111827"
                            }

                            Text {
                                text: GlobalState.showAuditTrail
                                      ? "Audit Trail On"
                                      : "Audit Trail Off"
                                font.pixelSize: 16
                                color: "#6B7280"
                            }
                        }

                        DDButton {
                            width: 90 * root.scale
                            height: 36 * root.scale

                            toggled: GlobalState.showAuditTrail

                            onToggledChanged: {
                                GlobalState.showAuditTrail = toggled
                            }
                        }
                    }
                }

                // ===== Card 4 =====
                Rectangle {
                    width: flow.cardWidth
                    height: 120 * root.scale
                    radius: 16
                    color: "#FFFFFF"
                    border.color: "#E5E7EB"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 16

                        ColumnLayout {
                            Layout.fillWidth: true

                            Text {
                                text: "Product Library"
                                font.pixelSize: 20

                                color: "#111827"
                            }

                            Text {
                                text: GlobalState.showProductLib
                                      ? "Product Library On"
                                      : "Product Library Off"
                                font.pixelSize: 16
                                color: "#6B7280"
                            }
                        }

                        DDButton {
                            width: 90 * root.scale
                            height: 36 * root.scale

                            toggled: GlobalState.showProductLib

                            onToggledChanged: {
                                GlobalState.showProductLib = toggled
                            }
                        }
                    }
                }
            }
        }
    }
}
