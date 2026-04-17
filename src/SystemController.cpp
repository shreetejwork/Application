#include "systemcontroller.h"
#include <QProcess>

SystemController::SystemController(QObject *parent)
    : QObject(parent)
{
}

void SystemController::shutdown()
{
    // Shutdown command for Raspberry Pi (Linux)
    QProcess::execute("sudo shutdown -h now");
}
