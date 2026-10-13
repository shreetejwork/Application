#include "SystemDiagnosis.h"
#include <QProcess>
#include <QRegularExpression>

SystemDiagnosis::SystemDiagnosis(QObject *parent) : QObject(parent) {}

// ===== STRING GETTERS =====
QString SystemDiagnosis::ramUsage()    const { return m_ram;  }
QString SystemDiagnosis::memoryUsage() const { return m_mem;  }
QString SystemDiagnosis::temperature() const { return m_temp; }
QString SystemDiagnosis::inputVoltage() const { return m_inputVoltage; }

// ===== NUMERIC GETTERS =====
double SystemDiagnosis::ramUsed()          const { return m_ramUsed;   }
double SystemDiagnosis::ramTotal()         const { return m_ramTotal;  }
double SystemDiagnosis::memUsed()          const { return m_memUsed;   }
double SystemDiagnosis::memTotal()         const { return m_memTotal;  }
double SystemDiagnosis::temperatureValue() const { return m_tempValue; }
double SystemDiagnosis::inputVoltageValue() const { return m_inputVoltageValue; }
bool SystemDiagnosis::undervoltageDetected() const { return m_undervoltageDetected; }
bool SystemDiagnosis::undervoltageOccurred() const { return m_undervoltageOccurred; }
bool SystemDiagnosis::voltageStatusAvailable() const { return m_voltageStatusAvailable; }

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
    // INPUT VOLTAGE — use an explicitly identified power-supply sensor.
    // Raspberry Pi firmware does not expose a numeric 5 V input reading.
    // =========================================================
    QString voltageOut = runCommand(
        "for supply in /sys/class/power_supply/*; do "
        "  [ -d \"$supply\" ] || continue; "
        "  type=$(cat \"$supply/type\" 2>/dev/null); "
        "  case \"$type\" in USB|Mains) "
        "    if [ -r \"$supply/voltage_now\" ]; then "
        "      awk '{printf \"%.3f\", $1 / 1000000}' \"$supply/voltage_now\"; "
        "      exit; "
        "    fi ;; "
        "  esac; "
        "done"
        );

    bool voltageOk = false;
    const double voltage = voltageOut.toDouble(&voltageOk);
    if (voltageOk && voltage > 0.0) {
        m_inputVoltageValue = voltage;
        m_inputVoltage = QString::number(voltage, 'f', 2) + " V";
    } else {
        m_inputVoltageValue = -1.0;
        m_inputVoltage = "Not available";
    }

    const QString throttleOut = runCommand(
        "if command -v vcgencmd >/dev/null 2>&1; then vcgencmd get_throttled; fi"
        );
    const QRegularExpression throttlePattern("throttled=0x([0-9a-fA-F]+)");
    const QRegularExpressionMatch throttleMatch = throttlePattern.match(throttleOut);
    bool throttleOk = false;
    const uint throttleFlags = throttleMatch.hasMatch()
                                   ? throttleMatch.captured(1).toUInt(&throttleOk, 16)
                                   : 0;
    m_voltageStatusAvailable = throttleOk;
    m_undervoltageDetected = throttleOk && (throttleFlags & 0x1);
    m_undervoltageOccurred = throttleOk && (throttleFlags & 0x10000);

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
    // TEMPERATURE
    // =========================================================
    m_tempValue = -1;
    m_temp = "N/A";
    m_inputVoltageValue = -1.0;
    m_inputVoltage = "Not available";
    m_undervoltageDetected = false;
    m_undervoltageOccurred = false;
    m_voltageStatusAvailable = false;

#endif

    emit dataChanged();
}
