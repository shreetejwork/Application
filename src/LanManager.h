#ifndef LANMANAGER_H
#define LANMANAGER_H

#include <QObject>
#include <QString>

class NetworkManager : public QObject
{
    Q_OBJECT

public:
    explicit NetworkManager(QObject *parent = nullptr);

    Q_INVOKABLE bool isEthernetAvailable(
        const QString &interfaceName = "eth0"
        );

    Q_INVOKABLE bool isEthernetConnected(
        const QString &interfaceName = "eth0"
        );

    Q_INVOKABLE QString getIPAddress(
        const QString &interfaceName = "eth0"
        );

    Q_INVOKABLE QString getSubnet(
        const QString &interfaceName = "eth0"
        );

    Q_INVOKABLE QString getGateway(
        const QString &interfaceName = "eth0"
        );

    Q_INVOKABLE QString getDns(
        const QString &interfaceName = "eth0"
        );

    Q_INVOKABLE QString setDhcp(
        const QString &interfaceName = "eth0"
        );

    Q_INVOKABLE QString setStaticIP(
        const QString &interfaceName,
        const QString &ipAddress,
        const QString &subnet,
        const QString &gateway,
        const QString &dns
        );

signals:

    void networkConfigurationChanged();

private:

    QString runNmcli(
        const QStringList &arguments,
        int timeout = 10000
        );

    bool runNmcliCommand(
        const QStringList &arguments,
        QString *output = nullptr,
        QString *error = nullptr,
        int timeout = 15000
        );
};


#endif // LANMANAGER_H
