#include "SystemDiagnosis.h"
#include <QProcess>

SystemDiagnosis::SystemDiagnosis(QObject *parent) : QObject(parent) {}

// ===== STRING GETTERS =====
QString SystemDiagnosis::ramUsage()    const { return m_ram;  }
QString SystemDiagnosis::memoryUsage() const { return m_mem;  }
QString SystemDiagnosis::temperature() const { return m_temp; }

// ===== NUMERIC GETTERS =====
double SystemDiagnosis::ramUsed()         const { return m_ramUsed;   }
double SystemDiagnosis::ramTotal()        const { return m_ramTotal;  }
double SystemDiagnosis::memUsed()         const { return m_memUsed;   }
double SystemDiagnosis::memTotal()        const { return m_memTotal;  }
double SystemDiagnosis::temperatureValue() const { return m_tempValue; }

void SystemDiagnosis::update()
{
    QProcess process;

#ifdef Q_OS_LINUX
    // ===== RAM: used & total (from /proc/meminfo for accuracy) =====
    process.start("bash", {"-c",
                              "awk '/MemTotal:/{t=$2} /MemAvailable:/{a=$2} "
                              "END{printf \"%.2f %.2f\", (t-a)/1048576, t/1048576}' /proc/meminfo"
                          });
    process.waitForFinished();
    QString ramOut = process.readAllStandardOutput().trimmed();
    QStringList ramParts = ramOut.split(" ");
    if (ramParts.size() >= 2) {
        m_ramUsed  = ramParts[0].toDouble();
        m_ramTotal = ramParts[1].toDouble();
    }
    m_ram = QString::number(m_ramUsed,  'f', 2) + " GB / " +
            QString::number(m_ramTotal, 'f', 2) + " GB";

    // ===== MEMORY: cached + buffers (extra insight) =====
    process.start("bash", {"-c",
                              "awk '/MemTotal:/{t=$2} /Buffers:/{b=$2} /^Cached:/{c=$2} "
                              "END{printf \"%.2f %.2f\", (b+c)/1048576, t/1048576}' /proc/meminfo"
                          });
    process.waitForFinished();
    QString memOut = process.readAllStandardOutput().trimmed();
    QStringList memParts = memOut.split(" ");
    if (memParts.size() >= 2) {
        m_memUsed  = memParts[0].toDouble();
        m_memTotal = memParts[1].toDouble();
    }
    m_mem = QString::number(m_memUsed,  'f', 2) + " GB / " +
            QString::number(m_memTotal, 'f', 2) + " GB";

    // ===== TEMPERATURE =====
    process.start("bash", {"-c",
                              "if command -v vcgencmd >/dev/null 2>&1; then "
                              "  vcgencmd measure_temp | grep -oP '[0-9]+\\.[0-9]+'; "
                              "else "
                              "  awk '{printf \"%.1f\", $1/1000}' /sys/class/thermal/thermal_zone0/temp; "
                              "fi"
                          });
    process.waitForFinished();
    QString tempOut = process.readAllStandardOutput().trimmed();
    m_tempValue = tempOut.toDouble();
    m_temp = QString::number(m_tempValue, 'f', 1) + " °C";

#elif defined(Q_OS_MACOS)
    // ===== macOS RAM =====
    // vm_stat gives pages; sysctl gives page size & total
    process.start("bash", {"-c",
                              "pagesize=$(vm_stat | awk '/page size/{print $8}'); "
                              "total=$(sysctl -n hw.memsize); "
                              "free_pages=$(vm_stat | awk '/Pages free/{gsub(\".\",\"\",$3); print $3}'); "
                              "spec_pages=$(vm_stat | awk '/Pages speculative/{gsub(\".\",\"\",$3); print $3}'); "
                              "total_gb=$(echo \"scale=2; $total/1073741824\" | bc); "
                              "free_gb=$(echo \"scale=2; ($free_pages+$spec_pages)*$pagesize/1073741824\" | bc); "
                              "used_gb=$(echo \"scale=2; $total_gb-$free_gb\" | bc); "
                              "echo \"$used_gb $total_gb\""
                          });
    process.waitForFinished();
    QString ramOut = process.readAllStandardOutput().trimmed();
    QStringList ramParts = ramOut.split(" ");
    if (ramParts.size() >= 2) {
        m_ramUsed  = ramParts[0].toDouble();
        m_ramTotal = ramParts[1].toDouble();
    }
    m_ram = QString::number(m_ramUsed,  'f', 2) + " GB / " +
            QString::number(m_ramTotal, 'f', 2) + " GB";

    // ===== macOS wired/compressed memory as "Memory" =====
    process.start("bash", {"-c",
                              "pagesize=$(vm_stat | awk '/page size/{print $8}'); "
                              "total=$(sysctl -n hw.memsize); "
                              "wired=$(vm_stat | awk '/wired/{gsub(\".\",\"\",$4); print $4}'); "
                              "comp=$(vm_stat | awk '/occupied by compressor/{gsub(\".\",\"\",$5); print $5}'); "
                              "total_gb=$(echo \"scale=2; $total/1073741824\" | bc); "
                              "used_gb=$(echo \"scale=2; ($wired+$comp)*$pagesize/1073741824\" | bc); "
                              "echo \"$used_gb $total_gb\""
                          });
    process.waitForFinished();
    QString memOut = process.readAllStandardOutput().trimmed();
    QStringList memParts = memOut.split(" ");
    if (memParts.size() >= 2) {
        m_memUsed  = memParts[0].toDouble();
        m_memTotal = memParts[1].toDouble();
    }
    m_mem = QString::number(m_memUsed,  'f', 2) + " GB / " +
            QString::number(m_memTotal, 'f', 2) + " GB";

    // macOS temperature requires IOKit — not easily shell-accessible
    m_tempValue = -1;
    m_temp = "N/A";
#endif

    emit dataChanged();
}
