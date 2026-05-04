#include "SystemDiagnosis.h"
#include <QProcess>

SystemDiagnosis::SystemDiagnosis(QObject *parent) : QObject(parent) {}

// ===== STRING GETTERS =====
QString SystemDiagnosis::ramUsage()    const { return m_ram;  }
QString SystemDiagnosis::memoryUsage() const { return m_mem;  }
QString SystemDiagnosis::temperature() const { return m_temp; }

// ===== NUMERIC GETTERS =====
double SystemDiagnosis::ramUsed()          const { return m_ramUsed;   }
double SystemDiagnosis::ramTotal()         const { return m_ramTotal;  }
double SystemDiagnosis::memUsed()          const { return m_memUsed;   }
double SystemDiagnosis::memTotal()         const { return m_memTotal;  }
double SystemDiagnosis::temperatureValue() const { return m_tempValue; }

// ===== HELPER: run a bash command and return trimmed stdout =====
static QString runCommand(const QString &cmd)
{
    QProcess p;
    p.start("bash", {"-c", cmd});
    p.waitForFinished(5000);
    return p.readAllStandardOutput().trimmed();
}

void SystemDiagnosis::update()
{
#ifdef Q_OS_LINUX

    QString ramOut = runCommand(
        "awk '/MemTotal:/{t=$2} /MemAvailable:/{a=$2} "
        "END{printf \"%.2f %.2f\", (t-a)/1048576, t/1048576}' "
        "/proc/meminfo"
        );

    QStringList ramParts = ramOut.split(" ");
    if (ramParts.size() >= 2) {
        m_ramUsed  = ramParts[0].toDouble();
        m_ramTotal = ramParts[1].toDouble();
    }
    m_ram = QString::number(m_ramUsed,  'f', 2) + " GB / " +
            QString::number(m_ramTotal, 'f', 2) + " GB";


    QString storageOut = runCommand(
        "df -BG / | awk 'NR==2 {"
        "  gsub(\"G\",\"\",$2); gsub(\"G\",\"\",$3);"
        "  printf \"%.2f %.2f\", $3+0, $2+0"
        "}'"
        );

    QStringList storageParts = storageOut.split(" ");
    if (storageParts.size() >= 2) {
        m_memUsed  = storageParts[0].toDouble();
    m_memTotal
