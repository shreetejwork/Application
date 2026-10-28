#include "WifiScanner.h"
#include <QProcess>
#include <QSet>
#include <QDebug>
#include <QTimer>

WiFiScanner::WiFiScanner(QObject *parent) : QObject(parent) {}

namespace {
QStringList splitNmcliFields(const QString &line)
{
    QStringList fields;
    QString field;
    bool escaped = false;

    for (const QChar character : line) {
        if (escaped) {
            if (character == 'n')
                field.append('\n');
            else
                field.append(character);
            escaped = false;
        } else if (character == '\\') {
            escaped = true;
        } else if (character == ':') {
            fields.append(field);
            field.clear();
        } else {
            field.append(character);
        }
    }

    if (escaped)
        field.append('\\');
    fields.append(field);
    return fields;
}

QVariantList parseWifiNetworks(const QString &output, const QSet<QString> &savedSsids)
{
    QVariantList networks;
    QSet<QString> seenSsids;

    for (const QString &line : output.split('\n', Qt::SkipEmptyParts)) {
        const QStringList parts = splitNmcliFields(line);
        if (parts.size() < 4)
            continue;

        const QString inUse = parts[0].trimmed();
        const QString ssid = parts[1].trimmed();
        bool signalOk = false;
        const int signal = parts[2].trimmed().toInt(&signalOk);
        const QString security = parts.mid(3).join(":").trimmed();

        if (ssid.isEmpty() || seenSsids.contains(ssid))
            continue;

        seenSsids.insert(ssid);
        QVariantMap network;
        network["name"] = ssid;
        network["signal"] = signalOk ? signal : 0;
        network["secured"] = !security.isEmpty() && security != "--";
        network["connected"] = inUse == "*";
        network["saved"] = savedSsids.contains(ssid);
        networks.append(network);
    }

    return networks;
}
}

QVariantList WiFiScanner::scanNetworks()
{
    QProcess process;
    process.start("nmcli", QStringList()
                               << "-t"
                               << "-f" << "IN-USE,SSID,SIGNAL,SECURITY"
                               << "dev" << "wifi" << "list");

    if (!process.waitForStarted(5000)) {
        qDebug() << "Failed to start nmcli scan process";
        return {};
    }

    if (!process.waitForFinished(10000)) {
        qDebug() << "nmcli scan process timed out";
        process.kill();
        process.waitForFinished(1000);
        return {};
    }

    if (process.exitCode() != 0) {
        QString error = process.readAllStandardError();
        qDebug() << "nmcli scan failed:" << error;
        return {};
    }

    return parseWifiNetworks(QString::fromUtf8(process.readAllStandardOutput()), {});
}

