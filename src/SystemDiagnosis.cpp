#include "SystemDiagnosis.h"
#include <QProcess>

SystemDiagnosis::SystemDiagnosis(QObject *parent) : QObject(parent) {}

// ===== STRING GETTERS =====
QString SystemDiagnosis::ramUsage()    const { return m_ram;  }
QString SystemDiagnosis::memoryUsage() const { return m_mem;  }
QString SystemDiagnosis::temperature() const { return m_temp; }
QString SystemDiagnosis::cpuUsage()    const { return m_cpu;  }

// ===== NUMERIC GETTERS =====
double SystemDiagnosis::ramUsed()          const { return m_ramUsed;   }
double SystemDiagnosis::ramTotal()         const { return m_ramTotal;  }
double SystemDiagnosis::memUsed()          const { return m_memUsed;   }
double SystemDiagnosis::memTotal()         const { return m_memTotal;  }
double SystemDiagnosis::temperatureValue() const { return m_tempValue; }
double SystemDiagnosis::cpuUsageValue()    const { return m_cpuValue;  }

// ===== HELPER: run a bash command and return trimmed stdout =====
static QString runCommand(const QString &cmd)
{
    QProcess p;
    p.start("bash", {"-c", cmd});
    p.waitForFinished(5000);   // 5s timeout — safe for Pi
    return p.readAllStandardOutput().trimmed();
}

void SystemDiagnosis::update()
{
#ifdef Q_OS_LINUX

    // =========================================================
    // RAM  —  read directly from /proc/meminfo (no external tool)
    // =========================================================
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

    // =========================================================
    // STORAGE  —  df -BG works on all Raspberry Pi OS versions
    // =========================================================
    QString storageOut = runCommand(
        "df -BG / | awk 'NR==2 {"
        "  gsub(\"G\",\"\",$2); gsub(\"G\",\"\",$3);"
        "  printf \"%.2f %.2f\", $3+0, $2+0"
        "}'"
        );

    QStringList storageParts = storageOut.split(" ");
    if (storageParts.size() >= 2) {
        m_memUsed  = storageParts[0].toDouble();
        m_memTotal = storageParts[1].toDouble();
    }

    m_mem = QString::number(m_memUsed,  'f', 2) + " GB / " +
            QString::number(m_memTotal, 'f', 2) + " GB";

    // =========================================================
    // CPU USAGE
    // =========================================================
    QString cpuOut = runCommand(
        "top -bn1 | grep 'Cpu(s)' | "
        "sed 's/.*, *\\([0-9.]*\\)%* id.*/\\1/' | "
        "awk '{printf \"%.1f\", 100 - $1}'"
        );

    m_cpuValue = cpuOut.toDouble();

    if (m_cpuValue < 0)
        m_cpu = "N/A";
    else
        m_cpu = QString::number(m_cpuValue, 'f', 1) + " %";

    // =========================================================
    // TEMPERATURE
    // =========================================================
    QString tempOut = runCommand(
        "if command -v vcgencmd >/dev/null 2>&1; then "
        "    vcgencmd measure_temp | sed \"s/temp=//;s/'C//\"; "
        "elif [ -f /sys/class/thermal/thermal_zone0/temp ]; then "
        "    awk '{printf \"%.1f\", $1/1000}' "
        "        /sys/class/thermal/thermal_zone0/temp; "
        "elif [ -f /sys/class/thermal/thermal_zone1/temp ]; then "
        "    awk '{printf \"%.1f\", $1/1000}' "
        "        /sys/class/thermal/thermal_zone1/temp; "
        "else "
        "    echo \"-1\"; "
        "fi"
        );

    m_tempValue = tempOut.toDouble();

    if (m_tempValue <= 0)
        m_temp = "N/A";
    else
        m_temp = QString::number(m_tempValue, 'f', 1) + " °C";

#elif defined(Q_OS_MACOS)

    // =========================================================
    // RAM  —  vm_stat + sysctl
    // =========================================================
    QString ramOut = runCommand(
        "pagesize=$(vm_stat | awk '/page size/{print $8}');"
        "total=$(sysctl -n hw.memsize);"
        "free_p=$(vm_stat | awk '/Pages free:/{gsub(\".\",\"\",$3); print $3}');"
        "spec_p=$(vm_stat | awk '/Pages speculative:/{gsub(\".\",\"\",$3); print $3}');"
        "total_gb=$(echo \"scale=2; $total/1073741824\" | bc);"
        "free_gb=$(echo \"scale=2; ($free_p+$spec_p)*$pagesize/1073741824\" | bc);"
        "used_gb=$(echo \"scale=2; $total_gb-$free_gb\" | bc);"
        "echo \"$used_gb $total_gb\""
        );

    QStringList ramParts = ramOut.split(" ");

    if (ramParts.size() >= 2) {
        m_ramUsed  = ramParts[0].toDouble();
        m_ramTotal = ramParts[1].toDouble();
    }

    m_ram = QString::number(m_ramUsed,  'f', 2) + " GB / " +
            QString::number(m_ramTotal, 'f', 2) + " GB";

    // =========================================================
    // STORAGE
    // =========================================================
    QString storageOut = runCommand(
        "df -g / | awk 'NR==2 { printf \"%.2f %.2f\", $3, $2 }'"
        );

    QStringList storageParts = storageOut.split(" ");

    if (storageParts.size() >= 2) {
        m_memUsed  = storageParts[0].toDouble();
        m_memTotal = storageParts[1].toDouble();
    }

    m_mem = QString::number(m_memUsed,  'f', 2) + " GB / " +
            QString::number(m_memTotal, 'f', 2) + " GB";

    // =========================================================
    // CPU USAGE
    // =========================================================
    QString cpuOut = runCommand(
        "top -l 1 | awk '/CPU usage/ {print 100 - $7}' | sed 's/%//'"
        );

    m_cpuValue = cpuOut.toDouble();

    if (m_cpuValue < 0)
        m_cpu = "N/A";
    else
        m_cpu = QString::number(m_cpuValue, 'f', 1) + " %";

    // =========================================================
    // TEMPERATURE
    // =========================================================
    m_tempValue = -1;
    m_temp = "N/A";

#endif

    emit dataChanged();
}
