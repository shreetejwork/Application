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
    QString text = QString::fromLatin1(frame);
    text.replace('\r', ' ');
    text.replace('\n', ' ');

    QStringList tokens = text.split(QRegularExpression("\\s+"), Qt::SkipEmptyParts);
    if (tokens.size() < 4)
    {
        qDebug() << "XY frame rejected: not enough ASCII tokens";
        return false;
    }

    int startIndex = -1;
    for (int i = 0; i + 1 < tokens.size(); ++i)
    {
        if (tokens[i].compare("A5", Qt::CaseInsensitive) == 0 &&
            tokens[i + 1].compare("5A", Qt::CaseInsensitive) == 0)
        {
            startIndex = i;
            break;
        }
    }

    if (startIndex < 0)
    {
        qDebug() << "XY frame rejected: no A5 5A start marker in ASCII stream";
        return false;
    }

    int endIndex = -1;
    for (int i = startIndex + 2; i + 1 < tokens.size(); ++i)
    {
        if (tokens[i].compare("E9", Qt::CaseInsensitive) == 0 &&
            tokens[i + 1].compare("43", Qt::CaseInsensitive) == 0)
        {
            endIndex = i;
            break;
        }
    }

    if (endIndex < 0)
    {
        qDebug() << "XY frame rejected: no E9 43 end marker in ASCII stream";
        return false;
    }

    QByteArray payload;
    for (int i = startIndex + 2; i < endIndex; ++i)
    {
        QByteArray byte = QByteArray::fromHex(tokens[i].toLatin1());
        if (byte.size() == 1)
            payload.append(byte.at(0));
    }

    if (payload.size() != 80)
    {
        qDebug() << "XY payload rejected: ASCII payload size=" << payload.size();
        return false;
    }

    qDebug() << "XY plot packet accepted: ASCII A5 5A -> payload 80 bytes -> E9 43";
    return decodeXyPlotPayload(payload, outData);
}

bool SerialManager::decodeXyPlotPayload(const QByteArray &payload, QVariantList &outData)
{
    if (payload.size() != 80)
    {
        qDebug() << "XY payload rejected: size=" << payload.size();
        return false;
    }

    outData.clear();

    qDebug() << "XY payload bytes:" << payload.toHex();

    for (int i = 0; i + 3 < payload.size(); i += 4)
    {
        const quint8 xHi = static_cast<quint8>(payload.at(i));
        const quint8 xLo = static_cast<quint8>(payload.at(i + 1));
        const quint8 yHi = static_cast<quint8>(payload.at(i + 2));
        const quint8 yLo = static_cast<quint8>(payload.at(i + 3));

        const quint16 xRaw = (static_cast<quint16>(xHi) << 8) |
                             static_cast<quint16>(xLo);
        const quint16 yRaw = (static_cast<quint16>(yHi) << 8) |
                             static_cast<quint16>(yLo);

        const qreal xValue = qBound(-100.0,
                                   static_cast<qreal>(xRaw) / 3.0,
                                   100.0);
        const qreal yValue = qBound(-100.0,
                                   static_cast<qreal>(yRaw) / 3.0,
                                   100.0);

        QVariantMap point;
        point["x"] = xValue;
        point["y"] = yValue;
        outData.append(point);

        if (outData.size() <= 5)
        {
            qDebug() << "XY point" << outData.size() << "=> x=" << xValue << "y=" << yValue;
        }
    }

    qDebug() << "Decoded XY payload: points=" << outData.size();
    qDebug() << "First decoded XY point=" << (outData.isEmpty() ? QVariantMap() : outData.first().toMap());

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
    }


    // Safety protection
    if(rxBuffer.size() > 4096)
    {
        qDebug() << "RX buffer overflow. Clearing.";
        rxBuffer.clear();
        return;
    }

    QString rxText = QString::fromLatin1(rxBuffer);
    rxText.replace('\r', ' ');
    rxText.replace('\n', ' ');

    QStringList tokens = rxText.split(QRegularExpression("\\s+"), Qt::SkipEmptyParts);
    int startIndex = -1;
    for (int i = 0; i + 1 < tokens.size(); ++i)
    {
        if (tokens[i].compare("A5", Qt::CaseInsensitive) == 0 &&
            tokens[i + 1].compare("5A", Qt::CaseInsensitive) == 0)
        {
            startIndex = i;
            break;
        }
    }

    if (startIndex >= 0)
    {
        int endIndex = -1;
        for (int i = startIndex + 2; i + 1 < tokens.size(); ++i)
        {
            if (tokens[i].compare("E9", Qt::CaseInsensitive) == 0 &&
                tokens[i + 1].compare("43", Qt::CaseInsensitive) == 0)
            {
                endIndex = i;
                break;
            }
        }

        if (endIndex >= 0)
        {
            QByteArray asciiFrame;
            for (int i = startIndex; i <= endIndex + 1; ++i)
                asciiFrame.append(tokens[i].toLatin1()).append(' ');

            QVariantList decodedData;
            if (parseXyPlotFrame(asciiFrame, decodedData))
            {
                qDebug() << "Valid XY ASCII frame found; updating plot data";
                updateXyPlotData(decodedData);
                rxBuffer.clear();
            }
            else
            {
                qDebug() << "ASCII XY frame invalid; dropping buffer";
                rxBuffer.clear();
            }
        }
    }
    else
    {
        qDebug() << "No XY start marker found in RX buffer; first bytes="
                 << rxBuffer.left(qMin(64, rxBuffer.size())).toHex();
        if (rxBuffer.size() > 128)
            rxBuffer.remove(0, rxBuffer.size() - 128);
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
