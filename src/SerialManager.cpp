#include "SerialManager.h"

#include <QDebug>
#include <QRandomGenerator>
#include <QTimer>

#include <QSerialPortInfo>

QString SerialManager::findAvailablePort()
{
    QList<QSerialPortInfo> ports =
        QSerialPortInfo::availablePorts();


    qDebug() << "Available Serial Ports:";


    for(const QSerialPortInfo &info : ports)
    {
        qDebug()
        << "Port:"
        << info.systemLocation()
        << "Description:"
        << info.description()
        << "Manufacturer:"
        << info.manufacturer();


        // Return first available serial device
        return info.systemLocation();
    }


    return QString();
}



SerialManager::SerialManager(QObject *parent)
    : QObject(parent)
{
    connect(&serial,
            &QSerialPort::readyRead,
            this,
            &SerialManager::onReadyRead);


    connect(&m_coilAverageTimer,
            &QTimer::timeout,
            this,
            &SerialManager::processCoilBuffer);


    m_coilAverageTimer.start(5 * 60 * 1000);    // 5 minutes


#ifdef Q_OS_MACOS

    openPort("/dev/cu.usbserial-10");


#elif defined(Q_OS_LINUX)

    QString detectedPort = findAvailablePort();


    if(!detectedPort.isEmpty())
    {
        qDebug() << "Detected Serial Port:"
                 << detectedPort;


        if(openPort(detectedPort))
        {
            qDebug() << "Serial communication started successfully";
        }
        else
        {
            qDebug() << "Failed to open serial port";
        }
    }
    else
    {
        qDebug() << "No serial port detected";
    }


#endif
}

void SerialManager::setCoilBalancingStatus(bool status)
{
    if(m_coilBalancingOn == status)
        return;

    m_coilBalancingOn = status;

    qDebug() << "SerialManager Coil Balancing:"
             << (m_coilBalancingOn ? "ON" : "OFF");
}

void SerialManager::setDatabaseManager(DatabaseManager *databaseManager)
{
    m_databaseManager = databaseManager;
}

// =========== Batch Settings =================

void SerialManager::setBatch(int state)
{
    switch(state)
    {
    case 1:     // Start
        sendCommand("{O11111}");
        break;

    case 2:     // Pause
        sendCommand("{O01010}");
        break;

    default:    // End
        sendCommand("{O00000}");
        break;
    }
}

// ========== Machine Settings ===============

void SerialManager::setLPF(int value)
{
    QString v =
        QString("%1")
            .arg(value,5,10,QChar('0'));

    sendCommand(QString("{E%1}").arg(v));
}


void SerialManager::setHPF(int value)
{
    QString v =
        QString("%1")
            .arg(value,5,10,QChar('0'));

    sendCommand(QString("{F%1}").arg(v));
}


void SerialManager::setOperateDelay(int value)
{
    QString v =
        QString("%1")
            .arg(value,5,10,QChar('0'));

    sendCommand(QString("{H%1}").arg(v));
}


void SerialManager::setHoldDelay(int value)
{
    QString v =
        QString("%1")
            .arg(value,5,10,QChar('0'));

    sendCommand(QString("{G%1}").arg(v));
}


void SerialManager::setRelayDelay(int value)
{
    QString v =
        QString("%1")
            .arg(value,5,10,QChar('0'));

    sendCommand(QString("{I%1}").arg(v));
}


void SerialManager::setDigitalGain(int value)
{
    QString v =
        QString("%1")
            .arg(value,5,10,QChar('0'));

    sendCommand(QString("{J%1}").arg(v));
}


void SerialManager::setAnalogGain(int value)
{
    QString v =
        QString("%1")
            .arg(value,5,10,QChar('0'));

    sendCommand(QString("{K%1}").arg(v));
}

// =============== D-duster ======================

void SerialManager::setDDuster(bool enabled)
{
    sendCommand(enabled ? "{L11111}" : "{L00000}");
}

void SerialManager::setDDPower(int value)
{
    QString v =
        QString("%1")
            .arg(value,5,10,QChar('0'));

    sendCommand(QString("{N%1}").arg(v));
}


void SerialManager::setDDFrequency(int value)
{
    QString v =
        QString("%1")
            .arg(value, 5, 10, QChar('0'));

    sendCommand(QString("{M%1}").arg(v));
}

// ================= MD Data ==================

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

}

void SerialManager::setMachinePhase(int value)
{
    QString v =
        QString("%1")
            .arg(value,5,10,QChar('0'));

    sendCommand(QString("{A%1}").arg(v));
}


void SerialManager::setSignalThreshold(int value)
{
    QString v =
        QString("%1")
            .arg(value,5,10,QChar('0'));

    sendCommand(QString("{B%1}").arg(v));
}


void SerialManager::setAmplitudeThreshold(int value)
{
    QString v =
        QString("%1")
            .arg(value,5,10,QChar('0'));

    sendCommand(QString("{C%1}").arg(v));
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


        // Always update UI coil output value
        if (coil != m_coilOutput)
        {
            m_coilOutput = coil;
            emit coilOutputChanged();
        }


        // Only store samples when Coil Balancing is OFF
        if(!m_coilBalancingOn)
        {
            m_coilBuffer.append(coil);
        }
        else
        {
            qDebug() << "Coil Balancing ON - Display only, not storing coil value";
        }

        qDebug() << "Phase     :" << m_productPhase;
        qDebug() << "Signal    :" << m_signal;
        qDebug() << "Amplitude :" << m_amplitude;
        qDebug() << "Coil Out  :" << m_coilOutput;
    }
}

void SerialManager::processCoilBuffer()
{
    if (m_coilBuffer.isEmpty())
    {
        qDebug() << "No coil samples received in last 5 minutes.";
        return;
    }

    qint64 sum = 0;

    for (int value : m_coilBuffer)
        sum += value;


    int average =
        static_cast<int>(
            static_cast<double>(sum) /
            m_coilBuffer.size()
            );


    qDebug() << "--------------------------------";
    qDebug() << "5 Minute Coil Statistics";
    qDebug() << "Samples :" << m_coilBuffer.size();
    qDebug() << "Average :" << average;
    qDebug() << "--------------------------------";


    // Save 5 minute average into database
    if (m_databaseManager)
    {
        bool saved =
            m_databaseManager->saveCoilOutputAverage(average);

        if(saved)
        {
            qDebug() << "Coil average saved successfully.";
        }
        else
        {
            qDebug() << "Failed to save coil average.";
        }
    }
    else
    {
        qDebug() << "DatabaseManager not connected.";
    }


    // Clear buffer for next 5 minute cycle
    m_coilBuffer.clear();
}
