#include "WifiScanner.h"
#include <QProcess>
#include <QStringList>

WiFiScanner::WiFiScanner(QObject *parent) : QObject(parent) {}


// ===== SCAN NETWORKS =====
QVariantList WiFiScanner::scanNetworks()
{
    QVariantList list;

    QProcess process;
    process.start("nmcli", QStringList()
                               << "-t"
                               << "-f" << "SSID,SIGNAL,SECURITY"
                               << "dev" << "wifi" << "list");

    process.waitForFinished();

    QString output = process.readAllStandardOutput();
    QStringList lines = output.split("\n", Qt::SkipEmptyParts);

    for (const QString &line : lines) {
        QStringList parts = line.split(":");

        if (parts.size() >= 3) {
            QVariantMap net;
            net["name"] = parts[0];
            net["signal"] = parts[1].toInt();
            net["secured"] = !parts[2].isEmpty();

            // Avoid empty SSID entries
            if (!net["name"].toString().isEmpty()) {
                list.append(net);
            }
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
        return "Failed: " + error;
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
