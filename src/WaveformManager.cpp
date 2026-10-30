#include "WaveformManager.h"

#include <QDebug>
#include <QVariantMap>

#include <cstdint>

namespace
{
constexpr uint8_t SYNC1 = 0xA5;
constexpr uint8_t SYNC2 = 0x5A;
constexpr uint8_t END1 = 0xB5;
constexpr uint8_t END2 = 0x5B;
constexpr int FRAME_OVERHEAD = 8;
constexpr int PACKET_NUMBER_SIZE = 2;
constexpr int WAVEFORM_PAYLOAD_UNIT = 4;
constexpr int CHANNEL_COUNT = 4;
constexpr int CHANNEL_SIZE = 2;
constexpr int SAMPLE_SIZE = CHANNEL_COUNT * CHANNEL_SIZE;
constexpr int PACKET_NUMBER_MODULUS = 1 << 16;

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

WaveformManager::WaveformManager(QObject *parent)
    : QObject(parent)
{
}

void WaveformManager::processPacket(const QByteArray &frame)
{
    if (frame.size() < FRAME_OVERHEAD + WAVEFORM_PAYLOAD_UNIT ||
        static_cast<uint8_t>(frame.at(0)) != SYNC1 ||
        static_cast<uint8_t>(frame.at(1)) != SYNC2 ||
        static_cast<uint8_t>(frame.at(frame.size() - 2)) != END1 ||
        static_cast<uint8_t>(frame.at(frame.size() - 1)) != END2)
    {
        qWarning() << "Waveform packet rejected: invalid frame";
        return;
    }

    const int payloadSize = frame.size() - FRAME_OVERHEAD;
    if (payloadSize % WAVEFORM_PAYLOAD_UNIT != 0)
    {
        qDebug() << "Waveform packet ignored: payload size is not divisible by four:"
                 << payloadSize;
        return;
    }
    if (payloadSize % SAMPLE_SIZE != 0)
    {
        qDebug() << "Waveform packet ignored: incomplete four-channel sample,"
                   << "payload bytes:" << payloadSize;
        return;
    }

    const int packetNumber =
        (static_cast<uint16_t>(static_cast<uint8_t>(frame.at(2))) << 8) |
        static_cast<uint16_t>(static_cast<uint8_t>(frame.at(3)));
    const QByteArray payload = frame.mid(2 + PACKET_NUMBER_SIZE, payloadSize);
    const QByteArray crcData = frame.mid(2, PACKET_NUMBER_SIZE + payloadSize);
    const int crcOffset = 2 + PACKET_NUMBER_SIZE + payloadSize;
    const uint16_t receivedCrc =
        (static_cast<uint16_t>(static_cast<uint8_t>(frame.at(crcOffset))) << 8) |
        static_cast<uint16_t>(static_cast<uint8_t>(frame.at(crcOffset + 1)));
    if (crc16Ccitt(crcData) != receivedCrc)
    {
        qWarning() << "Waveform packet rejected: CRC mismatch";
        return;
    }

    emit packetIntervalChanged(
        m_packetTimer.isValid()
            ? static_cast<int>(m_packetTimer.elapsed())
            : -1);
    m_packetTimer.restart();

    const auto readSignedValue = [&payload](int offset) {
        const uint16_t raw =
            (static_cast<uint16_t>(static_cast<uint8_t>(payload.at(offset))) << 8) |
            static_cast<uint16_t>(static_cast<uint8_t>(payload.at(offset + 1)));
        return static_cast<int>(static_cast<int16_t>(raw));
    };

    QVariantList decodedSamples;
    decodedSamples.reserve(payloadSize / SAMPLE_SIZE);
    for (int offset = 0; offset < payloadSize; offset += SAMPLE_SIZE)
    {
        const int x = readSignedValue(offset);
        const int y = readSignedValue(offset + CHANNEL_SIZE);
        const int z1 = readSignedValue(offset + 2 * CHANNEL_SIZE);
        const int z2 = readSignedValue(offset + 3 * CHANNEL_SIZE);

        QVariantMap sample;
        sample.insert(QStringLiteral("x"), x);
        sample.insert(QStringLiteral("y"), y);
        sample.insert(QStringLiteral("z1"), z1);
        sample.insert(QStringLiteral("z2"), z2);
        sample.insert(QStringLiteral("rawX"), x);
        sample.insert(QStringLiteral("rawY"), y);
        sample.insert(QStringLiteral("rawZ1"), z1);
        sample.insert(QStringLiteral("rawZ2"), z2);
        decodedSamples.append(sample);
    }

    if (m_lastPacketNumber >= 0)
    {
        const int distance =
            (packetNumber - m_lastPacketNumber + PACKET_NUMBER_MODULUS) %
            PACKET_NUMBER_MODULUS;
        if (distance > 1 && distance <= PACKET_NUMBER_MODULUS / 2)
        {
            emit packetGapDetected(
                (m_lastPacketNumber + 1) % PACKET_NUMBER_MODULUS,
                distance - 1);
        }
    }

    m_lastPacketNumber = packetNumber;
    m_waveformData = decodedSamples;
    emit waveformDataChanged();
}
