#ifndef DATABASEMANAGER_H
#define DATABASEMANAGER_H

#include <QObject>
#include <QStringList>
#include <QVariantMap>

class DatabaseManager : public QObject
{
    Q_OBJECT
public:
    explicit DatabaseManager(QObject *parent = nullptr);

    bool initialize();

    // Example functions
    Q_INVOKABLE bool insertUser(
        const QString &fpid,
        const QString &id,
        const QString &username,
        const QString &password,
        const QString &role);

    Q_INVOKABLE bool deleteUser(
        const QString &role,
        const QString &username);


    Q_INVOKABLE QStringList getUsersByRole(const QString &role);

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

    // Q_INVOKABLE bool updatePassword(
    //     const QString &username,
    //     const QString &newPassword);

    Q_INVOKABLE bool saveCoilOutputAverage(int average);

    void printAllUsers();

    Q_INVOKABLE bool saveMachinePhaseSettings(
        const QString &machinePhase,
        int signalThr,
        int ampThr);

    Q_INVOKABLE bool saveDDPower(int ddPower);

    Q_INVOKABLE bool saveDDFrequency(double ddFreq);

    Q_INVOKABLE QVariantMap getMachinePhaseSettings();

    Q_INVOKABLE QVariantMap getDDSettings();

    Q_INVOKABLE bool saveS1Settings(
        double lpf,
        double hpf,
        int operateDelay,
        int holdDelay,
        int relayDelay,
        double digitalGain,
        double analogGain
        );

    Q_INVOKABLE QVariantMap getS1Settings();

private:
    void createTables();

public:

   Q_INVOKABLE bool saveMachineInfo(const QString &supplierName,
                         const QString &serialNumber,
                         const QString &machineId,
                         const QString &userName,
                         const QString &location,
                         const QString &machineType);

    Q_INVOKABLE QVariantMap getMachineInfo();

    Q_INVOKABLE QVariantList getCoilOutputHistory();
};

#endif // DATABASEMANAGER_H
