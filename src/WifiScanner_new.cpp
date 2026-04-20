#include "WifiScanner.h"
#include <QProcess>
#include <QDebug>

WiFiScanner::WiFiScanner(QObject *parent) : QObject(parent) {}

void WiFiScanner::scan()
{
    QProcess process;
    process.start("nmcli", QStringList() << "-t" << "-f" << "SSID" << "dev" << "wifi" << "list");

    if (!process.waitForStarted(5000)) {
        qDebug() << "Failed to start nmcli scan process";
        return;
    }

    if (!process.waitForFinished(10000)) {
        qDebug() << "nmcli scan process timed out";
        process.kill();
        process.waitForFinished(1000);
        return;
    }

    if (process.exitCode() != 0) {
        QString error = process.readAllStandardError();
        qDebug() << "nmcli scan failed:" << error;
        return;
    }

    QString output = process.readAllStandardOutput();
    QStringList lines = output.split("\n", Qt::SkipEmptyParts);

    m_networks.clear();
    for (const QString &line : lines) {
        QString ssid = line.trimmed();
        if (!ssid.isEmpty() && !m_networks.contains(ssid)) {
            m_networks.append(ssid);
        }
    }

    emit networksChanged();
}

bool WiFiScanner::connectTo(const QString &ssid, const QString &password)
{
    QProcess process;
    QStringList args;
    args << "dev" << "wifi" << "connect" << ssid;

    if (!password.isEmpty()) {
        args << "password" << password;
    }

    process.start("nmcli", args);

    if (!process.waitForStarted(5000)) {
        qDebug() << "Failed to start nmcli connect process";
        return false;
    }

    if (!process.waitForFinished(30000)) {
        qDebug() << "nmcli connect process timed out";
        process.kill();
        process.waitForFinished(1000);
        return false;
    }

    QString error = process.readAllStandardError();
    QString output = process.readAllStandardOutput();

    qDebug() << "Connect output:" << output;
    qDebug() << "Connect error:" << error;

    return process.exitCode() == 0;
}

void WiFiScanner::enableWifi(bool enable)
{
    QProcess process;
    QStringList args;
    args << "radio" << "wifi";

    if (enable) {
        args << "on";
    } else {
        args << "off";
    }

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