#include "PrinterManager.h"

#include <QFile>
#include <QHash>
#include <QRegularExpression>
#include <QTextStream>
#include <QUrl>
#include <algorithm>

namespace {

bool runCommand(const QString &program,
                const QStringList &arguments,
                QString *standardOutput = nullptr)
{
    QProcess process;
    process.start(program, arguments);
    if (!process.waitForStarted(1500) || !process.waitForFinished(1500))
        return false;

    if (standardOutput)
        *standardOutput = QString::fromLocal8Bit(process.readAllStandardOutput());
    return process.exitStatus() == QProcess::NormalExit &&
           process.exitCode() == 0;
}

QString readDriverName(const QString &printerName)
{
    QFile ppdFile(QStringLiteral("/etc/cups/ppd/%1.ppd").arg(printerName));
    if (!ppdFile.open(QIODevice::ReadOnly | QIODevice::Text))
        return QStringLiteral("Not installed");

    QTextStream stream(&ppdFile);
    while (!stream.atEnd()) {
        const QString line = stream.readLine();
        if (line.startsWith(QStringLiteral("*NickName:")))
            return line.section('"', 1, 1).trimmed();
        if (line.startsWith(QStringLiteral("*ModelName:")))
            return line.section('"', 1, 1).trimmed();
    }

    return QStringLiteral("Installed (model not reported)");
}

QString brandForPrinter(const QString &printerName, const QString &model)
{
    const QString identity = (printerName + QLatin1Char(' ') + model).toLower();
    if (identity.contains(QStringLiteral("hp")) ||
        identity.contains(QStringLiteral("hewlett")))
        return QStringLiteral("HP");
    if (identity.contains(QStringLiteral("epson")))
        return QStringLiteral("Epson");
    if (identity.contains(QStringLiteral("canon")))
        return QStringLiteral("Canon");
    return {};
}

QStringList driverPackages(const QString &brand)
{
    if (brand == QStringLiteral("HP"))
        return {QStringLiteral("printer-driver-hpcups"),
                QStringLiteral("hplip"),
                QStringLiteral("printer-driver-foo2zjs"),
                QStringLiteral("printer-driver-gutenprint")};
    if (brand == QStringLiteral("Epson"))
        return {QStringLiteral("printer-driver-escpr"),
                QStringLiteral("printer-driver-gutenprint")};
    if (brand == QStringLiteral("Canon"))
        return {QStringLiteral("printer-driver-gutenprint")};
    return {};
}

} // namespace

PrinterManager::PrinterManager(QObject *parent)
    : QObject(parent)
{
    connect(&m_refreshTimer, &QTimer::timeout,
            this, &PrinterManager::refreshPrinters);
    m_refreshTimer.setInterval(5000);
    m_refreshTimer.start();

    connect(&m_installProcess,
            QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, &PrinterManager::finishInstall);
    connect(&m_installProcess, &QProcess::errorOccurred, this,
            [this](QProcess::ProcessError error) {
                if (error == QProcess::FailedToStart) {
                    m_installRunning = false;
                    emit installRunningChanged();
                    setStatus(QStringLiteral(
                        "Could not start the privileged installer. "
                        "Install the driver's package using the command shown in the kiosk setup."));
                }
            });

    QTimer::singleShot(0, this, &PrinterManager::refreshPrinters);
}

QVariantList PrinterManager::printers() const
{
    return m_printers;
}

QString PrinterManager::defaultPrinter() const
{
    return m_defaultPrinter;
}

QString PrinterManager::status() const
{
    return m_status;
}

bool PrinterManager::installRunning() const
{
    return m_installRunning;
}

void PrinterManager::setStatus(const QString &status)
{
    if (m_status == status)
        return;
    m_status = status;
    emit statusChanged();
}

void PrinterManager::refresh()
{
    refreshPrinters();
}

