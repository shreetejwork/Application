#include "SerialManager.h"

#include <QDebug>
#include <QRandomGenerator>
#include <QTimer>
#include <QFile>
#include <QSerialPortInfo>
#include <QRegularExpression>
#include <QtEndian>

#include <cstdint>

#include <QTime>

namespace
{
constexpr uint8_t XY_SYNC1 = 0xA5;
constexpr uint8_t XY_SYNC2 = 0x5A;
constexpr int XY_SAMPLES = 20;
constexpr int XY_SYNC_SIZE = 2;
constexpr int XY_DATA_SIZE = 80;
constexpr int XY_CRC_SIZE = 2;
constexpr int XY_PAYLOAD_OFFSET = XY_SYNC_SIZE;
constexpr int XY_CRC_OFFSET = XY_PAYLOAD_OFFSET + XY_DATA_SIZE;
constexpr int XY_PACKET_SIZE = XY_SYNC_SIZE + XY_DATA_SIZE + XY_CRC_SIZE;
constexpr qreal XY_PLOT_LIMIT = 100.0;
constexpr qreal XY_SIGNED_SCALE = XY_PLOT_LIMIT / 32768.0;

uint16_t crc16Ccitt(const QByteArray &data)
{
    uint16_t crc = 0xFFFF;

    for (const char byte : data)
    {
        crc ^= static_cast<uint16_t>(static_cast<uint8_t>(byte)) << 8;

        for (int bit = 0; bit < 8; ++bit)
        {
            if (crc & 0x8000)
                crc = static_cast<uint16_t>((crc << 1) ^ 0x1021);
            else
                crc = static_cast<uint16_t>(crc << 1);
        }
    }

    return crc;
}
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
    if (frame.size() != XY_PACKET_SIZE)
    {
        qDebug() << "XY frame rejected: size=" << frame.size();
        return false;
    }

    if (static_cast<uint8_t>(frame.at(0)) != XY_SYNC1 ||
        static_cast<uint8_t>(frame.at(1)) != XY_SYNC2)
    {
        qDebug() << "XY frame rejected: invalid synchronization";
        return false;
    }

    const QByteArray payload = frame.mid(XY_PAYLOAD_OFFSET, XY_DATA_SIZE);
    const uint16_t calculatedCrc = crc16Ccitt(payload);
    const uint16_t receivedCrc =
        (static_cast<uint16_t>(static_cast<uint8_t>(frame.at(XY_CRC_OFFSET))) << 8) |
        static_cast<uint16_t>(static_cast<uint8_t>(frame.at(XY_CRC_OFFSET + 1)));

    qDebug() << "XY CRC calculated:" << Qt::hex << calculatedCrc
             << "received:" << receivedCrc << Qt::dec;

    if (calculatedCrc != receivedCrc)
    {
        qDebug() << "XY CRC FAIL";
        return false;
    }

    qDebug() << "XY CRC PASS";
    return decodeXyPlotPayload(payload, outData);
}

bool SerialManager::decodeXyPlotPayload(const QByteArray &payload, QVariantList &outData)
{
    if (payload.size() != XY_DATA_SIZE)
    {
        qDebug() << "XY payload rejected: size=" << payload.size();
        return false;
    }

    outData.clear();
    QStringList decimalPairs;

    for (int i = 0; i < XY_SAMPLES; ++i)
    {
        const int offset = i * 4;
        const auto readSignedValue = [&payload](int valueOffset) {
            const uint16_t raw =
                (static_cast<uint16_t>(static_cast<uint8_t>(payload.at(valueOffset))) << 8) |
                static_cast<uint16_t>(static_cast<uint8_t>(payload.at(valueOffset + 1)));
            return static_cast<int16_t>(raw);
        };

        const int16_t xValue = readSignedValue(offset);
        const int16_t yValue = readSignedValue(offset + 2);

        const qreal plotX = qBound(-XY_PLOT_LIMIT,
                                   static_cast<qreal>(xValue) * XY_SIGNED_SCALE,
                                   XY_PLOT_LIMIT);
        const qreal plotY = qBound(-XY_PLOT_LIMIT,
                                   static_cast<qreal>(yValue) * XY_SIGNED_SCALE,
                                   XY_PLOT_LIMIT);

        QVariantMap point;
        point["x"] = plotX;
        point["y"] = plotY;
        point["rawX"] = static_cast<int>(xValue);
        point["rawY"] = static_cast<int>(yValue);
        outData.append(point);

        decimalPairs.append(QString("P%1 raw=(%2,%3) plot=(%4,%5)")
                                .arg(i + 1)
                                .arg(static_cast<int>(xValue))
                                .arg(static_cast<int>(yValue))
                                .arg(plotX, 0, 'f', 2)
                                .arg(plotY, 0, 'f', 2));
    }

    qDebug() << "Decoded XY payload: points=" << outData.size()
             << "signed decimal XY pairs:" << decimalPairs.join(" | ");
    return outData.size() == XY_SAMPLES;
}

