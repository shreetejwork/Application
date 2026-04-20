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
        return error.isEmpty() ? "Connection failed" : error;
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
