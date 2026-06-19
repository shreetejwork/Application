#pragma once

#include <QObject>
#include <QByteArray>
#include <QSerialPort>
#include <QSerialPortInfo>

class SerialManager : public QObject
{
    Q_OBJECT

    Q_PROPERTY(int productPhase
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

public:
    explicit SerialManager(QObject *parent = nullptr);

    int productPhase() const
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

    Q_INVOKABLE bool isConnected() const
    {
        return serial.isOpen();
    }

public slots:
    void setMachinePhase(int value);
    void setSignalThreshold(int value);
    void setAmplitudeThreshold(int value);

signals:
    void productPhaseChanged();

    void signalChanged();

    void amplitudeChanged();

    void coilOutputChanged();

private slots:
    void onReadyRead();

private:
    bool openPort(const QString &port);

    void sendCommand(const QString &cmd);

    QSerialPort serial;

    QByteArray rxBuffer;

    int m_productPhase = 0;   // 0 - 180

    int m_signal = 0;         // 0 - 30000

    int m_amplitude = 0;      // 0 - 14000

    int m_coilOutput = 0;     // 0 - 10000
};
