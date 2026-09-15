#ifndef USBSOFTWAREUPDATEMANAGER_H
#define USBSOFTWAREUPDATEMANAGER_H

#include <QObject>
#include <QThread>

class UsbSoftwareUpdateTaskWorker;

class UsbSoftwareUpdateManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString updateStatus READ updateStatus NOTIFY updateStatusChanged)
    Q_PROPERTY(int updateProgress READ updateProgress NOTIFY updateProgressChanged)
    Q_PROPERTY(bool updateRunning READ updateRunning NOTIFY updateRunningChanged)
    Q_PROPERTY(bool updateFinished READ updateFinished NOTIFY updateFinishedChanged)
    Q_PROPERTY(bool confirmationRequired READ confirmationRequired NOTIFY confirmationRequiredChanged)
    Q_PROPERTY(QString updateError READ updateError NOTIFY updateErrorChanged)

public:
    explicit UsbSoftwareUpdateManager(QObject *parent = nullptr);
    ~UsbSoftwareUpdateManager() override;

    QString updateStatus() const;
    int updateProgress() const;
    bool updateRunning() const;
    bool updateFinished() const;
    bool confirmationRequired() const;
    QString updateError() const;

public slots:
    void startUsbUpdate();
    void cancelUpdate();
    void confirmRestart();
    void declineRestart();

signals:
    void updateStatusChanged();
    void updateProgressChanged();
    void updateRunningChanged();
    void updateFinishedChanged();
    void confirmationRequiredChanged();
    void updateErrorChanged();
    void updateSucceeded();
    void updateFailed();
    void updateConfirmationRequired();

private slots:
    void handleStatusChanged(const QString &status);
    void handleProgressChanged(int progress);
    void handleErrorOccurred(const QString &errorMessage);
    void handleUpdateCompleted();
    void handleConfirmationRequired();
    void handleWorkerFinished();

private:
    void setUpdateStatus(const QString &status);
    void setUpdateProgress(int progress);
    void setUpdateRunning(bool running);
    void setUpdateFinished(bool finished);
    void setConfirmationRequired(bool required);
    void setUpdateError(const QString &errorMessage);
    void writeStateFile(const QString &state);
    void removeStagingDirectory();

    QString m_updateStatus;
    int m_updateProgress = 0;
    bool m_updateRunning = false;
    bool m_updateFinished = false;
    bool m_confirmationRequired = false;
    QString m_updateError;

    QThread m_updateThread;
    UsbSoftwareUpdateTaskWorker *m_worker = nullptr;
};

#endif // USBSOFTWAREUPDATEMANAGER_H
