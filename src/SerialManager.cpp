#include "SerialManager.h"

#include <QDebug>

SerialManager::SerialManager(QObject *parent)
    : QObject(parent)
{
    connect(&serial,
            &QSerialPort::readyRead,
            this,
            &SerialManager::onReadyRead);

#ifdef Q_OS_MACOS

    openPort("/dev/cu.usbserial-10");

#elif defined(Q_OS_LINUX)

    openPort("/dev/serial0");

#endif
}


bool SerialManager::openPort(const QString &port)
{
    if (serial.isOpen())
        serial.close();

    serial.setPortName(port);

    serial.setBaudRate(QSerialPort::Baud115200);
    serial.setDataBits(QSerialPort::Data8);
    serial.setParity(QSerialPort::NoParity);
    serial.setStopBits(QSerialPort::OneStop);
    serial.setFlowControl(QSerialPort::NoFlowControl);

    bool ok = serial.open(QIODevice::ReadWrite);

    qDebug() << "Opening :" << port;
    qDebug() << "Status  :" << ok;
    qDebug() << "Error   :" << serial.errorString();

    return ok;
}


void SerialManager::sendCommand(const QString &cmd)
{
    if (!serial.isOpen())
    {
        qDebug() << "UART not open";
        return;
    }

    QByteArray data = cmd.toUtf8();

    qint64 bytes = serial.write(data);

    bool ok = serial.waitForBytesWritten(1000);

    qDebug() << "TX :" << cmd.trimmed();
    // qDebug() << "Bytes :" << bytes;
    // qDebug() << "Written :" << ok;
    // qDebug() << "Pending :" << serial.bytesToWrite();
}

void SerialManager::setMachinePhase(int value)
{
    QString v =
        QString("%1")
            .arg(value,5,10,QChar('0'));

    sendCommand(QString("{MP%1}").arg(v));
}


void SerialManager::setSignalThreshold(int value)
{
    QString v =
        QString("%1")
            .arg(value,5,10,QChar('0'));

    sendCommand(QString("{TS%1}").arg(v));
}


void SerialManager::setAmplitudeThreshold(int value)
{
    QString v =
        QString("%1")
            .arg(value,5,10,QChar('0'));

    sendCommand(QString("{TA%1}").arg(v));
}


void SerialManager::onReadyRead()
{
    rxBuffer += serial.readAll();

    while (rxBuffer.contains('\n'))
    {
        int index = rxBuffer.indexOf('\n');

        QByteArray packet =
            rxBuffer.left(index);

        rxBuffer.remove(0,index+1);

        QString str =
            QString::fromUtf8(packet).trimmed();

        QStringList fields =
            str.split(',');

        for (QString f : fields)
        {
            f = f.trimmed();

            if (f.startsWith("PC="))
            {
                QString code =
                    f.mid(3);

                if (code != m_productCode)
                {
                    m_productCode = code;
                    emit productCodeChanged();
                }
            }
            else if (f.startsWith("S="))
            {
                int value =
                    f.mid(2).toInt();

                if (value != m_signal)
                {
                    m_signal = value;
                    emit signalChanged();
                }
            }
            else if (f.startsWith("A="))
            {
                int value =
                    f.mid(2).toInt();

                if (value != m_amplitude)
                {
                    m_amplitude = value;
                    emit amplitudeChanged();
                }
            }
        }

        qDebug() << "RX :" << str;
    }
}
