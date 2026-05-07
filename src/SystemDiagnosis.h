#ifndef SYSTEMDIAGNOSIS_H
#define SYSTEMDIAGNOSIS_H

#include <QObject>

class SystemDiagnosis : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString ramUsage        READ ramUsage        NOTIFY dataChanged)
    Q_PROPERTY(QString memoryUsage     READ memoryUsage     NOTIFY dataChanged)
    Q_PROPERTY(QString temperature     READ temperature     NOTIFY dataChanged)
    Q_PROPERTY(QString cpuUsage        READ cpuUsage        NOTIFY dataChanged)

    Q_PROPERTY(double  ramUsed         READ ramUsed         NOTIFY dataChanged)
    Q_PROPERTY(double  ramTotal        READ ramTotal        NOTIFY dataChanged)
    Q_PROPERTY(double  memUsed         READ memUsed         NOTIFY dataChanged)
    Q_PROPERTY(double  memTotal        READ memTotal        NOTIFY dataChanged)
    Q_PROPERTY(double  temperatureValue READ temperatureValue NOTIFY dataChanged)
    Q_PROPERTY(double  cpuUsageValue   READ cpuUsageValue   NOTIFY dataChanged)

public:
    explicit SystemDiagnosis(QObject *parent = nullptr);

    QString ramUsage()        const;
    QString memoryUsage()     const;
    QString temperature()     const;
    QString cpuUsage()        const;

    double  ramUsed()         const;
    double  ramTotal()        const;
    double  memUsed()         const;
    double  memTotal()        const;
    double  temperatureValue() const;
    double  cpuUsageValue()   const;

    Q_INVOKABLE void update();

signals:
    void dataChanged();

private:
    QString m_ram;
    QString m_mem;
    QString m_temp;
    QString m_cpu;

    double  m_ramUsed   = 0.0;
    double  m_ramTotal  = 0.0;

    double  m_memUsed   = 0.0;
    double  m_memTotal  = 0.0;

    double  m_tempValue = 0.0;
    double  m_cpuValue  = 0.0;
};

#endif
