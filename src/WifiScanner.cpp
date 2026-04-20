#include "WifiScanner.h"
#include <QProcess>
#include <QStringList>
#include <QSet>
#include <QDebug>
#include <QTimer>

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

    // Wait for process to start
    if (!process.waitForStarted(5000)) {
        qDebug() << "Failed to start nmcli process for scanning";
        return list;
    }

    // Wait for finish with timeout
    if (!process.waitForFinished(10000)) {
        qDebug() << "nmcli scan process timed out";
        process.kill();
        process.waitForFinished(1000);
        return list;
    }

    if (process.exitCode() != 0) {
        QString error = process.readAllStandardError();
        qDebug() << "nmcli scan failed:" << error;
        return list;
    }

    QString output = process.readAllStandardOutput();
    QStringList lines = output.split("\n", Qt::SkipEmptyParts);

    QSet<QString> seenSSIDs;

    for (const QString &line : lines) {
        QStringList parts = line.split(":");

        if (parts.size() >= 4) {
            QString inUse = parts[0].trimmed();
            QString ssid = parts[1].trimmed();
            int signal = parts[2].trimmed().toInt();
            QString security = parts[3].trimmed();

            if (ssid.isEmpty() || seenSSIDs.contains(ssid))
                continue;

            seenSSIDs.insert(ssid);

            QVariantMap net;
            net["name"] = ssid;
            net["signal"] = signal;
            net["secured"] = !security.isEmpty() && security != "--";
            net["connected"] = (inUse == "*");

            list.append(net);
        }
    }

    return list;
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

    // Wait for process to start
    if (!process.waitForStarted(5000)) {
        qDebug() << "Failed to start nmcli process for connection";
        return "CONNECTION_FAILED";
    }

    // Wait for finish with timeout (longer for connection)
    if (!process.waitForFinished(30000)) {
        qDebug() << "nmcli connect process timed out";
        process.kill();
        process.waitForFinished(1000);
        return "CONNECTION_TIMEOUT";
    }

    QString output = process.readAllStandardOutput();
    QString error  = process.readAllStandardError();

    qDebug() << "nmcli connect output:" << output;
    qDebug() << "nmcli connect error:" << error;
    qDebug() << "nmcli connect exit code:" << process.exitCode();

    if (process.exitCode() == 0) {
        return "Connected to " + ssid;
    } else {
        // Parse common nmcli error messages
        if (error.contains("Secrets were required, but not provided") ||
            error.contains("802-11-wireless-security.psk") ||
            error.contains("wpa_supplicant") ||
            error.contains("wrong key") ||
            error.contains("invalid key") ||
            error.contains("authentication failed") ||
            error.contains("WPA handshake failed")) {
            return "WRONG_PASSWORD";
        } else if (error.contains("No such file or directory") ||
                   error.contains("not found") ||
                   error.contains("SSID not found")) {
            return "NETWORK_NOT_FOUND";
        } else if (error.contains("timeout") ||
                   error.contains("Timeout") ||
                   error.contains("Connection activation failed")) {
            return "CONNECTION_TIMEOUT";
        } else if (error.contains("Device") && error.contains("not found")) {
            return "NO_WIFI_DEVICE";
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

    // Set up timeout timer
    QTimer *timeoutTimer = new QTimer(process);
    timeoutTimer->setSingleShot(true);
    timeoutTimer->setInterval(30000); // 30 second timeout

    connect(timeoutTimer, &QTimer::timeout, this, [process]() {
        qDebug() << "nmcli async connect timed out";
        if (process->state() == QProcess::Running) {
            process->kill();
            process->waitForFinished(1000);
        }
    });

    connect(process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this,
            [this, process, ssid, timeoutTimer](int exitCode, QProcess::ExitStatus) {
                timeoutTimer->stop();
                timeoutTimer->deleteLater();

                QString output = process->readAllStandardOutput();
                QString error = process->readAllStandardError();

                qDebug() << "nmcli async connect output:" << output;
                qDebug() << "nmcli async connect error:" << error;
                qDebug() << "nmcli async connect exit code:" << exitCode;

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
                        error.contains("authentication failed") ||
                        error.contains("WPA handshake failed")) {
                        result = "WRONG_PASSWORD";
                    } else if (error.contains("No such file or directory") ||
                               error.contains("not found") ||
                               error.contains("SSID not found")) {
                        result = "NETWORK_NOT_FOUND";
                    } else if (error.contains("timeout") ||
                               error.contains("Timeout") ||
                               error.contains("Connection activation failed")) {
                        result = "CONNECTION_TIMEOUT";
                    } else if (error.contains("Device") && error.contains("not found")) {
                        result = "NO_WIFI_DEVICE";
                    } else {
                        result = "CONNECTION_FAILED";
                    }
                }

                emit connectionResult(ssid, result);
            });

    // Start timeout timer and process
    timeoutTimer->start();
    process->start("nmcli", args);

    // Check if process started
    if (!process->waitForStarted(5000)) {
        timeoutTimer->stop();
        timeoutTimer->deleteLater();
        process->deleteLater();
        qDebug() << "Failed to start nmcli async process";
        emit connectionResult(ssid, "CONNECTION_FAILED");
    }
}

// ===== CURRENT CONNECTED WIFI =====
QString WiFiScanner::currentConnection()
{
    QProcess process;
    process.start("nmcli", QStringList()
                               << "-t"
                               << "-f" << "ACTIVE,SSID"
                               << "dev" << "wifi");

    // Wait for process to start
    if (!process.waitForStarted(5000)) {
        qDebug() << "Failed to start nmcli process for current connection";
        return "";
    }

    // Wait for finish with timeout
    if (!process.waitForFinished(10000)) {
        qDebug() << "nmcli current connection process timed out";
        process.kill();
        process.waitForFinished(1000);
        return "";
    }

    if (process.exitCode() != 0) {
        QString error = process.readAllStandardError();
        qDebug() << "nmcli current connection failed:" << error;
        return "";
    }

    QString output = process.readAllStandardOutput();
    QStringList lines = output.split("\n", Qt::SkipEmptyParts);

    for (const QString &line : lines) {
        QString trimmedLine = line.trimmed();
        if (trimmedLine.startsWith("yes:")) {
            QString ssid = trimmedLine.section(":", 1, 1).trimmed();
            if (!ssid.isEmpty()) {
                return ssid;
            }
        }
    }

    return "";
}

// ===== CHECK NMCLI AVAILABILITY =====
bool WiFiScanner::isNmcliAvailable()
{
    QProcess process;
    process.start("which", QStringList() << "nmcli");

    if (!process.waitForStarted(2000)) {
        return false;
    }

    if (!process.waitForFinished(5000)) {
        process.kill();
        process.waitForFinished(1000);
        return false;
    }

    return process.exitCode() == 0;
}