void PrinterManager::refreshPrinters()
{
    QString printerOutput;
    QString defaultOutput;
    QString queueUriOutput;
    QString deviceOutput;
    QString detailedOutput;
    if (!runCommand(QStringLiteral("lpstat"), {QStringLiteral("-p")}, &printerOutput)) {
        setStatus(QStringLiteral("CUPS is unavailable. Check that the CUPS service is running."));
        return;
    }

    runCommand(QStringLiteral("lpstat"), {QStringLiteral("-d")}, &defaultOutput);
    runCommand(QStringLiteral("lpstat"), {QStringLiteral("-v")}, &queueUriOutput);
    runCommand(QStringLiteral("lpstat"),
               {QStringLiteral("-l"), QStringLiteral("-p")},
               &detailedOutput);
    runCommand(QStringLiteral("lpinfo"), {QStringLiteral("-v")}, &deviceOutput);
    const QRegularExpression defaultPattern(
        QStringLiteral("^system default destination: (.+)$"),
        QRegularExpression::MultilineOption);
    const auto defaultMatch = defaultPattern.match(defaultOutput);
    const QString newDefault = defaultMatch.hasMatch()
                                   ? defaultMatch.captured(1).trimmed()
                                   : QString();

    QVariantList updatedPrinters;
    QStringList connectedPrinterKeys;
    QStringList configuredUris;
    const QRegularExpression uriPattern(
        QStringLiteral("^device for (\\S+): (\\S+)$"),
        QRegularExpression::MultilineOption);
    QHash<QString, QString> configuredQueues;
    auto uriIt = uriPattern.globalMatch(queueUriOutput);
    while (uriIt.hasNext()) {
        const auto match = uriIt.next();
        configuredQueues.insert(match.captured(1), match.captured(2));
        configuredUris.append(match.captured(2));
    }

    QHash<QString, QString> printerModels;
    QString currentQueue;
    const QStringList detailLines = detailedOutput.split(QLatin1Char('\n'));
    for (const QString &line : detailLines) {
        if (line.startsWith(QStringLiteral("printer "))) {
            currentQueue = line.section(QLatin1Char(' '), 1, 1);
        } else if (line.trimmed().startsWith(QStringLiteral("Description:")) &&
                   !currentQueue.isEmpty()) {
            printerModels.insert(
                currentQueue,
                line.section(QLatin1Char(':'), 1).trimmed());
        }
    }

    const QRegularExpression printerPattern(
        QStringLiteral("^printer (\\S+) is (.+)$"),
        QRegularExpression::MultilineOption);
    auto it = printerPattern.globalMatch(printerOutput);
    while (it.hasNext()) {
        const auto match = it.next();
        const QString name = match.captured(1);
        const QString state = match.captured(2).trimmed();
        const QString deviceUri = configuredQueues.value(name);
        const bool connected =
            (!deviceUri.startsWith(QStringLiteral("usb://")) &&
             !deviceUri.startsWith(QStringLiteral("ipp://localhost"))) ||
            deviceOutput.contains(deviceUri);
        QString driver = readDriverName(name);
        if (driver == QStringLiteral("Not installed") &&
            configuredQueues.value(name).startsWith(QStringLiteral("ipp")))
            driver = QStringLiteral("Driverless (IPP)");
        QVariantMap printer;
        printer.insert(QStringLiteral("key"), name);
        printer.insert(QStringLiteral("name"), name);
        printer.insert(QStringLiteral("model"),
                       printerModels.value(
                           name,
                           driver == QStringLiteral("Not installed")
                               ? QStringLiteral("Model information unavailable")
                               : driver));
        printer.insert(QStringLiteral("driver"), driver);
        printer.insert(QStringLiteral("brand"),
                       brandForPrinter(name, printerModels.value(name) +
                                                QLatin1Char(' ') + driver));
        printer.insert(QStringLiteral("state"), state);
        printer.insert(QStringLiteral("connected"), connected);
        printer.insert(QStringLiteral("ready"), connected &&
                       !state.contains(QStringLiteral("disabled"),
                                       Qt::CaseInsensitive));
        printer.insert(QStringLiteral("queued"), true);
        updatedPrinters.append(printer);

        if (connected)
            connectedPrinterKeys.append(name);
        if (connected && !m_previousPrinterNames.contains(name))
            emit printerConnected(name);
    }

    const QRegularExpression usbPattern(
        QStringLiteral("^direct (usb://\\S+)$"),
        QRegularExpression::MultilineOption);
    auto usbIt = usbPattern.globalMatch(deviceOutput);
    while (usbIt.hasNext()) {
        const QString uri = usbIt.next().captured(1);
        if (configuredUris.contains(uri))
            continue;

        const QUrl url = QUrl::fromEncoded(uri.toUtf8());
        const QString manufacturer = url.host(QUrl::FullyDecoded);
        QString model = url.path(QUrl::FullyDecoded);
        while (model.startsWith(QLatin1Char('/')))
            model.remove(0, 1);
        const QString brand = brandForPrinter(manufacturer, model);
        const QString displayName =
            (brand.isEmpty() ? manufacturer : brand) +
            (model.isEmpty() ? QString() : QStringLiteral(" ") + model);
        if (displayName.trimmed().isEmpty())
            continue;

        QVariantMap printer;
        printer.insert(QStringLiteral("key"), uri);
        printer.insert(QStringLiteral("name"), displayName);
        printer.insert(QStringLiteral("model"), model);
        printer.insert(QStringLiteral("driver"), QStringLiteral("Not installed"));
        printer.insert(QStringLiteral("brand"), brand);
        printer.insert(QStringLiteral("state"),
                       QStringLiteral("USB detected; queue not configured"));
        printer.insert(QStringLiteral("connected"), true);
        printer.insert(QStringLiteral("ready"), false);
        printer.insert(QStringLiteral("queued"), false);
        updatedPrinters.append(printer);
        connectedPrinterKeys.append(uri);
        if (!m_previousPrinterNames.contains(uri))
            emit printerConnected(displayName);
    }

    if (m_printers != updatedPrinters || m_defaultPrinter != newDefault) {
        m_printers = updatedPrinters;
        m_defaultPrinter = newDefault;
        emit printersChanged();
    }
    m_previousPrinterNames = connectedPrinterKeys;

    if (updatedPrinters.isEmpty())
        setStatus(QStringLiteral("No printers detected. Connect a printer and refresh."));
    else
        setStatus(QStringLiteral("%1 printer(s) detected; %2 currently connected.")
                      .arg(updatedPrinters.size())
                      .arg(connectedPrinterKeys.size()));
}