void SerialManager::updateXyPlotData(const QVariantList &data)
{
    m_xyPlotData = data;
    emit xyPlotDataChanged();

    qDebug() << "XY plot data updated with" << m_xyPlotData.size() << "points";
}

void SerialManager::logXyPacketBeforePlotUpdate(const QByteArray &frame,
                                                 const QVariantList &data)
{
    QStringList pairs;
    for (int i = 0; i < data.size(); ++i)
    {
        const QVariantMap point = data.at(i).toMap();
        pairs.append(QString("P%1 raw=(%2,%3) plot=(%4,%5)")
                         .arg(i + 1)
                         .arg(point.value(QStringLiteral("rawX")).toInt())
                         .arg(point.value(QStringLiteral("rawY")).toInt())
                         .arg(point.value(QStringLiteral("x")).toDouble(), 0, 'f', 2)
                         .arg(point.value(QStringLiteral("y")).toDouble(), 0, 'f', 2));
    }

    qDebug() << "XY FULL INCOMING PACKET BEFORE PLOT UPDATE"
             << "total bytes:" << frame.size()
             << "hex:" << frame.toHex(' ');
    qDebug() << "XY PLOT ARRAY BEFORE UPDATE: points=" << data.size()
             << pairs.join(" | ");
}

void SerialManager::processXyAsciiBuffer()
{
    while (true)
    {
        const QString text = QString::fromLatin1(xyRxBuffer);
        QRegularExpressionMatchIterator matches =
            QRegularExpression(QStringLiteral("\\S+")).globalMatch(text);
        QList<QRegularExpressionMatch> tokens;

        while (matches.hasNext())
            tokens.append(matches.next());

        if (tokens.size() < 2)
            return;

        int startToken = -1;
        for (int i = 0; i + 1 < tokens.size(); ++i)
        {
            if (tokens[i].captured().compare(QStringLiteral("A5"), Qt::CaseInsensitive) == 0 &&
                tokens[i + 1].captured().compare(QStringLiteral("5A"), Qt::CaseInsensitive) == 0)
            {
                startToken = i;
                break;
            }
        }

        if (startToken < 0)
        {
            const auto lastToken = tokens.constLast();
            if (lastToken.capturedStart() > 0)
                xyRxBuffer = xyRxBuffer.mid(lastToken.capturedStart());
            return;
        }

        if (tokens.constLast().capturedEnd() == text.size())
            return;

        const int availableTokens = tokens.size() - startToken;
        if (availableTokens < XY_PACKET_SIZE)
        {
            xyRxBuffer = xyRxBuffer.mid(tokens[startToken].capturedStart());
            qDebug() << "XY ASCII sync found; waiting for total packet bytes:"
                     << availableTokens << "/" << XY_PACKET_SIZE;
            return;
        }

        QByteArray frame;
        for (int i = 0; i < XY_PACKET_SIZE; ++i)
        {
            const QByteArray byte = QByteArray::fromHex(
                tokens[startToken + i].captured().toLatin1());
            if (byte.size() != 1)
            {
                qDebug() << "XY ASCII token rejected:"
                         << tokens[startToken + i].captured();
                xyRxBuffer.remove(0, tokens[startToken].capturedEnd());
                frame.clear();
                break;
            }
            frame.append(byte);
        }

        if (frame.isEmpty())
            continue;

        QVariantList decodedData;
        if (parseXyPlotFrame(frame, decodedData))
        {
            xyRxBuffer.remove(0, tokens[startToken + XY_PACKET_SIZE - 1].capturedEnd());
            logXyPacketBeforePlotUpdate(frame, decodedData);
            updateXyPlotData(decodedData);
        }
        else
        {
            qDebug() << "XY ASCII packet rejected; resynchronizing";
            xyRxBuffer.remove(0, tokens[startToken].capturedStart() + 2);
        }
    }
}

