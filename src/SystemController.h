#ifndef SYSTEMCONTROLLER_H
#define SYSTEMCONTROLLER_H

#include <QObject>

class SystemController : public QObject
{
    Q_OBJECT
public:
    explicit SystemController(QObject *parent = nullptr);

    Q_INVOKABLE void shutdown();
    Q_INVOKABLE void reboot();
};

#endif // SYSTEMCONTROLLER_H