void PrinterManager::installDriver(const QString &printerName)
{
    if (m_installRunning)
        return;

    const auto printerIt = std::find_if(
        m_printers.cbegin(), m_printers.cend(),
        [&printerName](const QVariant &entry) {
            return entry.toMap().value(QStringLiteral("key")).toString() ==
                   printerName;
        });
    if (printerIt == m_printers.cend()) {
        setStatus(QStringLiteral("That printer is no longer available. Refresh and try again."));
        return;
    }

    const QString brand =
        printerIt->toMap().value(QStringLiteral("brand")).toString();
    const QStringList packages = driverPackages(brand);
    if (packages.isEmpty()) {
        setStatus(QStringLiteral(
            "No supported HP, Epson, or Canon driver package was identified for this printer."));
        return;
    }

    QStringList arguments{QStringLiteral("apt-get"),
                          QStringLiteral("install"),
                          QStringLiteral("-y")};
    arguments.append(packages);
    m_installRunning = true;
    emit installRunningChanged();
    setStatus(QStringLiteral("Installing %1 driver packages for %2...")
                  .arg(brand, printerName));
    m_installProcess.start(QStringLiteral("pkexec"), arguments);
}

void PrinterManager::finishInstall(int exitCode, QProcess::ExitStatus exitStatus)
{
    m_installRunning = false;
    emit installRunningChanged();

    if (exitStatus != QProcess::NormalExit || exitCode != 0) {
        const QString error =
            QString::fromLocal8Bit(m_installProcess.readAllStandardError())
                .trimmed().left(250);
        setStatus(QStringLiteral(
            "Driver installation failed or was cancelled. %1")
                      .arg(error.isEmpty()
                               ? QStringLiteral("Check administrator authorization and network access.")
                               : error));
        return;
    }

    setStatus(QStringLiteral(
        "Driver packages installed. Refreshing CUPS printer configuration..."));

    QString ignored;
    const bool serviceRestarted =
        runCommand(QStringLiteral("pkexec"),
                   {QStringLiteral("systemctl"),
                    QStringLiteral("restart"),
                    QStringLiteral("wrs-usb-printer-auto-setup.service")},
                   &ignored);
    QTimer::singleShot(1500, this, [this, serviceRestarted]() {
        refreshPrinters();
        const bool hasUnqueuedPrinter = std::any_of(
            m_printers.cbegin(), m_printers.cend(),
            [](const QVariant &entry) {
                return !entry.toMap().value(QStringLiteral("queued")).toBool();
            });
        if (!serviceRestarted) {
            setStatus(QStringLiteral(
                "Driver packages installed, but the printer auto-setup service could not be restarted."));
        } else if (hasUnqueuedPrinter || m_printers.isEmpty()) {
            setStatus(QStringLiteral(
                "Driver packages installed, but this model has no matching queue/driver yet."));
        } else {
            setStatus(QStringLiteral(
                "Driver packages installed and the printer queue was refreshed. Verify the driver shown below."));
        }
    });
}

void PrinterManager::setDefaultPrinter(const QString &printerName)
{
    const auto printerIt = std::find_if(
        m_printers.cbegin(), m_printers.cend(),
        [&printerName](const QVariant &entry) {
            const QVariantMap printer = entry.toMap();
            return printer.value(QStringLiteral("name")).toString() ==
                       printerName &&
                   printer.value(QStringLiteral("queued")).toBool();
        });
    if (printerIt == m_printers.cend()) {
        setStatus(QStringLiteral("That printer is no longer available. Refresh and try again."));
        return;
    }

    QProcess process;
    process.start(QStringLiteral("pkexec"),
                  {QStringLiteral("lpadmin"),
                   QStringLiteral("-d"),
                   printerName});
    if (!process.waitForStarted(3000) || !process.waitForFinished(15000) ||
        process.exitStatus() != QProcess::NormalExit ||
        process.exitCode() != 0) {
        setStatus(QStringLiteral(
            "Could not set the default printer. Administrator authorization may be required."));
        return;
    }

    setStatus(QStringLiteral("%1 is now the system default printer.")
                  .arg(printerName));
    refreshPrinters();
}
