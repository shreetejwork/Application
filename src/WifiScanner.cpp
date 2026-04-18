#include "wifiscanner.h"
#include <QProcess>
#include <QStringList>

WiFiScanner::WiFiScanner(QObject *parent) : QObject(parent) {}

QVariantList WiFiScanner::scanNetworks()
{
    QVariantList list;

    QProcess process;
    process.start("nmcli", QStringList() << "-t" << "-f" << "SSID,SIGNAL,SECURITY" << "dev" << "wifi" << "list");
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

            list.append(net);
        }
    }

    return list;
}
