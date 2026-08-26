#pragma once

#include "DatabaseManager.h"

#include <QObject>
#include <QByteArray>
#include <QSerialPort>
#include <QSerialPortInfo>
#include <QVector>
#include <QTimer>

class SerialManager : public QObject
{
    Q_OBJECT

    Q_PROPERTY(double productPhase
                   READ productPhase
                       NOTIFY productPhaseChanged)

    Q_PROPERTY(int signal
                   READ signal
                       NOTIFY signalChanged)

    Q_PROPERTY(int amplitude
                   READ amplitude
                       NOTIFY amplitudeChanged)

    Q_PROPERTY(int coilOutput
                   READ coilOutput
                       NOTIFY coilOutputChanged)

    Q_PROPERTY(QString rawRxLog
                   READ rawRxLog
                       NOTIFY rawRxLogChanged)

    Q_PROPERTY(QString rawTxLog
                   READ rawTxLog
                       NOTIFY rawTxLogChanged)

public:
    explicit SerialManager(QObject *parent = nullptr);

    void setDatabaseManager(DatabaseManager *databaseManager);

    double productPhase() const
    {
        return m_productPhase;
    }

    int signal() const
    {
        return m_signal;
    }

    int amplitude() const
    {
        return m_amplitude;
    }

    int coilOutput() const
    {
        return m_coilOutput;
    }

    QString rawRxLog() const
    {
        return m_rawRxLog;
    }

    QString rawTxLog() const
    {
        return m_rawTxLog;
    }

    Q_INVOKABLE bool isConnected() const
    {
        return serial.isOpen();
    }

    Q_INVOKABLE void clearRxLog();
    Q_INVOKABLE void clearTxLog();
    Q_INVOKABLE void clearAllLogs();

public slots:
    void setMachinePhase(int value);
    void setSignalThreshold(int value);
    void setAmplitudeThreshold(int value);

    // D-duster ON/OFF
    void setDDuster(bool enabled);
    void setDDPower(int value);
    void setDDFrequency(int value);

    // Machine setting parameters
    void setLPF(int value);
    void setHPF(int value);

    void setOperateDelay(int value);
    void setHoldDelay(int value);
    void setRelayDelay(int value);

    void setDigitalGain(int value);
    void setAnalogGain(int value);

    // Tracking Settings
    void setTracking(bool enabled);
    void setTrackingCount(int value);
    void setTrackingThreshold(int value);
    void setTrackingTolerance(int value);

    // Batch Settings
    void setBatch(int state);

    void setCoilBalancingStatus(bool status);

signals:
    void productPhaseChanged();

    void signalChanged();

    void amplitudeChanged();

    void coilOutputChanged();

    void mcuParameterRequestReceived();

    void rawRxLogChanged();

    void rawTxLogChanged();

private slots:
    void onReadyRead();

private:
    bool openPort(const QString &port);

    void sendCommand(const QString &cmd);

    void appendRxLog(const QString &text);

    void appendTxLog(const QString &text);

    bool m_coilBalancingOn = false;

private:

    DatabaseManager *m_databaseManager = nullptr;

    QVector<int> m_coilBuffer;
    QTimer m_coilAverageTimer;

    void processCoilBuffer();



    QSerialPort serial;

    QByteArray rxBuffer;

    double m_productPhase = 0.0;   // 0 - 180

    int m_signal = 0;         // 0 - 30000

    int m_amplitude = 0;      // 0 - 14000

    int m_coilOutput = 0;     // 0 - 10000

    QString m_rawRxLog;

    QString m_rawTxLog;
};


