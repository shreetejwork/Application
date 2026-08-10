pragma Singleton
import QtQuick 2.15
import Qt.labs.settings 1.1

QtObject {
    id: root

    signal validationAlarmTriggered()


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

        property string validationTimersJson:
            '[{"time":"11:15","enabled":false},
              {"time":"11:30","enabled":false},
              {"time":"11:45","enabled":false},
              {"time":"11:00","enabled":false}]'

        property string machinePowerState: "Shutdown"

        property string powerFailureDate: ""
        property string powerFailureTime: ""

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

    property string machinePowerState: settings.machinePowerState

    property string powerFailureDate: settings.powerFailureDate

    property string powerFailureTime: settings.powerFailureTime



    onBlockedUsersJsonChanged:   settings.blockedUsersJson   = blockedUsersJson
    onFailedAttemptsJsonChanged: settings.failedAttemptsJson = failedAttemptsJson

    onShowDDusterChanged: settings.showDDuster = showDDuster
    onShowNetworkScreenChanged: settings.showNetworkScreen = showNetworkScreen
    onShowAuditTrailChanged: settings.showAuditTrail = showAuditTrail
    onShowProductLibChanged: settings.showProductLib = showProductLib

    onMachinePowerStateChanged: settings.machinePowerState = machinePowerState


    onPowerFailureDateChanged: settings.powerFailureDate = powerFailureDate


    onPowerFailureTimeChanged: settings.powerFailureTime = powerFailureTime


    property string validationTimersJson:
            settings.validationTimersJson


    onValidationTimersJsonChanged:
    {
        settings.validationTimersJson = validationTimersJson
    }


    // =========================================================
    // OTHER PROPERTIES
    // =========================================================
    property real productPhase: 0
    property real machinePhase: 180.0

    property bool countRejection: true

    property int rejectedCount: 0

    property int signalThreshold: 500
    property int amplitudeThreshold: 180

    property bool developerLogin: false
    property bool engineerLogin: false

    property bool coilBalancingOn: false

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

    property real digitalGain: 1.0


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


    function getCurrentUser()
    {
        // if (developerLogin)
        //     return "D/Developer"

        // if (engineerLogin)
        //     return "E/Engineer"


        var role = loggedInUserRole
        var username = loggedInUserName

        var initial = "U"

        if(role === "Admin")
            initial = "A"
        else if(role === "Supervisor")
            initial = "S"
        else if(role === "Operator")
            initial = "O"


        return initial + "/" + username
    }

    Component.onCompleted: {

        try {

            var data = JSON.parse(reportSettings.logsJson)


            if(data.created)
            {
                for(var i = 0; i < data.created.length; i++)
                {
                    reportsLogModel.insert(0,{
                        sr: i + 1,
                        fileName: data.created[i].fileName || "-",
                        type: data.created[i].type || "-",
                        action: data.created[i].action || "-",
                        date: data.created[i].date || "-",
                        from: data.created[i].from || "-",
                        to: data.created[i].to || "-",
                        by: data.created[i].by || "-"
                    })
                }
            }


            if(data.deleted)
            {
                for(var j = 0; j < data.deleted.length; j++)
                {
                    deletedFilesModel.insert(0,{
                        sr:j+1,
                        fileName:data.deleted[j].fileName || "-",
                        action:data.deleted[j].action || "-",
                        date:data.deleted[j].date || "-",
                        by:data.deleted[j].by || "-"
                    })
                }
            }


            if(data.copied)
            {
                for(var k = 0; k < data.copied.length; k++)
                {
                    copiedFilesModel.insert(0,{
                        sr:k+1,
                        fileName:data.copied[k].fileName || "-",
                        action:data.copied[k].action || "-",
                        date:data.copied[k].date || "-",
                        by:data.copied[k].by || "-"
                    })
                }
            }

        }
        catch(e)
        {
            console.log("Failed loading logs",e)
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
    function addReportLog(type, fileName, action, fromDate, toDate)
    {
        var now = new Date()

        var currentUser = getCurrentUser()

        var newSr = reportsLogModel.count + 1


        reportsLogModel.insert(0, {
            sr: 1,
            fileName: fileName,
            type: type,
            action: action,
            date: Qt.formatDate(now, "dd/MM/yyyy"),
            from: fromDate || "-",
            to: toDate || "-",
            by: currentUser
        })

        // Renumber all rows
        for (var i = 0; i < reportsLogModel.count; i++) {
            reportsLogModel.setProperty(i, "sr", i + 1)
        }

        saveLogs()
    }



    function addDeletedFileLog(fileName)
    {
        var now = new Date()

        var currentUser = getCurrentUser()

        var newSr = deletedFilesModel.count + 1


        deletedFilesModel.insert(0, {
            sr: 1,
            fileName: fileName,
            action: "Deleted",
            date: Qt.formatDate(now, "dd/MM/yyyy"),
            by: currentUser
        })

        for (var i = 0; i < deletedFilesModel.count; i++) {
            deletedFilesModel.setProperty(i, "sr", i + 1)
        }

        saveLogs()
    }



    function addCopiedFileLog(fileName)
    {
        var now = new Date()

        var currentUser = getCurrentUser()

        var newSr = copiedFilesModel.count + 1


        copiedFilesModel.insert(0, {
            sr: 1,
            fileName: fileName,
            action: "Copied",
            date: Qt.formatDate(now, "dd/MM/yyyy"),
            by: currentUser
        })

        for (var i = 0; i < copiedFilesModel.count; i++) {
            copiedFilesModel.setProperty(i, "sr", i + 1)
        }

        saveLogs()

        saveLogs()
    }

    //////////////////////////////////////////////////////////////////

    function getValidationTimers()
    {
        return JSON.parse(validationTimersJson)
    }



    function saveValidationTimers(data)
    {
        validationTimersJson = JSON.stringify(data)

    }

    function triggerValidationAlarm()
    {
        validationAlarmTriggered()
    }

    function setMachineRunning()
    {
        machinePowerState = "Running"
    }



    function setMachineShutdown()
    {
        machinePowerState = "Shutdown"
    }



    function savePowerFailureTime()
    {
        var now = new Date()

        powerFailureDate =
                Qt.formatDate(
                    now,
                    "dd/MM/yyyy"
                )


        powerFailureTime =
                Qt.formatTime(
                    now,
                    "HH:mm:ss"
                )
    }
}
