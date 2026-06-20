#pragma once

#include <QObject>
#include <QByteArray>
#include <QSerialPort>
#include <QSerialPortInfo>

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

public:
    explicit SerialManager(QObject *parent = nullptr);

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

    Q_INVOKABLE bool isConnected() const
    {
        return serial.isOpen();
    }

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

    // Batch Settings
    void setBatch(int state);

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

// private slots:
//     void generateDummyPacket();

// private:
//     QTimer m_dummyTimer;


    QSerialPort serial;

    QByteArray rxBuffer;

    double m_productPhase = 0.0;   // 0 - 180

    int m_signal = 0;         // 0 - 30000

    int m_amplitude = 0;      // 0 - 14000

    int m_coilOutput = 0;     // 0 - 10000
};


