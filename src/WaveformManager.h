#pragma once

#include <QByteArray>
#include <QElapsedTimer>
#include <QObject>
#include <QVariantList>

class WaveformManager : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QVariantList waveformData
                   READ waveformData
                       NOTIFY waveformDataChanged)

public:
    explicit WaveformManager(QObject *parent = nullptr);

    QVariantList waveformData() const
    {
        return m_waveformData;
    }

public slots:
    void processPacket(const QByteArray &frame);

signals:
    void waveformDataChanged();
    void packetGapDetected(int firstMissingPacket, int missingPacketCount);
    void packetIntervalChanged(int intervalMilliseconds);

private:
    QVariantList m_waveformData;
    int m_lastPacketNumber = -1;
    QElapsedTimer m_packetTimer;
};
