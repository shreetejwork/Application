#ifndef WIFISCANNER_H
#define WIFISCANNER_H

#include <QObject>
#include <QHash>
#include <QVariantList>

class WiFiScanner : public QObject
{
    Q_OBJECT
    bool m_scanInProgress = false;
    QHash<QString, QString> m_savedProfileIds;

public:
    explicit WiFiScanner(QObject *parent = nullptr);

    Q_INVOKABLE QVariantList scanNetworks();
    Q_INVOKABLE void scanNetworksAsync();
    Q_INVOKABLE void connectToWifiAsync(QString ssid, QString password, bool secured);
    Q_INVOKABLE void forgetWifiAsync(QString ssid);
    Q_INVOKABLE bool enableWifi(bool enable);
    Q_INVOKABLE bool isWifiEnabled();
    Q_INVOKABLE QString currentConnection();
    Q_INVOKABLE void currentConnectionAsync();
    Q_INVOKABLE bool isNmcliAvailable();

signals:
    void connectionResult(QString ssid, QString result);
    void networksScanned(QVariantList networks);
    void scanFailed(QString message);
    void forgetResult(QString ssid, QString result);
    void currentConnectionReady(QString ssid);
};

#endif // WIFISCANNER_H