void WiFiScanner::connectToWifiAsync(QString ssid, QString password, bool secured)
{
    const QString profileId = m_savedProfileIds.value(ssid);
    if (password.isEmpty() && secured && profileId.isEmpty()) {
        emit connectionResult(ssid, "NEEDS_PASSWORD");
        return;
    }

    QProcess *process = new QProcess(this);
    QStringList args;
    if (password.isEmpty() && !profileId.isEmpty()) {
        args << "-w" << "30" << "connection" << "up" << "id" << profileId;
    } else {
        args << "-w" << "30" << "dev" << "wifi" << "connect" << ssid;
        if (!password.isEmpty())
            args << "password" << password;
    }

    QTimer *timeoutTimer = new QTimer(process);
    timeoutTimer->setSingleShot(true);
    timeoutTimer->setInterval(30000);

    connect(timeoutTimer, &QTimer::timeout, this, [process]() {
        qDebug() << "nmcli async connect timed out";
        process->setProperty("wifiConnectTimedOut", true);
        if (process->state() == QProcess::Running)
            process->kill();
    });

    connect(process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this,
            [this, process, ssid, timeoutTimer](int exitCode, QProcess::ExitStatus) {
                timeoutTimer->stop();
                QString output = process->readAllStandardOutput();
                QString error = process->readAllStandardError();
                const bool timedOut = process->property("wifiConnectTimedOut").toBool();

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

    connect(process, &QProcess::errorOccurred, this,
            [this, process, ssid, timeoutTimer](QProcess::ProcessError error) {
        if (error != QProcess::FailedToStart)
            return;
        timeoutTimer->stop();
        timeoutTimer->deleteLater();
        qWarning() << "Failed to start nmcli connect process:" << process->errorString();
        process->deleteLater();
        emit connectionResult(ssid, "CONNECTION_FAILED");
    });
    timeoutTimer->start();
    process->start("nmcli", args);
}

void WiFiScanner::forgetWifiAsync(QString ssid)
{
    const QString profileId = m_savedProfileIds.value(ssid);
    if (profileId.isEmpty()) {
        emit forgetResult(ssid, "FORGET_FAILED");
        return;
    }

    QProcess *process = new QProcess(this);
    connect(process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this,
            [this, process, ssid](int exitCode, QProcess::ExitStatus) {
                const QString error = QString::fromUtf8(process->readAllStandardError()).trimmed();
                process->deleteLater();
                if (exitCode == 0) {
                    m_savedProfileIds.remove(ssid);
                    emit forgetResult(ssid, "FORGET_SUCCESS");
                } else {
                    qWarning() << "Failed to forget WiFi profile:" << error;
                    emit forgetResult(ssid, "FORGET_FAILED");
                }
            });
    connect(process, &QProcess::errorOccurred, this,
            [this, process, ssid](QProcess::ProcessError error) {
                if (error != QProcess::FailedToStart)
                    return;
                qWarning() << "Failed to start nmcli forget process:" << process->errorString();
                process->deleteLater();
                emit forgetResult(ssid, "FORGET_FAILED");
            });
    process->start("nmcli", QStringList() << "connection" << "delete" << "id" << profileId);
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

    const QString output = QString::fromUtf8(process.readAllStandardOutput());
    for (const QString &line : output.split('\n', Qt::SkipEmptyParts)) {
        const QStringList parts = splitNmcliFields(line);
        if (parts.size() >= 2 && parts[0].trimmed() == "yes" && !parts[1].trimmed().isEmpty())
            return parts[1].trimmed();
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
    if (m_scanInProgress)
        return;

    m_scanInProgress = true;
    QProcess *scanProcess = new QProcess(this);
    connect(scanProcess, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this,
            [this, scanProcess](int exitCode, QProcess::ExitStatus) {
                const QString scanOutput = QString::fromUtf8(scanProcess->readAllStandardOutput());
                const QString scanError = QString::fromUtf8(scanProcess->readAllStandardError()).trimmed();
                scanProcess->deleteLater();

                if (exitCode != 0) {
                    m_scanInProgress = false;
                    qWarning() << "nmcli scan failed:" << scanError;
                    emit scanFailed(scanError.isEmpty() ? "WiFi scan failed" : scanError);
                    return;
                }

                QProcess *profilesProcess = new QProcess(this);
                connect(profilesProcess,
                        QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this,
                        [this, profilesProcess, scanOutput](int profilesExitCode, QProcess::ExitStatus) {
                            QSet<QString> savedSsids;

                            if (profilesExitCode == 0) {
                                m_savedProfileIds.clear();
                                const QString profilesOutput =
                                    QString::fromUtf8(profilesProcess->readAllStandardOutput());
                                for (const QString &line : profilesOutput.split('\n', Qt::SkipEmptyParts)) {
                                    const QStringList fields = splitNmcliFields(line);
                                    if (fields.size() < 3 || fields[1].trimmed() != "802-11-wireless")
                                        continue;

                                    const QString ssid = fields[2].trimmed();
                                    if (ssid.isEmpty())
                                        continue;
                                    m_savedProfileIds.insert(ssid, fields[0]);
                                    savedSsids.insert(ssid);
                                }
                            } else {
                                qWarning() << "Failed to read saved WiFi profiles:"
                                           << QString::fromUtf8(profilesProcess->readAllStandardError()).trimmed();
                                profilesProcess->deleteLater();
                                m_scanInProgress = false;
                                emit scanFailed("Unable to read saved WiFi profiles");
                                return;
                            }

                            profilesProcess->deleteLater();
                            m_scanInProgress = false;
                            emit networksScanned(parseWifiNetworks(scanOutput, savedSsids));
                        });
                connect(profilesProcess, &QProcess::errorOccurred, this,
                        [this, profilesProcess](QProcess::ProcessError error) {
                            if (error != QProcess::FailedToStart)
                                return;
                            const QString message = profilesProcess->errorString();
                            qWarning() << "Failed to read saved WiFi profiles:" << message;
                            profilesProcess->deleteLater();
                            m_scanInProgress = false;
                            emit scanFailed(message);
                        });
                profilesProcess->start("nmcli", QStringList()
                    << "-t" << "-f" << "NAME,TYPE,802-11-wireless.ssid"
                    << "connection" << "show");
            });
    connect(scanProcess, &QProcess::errorOccurred, this,
            [this, scanProcess](QProcess::ProcessError error) {
                if (error != QProcess::FailedToStart)
                    return;
                const QString message = scanProcess->errorString();
                qWarning() << "Failed to start nmcli scan process:" << message;
                scanProcess->deleteLater();
                m_scanInProgress = false;
                emit scanFailed(message);
            });
    scanProcess->start("nmcli", QStringList()
        << "-t" << "-f" << "IN-USE,SSID,SIGNAL,SECURITY"
        << "dev" << "wifi" << "list");
}

void WiFiScanner::currentConnectionAsync()
{
    QProcess *process = new QProcess(this);
    connect(process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this,
            [this, process](int exitCode, QProcess::ExitStatus) {
                QString ssid;
                if (exitCode == 0) {
                    const QString output = QString::fromUtf8(process->readAllStandardOutput());
                    for (const QString &line : output.split('\n', Qt::SkipEmptyParts)) {
                        const QStringList fields = splitNmcliFields(line);
                        if (fields.size() >= 2 && fields[0].trimmed() == "yes") {
                            ssid = fields[1].trimmed();
                            break;
                        }
                    }
                } else {
                    qWarning() << "nmcli current connection failed:"
                               << QString::fromUtf8(process->readAllStandardError()).trimmed();
                }
                process->deleteLater();
                emit currentConnectionReady(ssid);
            });
    connect(process, &QProcess::errorOccurred, this,
            [this, process](QProcess::ProcessError error) {
                if (error != QProcess::FailedToStart)
                    return;
                qWarning() << "Failed to start nmcli current connection process:"
                           << process->errorString();
                process->deleteLater();
                emit currentConnectionReady({});
            });
    process->start("nmcli", QStringList()
        << "-t" << "-f" << "ACTIVE,SSID" << "dev" << "wifi");
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
