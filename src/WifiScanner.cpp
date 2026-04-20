#include "WifiScanner.h"
#include <QProcess>
#include <QStringList>
#include <QSet>

WiFiScanner::WiFiScanner(QObject *parent) : QObject(parent) {}


// ===== SCAN NETWORKS =====
QVariantList WiFiScanner::scanNetworks()
{
    QVariantList list;

    QProcess process;
    process.start("nmcli", QStringList()
                               << "-t"
                               << "-f" << "IN-USE,SSID,SIGNAL,SECURITY"
                               << "dev" << "wifi" << "list");

    process.waitForFinished();

    QString output = process.readAllStandardOutput();
    QStringList lines = output.split("\n", Qt::SkipEmptyParts);

    QSet<QString> seenSSIDs;

    for (const QString &line : lines) {
        QStringList parts = line.split(":");

        if (parts.size() >= 4) {
            QString inUse = parts[0];
            QString ssid = parts[1];
            int signal = parts[2].toInt();
            QString security = parts[3];

            if (ssid.isEmpty() || seenSSIDs.contains(ssid))
                continue;

            seenSSIDs.insert(ssid);

            QVariantMap net;
            net["name"] = ssid;
            net["signal"] = signal;
            net["secured"] = !security.isEmpty();
            net["connected"] = (inUse == "*");

            list.append(net);
        }
    }

    return list;
}


// ===== CONNECT TO WIFI =====
QString WiFiScanner::connectToWifi(QString ssid, QString password)
{
    QProcess process;
    QStringList args;

    if (password.isEmpty()) {
        args << "dev" << "wifi" << "connect" << ssid;
    } else {
        args << "dev" << "wifi" << "connect" << ssid << "password" << password;
    }

    process.start("nmcli", args);
    process.waitForFinished();

    QString output = process.readAllStandardOutput();
    QString error  = process.readAllStandardError();

    if (process.exitCode() == 0) {
        return "Connected to " + ssid;
    } else {
        // Parse common nmcli error messages
        if (error.contains("Secrets were required, but not provided") ||
            error.contains("802-11-wireless-security.psk") ||
            error.contains("wpa_supplicant") ||
            error.contains("wrong key") ||
            error.contains("invalid key") ||
            error.contains("authentication failed")) {
            return "WRONG_PASSWORD";
        } else if (error.contains("No such file or directory") ||
                   error.contains("not found")) {
            return "NETWORK_NOT_FOUND";
        } else if (error.contains("timeout") ||
                   error.contains("Timeout")) {
            return "CONNECTION_TIMEOUT";
        } else {
            return "CONNECTION_FAILED";
        }
    }
}

void WiFiScanner::connectToWifiAsync(QString ssid, QString password)
{
    QProcess *process = new QProcess(this);
    QStringList args;

    if (password.isEmpty()) {
        args << "dev" << "wifi" << "connect" << ssid;
    } else {
        args << "dev" << "wifi" << "connect" << ssid << "password" << password;
    }

    connect(process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this,
            [this, process, ssid](int exitCode, QProcess::ExitStatus) {
                QString error = process->readAllStandardError();
                process->deleteLater();

                QString result;
                if (exitCode == 0) {
                    result = "Connected to " + ssid;
                } else {
                    if (error.contains("Secrets were required, but not provided") ||
                        error.contains("802-11-wireless-security.psk") ||
                        error.contains("wpa_supplicant") ||
                        error.contains("wrong key") ||
                        error.contains("invalid key") ||
                        error.contains("authentication failed")) {
                        result = "WRONG_PASSWORD";
                    } else if (error.contains("No such file or directory") ||
                               error.contains("not found")) {
                        result = "NETWORK_NOT_FOUND";
                    } else if (error.contains("timeout") ||
                               error.contains("Timeout")) {
                        result = "CONNECTION_TIMEOUT";
                    } else {
                        result = "CONNECTION_FAILED";
                    }
                }

                emit connectionResult(ssid, result);
            });

    process->start("nmcli", args);
}

// ===== CURRENT CONNECTED WIFI =====
QString WiFiScanner::currentConnection()
{
    QProcess process;
    process.start("nmcli", QStringList()
                               << "-t"
                               << "-f" << "ACTIVE,SSID"
                               << "dev" << "wifi");

    process.waitForFinished();

    QString output = process.readAllStandardOutput();
    QStringList lines = output.split("\n", Qt::SkipEmptyParts);

    for (const QString &line : lines) {
        if (line.startsWith("yes:")) {
            return line.section(":", 1, 1);
        }
    }

    return "";
}
