#include "SerialManager.h"

#include <QDebug>
#include <QRandomGenerator>
#include <QTimer>

SerialManager::SerialManager(QObject *parent)
    : QObject(parent)
{
    connect(&serial,
            &QSerialPort::readyRead,
            this,
            &SerialManager::onReadyRead);

    // connect(&m_dummyTimer,
    //         &QTimer::timeout,
    //         this,
    //         &SerialManager::generateDummyPacket);

    // m_dummyTimer.start(3000);

#ifdef Q_OS_MACOS

    openPort("/dev/cu.usbserial-10");

#elif defined(Q_OS_LINUX)

    openPort("/dev/ttyAMA0");

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

    while (true)
    {
        // Find packet start
        int start = rxBuffer.indexOf('N');

        if (start < 0)
        {
            rxBuffer.clear();
            return;
        }

        // Find packet end
        int end = rxBuffer.indexOf('n', start);

        if (end < 0)
            return;     // wait for complete packet


        QByteArray packet =
            rxBuffer.mid(start, end - start + 1);

        rxBuffer.remove(0, end + 1);


        QString str =
            QString::fromUtf8(packet).trimmed();

        qDebug() << "RX :" << str;


        // Remove start/end markers
        str.remove(0,1);    // remove N
        str.chop(1);        // remove n
        str = str.trimmed();


        QStringList fields =
            str.split(',');


        if (fields.size() != 4)
        {
            qDebug() << "Invalid packet";
            continue;
        }


        bool ok1, ok2, ok3, ok4;

        int phaseRaw =
            fields[0].trimmed().toInt(&ok1);

        double phase =
            phaseRaw / 10.0;

        int signal =
            fields[1].trimmed().toInt(&ok2);

        int amplitude =
            fields[2].trimmed().toInt(&ok3);

        int coil =
            fields[3].trimmed().toInt(&ok4);


        if (!(ok1 && ok2 && ok3 && ok4))
        {
            qDebug() << "Non numeric packet";
            continue;
        }


        // Validate ranges
        if (phase > 180 ||
            signal > 30000 ||
            amplitude > 14000 ||
            coil > 10000)
        {
            qDebug() << "Packet out of range";
            continue;
        }


        // Update properties
        if (!qFuzzyCompare(m_productPhase + 1.0,
                           phase + 1.0))
        {
            m_productPhase = phase;

            emit productPhaseChanged();
        }


        if (signal != m_signal)
        {
            m_signal = signal;
            emit signalChanged();
        }


        if (amplitude != m_amplitude)
        {
            m_amplitude = amplitude;
            emit amplitudeChanged();
        }


        if (coil != m_coilOutput)
        {
            m_coilOutput = coil;
            emit coilOutputChanged();
        }


        qDebug() << "Phase     :" << m_productPhase;
        qDebug() << "Signal    :" << m_signal;
        qDebug() << "Amplitude :" << m_amplitude;
        qDebug() << "Coil Out  :" << m_coilOutput;
    }
}

// void SerialManager::generateDummyPacket()
// {
//     int phase =
//         QRandomGenerator::global()->bounded(181);

//     int signal =
//         QRandomGenerator::global()->bounded(
//             QRandomGenerator::global()->bounded(30001));

//     int amplitude =
//         QRandomGenerator::global()->bounded(
//             QRandomGenerator::global()->bounded(14001));

//     int coil =
//         QRandomGenerator::global()->bounded(
//             QRandomGenerator::global()->bounded(10001));


//     QString packet =
//         QString("N %1,%2,%3,%4 n")
//             .arg(phase,5,10,QChar('0'))
//             .arg(signal,5,10,QChar('0'))
//             .arg(amplitude,5,10,QChar('0'))
//             .arg(coil,5,10,QChar('0'));


//     qDebug() << "Dummy RX :" << packet;


//     if (phase != m_productPhase)
//     {
//         m_productPhase = phase;
//         emit productPhaseChanged();
//     }

//     if (signal != m_signal)
//     {
//         m_signal = signal;
//         emit signalChanged();
//     }

//     if (amplitude != m_amplitude)
//     {
//         m_amplitude = amplitude;
//         emit amplitudeChanged();
//     }

//     if (coil != m_coilOutput)
//     {
//         m_coilOutput = coil;
//         emit coilOutputChanged();
//     }

//     qDebug() << "Phase     :" << m_productPhase;
//     qDebug() << "Signal    :" << m_signal;
//     qDebug() << "Amplitude :" << m_amplitude;
//     qDebug() << "Coil Out  :" << m_coilOutput;
// }
