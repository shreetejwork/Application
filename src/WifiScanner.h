#ifndef WIFISCANNER_H
#define WIFISCANNER_H

#include <QObject>
#include <QStringList>

class WiFiScanner : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QStringList networks READ networks NOTIFY networksChanged)

public:
    explicit WiFiScanner(QObject *parent = nullptr);

    QStringList networks() const { return m_networks; }

    Q_INVOKABLE void scan();
    Q_INVOKABLE bool connectTo(const QString &ssid, const QString &password);
    Q_INVOKABLE void enableWifi(bool enable);

signals:
    void networksChanged();

private:
    QStringList m_networks;
};

#endif // WIFISCANNER_H
