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
constexpr int SYNC_SIZE = 2;
constexpr int SIZE_FIELD_SIZE = 2;
constexpr int CRC_SIZE = 2;
constexpr int END_SIZE = 2;
constexpr int CHANNEL_COUNT = 4;
constexpr int CHANNEL_SIZE = 2;
constexpr int SAMPLE_SIZE = CHANNEL_COUNT * CHANNEL_SIZE;
constexpr int MIN_PACKET_SIZE = SIZE_FIELD_SIZE + SAMPLE_SIZE + CRC_SIZE;

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
    if (frame.size() < SYNC_SIZE + MIN_PACKET_SIZE + END_SIZE ||
        static_cast<uint8_t>(frame.at(0)) != SYNC1 ||
        static_cast<uint8_t>(frame.at(1)) != SYNC2 ||
        static_cast<uint8_t>(frame.at(frame.size() - END_SIZE)) != END1 ||
        static_cast<uint8_t>(frame.at(frame.size() - 1)) != END2)
    {
        qWarning() << "Waveform packet rejected: invalid frame";
        return;
    }

    const int packetSize =
        (static_cast<uint16_t>(static_cast<uint8_t>(frame.at(SYNC_SIZE))) << 8) |
        static_cast<uint16_t>(
            static_cast<uint8_t>(frame.at(SYNC_SIZE + 1)));
    if (packetSize < MIN_PACKET_SIZE ||
        frame.size() != SYNC_SIZE + packetSize + END_SIZE)
    {
        qWarning() << "Waveform packet rejected: declared size does not match frame"
                   << "declared:" << packetSize << "frame bytes:" << frame.size();
        return;
    }

    const int payloadSize = packetSize - SIZE_FIELD_SIZE - CRC_SIZE;
    if (payloadSize % SAMPLE_SIZE != 0)
    {
        qWarning() << "Waveform packet rejected: incomplete four-channel sample,"
                   << "payload bytes:" << payloadSize;
        return;
    }

    const QByteArray payload = frame.mid(SYNC_SIZE + SIZE_FIELD_SIZE, payloadSize);
    const int crcOffset = SYNC_SIZE + packetSize - CRC_SIZE;
    const uint16_t receivedCrc =
        (static_cast<uint16_t>(static_cast<uint8_t>(frame.at(crcOffset))) << 8) |
        static_cast<uint16_t>(static_cast<uint8_t>(frame.at(crcOffset + 1)));
    const QByteArray crcInput = frame.mid(SYNC_SIZE, packetSize - CRC_SIZE);
    const uint16_t calculatedCrc = crc16Ccitt(crcInput);
    if (calculatedCrc != receivedCrc)
    {
        qWarning() << "Waveform packet rejected: CRC mismatch"
                   << "calculated:" << Qt::hex << calculatedCrc
                   << "received:" << receivedCrc << Qt::dec;
        return;
    }

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

    m_waveformData = decodedSamples;
    emit waveformDataChanged();
}
