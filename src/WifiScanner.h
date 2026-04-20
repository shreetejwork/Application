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
    Q_INVOKABLE void scanNetworksAsync();
    Q_INVOKABLE void connectToWifiAsync(QString ssid, QString password);
    Q_INVOKABLE void enableWifi(bool enable);
    Q_INVOKABLE QString currentConnection();
    Q_INVOKABLE void currentConnectionAsync();
    Q_INVOKABLE bool isNmcliAvailable();

signals:
    void connectionResult(QString ssid, QString result);
    void networksScanned(QVariantList networks);
    void currentConnectionReady(QString ssid);
};

#endif // WIFISCANNER_H
