#include "WifiScanner.h"
#include <QProcess>
#include <QSet>
#include <QDebug>
#include <QTimer>
#include <QThread>

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
    const bool useSavedProfile = password.isEmpty();
    QStringList args = useSavedProfile
        ? (QStringList() << "-w" << "30" << "connection" << "up" << "id" << ssid)
        : (QStringList() << "-w" << "30" << "dev" << "wifi" << "connect" << ssid
                         << "password" << password);

    QTimer *timeoutTimer = new QTimer(process);
    timeoutTimer->setSingleShot(true);
    timeoutTimer->setInterval(30000);

    connect(timeoutTimer, &QTimer::timeout, this, [process]() {
        qDebug() << "nmcli async connect timed out";
        process->setProperty("wifiConnectTimedOut", true);
        if (process->state() == QProcess::Running) {
            process->kill();
            process->waitForFinished(1000);
        }
    });

    connect(process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this,
            [this, process, ssid, timeoutTimer, useSavedProfile](int exitCode, QProcess::ExitStatus) mutable {
                timeoutTimer->stop();
                QString output = process->readAllStandardOutput();
                QString error = process->readAllStandardError();
                const bool timedOut = process->property("wifiConnectTimedOut").toBool();

                if (exitCode != 0 && useSavedProfile && !timedOut) {
                    // No saved profile: let NetworkManager discover the network, then report
                    // that credentials are needed if it cannot activate it without a secret.
                    process->start("nmcli", QStringList() << "-w" << "30" << "dev" << "wifi"
                                                            << "connect" << ssid);
                    timeoutTimer->start();
                    return;
                }

                const QString diagnostics = output + "\n" + error;
                process->deleteLater();
                timeoutTimer->deleteLater();

                QString result;
                if (timedOut) {
                    result = "CONNECTION_TIMEOUT";
                } else if (exitCode == 0) {
                    result = "Connected to " + ssid;
                } else {
                    if (diagnostics.contains("Secrets were required", Qt::CaseInsensitive) ||
                        diagnostics.contains("802-11-wireless-security", Qt::CaseInsensitive) ||
                        diagnostics.contains("No suitable secrets", Qt::CaseInsensitive)) {
                        result = "NEEDS_PASSWORD";
                    } else if (diagnostics.contains("wrong key", Qt::CaseInsensitive) ||
                               diagnostics.contains("invalid key", Qt::CaseInsensitive) ||
                               diagnostics.contains("authentication failed", Qt::CaseInsensitive) ||
                               diagnostics.contains("WPA handshake failed", Qt::CaseInsensitive)) {
                        result = "WRONG_PASSWORD";
                    } else if (diagnostics.contains("No such file or directory", Qt::CaseInsensitive) ||
                               diagnostics.contains("not found", Qt::CaseInsensitive) ||
                               diagnostics.contains("SSID not found", Qt::CaseInsensitive)) {
                        result = "NETWORK_NOT_FOUND";
                    } else if (diagnostics.contains("timeout", Qt::CaseInsensitive) ||
                               diagnostics.contains("Connection activation failed", Qt::CaseInsensitive)) {
                        result = "CONNECTION_TIMEOUT";
                    } else if (diagnostics.contains("Device", Qt::CaseInsensitive) &&
                               diagnostics.contains("not found", Qt::CaseInsensitive)) {
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

void WiFiScanner::scanNetworksAsync()
{
    QThread *thread = new QThread(this);
    QObject *worker = new QObject();
    worker->moveToThread(thread);

    connect(thread, &QThread::started, this, [this, worker, thread]() {
        QVariantList networks = scanNetworks();
        emit networksScanned(networks);
        thread->quit();
        worker->deleteLater();
        thread->deleteLater();
    });

    thread->start();
}

void WiFiScanner::currentConnectionAsync()
{
    QThread *thread = new QThread(this);
    QObject *worker = new QObject();
    worker->moveToThread(thread);

    connect(thread, &QThread::started, this, [this, worker, thread]() {
        QString ssid = currentConnection();
        emit currentConnectionReady(ssid);
        thread->quit();
        worker->deleteLater();
        thread->deleteLater();
    });

    thread->start();
}

bool WiFiScanner::isWifiEnabled()
{
    QProcess process;
    process.start("nmcli", QStringList() << "radio" << "wifi");
    if (!process.waitForStarted(2000) || !process.waitForFinished(5000)) {
        process.kill();
        process.waitForFinished(1000);
        return false;
    }

    return process.exitCode() == 0 && process.readAllStandardOutput().trimmed() == "enabled";
}

bool WiFiScanner::enableWifi(bool enable)
{
    QProcess process;
    QStringList args;
    args << "radio" << "wifi" << (enable ? "on" : "off");

    process.start("nmcli", args);

    if (!process.waitForStarted(5000)) {
        qDebug() << "Failed to start nmcli radio process";
        return false;
    }

    if (!process.waitForFinished(10000)) {
        qDebug() << "nmcli radio process timed out";
        process.kill();
        process.waitForFinished(1000);
        return false;
    }

    return process.exitCode() == 0;
}
