#pragma once

#include <QObject>
#include <QByteArray>
#include <QSerialPort>
#include <QSerialPortInfo>

class SerialManager : public QObject
{
    Q_OBJECT

    Q_PROPERTY(int signal
                   READ signal
                       NOTIFY signalChanged)

    Q_PROPERTY(int amplitude
                   READ amplitude
                       NOTIFY amplitudeChanged)

    Q_PROPERTY(QString productCode
                   READ productCode
                       NOTIFY productCodeChanged)

public:
    explicit SerialManager(QObject *parent = nullptr);

    int signal() const { return m_signal; }
    int amplitude() const { return m_amplitude; }
    QString productCode() const { return m_productCode; }

    Q_INVOKABLE bool isConnected() const
    {
        return serial.isOpen();
    }

public slots:
    void setMachinePhase(int value);
    void setSignalThreshold(int value);
    void setAmplitudeThreshold(int value);

signals:
    void signalChanged();
    void amplitudeChanged();
    void productCodeChanged();

private slots:
    void onReadyRead();

private:
    bool openPort(const QString &port);
    void sendCommand(const QString &cmd);

    QSerialPort serial;
    QByteArray rxBuffer;

    int m_signal = 0;
    int m_amplitude = 0;
    QString m_productCode;
};
