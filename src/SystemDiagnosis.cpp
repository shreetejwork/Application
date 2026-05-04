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
    // Column layout:  Filesystem  1G-blocks  Used  Available  Use%  Mounted
    //                 $1          $2         $3    $4         $5    $6
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
    // TEMPERATURE
    //   Priority 1 : vcgencmd  (Pi 1–4, needs video group permission)
    //   Priority 2 : thermal_zone0  (Pi 5, all other Linux)
    //   Priority 3 : thermal_zone1  (fallback if zone0 missing)
    // sed used instead of grep -oP (Perl regex not guaranteed on Pi OS)
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
    // STORAGE  —  df -g gives 1G blocks on macOS
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

    // Temperature not accessible via shell on macOS
    m_tempValue = -1;
    m_temp = "N/A";

#endif

    emit dataChanged();
}
