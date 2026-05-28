import QtQuick
import QtQuick.Layouts

Rectangle {
    Typography {
        id: componentTypography
        scale: root.scale || 1.0
    }
    id: card

    property string title:    ""
    property string status:   "OK"
    property string detail:   ""
    property real   uiScale:  1.0
    property color  cardColor: "#FFFFFF"
    property real   progress:  -1
    property string subtitle: ""
    
    // =========================================================
    // TYPOGRAPHY FOR DIAG CARD
    // =========================================================
    
    Typography {
        id: cardTypography
        scale: card.uiScale
    }

    radius:       12 * uiScale
    color:        cardColor
    border.color: statusBorderColor()
    border.width: 1

    Behavior on color        { ColorAnimation { duration: 300 } }
    Behavior on border.color { ColorAnimation { duration: 300 } }

    function statusBorderColor() {
        if (status === "OK")          return "#43A047"
        if (status === "Warning")     return "#FB8C00"
        if (status === "Checking...") return "#1E88E5"
        return "#E53935"
    }
    function statusBadgeBg() {
        if (status === "OK")          return "#E3F2FD"
        if (status === "Warning")     return "#FFF3E0"
        if (status === "Checking...") return "#E3F2FD"
        return "#E3F2FD"
    }
    function statusTextColor() {
        if (status === "OK")          return "#2E7D32"
        if (status === "Warning")     return "#E65100"
        if (status === "Checking...") return "#1565C0"
        return "#B71C1C"
    }
    function statusIcon() {
        if (status === "OK")          return "✔"
        if (status === "Warning")     return "⚠"
        if (status === "Checking...") return "..."
        return "✖"
    }

    ColumnLayout {
        anchors.fill:    parent
        anchors.margins: 16
        spacing:         10

        // ── header row ──────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                width:  10; height: 10; radius: 5
                color: card.statusBorderColor()

                SequentialAnimation on opacity {
                    running: card.status === "Checking..."
                    loops:   Animation.Infinite
                    NumberAnimation { to: 0.2; duration: 600 }
                    NumberAnimation { to: 1.0; duration: 600 }
                }
            }

            Text {
                text:             card.title
                font.pixelSize:   cardTypography.body
                font.weight:      Font.Bold
                color:            "#1A1A1A"
                Layout.fillWidth: true
                elide:            Text.ElideRight
            }

            Rectangle {
                width:  Math.max(26, 28 * card.uiScale)
                height: Math.max(26, 28 * card.uiScale)
                radius: width / 2
                color:  card.statusBadgeBg()

                Text {
                    anchors.centerIn: parent
                    text:             card.statusIcon()
                    font.pixelSize:   cardTypography.small
                    color:            card.statusTextColor()
                }
            }
        }

        // ── divider ─────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 3
            color: "#EEEEEE"
        }

        // ── main value ──────────────────────────────────────────
        Text {
            Layout.alignment:    Qt.AlignHCenter
            text:                card.detail
            font.pixelSize:      cardTypography.heading
            font.weight:         Font.DemiBold
            color:               "#111111"
            horizontalAlignment: Text.AlignHCenter
            wrapMode:            Text.WordWrap
            Layout.fillWidth:    true
        }

        // ── progress bar ────────────────────────────────────────
        ColumnLayout {
            visible:          card.progress >= 0
            Layout.fillWidth: true
            spacing:          4

            Rectangle {
                Layout.fillWidth: true
                height:           8
                radius:           4
                color:            "#E0E0E0"

                Rectangle {
                    width:   parent.width * Math.max(0, Math.min(1, card.progress))
                    height:  parent.height
                    radius:  4
                    color:   card.statusBorderColor()

                    Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation  { duration: 300 } }
                }
            }

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text:           "0"
                    font.pixelSize: cardTypography.tiny
                    color:          "#9E9E9E"
                }
                Item { Layout.fillWidth: true }
                Text {
                    text:           card.progress >= 0
                                    ? Math.round(card.progress * 100) + "% used"
                                    : ""
                    font.pixelSize: cardTypography.small
                    color:          "#9E9E9E"
                }
            }
        }

        Item { Layout.fillHeight: true }

        // ── status badge ────────────────────────────────────────
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width:  statusLbl.implicitWidth + 24
            height: 26
            radius: 13
            color:  card.statusBadgeBg()

            Behavior on color { ColorAnimation { duration: 300 } }

            Text {
                id:              statusLbl
                anchors.centerIn: parent
                text:             card.status
                font.pixelSize:   cardTypography.caption
                font.weight:      Font.Medium
                color:            card.statusTextColor()
            }
        }
    }
}
