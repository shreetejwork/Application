import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../components"

Item {
    id: root
    anchors.fill: parent

    property var globalTopBar

    property real baseWidth: 1024
    property real baseHeight: 600
    property real scale: Math.min(width / baseWidth, height / baseHeight)

    property string folderPath: PdfExporter.getReportsFolderPath()
    property string activeFilter: "All"
    property bool selectionMode: false

    // COLUMN WIDTHS (shared)
    property real colCheck: 36 * root.scale
    property real colName: 0.55
    property real colType: 0.20
    property real colActions: 0.25

    ListModel { id: pdfModel }
    ListModel { id: filteredModel }

    function notify(msg) {
        if (root.globalTopBar && root.globalTopBar.showNotification)
            root.globalTopBar.showNotification(msg)
    }

    function matchesFilter(fileName) {
        if (activeFilter === "All") return true
        if (activeFilter === "Audit Report")    return fileName.toLowerCase().indexOf("audit")   !== -1
        if (activeFilter === "Batch Report") return fileName.toLowerCase().indexOf("batch") !== -1
        return true
    }

    function loadFiles() {
        pdfModel.clear()
        filteredModel.clear()
        selectionMode = false

        var files = PdfExporter.getAllPdfFiles()
        for (var i = 0; i < files.length; i++) {
            var fullPath = files[i]
            var name = fullPath.split("/").pop()
            pdfModel.append({ fileName: name, filePath: fullPath })
        }
        applyFilter()
    }

    function applyFilter() {
        filteredModel.clear()
        for (var i = 0; i < pdfModel.count; i++) {
            var item = pdfModel.get(i)
            if (matchesFilter(item.fileName)) {
                filteredModel.append({
                                         fileName: item.fileName,
                                         filePath: item.filePath,
                                         selected: false
                                     })
            }
        }
    }

    function setFilter(f) {
        activeFilter = f
        selectionMode = false
        applyFilter()
    }

    function selectedCount() {
        var c = 0
        for (var i = 0; i < filteredModel.count; i++)
            if (filteredModel.get(i).selected) c++
        return c
    }

    function selectAll() {
        for (var i = 0; i < filteredModel.count; i++)
            filteredModel.setProperty(i, "selected", true)
    }

    function deselectAll() {
        for (var i = 0; i < filteredModel.count; i++)
            filteredModel.setProperty(i, "selected", false)
    }

    function deleteSelected() {
        for (var i = filteredModel.count - 1; i >= 0; i--) {
            if (filteredModel.get(i).selected)
                PdfExporter.deletePdf(filteredModel.get(i).filePath)
        }
        loadFiles()
    }

    function copySelected() {
        var paths = []

        for (var i = 0; i < filteredModel.count; i++) {
            if (filteredModel.get(i).selected)
                paths.push(filteredModel.get(i).filePath)
        }

        if (paths.length === 0)
            return

        if (PdfExporter.isUsbMounted()) {
            notify("✓ USB Attached")
        } else {
            notify("⚠ USB not attached")
            return
        }

        var ok = PdfExporter.moveFilesToUsb(paths)

        if (ok) {
            notify("✓ Files moved to USB")
            loadFiles()
        } else {
            notify("⚠ Some files failed to move")
        }
    }

    Component.onCompleted: loadFiles()

    Rectangle {
        anchors.fill: parent
        color: "#EDF1FA"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 28 * root.scale
            spacing: 18 * root.scale

            // ══════════════════════════════════════════════════════
            // HEADER
            // ══════════════════════════════════════════════════════
            RowLayout {
                Layout.fillWidth: true
                spacing: 0

                Column {
                    spacing: 6 * root.scale

                    Text {
                        text: "Reports Folder"
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

                Rectangle {
                    width: countLabel.implicitWidth + 24 * root.scale
                    height: 30 * root.scale
                    radius: 15 * root.scale
                    color: "#1A4DB5"

                    Text {
                        id: countLabel
                        anchors.centerIn: parent
                        text: filteredModel.count + " file" + (filteredModel.count !== 1 ? "s" : "")
                        font.pixelSize: 14 * root.scale
                        font.weight: Font.Medium
                        color: "#FFFFFF"
                    }
                }
            }

            // ══════════════════════════════════════════════════════
            // ACTION BAR
            // ══════════════════════════════════════════════════════
            Rectangle {
                Layout.fillWidth: true
                height: 60 * root.scale
                color: "#FFFFFF"
                radius: 12 * root.scale
                border.color: "#C8D4EE"
                border.width: 1

                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 2 * root.scale
                    radius: 12 * root.scale
                    color: "#E8EEF9"
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin:   14 * root.scale
                    anchors.rightMargin:  14 * root.scale
                    anchors.topMargin:    10 * root.scale
                    anchors.bottomMargin: 10 * root.scale
                    spacing: 10 * root.scale

                    // ── REFRESH (pinned left) ──────────────────────
                    Rectangle {
                        width: 104 * root.scale
                        height: 38 * root.scale
                        radius: 8 * root.scale
                        color: refreshMa.containsMouse ? "#1A4DB5" : "#1A4DB5"
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text: "Refresh"
                            font.pixelSize: 15 * root.scale
                            font.weight: Font.Medium
                            color: "#FFFFFF"
                        }

                        MouseArea {
                            id: refreshMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: loadFiles()
                        }
                    }

                    // ── FILTER PILL GROUP ──────────────────────────
                    Rectangle {
                        height: 38 * root.scale
                        width: filterRow.implicitWidth + 8 * root.scale
                        color: "#EDF1FA"
                        radius: 8 * root.scale
                        border.color: "#C8D4EE"
                        border.width: 1

                        Row {
                            id: filterRow
                            anchors.centerIn: parent
                            spacing: 4 * root.scale

                            Repeater {
                                model: ["All", "Audit Report", "Batch Report"]

                                Rectangle {
                                    property bool active: root.activeFilter === modelData
                                    width: flbl.implicitWidth + 20 * root.scale
                                    height: 30 * root.scale
                                    radius: 6 * root.scale
                                    color: active ? "#1A4DB5" : "transparent"
                                    Behavior on color { ColorAnimation { duration: 150 } }

                                    Text {
                                        id: flbl
                                        anchors.centerIn: parent
                                        text: modelData
                                        font.pixelSize: 14 * root.scale
                                        font.weight: active ? Font.SemiBold : Font.Normal
                                        color: active ? "#FFFFFF" : "#4A5E8A"
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.setFilter(modelData)
                                    }
                                }
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // ── SELECT TOGGLE ──────────────────────────────
                    Rectangle {
                        width: 100 * root.scale
                        height: 38 * root.scale
                        radius: 8 * root.scale
                        color: root.selectionMode ? "#1A4DB5" : "#FFFFFF"
                        border.color: "#1A4DB5"
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text: root.selectionMode ? "Cancel" : "Select"
                            font.pixelSize: 15 * root.scale
                            font.weight: Font.Medium
                            color: root.selectionMode ? "#FFFFFF" : "#1A4DB5"
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.selectionMode = !root.selectionMode
                                if (!root.selectionMode) root.deselectAll()
                            }
                        }
                    }

                    // ── SELECT ALL ─────────────────────────────────
                    Rectangle {
                        visible: root.selectionMode
                        width: 96 * root.scale
                        height: 38 * root.scale
                        radius: 8 * root.scale
                        color: "#FFFFFF"
                        border.color: "#1A4DB5"
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "Select All"
                            font.pixelSize: 15 * root.scale
                            font.weight: Font.Medium
                            color: "#1A4DB5"
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectAll()
                        }
                    }

                    // ── Move to USB ───────────────────────────────────────
                    Rectangle {
                        visible: root.selectionMode
                        width: 100 * root.scale
                        height: 38 * root.scale
                        radius: 8 * root.scale
                        color: "#FFFFFF"
                        border.color: "#2E7D32"
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "Move to USB"
                            font.pixelSize: 15 * root.scale
                            font.weight: Font.Medium
                            color: "#2E7D32"
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.copySelected()
                        }
                    }

                    // ── DELETE (bulk) ──────────────────────────────
                    Rectangle {
                        visible: root.selectionMode
                        width: 90 * root.scale
                        height: 38 * root.scale
                        radius: 8 * root.scale
                        color: "#FFFFFF"
                        border.color: "#C62828"
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "Delete"
                            font.pixelSize: 15 * root.scale
                            font.weight: Font.Medium
                            color: "#C62828"
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.deleteSelected()
                        }
                    }
                }
            }

            // ══════════════════════════════════════════════════════
            // FILE TABLE
            // ══════════════════════════════════════════════════════
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 14 * root.scale
                color: "#FFFFFF"
                border.color: "#C8D4EE"
                border.width: 1
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // ── TABLE HEADER ───────────────────────────────
                    Rectangle {
                        Layout.fillWidth: true
                        height: 46 * root.scale
                        color: "#1A4DB5"
                        radius: 14 * root.scale

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 14 * root.scale
                            color: "#1A4DB5"
                        }

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin:  16 * root.scale
                            anchors.rightMargin: 16 * root.scale

                            Item {
                                width: root.selectionMode ? 36 * root.scale : 0
                                height: parent.height
                                visible: root.selectionMode
                            }

                            Text {
                                text: "File Name"
                                font.bold: true
                                color: "#FFFFFF"
                                font.pixelSize: 16 * root.scale
                                width: parent.width * 0.55
                                verticalAlignment: Text.AlignVCenter
                                height: parent.height
                                opacity: 0.92
                            }
                        }
                    }

                    // ── ROWS ───────────────────────────────────────
                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        model: filteredModel
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                            width: 8 * root.scale
                        }

                        delegate: Rectangle {
                            id: rowRect
                            width: ListView.view.width
                            height: 60 * root.scale

                            property bool isSelected: model.selected === true

                            color: isSelected
                                   ? "#E3EDFF"
                                   : (index % 2 === 0 ? "#FFFFFF" : "#F7F9FF")
                            Behavior on color { ColorAnimation { duration: 120 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin:  16 * root.scale
                                anchors.rightMargin: 16 * root.scale
                                spacing: 10 * root.scale

                                // Checkbox
                                Rectangle {
                                    visible: root.selectionMode
                                    width:  root.selectionMode ? 22 * root.scale : 0
                                    height: 22 * root.scale
                                    radius: 5 * root.scale
                                    color: rowRect.isSelected ? "#1A4DB5" : "#FFFFFF"
                                    border.color: rowRect.isSelected ? "#1A4DB5" : "#8BA0CC"
                                    border.width: 2
                                    Behavior on color { ColorAnimation { duration: 120 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "✓"
                                        font.pixelSize: 13 * root.scale
                                        font.bold: true
                                        color: "#FFFFFF"
                                        visible: rowRect.isSelected
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: filteredModel.setProperty(index, "selected", !model.selected)
                                    }
                                }

                                // File name with PDF icon (FIXED)
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 10 * root.scale

                                    // ICON (properly constrained)
                                    Image {
                                        source: "qrc:/qt/qml/Application/assets/images/pdf.png"
                                        Layout.preferredWidth: 20 * root.scale
                                        Layout.preferredHeight: 20 * root.scale
                                        Layout.alignment: Qt.AlignVCenter

                                        fillMode: Image.PreserveAspectFit
                                        smooth: true
                                        mipmap: true
                                    }

                                    // FILE NAME
                                    Text {
                                        Layout.fillWidth: true
                                        text: fileName
                                        font.pixelSize: 15 * root.scale
                                        color: "#2A3550"
                                        elide: Text.ElideRight
                                        font.weight: rowRect.isSelected ? Font.Medium : Font.Normal
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }

                                // Type badge
                                Rectangle {
                                    width: typeLbl.implicitWidth + 18 * root.scale
                                    height: 26 * root.scale
                                    radius: 14 * root.scale
                                    color: {
                                        var n = fileName.toLowerCase()
                                        if (n.indexOf("audit")   !== -1) return "#E8F5E9"
                                        if (n.indexOf("batch") !== -1) return "#FFF3E0"
                                        return "#EDF1FA"
                                    }

                                    Text {
                                        id: typeLbl
                                        anchors.centerIn: parent
                                        font.pixelSize: 12 * root.scale
                                        font.weight: Font.Medium
                                        color: {
                                            var n = fileName.toLowerCase()
                                            if (n.indexOf("audit")   !== -1) return "#2E7D32"
                                            if (n.indexOf("batch") !== -1) return "#E65100"
                                            return "#4A5E8A"
                                        }
                                        text: {
                                            var n = fileName.toLowerCase()
                                            if (n.indexOf("audit")   !== -1) return "Audit Trail Report"
                                            if (n.indexOf("batch") !== -1) return "Batch Report"
                                            return "General"
                                        }
                                    }
                                }

                                Item { width: 8 * root.scale }

                                // View button
                                Rectangle {
                                    width: 100 * root.scale
                                    height: 38 * root.scale
                                    radius: 7 * root.scale
                                    color: "#FFFFFF"
                                    border.color: "#1A4DB5"
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: "View"
                                        font.pixelSize: 15 * root.scale
                                        font.weight: Font.Medium
                                        color: "#1A4DB5"
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            pdfPreview.pdfSource = "file:///" + filePath
                                            pdfPreview.open()
                                        }
                                    }
                                }
                            }

                            // Row divider
                            Rectangle {
                                anchors.bottom: parent.bottom
                                width: parent.width
                                height: 1
                                color: "#E4EAF5"
                            }

                            // Click whole row to toggle in selection mode
                            MouseArea {
                                anchors.fill: parent
                                enabled: root.selectionMode
                                cursorShape: Qt.PointingHandCursor
                                onClicked: filteredModel.setProperty(index, "selected", !model.selected)
                            }
                        }

                        // ── EMPTY STATE ────────────────────────────
                        Item {
                            anchors.fill: parent
                            visible: filteredModel.count === 0

                            Column {
                                anchors.centerIn: parent
                                spacing: 14 * root.scale

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    font.pixelSize: 48 * root.scale
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "No reports found"
                                    font.pixelSize: 22 * root.scale
                                    font.weight: Font.Medium
                                    color: "#8896B0"
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: root.activeFilter === "All"
                                          ? "No PDF files in the reports folder"
                                          : "No \"" + root.activeFilter + "\" files found"
                                    font.pixelSize: 15 * root.scale
                                    color: "#B0BEE0"
                                }

                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 130 * root.scale
                                    height: 42 * root.scale
                                    radius: 10 * root.scale
                                    color: "#1A4DB5"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "↺  Refresh"
                                        font.pixelSize: 15 * root.scale
                                        color: "#FFFFFF"
                                        font.weight: Font.Medium
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: loadFiles()
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ══════════════════════════════════════════════════════
            // STATUS BAR
            // ══════════════════════════════════════════════════════
            Rectangle {
                Layout.fillWidth: true
                height: root.selectionMode ? 36 * root.scale : 0
                visible: root.selectionMode
                color: "#1A4DB5"
                radius: 8 * root.scale
                Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                Text {
                    anchors.centerIn: parent
                    text: root.selectedCount() + " of " + filteredModel.count + " file(s) selected  —  click rows or checkboxes to select"
                    font.pixelSize: 13 * root.scale
                    color: "#FFFFFF"
                    opacity: 0.9
                }
            }
        }
    }

    PdfPreview {
        id: pdfPreview
    }
}
