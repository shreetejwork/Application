#include "SerialManager.h"

#include <QDebug>
#include <QRandomGenerator>
#include <QTimer>
#include <QFile>
#include <QSerialPortInfo>
#include <QRegularExpression>
#include <QtEndian>

#include <QTime>

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

#include <QSerialPortInfo>

#elif defined(Q_OS_LINUX)

    bool connected = false;

    const QList<QSerialPortInfo> availablePorts =
        QSerialPortInfo::availablePorts();

    qDebug() << "Available Serial Ports:";

    for (const QSerialPortInfo &info : availablePorts)
    {
        qDebug() << "--------------------------------";
        qDebug() << "Port Name      :" << info.portName();
        qDebug() << "System Location:" << info.systemLocation();
        qDebug() << "Description    :" << info.description();
        qDebug() << "Manufacturer   :" << info.manufacturer();

        QString port = info.systemLocation();

        qDebug() << "Trying:" << port;

        if (openPort(port))
        {
            qDebug() << "Connected to:" << port;
            connected = true;
            break;
        }

        qDebug() << "Failed:" << port;
    }

    if (!connected)
    {
        qDebug() << "No usable serial port found.";
    }

#endif
}

void SerialManager::appendRxLog(const QString &text)
{
    m_rawRxLog += "[" +
                  QTime::currentTime().toString("HH:mm:ss.zzz") +
                  "] " +
                  text +
                  "\n";

    QStringList lines = m_rawRxLog.split('\n');

    while (lines.size() > 500)
        lines.removeFirst();

    m_rawRxLog = lines.join('\n');

    emit rawRxLogChanged();
}

void SerialManager::appendTxLog(const QString &text)
{
    m_rawTxLog += "[" +
                  QTime::currentTime().toString("HH:mm:ss.zzz") +
                  "] " +
                  text +
                  "\n";

    QStringList lines = m_rawTxLog.split('\n');

    while (lines.size() > 500)
        lines.removeFirst();

    m_rawTxLog = lines.join('\n');

    emit rawTxLogChanged();
}

void SerialManager::clearRxLog()
{
    m_rawRxLog.clear();
    emit rawRxLogChanged();
}

void SerialManager::clearTxLog()
{
    m_rawTxLog.clear();
    emit rawTxLogChanged();
}

