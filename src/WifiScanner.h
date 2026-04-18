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
};

#endif
