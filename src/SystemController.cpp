#include "SystemController.h"
#include <QProcess>

SystemController::SystemController(QObject *parent)
    : QObject(parent)
{
}

void SystemController::shutdown()
{
    QProcess::execute("/sbin/shutdown", QStringList() << "-h" << "now");
}
