#include "WifiScanner.h"
#include <QProcess>
#include <QSet>
#include <QDebug>
#include <QTimer>

WiFiScanner::WiFiScanner(QObject *parent) : QObject(parent) {}

QVariantList WiFiScanner::scanNetworks()
{
    QVariantList list;

    QProcess process;
    process.start("nmcli", QStringList()
                               << "-t"
                               << "-f" << "IN-USE,SSID,SIGNAL,SECURITY"
                               << "dev" << "wifi" << "list");

    if (!process.waitForStarted(5000)) {
        qDebug() << "Failed to start nmcli scan process";
        return list;
    }

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
        if (parts.size() < 4)
            continue;

        QString inUse = parts[0].trimmed();
        QString ssid = parts[1].trimmed();
        int signal = parts[2].trimmed().toInt();
        QString security = parts.mid(3).join(":").trimmed();

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

    return list;
}

void WiFiScanner::connectToWifiAsync(QString ssid, QString password)
{
    QProcess *process = new QProcess(this);
    QStringList args;

    // For secured networks, use connection settings with explicit key-mgmt
    if (!password.isEmpty()) {
        // Create/update connection with proper security settings
        args << "connection" << "add" << "type" << "wifi" 
             << "ifname" << "wlan0"
             << "con-name" << ssid
             << "autoconnect" << "yes"
             << "ssid" << ssid
             << "802-11-wireless-security.key-mgmt" << "wpa-psk"
             << "802-11-wireless-security.psk" << password;
    } else {
        // For open networks, use simpler connect method
        args << "dev" << "wifi" << "connect" << ssid;
    }

    QTimer *timeoutTimer = new QTimer(process);
    timeoutTimer->setSingleShot(true);
    timeoutTimer->setInterval(30000);

    connect(timeoutTimer, &QTimer::timeout, this, [process]() {
        qDebug() << "nmcli async connect timed out";
        if (process->state() == QProcess::Running) {
            process->kill();
            process->waitForFinished(1000);
        }
    });

    connect(process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this,
            [this, process, ssid, timeoutTimer, password](int exitCode, QProcess::ExitStatus) {
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
                    // If we created a connection, activate it
                    if (!password.isEmpty()) {
                        QProcess activateProcess;
                        activateProcess.start("nmcli", QStringList() << "connection" << "up" << ssid);
                        activateProcess.waitForFinished(10000);
                        if (activateProcess.exitCode() == 0) {
                            result = "Connected to " + ssid;
                        } else {
                            result = "CONNECTION_FAILED";
                        }
                    } else {
                        result = "Connected to " + ssid;
                    }
                } else {
                    if (error.contains("Secrets were required") ||
                        error.contains("802-11-wireless-security") ||
                        error.contains("key-mgmt") ||
                        error.contains("psk") ||
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

    timeoutTimer->start();
    process->start("nmcli", args);
    if (!process->waitForStarted(5000)) {
        timeoutTimer->stop();
        timeoutTimer->deleteLater();
        process->deleteLater();
        qDebug() << "Failed to start nmcli async process";
        emit connectionResult(ssid, "CONNECTION_FAILED");
    }
}

QString WiFiScanner::currentConnection()
{
    QProcess process;
    process.start("nmcli", QStringList()
                               << "-t"
                               << "-f" << "ACTIVE,SSID"
                               << "dev" << "wifi");

    if (!process.waitForStarted(5000)) {
        qDebug() << "Failed to start nmcli current connection process";
        return "";
    }

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

void WiFiScanner::enableWifi(bool enable)
{
    QProcess process;
    QStringList args;
    args << "radio" << "wifi" << (enable ? "on" : "off");

    process.start("nmcli", args);

    if (!process.waitForStarted(5000)) {
        qDebug() << "Failed to start nmcli radio process";
        return;
    }

    if (!process.waitForFinished(10000)) {
        qDebug() << "nmcli radio process timed out";
        process.kill();
        process.waitForFinished(1000);
    }
}
