#ifndef DATABASEMANAGER_H
#define DATABASEMANAGER_H

#include <QObject>
#include <QString>
#include <QStringList>
#include <QVariantMap>
#include <QVariantList>

class DatabaseManager : public QObject
{
    Q_OBJECT

public:

    explicit DatabaseManager(QObject *parent = nullptr);

    bool initialize();

    // =====================================================
    // USERS
    // =====================================================

    Q_INVOKABLE bool insertUser(
        const QString &fpid,
        const QString &id,
        const QString &username,
        const QString &password,
        const QString &role);

    Q_INVOKABLE bool deleteUser(
        const QString &role,
        const QString &username);

    Q_INVOKABLE QStringList getUsersByRole(
        const QString &role);

    Q_INVOKABLE bool updatePassword(
        const QString &role,
        const QString &username,
        const QString &newPassword);

    Q_INVOKABLE bool validateLogin(
        const QString &role,
        const QString &username,
        const QString &password);

    Q_INVOKABLE bool isPasswordExpired(
        const QString &username);

    Q_INVOKABLE int daysUntilPasswordExpiry(
        const QString &username);

    // =====================================================
    // COIL
    // =====================================================

    Q_INVOKABLE bool saveCoilOutputAverage(int average);

    Q_INVOKABLE QVariantList getCoilOutputHistory();

    void printAllUsers();

    // =====================================================
    // MACHINE SETTINGS
    // =====================================================

    Q_INVOKABLE bool saveMachinePhaseSettings(
        const QString &machinePhase,
        int signalThr,
        int ampThr);

    Q_INVOKABLE bool saveDDPower(int ddPower);

    Q_INVOKABLE bool saveDDFrequency(double ddFreq);

    Q_INVOKABLE QVariantMap getMachinePhaseSettings();

    Q_INVOKABLE QVariantMap getDDSettings();


    // =====================================================
    // FILTER SETTINGS
    // =====================================================

    Q_INVOKABLE bool saveS1Settings(
        double lpf,
        double hpf,
        int operateDelay,
        int holdDelay,
        int relayDelay,
        double digitalGain,
        double analogGain);

    Q_INVOKABLE QVariantMap getS1Settings();

    // =====================================================
    // AUDIT
    // =====================================================

    Q_INVOKABLE bool addAuditTrailRecord(
        const QString &user,
        const QString &oldValue,
        const QString &newValue,
        const QString &remark);

    Q_INVOKABLE QVariantList getAuditTrailReport();

    Q_INVOKABLE bool clearAuditTrail();

    // =====================================================
    // BATCH
    // =====================================================

    Q_INVOKABLE int createBatchReport(
        const QString &batchId,
        const QString &productName,
        const QString &productCode,
        const QString &productSno,
        const QString &startedAt,
        const QString &startedBy);

    Q_INVOKABLE bool addBatchReportEvent(
        int batchReportId,
        const QString &eventType,
        const QString &eventTime,
        const QString &user,
        int rejectCount = 0);

    Q_INVOKABLE bool finishBatchReport(
        int batchReportId,
        const QString &endedAt,
        int runDuration,
        int pauseDuration,
        int totalDuration,
        const QString &endedBy,
        int rejectionCount);

    Q_INVOKABLE QVariantList getBatchReports();

    Q_INVOKABLE QVariantList getBatchReportEvents(
        int batchReportId);

    Q_INVOKABLE bool deleteAllBatchReports();

    // =====================================================
    // MACHINE INFO
    // =====================================================

    Q_INVOKABLE bool saveMachineInfo(
        const QString &supplierName,
        const QString &serialNumber,
        const QString &machineId,
        const QString &userName,
        const QString &location,
        const QString &machineType);

    Q_INVOKABLE QVariantMap getMachineInfo();

    // =====================================================
    // PRODUCT LIBRARY
    // =====================================================

    Q_INVOKABLE bool createProductLibraryTable(
        int groupNo);

    Q_INVOKABLE bool addProductLibraryProduct(
        int groupNo,
        const QString &productName,
        const QString &productCode
        );

    Q_INVOKABLE QVariantList getProductLibraryProducts(
        int groupNo);

    Q_INVOKABLE bool deleteProductLibraryProduct(
        int groupNo,
        int srNo);

    Q_INVOKABLE bool setActiveProductLibraryProduct(
        int groupNo,
        int srNo);

    Q_INVOKABLE bool applyActiveProductParameters(
        int groupNo,
        int srNo);

    Q_INVOKABLE bool productLibraryTableExists(
        int groupNo);

    Q_INVOKABLE bool productLibraryProductExists(
        int groupNo,
        int srNo);

    Q_INVOKABLE QVariantMap getActiveProduct();

private:

    void createTables();

signals:
    void machineParametersChanged();

};


#endif // DATABASEMANAGER_H
