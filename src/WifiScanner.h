#ifndef WIFISCANNER_H
#define WIFISCANNER_H

#include <QObject>
#include <QVariantList>

class WiFiScanner : public QObject
{
    Q_OBJECT
public:
    explicit WiFiScanner(QObject *parent = nullptr);

    Q_INVOKABLE QVariantList scanNetworks();
    Q_INVOKABLE QString connectToWifi(QString ssid, QString password);
    Q_INVOKABLE QString currentConnection();
};

#endif // WIFISCANNER_H
