#include "WifiScanner.h"
#include <QProcess>
#include <QSet>
#include <QDebug>
#include <QRegularExpression>
#include <QTimer>
#include <memory>

WiFiScanner::WiFiScanner(QObject *parent) : QObject(parent) {}

namespace {
struct SavedProfileLookup {
    QString scanOutput;
    QHash<QString, QString> profileIds;
    int pending = 0;
};

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
    QHash<QString, int> networkIndexBySsid;

    for (const QString &line : output.split('\n', Qt::SkipEmptyParts)) {
        const QStringList parts = splitNmcliFields(line);
        if (parts.size() < 4)
            continue;

        const QString inUse = parts[0].trimmed();
        const QString ssid = parts[1].trimmed();
        bool signalOk = false;
        const int signal = parts[2].trimmed().toInt(&signalOk);
        const QString security = parts.mid(3).join(":").trimmed();
        const bool connected = inUse == "*";

        if (ssid.isEmpty())
            continue;

        const auto existing = networkIndexBySsid.constFind(ssid);
        if (existing != networkIndexBySsid.cend()) {
            QVariantMap network = networks[existing.value()].toMap();
            network["connected"] = network["connected"].toBool() || connected;
            network["signal"] = qMax(network["signal"].toInt(), signalOk ? signal : 0);
            networks[existing.value()] = network;
            continue;
        }

        QVariantMap network;
        network["name"] = ssid;
        network["signal"] = signalOk ? signal : 0;
        network["secured"] = !security.isEmpty() && security != "--";
        network["connected"] = connected;
        network["saved"] = savedSsids.contains(ssid);
        networkIndexBySsid.insert(ssid, networks.size());
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
    if (m_connectionInProgress) {
        return;
    }

    const QString profileId = m_savedProfileIds.value(ssid);
    if (password.isEmpty() && secured && profileId.isEmpty()) {
        emit connectionResult(ssid, "NEEDS_PASSWORD");
        return;
    }

    m_connectionInProgress = true;
    QProcess *process = new QProcess(this);
    QStringList args;
    if (password.isEmpty() && !profileId.isEmpty()) {
        args << "--ask" << "-w" << "30" << "connection" << "up" << "uuid" << profileId;
    } else {
        args << "--ask" << "-w" << "30" << "dev" << "wifi" << "connect" << ssid;
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
            [this, process, ssid, secured, hasPassword = !password.isEmpty(), timeoutTimer]
            (int exitCode, QProcess::ExitStatus) {
                timeoutTimer->stop();
                const QString output = process->property("wifiConnectOutput").toString()
                    + QString::fromUtf8(process->readAllStandardOutput());
                const QString error = process->property("wifiConnectError").toString()
                    + QString::fromUtf8(process->readAllStandardError());
                const bool timedOut = process->property("wifiConnectTimedOut").toBool();
                const bool secretPrompted = process->property("wifiSecretPrompted").toBool();

                const QString diagnostics = output + "\n" + error;
                process->deleteLater();
                timeoutTimer->deleteLater();
                m_connectionInProgress = false;

                QString result;
                if (timedOut) {
                    result = "CONNECTION_TIMEOUT";
                } else if (secretPrompted) {
                    result = hasPassword ? "WRONG_PASSWORD" : "NEEDS_PASSWORD";
                } else if (exitCode == 0) {
                    result = "Connected to " + ssid;
                } else {
                    if (diagnostics.contains("Secrets were required", Qt::CaseInsensitive) ||
                        diagnostics.contains("802-11-wireless-security", Qt::CaseInsensitive) ||
                        diagnostics.contains("No suitable secrets", Qt::CaseInsensitive) ||
                        (secured && diagnostics.contains("unknown connection", Qt::CaseInsensitive))) {
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

    const auto detectSecretPrompt = [process](QProcess::ProcessChannel channel) {
        const QString chunk = QString::fromUtf8(channel == QProcess::StandardOutput
            ? process->readAllStandardOutput()
            : process->readAllStandardError());
        const char *propertyName = channel == QProcess::StandardOutput
            ? "wifiConnectOutput" : "wifiConnectError";
        const QString accumulated = process->property(propertyName).toString() + chunk;
        process->setProperty(propertyName, accumulated);

        static const QRegularExpression secretPrompt(
            QStringLiteral("(?:password|psk)[^\\r\\n]*:\\s*$"),
            QRegularExpression::CaseInsensitiveOption);
        if (!process->property("wifiSecretPrompted").toBool() &&
            secretPrompt.match(accumulated).hasMatch()) {
            process->setProperty("wifiSecretPrompted", true);
            process->kill();
        }
    };
    connect(process, &QProcess::readyReadStandardOutput, process, [detectSecretPrompt]() {
        detectSecretPrompt(QProcess::StandardOutput);
    });
    connect(process, &QProcess::readyReadStandardError, process, [detectSecretPrompt]() {
        detectSecretPrompt(QProcess::StandardError);
    });
    connect(process, &QProcess::errorOccurred, this,
            [this, process, ssid, timeoutTimer](QProcess::ProcessError error) {
        if (error != QProcess::FailedToStart)
            return;
        timeoutTimer->stop();
        timeoutTimer->deleteLater();
        qWarning() << "Failed to start nmcli connect process:" << process->errorString();
        process->deleteLater();
        m_connectionInProgress = false;
        emit connectionResult(ssid, "CONNECTION_FAILED");
    });
    timeoutTimer->start();
    process->start("nmcli", args);
}

void WiFiScanner::forgetWifiAsync(QString ssid)
{
    const QString profileId = m_savedProfileIds.value(ssid);
    if (m_forgetInProgress) {
        emit forgetResult(ssid, "FORGET_IN_PROGRESS");
        return;
    }
    if (profileId.isEmpty()) {
        emit forgetResult(ssid, "FORGET_NOT_FOUND");
        return;
    }

    m_forgetInProgress = true;
    QProcess *verifyProcess = new QProcess(this);
    connect(verifyProcess, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this,
            [this, verifyProcess, ssid, profileId](int exitCode, QProcess::ExitStatus) {
                const QString error =
                    QString::fromUtf8(verifyProcess->readAllStandardError()).trimmed();
                verifyProcess->deleteLater();
                if (exitCode != 0) {
                    qWarning() << "Saved WiFi profile is no longer available:" << error;
                    m_savedProfileIds.remove(ssid);
                    m_forgetInProgress = false;
                    emit forgetResult(ssid, "FORGET_NOT_FOUND");
                    return;
                }

                QProcess *deleteProcess = new QProcess(this);
                connect(deleteProcess,
                        QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this,
                        [this, deleteProcess, ssid](int deleteExitCode, QProcess::ExitStatus) {
                            const QString deleteError =
                                QString::fromUtf8(deleteProcess->readAllStandardError()).trimmed();
                            deleteProcess->deleteLater();
                            m_forgetInProgress = false;
                            if (deleteExitCode == 0) {
                                m_savedProfileIds.remove(ssid);
                                emit forgetResult(ssid, "FORGET_SUCCESS");
                            } else if (deleteError.contains("unknown connection", Qt::CaseInsensitive) ||
                                       deleteError.contains("cannot delete unknown", Qt::CaseInsensitive)) {
                                m_savedProfileIds.remove(ssid);
                                emit forgetResult(ssid, "FORGET_NOT_FOUND");
                            } else {
                                qWarning() << "Failed to forget WiFi profile:" << deleteError;
                                emit forgetResult(ssid, "FORGET_FAILED");
                            }
                        });
                connect(deleteProcess, &QProcess::errorOccurred, this,
                        [this, deleteProcess, ssid](QProcess::ProcessError error) {
                            if (error != QProcess::FailedToStart)
                                return;
                            qWarning() << "Failed to start nmcli forget process:"
                                       << deleteProcess->errorString();
                            deleteProcess->deleteLater();
                            m_forgetInProgress = false;
                            emit forgetResult(ssid, "FORGET_FAILED");
                        });
                deleteProcess->start("nmcli",
                    QStringList() << "connection" << "delete" << "uuid" << profileId);
            });
    connect(verifyProcess, &QProcess::errorOccurred, this,
            [this, verifyProcess, ssid](QProcess::ProcessError error) {
                if (error != QProcess::FailedToStart)
                    return;
                qWarning() << "Failed to verify saved WiFi profile:"
                           << verifyProcess->errorString();
                verifyProcess->deleteLater();
                m_forgetInProgress = false;
                emit forgetResult(ssid, "FORGET_FAILED");
            });
    verifyProcess->start("nmcli", QStringList()
        << "connection" << "show" << "uuid" << profileId);
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
                            const QString profileError =
                                QString::fromUtf8(profilesProcess->readAllStandardError()).trimmed();
                            const QString profilesOutput =
                                QString::fromUtf8(profilesProcess->readAllStandardOutput());
                            profilesProcess->deleteLater();

                            if (profilesExitCode != 0) {
                                qWarning() << "Failed to list saved WiFi profiles:" << profileError;
                                m_savedProfileIds.clear();
                                m_scanInProgress = false;
                                emit networksScanned(parseWifiNetworks(scanOutput, {}));
                                return;
                            }

                            QStringList wirelessProfileUuids;
                            for (const QString &line : profilesOutput.split('\n', Qt::SkipEmptyParts)) {
                                const QStringList fields = splitNmcliFields(line);
                                if (fields.size() >= 3 && fields[2].trimmed() == "802-11-wireless")
                                    wirelessProfileUuids.append(fields[1].trimmed());
                            }

                            const auto state = std::make_shared<SavedProfileLookup>();
                            state->scanOutput = scanOutput;
                            state->pending = wirelessProfileUuids.size();

                            const auto finishScan = [this, state]() {
                                m_savedProfileIds = state->profileIds;
                                QSet<QString> savedSsids;
                                for (auto it = state->profileIds.cbegin(); it != state->profileIds.cend(); ++it)
                                    savedSsids.insert(it.key());
                                m_scanInProgress = false;
                                emit networksScanned(parseWifiNetworks(state->scanOutput, savedSsids));
                            };

                            if (state->pending == 0) {
                                finishScan();
                                return;
                            }

                            for (const QString &uuid : wirelessProfileUuids) {
                                QProcess *ssidProcess = new QProcess(this);
                                const auto completeLookup = [state, finishScan, ssidProcess, uuid]() {
                                    if (ssidProcess->property("wifiProfileLookupHandled").toBool())
                                        return;
                                    ssidProcess->setProperty("wifiProfileLookupHandled", true);

                                    const QString ssid =
                                        QString::fromUtf8(ssidProcess->readAllStandardOutput()).trimmed();
                                    if (ssidProcess->exitStatus() == QProcess::NormalExit &&
                                        ssidProcess->exitCode() == 0 && !ssid.isEmpty()) {
                                        state->profileIds.insert(ssid, uuid);
                                    } else {
                                        qWarning() << "Unable to read SSID for saved WiFi profile"
                                                   << uuid << ":"
                                                   << QString::fromUtf8(ssidProcess->readAllStandardError()).trimmed();
                                    }
                                    ssidProcess->deleteLater();

                                    if (--state->pending == 0)
                                        finishScan();
                                };

                                connect(ssidProcess,
                                        QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
                                        this, [completeLookup](int, QProcess::ExitStatus) {
                                            completeLookup();
                                        });
                                connect(ssidProcess, &QProcess::errorOccurred, this,
                                        [completeLookup, ssidProcess](QProcess::ProcessError error) {
                                            if (error != QProcess::FailedToStart)
                                                return;
                                            qWarning() << "Failed to start saved WiFi SSID lookup:"
                                                       << ssidProcess->errorString();
                                            completeLookup();
                                        });
                                ssidProcess->start("nmcli", QStringList()
                                    << "-g" << "802-11-wireless.ssid"
                                    << "connection" << "show" << "uuid" << uuid);
                            }
                        });
                connect(profilesProcess, &QProcess::errorOccurred, this,
                        [this, profilesProcess, scanOutput](QProcess::ProcessError error) {
                            if (error != QProcess::FailedToStart)
                                return;
                            const QString message = profilesProcess->errorString();
                            qWarning() << "Failed to list saved WiFi profiles:" << message;
                            profilesProcess->deleteLater();
                            m_savedProfileIds.clear();
                            m_scanInProgress = false;
                            emit networksScanned(parseWifiNetworks(scanOutput, {}));
                        });
                profilesProcess->start("nmcli", QStringList()
                    << "-t" << "-f" << "NAME,UUID,TYPE"
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
