pragma Singleton
import QtQuick 2.15
import Qt.labs.settings 1.1

QtObject {
    id: root

    // =========================================================
    // SETTINGS (SAFE)
    // =========================================================
    property var settings: Settings {
        category: "GlobalState"

        property bool showDDuster: true
        property bool showNetworkScreen: true
        property bool showAuditTrail: true
        property bool showProductLib: true

        property string blockedUsersJson:   "{}"
        property string failedAttemptsJson: "{}"

    }

    property var reportSettings: Settings {
        category: "ReportsLog"
        property string logsJson: "[]"
    }

    // =========================================================
    //  PERSISTED UI STATE
    // =========================================================
    property bool showDDuster: settings.showDDuster
    property bool showNetworkScreen: settings.showNetworkScreen
    property bool showAuditTrail: settings.showAuditTrail
    property bool showProductLib: settings.showProductLib

    property string blockedUsersJson:   settings.blockedUsersJson
    property string failedAttemptsJson: settings.failedAttemptsJson

    onBlockedUsersJsonChanged:   settings.blockedUsersJson   = blockedUsersJson
    onFailedAttemptsJsonChanged: settings.failedAttemptsJson = failedAttemptsJson

    onShowDDusterChanged: settings.showDDuster = showDDuster
    onShowNetworkScreenChanged: settings.showNetworkScreen = showNetworkScreen
    onShowAuditTrailChanged: settings.showAuditTrail = showAuditTrail
    onShowProductLibChanged: settings.showProductLib = showProductLib


    // =========================================================
    // OTHER PROPERTIES
    // =========================================================
    property real productPhase: 0
    property real machinePhase: 180.0

    property real signalThreshold: 500
    property real amplitudeThreshold: 180

    property bool loginKeyboardRequest: false
    property var activeInputField: null

    property var globalDateTime: new Date()

    property string loggedInUserName: ""
    property string loggedInUserRole: ""

    property string supplierName: ""
    property string serialNumber: ""
    property string machineId: ""
    property string userName: ""
    property string location: ""


    // =========================================================
    //  MODELS (3 SEPARATE LOG STORES)
    // =========================================================

    property var reportsLogModel: Qt.createQmlObject('
        import QtQuick 2.15;
        ListModel {}
    ', root)

    property var deletedFilesModel: Qt.createQmlObject('
        import QtQuick 2.15;
        ListModel {}
    ', root)

    property var copiedFilesModel: Qt.createQmlObject('
        import QtQuick 2.15;
        ListModel {}
    ', root)

    // =========================================================
    //  LOAD LOGS
    // =========================================================
    Component.onCompleted: {
        try {
            var data = JSON.parse(reportSettings.logsJson)

            if (data.created) {
                for (var i = 0; i < data.created.length; i++)
                    reportsLogModel.append(data.created[i])
            }

            if (data.deleted) {
                for (var i = 0; i < data.deleted.length; i++)
                    deletedFilesModel.append(data.deleted[i])
            }

            if (data.copied) {
                for (var i = 0; i < data.copied.length; i++)
                    copiedFilesModel.append(data.copied[i])
            }

        } catch (e) {
            console.log("Failed to load logs:", e)
        }
    }

    // =========================================================
    //  SAVE LOGS
    // =========================================================
    function saveLogs() {

        var created = []
        for (var i = 0; i < reportsLogModel.count; i++)
            created.push(reportsLogModel.get(i))

        var deleted = []
        for (var i = 0; i < deletedFilesModel.count; i++)
            deleted.push(deletedFilesModel.get(i))

        var copied = []
        for (var i = 0; i < copiedFilesModel.count; i++)
            copied.push(copiedFilesModel.get(i))

        reportSettings.logsJson = JSON.stringify({
            created: created,
            deleted: deleted,
            copied: copied
        })
    }

    // =========================================================
    //  ADD LOG
    // =========================================================
    function addReportLog(type, fileName, action, fromDate, toDate, user) {

        var now = new Date()

        reportsLogModel.insert(0, {
            sr: reportsLogModel.count + 1,
            fileName: fileName,
            type: type,
            action: action,
            date: Qt.formatDate(now, "dd/MM/yyyy"),
            from: fromDate || "-",
            to: toDate || "-",
            by: user || "System"
        })

        saveLogs()
    }

    function addDeletedFileLog(fileName, user) {

        var now = new Date()

        deletedFilesModel.insert(0, {
            sr: deletedFilesModel.count + 1,
            fileName: fileName,
            action: "Deleted",
            date: Qt.formatDate(now, "dd/MM/yyyy"),
            by: user || "System"
        })

        saveLogs()
    }

    function addCopiedFileLog(fileName, user) {

        var now = new Date()

        copiedFilesModel.insert(0, {
            sr: copiedFilesModel.count + 1,
            fileName: fileName,
            action: "Copied",
            date: Qt.formatDate(now, "dd/MM/yyyy"),
            by: user || "System"
        })

        saveLogs()
    }
}
