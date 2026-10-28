#include "SystemController.h"
#include <QProcess>
#include <QDebug>

#ifdef Q_OS_LINUX
#include <cerrno>
#include <cstring>
#include <fcntl.h>
#include <linux/rtc.h>
#include <sys/ioctl.h>
#include <unistd.h>
#endif

SystemController::SystemController(QObject *parent)
    : QObject(parent)
{
}

void SystemController::shutdown()
{
    QProcess::execute("/sbin/shutdown", QStringList() << "-h" << "now");
}

void SystemController::reboot()
{
    QProcess::startDetached("/sbin/reboot");
}

QString SystemController::writeRtcDateTime(const QDateTime &dateTime)
{
    if (!dateTime.isValid())
        return "Invalid date or time";

#ifdef Q_OS_LINUX
    int rtcFd = ::open("/dev/rtc0", O_RDWR | O_CLOEXEC);
    if (rtcFd < 0)
        rtcFd = ::open("/dev/rtc", O_RDWR | O_CLOEXEC);
    if (rtcFd < 0) {
        const QString error = QString::fromLocal8Bit(std::strerror(errno));
        qWarning() << "Unable to open RTC device:" << error;
        return "RTC unavailable: " + error;
    }

    const QDateTime utcDateTime = dateTime.toUTC();
    const QDate date = utcDateTime.date();
    const QTime time = utcDateTime.time();
    struct rtc_time rtcTime {};
    rtcTime.tm_sec = time.second();
    rtcTime.tm_min = time.minute();
    rtcTime.tm_hour = time.hour();
    rtcTime.tm_mday = date.day();
    rtcTime.tm_mon = date.month() - 1;
    rtcTime.tm_year = date.year() - 1900;
    rtcTime.tm_wday = date.dayOfWeek() % 7;
    rtcTime.tm_yday = date.dayOfYear() - 1;
    rtcTime.tm_isdst = 0;

    const int result = ::ioctl(rtcFd, RTC_SET_TIME, &rtcTime);
    const int errorNumber = errno;
    ::close(rtcFd);
    if (result < 0) {
        const QString error = QString::fromLocal8Bit(std::strerror(errorNumber));
        qWarning() << "Unable to write date/time to RTC:" << error;
        return "RTC update failed: " + error;
    }

    return {};
#else
    Q_UNUSED(dateTime);
    return "RTC updates are only available on Linux";
#endif
}