void SerialManager::onReadyRead()
{
    QByteArray data = serial.readAll();

    if (!data.isEmpty())
    {
        const QByteArray preview = data.left(12).toHex(' ');

        qDebug() << "XY serial bytes received:" << data.size()
                 << "preview:" << preview
                 << "sync index:"
                 << data.indexOf(QByteArray::fromHex("A55A"));

        // Show exactly what arrived from UART
        appendRxLog(QString::fromUtf8(data));

        // Existing buffers
        rxBuffer.append(data);
        xyRxBuffer.append(data);
    }


    // =====================================================
    // Safety protection - Main RX buffer
    // =====================================================

    if (rxBuffer.size() > 4096)
    {
        qDebug() << "RX buffer overflow. Clearing.";
        rxBuffer.clear();
        return;
    }


    // =====================================================
    // Safety protection - XY RX buffer
    // =====================================================

    if (xyRxBuffer.size() > 4096)
    {
        qDebug() << "XY RX buffer overflow. Clearing.";
        xyRxBuffer.clear();
    }


    // =====================================================
    // XY PLOT PROCESSING
    // =====================================================

    const QByteArray sync =
        QByteArray(1, static_cast<char>(XY_SYNC1)) +
        QByteArray(1, static_cast<char>(XY_SYNC2));


    if (xyRxBuffer.indexOf(sync) >= 0)
    {
        while (true)
        {
            const qsizetype startIndex =
                xyRxBuffer.indexOf(sync);

            if (startIndex < 0)
                break;


            if (startIndex > 0)
                xyRxBuffer.remove(0, startIndex);


            if (xyRxBuffer.size() < XY_PACKET_SIZE)
            {
                qDebug()
                << "XY sync found; waiting for total packet bytes:"
                << xyRxBuffer.size()
                << "/"
                << XY_PACKET_SIZE;

                break;
            }


            const QByteArray frame =
                xyRxBuffer.left(XY_PACKET_SIZE);


            QVariantList decodedData;


            if (parseXyPlotFrame(frame, decodedData))
            {
                xyRxBuffer.remove(0, XY_PACKET_SIZE);

                logXyPacketBeforePlotUpdate(
                    frame,
                    decodedData);

                updateXyPlotData(decodedData);
            }
            else
            {
                xyRxBuffer.remove(0, 1);
            }
        }
    }
    else
    {
        processXyAsciiBuffer();
    }


    // =====================================================
    // MCU REQUESTING MACHINE PARAMETERS
    // =====================================================

    if (rxBuffer.contains("{*****}"))
    {
        rxBuffer.replace("{*****}", "");

        qDebug()
            << "MCU requested machine settings.";

        emit mcuParameterRequestReceived();
    }


    // =====================================================
    // N / D PACKET PROCESSING
    // =====================================================

    while (true)
    {
        // -------------------------------------------------
        // Find next normal packet
        // N........n
        // -------------------------------------------------

        const int normalStart =
            rxBuffer.indexOf('N');


        // -------------------------------------------------
        // Find next defect packet
        // D........d
        // -------------------------------------------------

        const int defectStart =
            rxBuffer.indexOf('D');


        int start =
            normalStart;


        // Select whichever packet starts first
        if (start < 0 ||
            (defectStart >= 0 && defectStart < start))
        {
            start = defectStart;
        }


        // -------------------------------------------------
        // No N or D packet found
        // -------------------------------------------------

        if (start < 0)
        {
            // Keep a small amount of data in case the
            // packet is fragmented across serial reads.
            if (rxBuffer.size() > 10)
            {
                rxBuffer.remove(
                    0,
                    rxBuffer.size() - 10);
            }

            return;
        }


        // -------------------------------------------------
        // Determine packet type
        // -------------------------------------------------

        const bool isDefectPacket =
            (rxBuffer.at(start) == 'D');


        const char endMarker =
            isDefectPacket ? 'd' : 'n';


        // -------------------------------------------------
        // Find packet end marker
        // -------------------------------------------------

        const int end =
            rxBuffer.indexOf(
                endMarker,
                start);


        // -------------------------------------------------
        // Packet not complete yet
        // Wait for next readyRead()
        // -------------------------------------------------

        if (end < 0)
            return;


        // -------------------------------------------------
        // Extract complete packet
        // -------------------------------------------------

        const QByteArray packet =
            rxBuffer.mid(
                start,
                end - start + 1);


        // Remove processed packet from buffer
        rxBuffer.remove(
            0,
            end + 1);


        // -------------------------------------------------
        // Convert packet to QString
        // -------------------------------------------------

        QString str =
            QString::fromUtf8(packet).trimmed();


        qDebug() << "RX :" << str;


        // -------------------------------------------------
        // Remove packet start marker
        // N or D
        // -------------------------------------------------

        str.remove(0, 1);


        // -------------------------------------------------
        // Remove packet end marker
        // n or d
        // -------------------------------------------------

        str.chop(1);


        str =
            str.trimmed();


        // -------------------------------------------------
        // Split parameters
        // -------------------------------------------------

        const QStringList fields =
            str.split(',');


        // =================================================
        // DEFECT PACKET
        //
        // ONLY accepted format:
        //
        // D00381,00260,00968d
        //
        // Fields:
        // [0] = Phase
        // [1] = Signal
        // [2] = Amplitude
        //
        // There is NO coil value.
        // =================================================

        if (isDefectPacket)
        {
            // -------------------------------------------------
            // Defect packet MUST contain exactly 3 parameters
            // -------------------------------------------------

            if (fields.size() != 3)
            {
                qDebug()
                << "Invalid defect packet."
                << "Expected exactly 3 parameters, received:"
                << fields.size()
                << "Packet:"
                << packet;

                continue;
            }


            // -------------------------------------------------
            // Conversion flags
            // -------------------------------------------------

            bool okPhase = false;
            bool okSignal = false;
            bool okAmplitude = false;


            // -------------------------------------------------
            // 1st Parameter - Defect Phase
            //
            // Example:
            // 00381 -> 38.1
            // -------------------------------------------------

            const int phaseRaw =
                fields[0]
                    .trimmed()
                    .toInt(&okPhase);


            const double phase =
                phaseRaw / 10.0;


            // -------------------------------------------------
            // 2nd Parameter - Defect Signal
            // -------------------------------------------------

            const int signal =
                fields[1]
                    .trimmed()
                    .toInt(&okSignal);


            // -------------------------------------------------
            // 3rd Parameter - Defect Amplitude
            // -------------------------------------------------

            const int amplitude =
                fields[2]
                    .trimmed()
                    .toInt(&okAmplitude);


            // -------------------------------------------------
            // Numeric validation
            // -------------------------------------------------

            if (!(okPhase &&
                  okSignal &&
                  okAmplitude))
            {
                qDebug()
                << "Invalid defect packet:"
                << "non-numeric value."
                << "Packet:"
                << packet;

                continue;
            }


            // -------------------------------------------------
            // Range validation
            // -------------------------------------------------

            if (phase < 0 ||
                phase > 180 ||
                signal < 0 ||
                signal > 30000 ||
                amplitude < 0 ||
                amplitude > 14000)
            {
                qDebug()
                << "Invalid defect packet:"
                << "value out of range."
                << "Phase:"
                << phase
                << "Signal:"
                << signal
                << "Amplitude:"
                << amplitude;

                continue;
            }


            // -------------------------------------------------
            // Update Defect Phase
            // -------------------------------------------------

            if (!qFuzzyCompare(
                    m_defectPhase + 1.0,
                    phase + 1.0))
            {
                m_defectPhase =
                    phase;

                emit defectPhaseChanged();
            }


            // -------------------------------------------------
            // Update Defect Signal
            // -------------------------------------------------

            if (signal !=
                m_defectSignal)
            {
                m_defectSignal =
                    signal;

                emit defectSignalChanged();
            }


            // -------------------------------------------------
            // Update Defect Amplitude
            // -------------------------------------------------

            if (amplitude !=
                m_defectAmplitude)
            {
                m_defectAmplitude =
                    amplitude;

                emit defectAmplitudeChanged();
            }


            // -------------------------------------------------
            // Debug
            // -------------------------------------------------

            qDebug()
                << "========================================";

            qDebug()
                << "DEFECT PACKET RECEIVED";

            qDebug()
                << "Raw Packet       :" << packet;

            qDebug()
                << "Defect Phase     :" << phase;

            qDebug()
                << "Defect Signal    :" << signal;

            qDebug()
                << "Defect Amplitude :" << amplitude;

            qDebug()
                << "========================================";


            // -------------------------------------------------
            // Notify QML
            // -------------------------------------------------

            emit defectPacketReceived();


            // -------------------------------------------------
            // IMPORTANT:
            //
            // Do NOT process this packet as an N packet.
            // Do NOT access fields[3].
            // Do NOT modify m_coilOutput.
            // -------------------------------------------------

            continue;
        }


        // =================================================
        // NORMAL PACKET
        //
        // Accepted formats:
        //
        // N00027,00500,14000,02500n
        //
        // OR
        //
        // N00027,00500,14000,02500,00150n
        // =================================================

        if (fields.size() != 4 &&
            fields.size() != 5)
        {
            qDebug()
            << "Invalid normal packet."
            << "Expected 4 or 5 parameters, received:"
            << fields.size()
            << "Packet:"
            << packet;

            continue;
        }


        // -------------------------------------------------
        // Conversion flags
        // -------------------------------------------------

        bool ok1 = false;
        bool ok2 = false;
        bool ok3 = false;
        bool ok4 = false;
        bool ok5 = false;


        // =================================================
        // 1st Parameter - Product Phase
        // =================================================

        const int phaseRaw =
            fields[0]
                .trimmed()
                .toInt(&ok1);


        const double phase =
            phaseRaw / 10.0;


        // =================================================
        // 2nd Parameter - Signal
        // =================================================

        const int signal =
            fields[1]
                .trimmed()
                .toInt(&ok2);


        // =================================================
        // 3rd Parameter - Amplitude
        // =================================================

        const int amplitude =
            fields[2]
                .trimmed()
                .toInt(&ok3);


        // =================================================
        // 4th Parameter - Coil
        // =================================================

        const int coil =
            fields[3]
                .trimmed()
                .toInt(&ok4);


        // =================================================
        // 5th Parameter - Tracking Phase
        //
        // Same handling as Product Phase
        // =================================================

        double trackingPhaseValue =
            0.0;


        if (fields.size() == 5)
        {
            const int trackingPhaseRaw =
                fields[4]
                    .trimmed()
                    .toInt(&ok5);


            trackingPhaseValue =
                trackingPhaseRaw / 10.0;
        }


        // =================================================
        // Validate numeric normal packet
        // =================================================

        if (!(ok1 &&
              ok2 &&
              ok3 &&
              ok4))
        {
            qDebug()
            << "Non numeric normal packet:"
            << packet;

            continue;
        }


        // =================================================
        // Validate normal packet ranges
        // =================================================

        if (phase < 0 ||
            phase > 180 ||
            signal < 0 ||
            signal > 30000 ||
            amplitude < 0 ||
            amplitude > 14000 ||
            coil < 0 ||
            coil > 10000)
        {
            qDebug()
            << "Normal packet out of range:"
            << packet;

            continue;
        }


        // =================================================
        // Tracking Phase
        //
        // Valid range:
        // 0 to 180
        //
        // Invalid value:
        // "---"
        // =================================================

        QString newTrackingPhase =
            m_trackingPhase;


        if (fields.size() == 5 &&
            (!ok5 ||
             trackingPhaseValue < 0 ||
             trackingPhaseValue > 180))
        {
            qDebug()
            << "Invalid Tracking Phase:"
            << fields[4];


            newTrackingPhase =
                "---";
        }
        else if (fields.size() == 5)
        {
            newTrackingPhase =
                QString::number(
                    trackingPhaseValue,
                    'f',
                    1);
        }


        // =================================================
        // Update Product Phase
        // =================================================

        if (!qFuzzyCompare(
                m_productPhase + 1.0,
                phase + 1.0))
        {
            m_productPhase =
                phase;

            emit productPhaseChanged();
        }


        // =================================================
        // Update Tracking Phase
        // =================================================

        if (m_trackingPhase !=
            newTrackingPhase)
        {
            m_trackingPhase =
                newTrackingPhase;

            emit trackingPhaseChanged();
        }


        // =================================================
        // Update Signal
        // =================================================

        if (signal !=
            m_signal)
        {
            m_signal =
                signal;

            emit signalChanged();
        }


        // =================================================
        // Update Amplitude
        // =================================================

        if (amplitude !=
            m_amplitude)
        {
            m_amplitude =
                amplitude;

            emit amplitudeChanged();
        }


        // =================================================
        // Update Coil Output
        // =================================================

        if (coil !=
            m_coilOutput)
        {
            m_coilOutput =
                coil;

            emit coilOutputChanged();
        }


        // =================================================
        // Store Coil Sample
        //
        // Only when Coil Balancing is OFF
        // =================================================

        if (!m_coilBalancingOn)
        {
            m_coilBuffer.append(coil);
        }
        else
        {
            qDebug()
            << "Coil Balancing ON - Display only,"
               "not storing coil value";
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
