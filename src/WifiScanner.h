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
    Q_INVOKABLE void connectToWifiAsync(QString ssid, QString password);
    Q_INVOKABLE QString currentConnection();
    Q_INVOKABLE bool isNmcliAvailable();

signals:
    void connectionResult(QString ssid, QString result);
};

#endif // WIFISCANNER_H
