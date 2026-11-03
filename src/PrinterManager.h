#pragma once

#include <QObject>
#include <QProcess>
#include <QTimer>
#include <QVariantList>

class PrinterManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList printers READ printers NOTIFY printersChanged)
    Q_PROPERTY(QString defaultPrinter READ defaultPrinter NOTIFY printersChanged)
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)
    Q_PROPERTY(bool installRunning READ installRunning NOTIFY installRunningChanged)
    Q_PROPERTY(bool printerSearchEnabled READ printerSearchEnabled
                   NOTIFY printerSearchEnabledChanged)

public:
    explicit PrinterManager(QObject *parent = nullptr);

    QVariantList printers() const;
    QString defaultPrinter() const;
    QString status() const;
    bool installRunning() const;
    bool printerSearchEnabled() const;

    Q_INVOKABLE void refresh();
    Q_INVOKABLE void setPrinterSearchEnabled(bool enabled);
    Q_INVOKABLE void installDriver(const QString &printerName);
    Q_INVOKABLE void setDefaultPrinter(const QString &printerName);

signals:
    void printersChanged();
    void statusChanged();
    void installRunningChanged();
    void printerSearchEnabledChanged();
    void printerConnected(const QString &printerName);

private:
    void setStatus(const QString &status, bool transient = false);
    void refreshPrinters();
    void finishInstall(int exitCode, QProcess::ExitStatus exitStatus);
    void verifyPrinterSetup(int attemptsRemaining);

    QVariantList m_printers;
    QString m_defaultPrinter;
    QString m_status;
    QStringList m_previousPrinterNames;
    QTimer m_refreshTimer;
    QProcess m_installProcess;
    QString m_pendingDeviceUri;
    QString m_pendingModel;
    QString m_pendingBrand;
    bool m_statusPinned = false;
    bool m_installRunning = false;
    bool m_printerSearchEnabled = false;
};
