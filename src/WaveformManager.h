#pragma once

#include <QByteArray>
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

private:
    QVariantList m_waveformData;
};