void SerialManager::clearAllLogs()
{
    m_rawRxLog.clear();
    m_rawTxLog.clear();

    emit rawRxLogChanged();
    emit rawTxLogChanged();
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

// =============== Tracking Settings ==================

void SerialManager::setTracking(bool enabled)
{
    sendCommand(enabled ? "{D11111}" : "{D00000}");
}

void SerialManager::setTrackingCount(int value)
{
    QString v =
        QString("%1")
            .arg(value, 5, 10, QChar('0'));

    sendCommand(QString("{P%1}").arg(v));
}


void SerialManager::setTrackingThreshold(int value)
{
    QString v =
        QString("%1")
            .arg(value, 5, 10, QChar('0'));

    sendCommand(QString("{Q%1}").arg(v));
}


void SerialManager::setTrackingTolerance(int value)
{
    QString v =
        QString("%1")
            .arg(value, 5, 10, QChar('0'));

    sendCommand(QString("{R%1}").arg(v));
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
    if(serial.isOpen())
        serial.close();


    serial.setPortName(port);

    serial.setBaudRate(115200);
    serial.setDataBits(QSerialPort::Data8);
    serial.setParity(QSerialPort::NoParity);
    serial.setStopBits(QSerialPort::OneStop);
    serial.setFlowControl(QSerialPort::NoFlowControl);

    serial.setReadBufferSize(8192);


    bool ok = serial.open(QIODevice::ReadWrite);


    qDebug() << "==============================";
    qDebug() << "Opening Port :" << port;
    qDebug() << "Status       :" << ok;
    qDebug() << "Actual Port  :" << serial.portName();
    qDebug() << "Error        :" << serial.errorString();
    qDebug() << "==============================";


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

    appendTxLog(cmd.trimmed());

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

bool SerialManager::parseXyPlotFrame(const QByteArray &frame, QVariantList &outData)
{
    if (frame.size() != 84)
    {
        qDebug() << "XY frame rejected: size=" << frame.size();
        return false;
    }

    if (static_cast<quint8>(frame.at(0)) != 0xA5 ||
        static_cast<quint8>(frame.at(1)) != 0x5A ||
        static_cast<quint8>(frame.at(82)) != 0xE9 ||
        static_cast<quint8>(frame.at(83)) != 0x43)
    {
        qDebug() << "XY frame rejected: invalid markers";
        return false;
    }

    return decodeXyPlotPayload(frame.mid(2, 80), outData);
}

bool SerialManager::decodeXyPlotPayload(const QByteArray &payload, QVariantList &outData)
{
    if (payload.size() != 80)
    {
        qDebug() << "XY payload rejected: size=" << payload.size();
        return false;
    }

    outData.clear();
    quint16 firstRawValue = 0;
    quint16 lastRawValue = 0;

    for (int i = 0; i < 40; ++i)
    {
        const int offset = i * 2;
        const quint16 value = (static_cast<quint16>(static_cast<quint8>(payload.at(offset))) << 8) |
                              static_cast<quint16>(static_cast<quint8>(payload.at(offset + 1)));

        if (i == 0)
            firstRawValue = value;
        lastRawValue = value;

        const qreal xValue = -90.0 + (180.0 * i / 39.0);
        const qreal yValue = qBound(-100.0,
                                    static_cast<qreal>(value) / 3.0,
                                    100.0);

        QVariantMap point;
        point["x"] = xValue;
        point["y"] = yValue;
        outData.append(point);
    }

    qDebug() << "Decoded XY payload: points=" << outData.size();
    qDebug() << "XY frame received: 84 bytes"
             << "XY payload: 80 bytes"
             << "XY points:" << outData.size()
             << "XY first value:" << firstRawValue
             << "XY last value:" << lastRawValue;
    return !outData.isEmpty();
}

void SerialManager::updateXyPlotData(const QVariantList &data)
{
    if (m_xyPlotData == data)
        return;

    m_xyPlotData = data;
    emit xyPlotDataChanged();

    qDebug() << "XY plot data updated with" << m_xyPlotData.size() << "points";
}

void SerialManager::onReadyRead()
{
    QByteArray data = serial.readAll();

    if (!data.isEmpty())
    {
        // Show exactly what arrived from UART
        appendRxLog(QString::fromUtf8(data));

        // Existing buffer for parser
        rxBuffer.append(data);
        xyRxBuffer.append(data);
    }


    // Safety protection
    if(rxBuffer.size() > 4096)
    {
        qDebug() << "RX buffer overflow. Clearing.";
        rxBuffer.clear();
        return;
    }

    if (xyRxBuffer.size() > 4096)
    {
        qDebug() << "XY RX buffer overflow. Clearing.";
        xyRxBuffer.clear();
    }

    while (true)
    {
        const qsizetype startIndex = xyRxBuffer.indexOf(QByteArray::fromHex("A55A"));
        if (startIndex < 0)
            break;

        if (startIndex > 0)
            xyRxBuffer.remove(0, startIndex);

        if (xyRxBuffer.size() < 84)
            break;

        const QByteArray frame = xyRxBuffer.left(84);
        xyRxBuffer.remove(0, 84);

        if (static_cast<quint8>(frame.at(82)) != 0xE9 ||
            static_cast<quint8>(frame.at(83)) != 0x43)
        {
            qDebug() << "XY frame rejected: invalid end marker";
            continue;
        }

        QVariantList decodedData;
        if (parseXyPlotFrame(frame, decodedData))
            updateXyPlotData(decodedData);
    }

    // Some MCU/USB serial adapters deliver the frame as space-separated hex text.
    while (xyRxBuffer.indexOf(QByteArray::fromHex("A55A")) < 0)
    {
        const QString text = QString::fromLatin1(xyRxBuffer);
        QRegularExpression tokenExpression("\\S+");
        QRegularExpressionMatchIterator matches = tokenExpression.globalMatch(text);
        QList<QRegularExpressionMatch> tokenMatches;

        while (matches.hasNext())
            tokenMatches.append(matches.next());

        int startToken = -1;
        for (int i = 0; i + 1 < tokenMatches.size(); ++i)
        {
            if (tokenMatches[i].captured().compare("A5", Qt::CaseInsensitive) == 0 &&
                tokenMatches[i + 1].captured().compare("5A", Qt::CaseInsensitive) == 0)
            {
                startToken = i;
                break;
            }
        }

        if (startToken < 0)
            break;

        if (tokenMatches.size() < startToken + 84)
            break;

        if (tokenMatches[startToken + 82].captured().compare("E9", Qt::CaseInsensitive) != 0 ||
            tokenMatches[startToken + 83].captured().compare("43", Qt::CaseInsensitive) != 0)
        {
            xyRxBuffer.remove(0, tokenMatches[startToken].capturedStart() + 2);
            continue;
        }

        QByteArray frame;
        bool validFrame = true;
        for (int i = startToken; i < startToken + 84; ++i)
        {
            const QByteArray byte = QByteArray::fromHex(tokenMatches[i].captured().toLatin1());
            if (byte.size() != 1)
            {
                validFrame = false;
                break;
            }
            frame.append(byte);
        }

        const int consumed = tokenMatches[startToken + 83].capturedEnd();
        xyRxBuffer.remove(0, consumed);

        if (!validFrame)
            continue;

        QVariantList decodedData;
        if (parseXyPlotFrame(frame, decodedData))
            updateXyPlotData(decodedData);
    }

    // MCU requesting parameters
        if (rxBuffer.contains("{*****}"))
    {
        rxBuffer.replace("{*****}", "");

        qDebug() << "MCU requested machine settings.";

        emit mcuParameterRequestReceived();
    }

    while (true)
    {
        // Find packet start
        int start = rxBuffer.indexOf('N');

        if (start < 0)
        {
            if(rxBuffer.size() > 10)
                rxBuffer.remove(0, rxBuffer.size()-10);

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


        if (fields.size() != 5)
        {
            qDebug() << "Invalid packet. Expected 5 parameters, received:"
                     << fields.size();
            continue;
        }


        bool ok1, ok2, ok3, ok4, ok5;


        // =====================================================
        // 1st Parameter - Product Phase
        // =====================================================

        int phaseRaw =
            fields[0].trimmed().toInt(&ok1);

        double phase =
            phaseRaw / 10.0;


        // =====================================================
        // 2nd Parameter - Signal
        // =====================================================

        int signal =
            fields[1].trimmed().toInt(&ok2);


        // =====================================================
        // 3rd Parameter - Amplitude
        // =====================================================

        int amplitude =
            fields[2].trimmed().toInt(&ok3);


        // =====================================================
        // 4th Parameter - Coil
        // =====================================================

        int coil =
            fields[3].trimmed().toInt(&ok4);


        // =====================================================
        // 5th Parameter - Tracking Phase
        // Same handling as Product Phase
        // =====================================================

        int trackingPhaseRaw =
            fields[4].trimmed().toInt(&ok5);

        double trackingPhaseValue =
            trackingPhaseRaw / 10.0;

        if (!(ok1 && ok2 && ok3 && ok4))
        {
            qDebug() << "Non numeric packet";
            continue;
        }


        // Validate ranges
        if (phase < 0 ||
            phase > 180 ||
            signal < 0 ||
            signal > 30000 ||
            amplitude < 0 ||
            amplitude > 14000 ||
            coil < 0 ||
            coil > 10000)
        {
            qDebug() << "Main packet out of range";
            continue;
        }

        // =====================================================
        // Validate 5th parameter - Tracking Phase
        // Valid range: 0 to 180
        // Invalid value will be sent to QML as "---"
        // =====================================================

        QString newTrackingPhase;

        if (!ok5 ||
            trackingPhaseValue < 0 ||
            trackingPhaseValue > 180)
        {
            qDebug() << "Invalid Tracking Phase:"
                     << fields[4];

            newTrackingPhase = "---";
        }
        else
        {
            newTrackingPhase =
                QString::number(trackingPhaseValue, 'f', 1);
        }


        // Update properties
        if (!qFuzzyCompare(m_productPhase + 1.0,
                           phase + 1.0))
        {
            m_productPhase = phase;

            emit productPhaseChanged();
        }

        if (m_trackingPhase != newTrackingPhase)
        {
            m_trackingPhase = newTrackingPhase;

            emit trackingPhaseChanged();
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
    }
}

QString SerialManager::trackingPhase() const
{
    return m_trackingPhase;
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
