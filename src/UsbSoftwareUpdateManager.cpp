#include "UsbSoftwareUpdateManager.h"

#include <QDir>
#include <QDirIterator>
#include <QCoreApplication>
#include <QFile>
#include <QFileInfo>
#include <QProcess>
#include <QStorageInfo>
#include <QThread>
#include <QTimer>
#include <functional>

namespace {

constexpr const char *kAppDeployPath = "/home/pi/ApplicationDeploy";
constexpr const char *kAppDeployNewPath = "/home/pi/ApplicationDeploy.new";
constexpr const char *kAppDeployBackupPath = "/home/pi/ApplicationBackup";
constexpr const char *kUpdateStatePath = "/home/pi/.application_update_state";
constexpr const char *kUpdaterPath = "/home/pi/ApplicationUpdater.sh";

static bool isLikelyUsbMount(const QString &rootPath)
{
    const QString normalized = rootPath.trimmed();
    if (normalized.isEmpty())
        return false;

    if (normalized.contains("/media/", Qt::CaseInsensitive)
        || normalized.contains("/run/media/", Qt::CaseInsensitive)
        || normalized.contains("/Volumes/", Qt::CaseInsensitive))
        return true;

    return false;
}

static QString cleanStateText(const QString &text)
{
    QString trimmed = text.trimmed();
    if (trimmed.isEmpty())
        return QStringLiteral("Updating application...");
    return trimmed;
}

static QString toUserFriendlyError(const QString &rawText)
{
    const QString text = rawText.trimmed();
    if (text.isEmpty())
        return QStringLiteral("Update failed: Unknown error.");

    if (text.contains("USB disconnected", Qt::CaseInsensitive)
        || text.contains("could not be read", Qt::CaseInsensitive)
        || text.contains("I/O error", Qt::CaseInsensitive)
        || text.contains("No such file", Qt::CaseInsensitive))
        return QStringLiteral("Update failed: USB disconnected or could not be read.");

    if (text.contains("No space", Qt::CaseInsensitive)
        || text.contains("not enough storage", Qt::CaseInsensitive)
        || text.contains("ENOSPC", Qt::CaseInsensitive))
        return QStringLiteral("Update failed: Not enough storage space.");

    if (text.contains("Permission denied", Qt::CaseInsensitive))
        return QStringLiteral("Update failed: Permission denied.");

    return QStringLiteral("Update failed: %1").arg(text);
}

static qint64 directorySize(const QString &path)
{
    qint64 total = 0;
    QDir dir(path);
    QDirIterator it(path,
                    QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot | QDir::Hidden,
                    QDirIterator::Subdirectories);

    while (it.hasNext()) {
        it.next();
        const QFileInfo fileInfo = it.fileInfo();
        if (fileInfo.isFile())
            total += fileInfo.size();
    }

    return total;
}

static bool directoryExistsAndReadable(const QString &path)
{
    const QFileInfo info(path);
    return info.exists() && info.isDir() && info.isReadable();
}

static bool isValidApplicationDirectory(const QString &path)
{
    const QFileInfo info(path);
    if (!info.exists() || !info.isDir() || !info.isReadable())
        return false;

    QDir dir(path);
    const QStringList entries = dir.entryList(QDir::Dirs | QDir::Files | QDir::NoDotAndDotDot | QDir::Hidden);
    if (entries.isEmpty())
        return false;

    const QStringList candidates = {
        QStringLiteral("appApplication"),
        QStringLiteral("Application"),
        QStringLiteral("run.sh"),
        QStringLiteral("ApplicationDeploy")
    };

    for (const QString &entry : entries) {
        if (candidates.contains(entry))
            return true;

        if (entry == QLatin1String("qml") || entry == QLatin1String("assets") || entry == QLatin1String("bin"))
            return true;
    }

    return false;
}

static bool removeDirectoryContents(const QString &path)
{
    QDir dir(path);
    if (!dir.exists())
        return true;

    const QFileInfoList entries = dir.entryInfoList(QDir::AllEntries | QDir::NoDotAndDotDot | QDir::Hidden, QDir::DirsFirst);
    for (const QFileInfo &entry : entries) {
        const QString filePath = entry.absoluteFilePath();
        if (entry.isDir()) {
            if (!removeDirectoryContents(filePath))
                return false;
            if (!QDir().rmdir(filePath))
                return false;
        } else if (!QFile::remove(filePath)) {
            return false;
        }
    }

    return true;
}

static bool removeDirectoryRecursively(const QString &path)
{
    if (!QDir(path).exists())
        return true;

    if (!removeDirectoryContents(path))
        return false;

    return QDir().rmdir(path);
}

static bool copyDirectoryRecursive(const QString &sourceDir,
                                  const QString &destinationDir,
                                  qint64 *copiedBytes,
                                  qint64 totalSize,
                                  std::function<void(qint64, qint64)> progressCallback,
                                  QString *errorText)
{
    if (!directoryExistsAndReadable(sourceDir)) {
        *errorText = QStringLiteral("USB disconnected or could not be read.");
        return false;
    }

    if (!QDir().mkpath(destinationDir)) {
        *errorText = QStringLiteral("Could not create update staging directory.");
        return false;
    }

    QDir source(sourceDir);
    const QStringList entries = source.entryList(QDir::Dirs | QDir::Files | QDir::Hidden | QDir::NoDotAndDotDot,
                                                QDir::DirsFirst);

    for (const QString &entry : entries) {
        const QString sourcePath = source.filePath(entry);
        const QString destinationPath = QDir(destinationDir).filePath(entry);
        const QFileInfo info(sourcePath);

        if (info.isDir()) {
            if (!copyDirectoryRecursive(sourcePath, destinationPath, copiedBytes, totalSize, progressCallback, errorText))
                return false;
            continue;
        }

        QFile sourceFile(sourcePath);
        if (!sourceFile.open(QIODevice::ReadOnly)) {
            *errorText = QStringLiteral("USB disconnected or could not be read.");
            return false;
        }

        QFileInfo destinationInfo(destinationPath);
        if (!destinationInfo.absoluteDir().exists()) {
            QDir().mkpath(destinationInfo.absolutePath());
        }

        QFile destinationFile(destinationPath);
        if (!destinationFile.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
            sourceFile.close();
            *errorText = QStringLiteral("Could not write update files.");
            return false;
        }

        QByteArray buffer(64 * 1024, '\0');
        qint64 bytesMoved = 0;
        while (true) {
            const qint64 readSize = sourceFile.read(buffer.data(), buffer.size());
            if (readSize < 0) {
                sourceFile.close();
                destinationFile.close();
                *errorText = QStringLiteral("USB disconnected or could not be read.");
                return false;
            }
            if (readSize == 0)
                break;

            const qint64 written = destinationFile.write(buffer.constData(), readSize);
            if (written != readSize) {
                sourceFile.close();
                destinationFile.close();
                *errorText = QStringLiteral("Update failed: Not enough storage space.");
                return false;
            }

            bytesMoved += readSize;
            if (copiedBytes != nullptr)
                *copiedBytes += readSize;

            if (progressCallback) {
                const qint64 currentTotal = *copiedBytes;
                const int percentage = totalSize > 0 ? qMin(95, static_cast<int>((currentTotal * 100) / totalSize)) : 0;
                progressCallback(currentTotal, percentage);
            }
        }

        sourceFile.close();
        destinationFile.close();
    }

    return true;
}

static bool copyUpdateArchive(const QString &sourcePath,
                              const QString &destinationPath,
                              qint64 *copiedBytes,
                              QString *errorText)
{
    QFile sourceFile(sourcePath);
    if (!sourceFile.open(QIODevice::ReadOnly)) {
        *errorText = QStringLiteral("USB disconnected or could not be read.");
        return false;
    }

    QFile destinationFile(destinationPath);
    if (!destinationFile.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        *errorText = QStringLiteral("Could not write update files.");
        return false;
    }

    QByteArray buffer(64 * 1024, '\0');
    while (true) {
        const qint64 readSize = sourceFile.read(buffer.data(), buffer.size());
        if (readSize < 0) {
            *errorText = QStringLiteral("USB disconnected or could not be read.");
            return false;
        }
        if (readSize == 0)
            break;

        if (destinationFile.write(buffer.constData(), readSize) != readSize) {
            *errorText = QStringLiteral("Update failed: Not enough storage space.");
            return false;
        }

        if (copiedBytes != nullptr)
            *copiedBytes += readSize;
    }

    return true;
}

static bool hasEnoughFreeSpace(const QString &sourcePath, const QString &targetPath, qint64 *requiredSize)
{
    const qint64 sourceSize = directorySize(sourcePath);
    if (sourceSize <= 0)
        return true;

    const qint64 reserveSpace = qMax<qint64>(256LL * 1024LL * 1024LL, sourceSize / 2LL);
    const qint64 totalRequired = sourceSize + reserveSpace;
    *requiredSize = totalRequired;

    const QStorageInfo storageInfo(targetPath);
    if (!storageInfo.isReady())
        return false;

    return storageInfo.bytesAvailable() >= totalRequired;
}

static void writeState(const QString &state)
{
    QFile stateFile(QString::fromUtf8(kUpdateStatePath));
    if (stateFile.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        stateFile.write(state.toUtf8());
        stateFile.close();
    }
}

} // namespace

class UsbSoftwareUpdateTaskWorker : public QObject
{
    Q_OBJECT
public:
    explicit UsbSoftwareUpdateTaskWorker(QObject *parent = nullptr)
        : QObject(parent)
    {
    }

    void setCancelRequested(bool cancelRequested)
    {
        m_cancelRequested = cancelRequested;
    }

signals:
    void statusChanged(const QString &status);
    void progressChanged(int progress);
    void errorOccurred(const QString &errorMessage);
    void updateCompleted();
    void updateConfirmationRequired();
    void finished();

public slots:
    void startUpdate()
    {
        QString errorMessage;
        qint64 requiredSize = 0;
        qint64 copiedBytes = 0;
        qint64 sourceSize = 0;

        m_cancelRequested = false;

        emit statusChanged(QStringLiteral("Checking for USB..."));
        emit progressChanged(10);
        writeState(QStringLiteral("COPYING"));

        const QList<QStorageInfo> mounts = QStorageInfo::mountedVolumes();
        QStorageInfo selectedUsb;
        for (const QStorageInfo &volume : mounts) {
            if (!volume.isValid() || !volume.isReady())
                continue;

            const QString rootPath = volume.rootPath();
            if (isLikelyUsbMount(rootPath)) {
                selectedUsb = volume;
                break;
            }
        }

        if (!selectedUsb.isValid() || !selectedUsb.isReady()) {
            errorMessage = QStringLiteral("USB Not Connected");
            emit errorOccurred(errorMessage);
            writeState(QStringLiteral("NONE"));
            emit finished();
            return;
        }

        emit statusChanged(QStringLiteral("Checking ApplicationNew.tar.gz..."));
        emit progressChanged(25);

        const QString usbRoot = selectedUsb.rootPath();
        const QString updateArchivePath = QDir(usbRoot).filePath(QStringLiteral("ApplicationNew.tar.gz"));
        const QFileInfo updateArchiveInfo(updateArchivePath);
        if (!updateArchiveInfo.exists() || !updateArchiveInfo.isFile() || !updateArchiveInfo.isReadable()) {
            errorMessage = QStringLiteral("ApplicationNew.tar.gz not found on USB.");
            emit errorOccurred(errorMessage);
            writeState(QStringLiteral("NONE"));
            emit finished();
            return;
        }

        sourceSize = updateArchiveInfo.size();
        const qint64 reserveSpace = qMax<qint64>(256LL * 1024LL * 1024LL, sourceSize / 2LL);
        requiredSize = sourceSize + reserveSpace;
        const QStorageInfo targetStorage(QString::fromUtf8(kAppDeployPath));
        if (!targetStorage.isReady() || targetStorage.bytesAvailable() < requiredSize) {
            errorMessage = QStringLiteral("Not enough storage space to update the application.");
            emit errorOccurred(errorMessage);
            writeState(QStringLiteral("NONE"));
            emit finished();
            return;
        }

        emit statusChanged(QStringLiteral("Preparing update..."));
        emit progressChanged(35);

        const QString stagingPath = QString::fromUtf8(kAppDeployNewPath);
        if (QDir(stagingPath).exists()) {
            if (!removeDirectoryRecursively(stagingPath)) {
                errorMessage = QStringLiteral("Update failed: Unable to reset the staging area.");
                emit errorOccurred(errorMessage);
                writeState(QStringLiteral("NONE"));
                emit finished();
                return;
            }
        }

        emit statusChanged(QStringLiteral("Updating application..."));
        emit progressChanged(40);

        const QString stagedArchivePath = QDir(stagingPath).filePath(QStringLiteral("ApplicationNew.tar.gz"));
        bool success = copyUpdateArchive(updateArchivePath,
                                          stagedArchivePath,
                                          &copiedBytes,
                                          &errorMessage);

        if (success) {
            emit progressChanged(70);
            QProcess tarProcess;
            tarProcess.start(QStringLiteral("tar"), {
                QStringLiteral("-xzf"),
                stagedArchivePath,
                QStringLiteral("-C"),
                stagingPath
            });

            if (!tarProcess.waitForStarted() || !tarProcess.waitForFinished()) {
                errorMessage = QStringLiteral("Could not extract the update archive.");
                success = false;
            } else if (tarProcess.exitStatus() != QProcess::NormalExit || tarProcess.exitCode() != 0) {
                errorMessage = QStringLiteral("Could not extract the update archive: %1")
                                   .arg(QString::fromLocal8Bit(tarProcess.readAllStandardError()).trimmed());
                success = false;
            }
        }

        if (success && !QFile::remove(stagedArchivePath)) {
            errorMessage = QStringLiteral("Could not remove the update archive after extraction.");
            success = false;
        }

        if (!success) {
            if (QDir(stagingPath).exists())
                removeDirectoryRecursively(stagingPath);

            const QString userFacing = toUserFriendlyError(errorMessage);
            emit errorOccurred(userFacing);
            writeState(QStringLiteral("NONE"));
            emit finished();
            return;
        }

        if (!isValidApplicationDirectory(stagingPath)) {
            removeDirectoryRecursively(stagingPath);
            errorMessage = QStringLiteral("Invalid extracted application archive.");
            emit errorOccurred(errorMessage);
            writeState(QStringLiteral("NONE"));
            emit finished();
            return;
        }

        emit statusChanged(QStringLiteral("Validating new application..."));
        emit progressChanged(90);
        writeState(QStringLiteral("READY_TO_SWITCH"));

        emit statusChanged(QStringLiteral("Application update completed successfully."));
        emit progressChanged(100);
        emit updateConfirmationRequired();

        writeState(QStringLiteral("READY_TO_SWITCH"));
        emit finished();
    }

private:
    bool m_cancelRequested = false;
};

UsbSoftwareUpdateManager::UsbSoftwareUpdateManager(QObject *parent)
    : QObject(parent)
{
    m_updateStatus = QStringLiteral("Checking for USB...");
    m_updateProgress = 0;
    m_worker = new UsbSoftwareUpdateTaskWorker();
    m_worker->moveToThread(&m_updateThread);

    connect(&m_updateThread, &QThread::started, m_worker, &UsbSoftwareUpdateTaskWorker::startUpdate);
    connect(m_worker, &UsbSoftwareUpdateTaskWorker::statusChanged, this, &UsbSoftwareUpdateManager::handleStatusChanged);
    connect(m_worker, &UsbSoftwareUpdateTaskWorker::progressChanged, this, &UsbSoftwareUpdateManager::handleProgressChanged);
    connect(m_worker, &UsbSoftwareUpdateTaskWorker::errorOccurred, this, &UsbSoftwareUpdateManager::handleErrorOccurred);
    connect(m_worker, &UsbSoftwareUpdateTaskWorker::updateConfirmationRequired, this, &UsbSoftwareUpdateManager::handleConfirmationRequired);
    connect(m_worker, &UsbSoftwareUpdateTaskWorker::finished, this, &UsbSoftwareUpdateManager::handleWorkerFinished);
}

UsbSoftwareUpdateManager::~UsbSoftwareUpdateManager()
{
    if (m_updateThread.isRunning()) {
        m_updateThread.quit();
        m_updateThread.wait(1000);
    }
    if (m_worker) {
        m_worker->deleteLater();
        m_worker = nullptr;
    }
}

QString UsbSoftwareUpdateManager::updateStatus() const
{
    return m_updateStatus;
}

int UsbSoftwareUpdateManager::updateProgress() const
{
    return m_updateProgress;
}

bool UsbSoftwareUpdateManager::updateRunning() const
{
    return m_updateRunning;
}

bool UsbSoftwareUpdateManager::updateFinished() const
{
    return m_updateFinished;
}

bool UsbSoftwareUpdateManager::confirmationRequired() const
{
    return m_confirmationRequired;
}

QString UsbSoftwareUpdateManager::updateError() const
{
    return m_updateError;
}

void UsbSoftwareUpdateManager::startUsbUpdate()
{
    if (m_updateRunning)
        return;

    if (!m_worker) {
        m_worker = new UsbSoftwareUpdateTaskWorker();
        m_worker->moveToThread(&m_updateThread);

        connect(&m_updateThread, &QThread::started, m_worker, &UsbSoftwareUpdateTaskWorker::startUpdate);
        connect(m_worker, &UsbSoftwareUpdateTaskWorker::statusChanged, this, &UsbSoftwareUpdateManager::handleStatusChanged);
        connect(m_worker, &UsbSoftwareUpdateTaskWorker::progressChanged, this, &UsbSoftwareUpdateManager::handleProgressChanged);
        connect(m_worker, &UsbSoftwareUpdateTaskWorker::errorOccurred, this, &UsbSoftwareUpdateManager::handleErrorOccurred);
        connect(m_worker, &UsbSoftwareUpdateTaskWorker::updateConfirmationRequired, this, &UsbSoftwareUpdateManager::handleConfirmationRequired);
        connect(m_worker, &UsbSoftwareUpdateTaskWorker::finished, this, &UsbSoftwareUpdateManager::handleWorkerFinished);
    }

    setUpdateProgress(0);
    setUpdateError(QString());
    setUpdateFinished(false);
    setConfirmationRequired(false);
    setUpdateRunning(true);
    setUpdateStatus(QStringLiteral("Checking for USB..."));

    if (m_updateThread.isRunning())
        m_updateThread.quit();

    m_updateThread.start();
}

void UsbSoftwareUpdateManager::cancelUpdate()
{
    setUpdateRunning(false);
    setUpdateFinished(true);
    setUpdateStatus(QStringLiteral("Update cancelled."));
    writeState(QStringLiteral("NONE"));
}

void UsbSoftwareUpdateManager::confirmRestart()
{
    if (!QFileInfo::exists(QString::fromUtf8(kUpdaterPath))) {
        setUpdateError(QStringLiteral("Update failed: external updater not found."));
        return;
    }

    setUpdateRunning(false);
    setUpdateFinished(true);
    setUpdateStatus(QStringLiteral("Preparing system restart..."));
    writeState(QStringLiteral("SWITCHING"));

    QProcess::startDetached(QString::fromUtf8(kUpdaterPath), QStringList() << QStringLiteral("--finalize"));
    QTimer::singleShot(100, QCoreApplication::instance(), []() {
        QCoreApplication::instance()->quit();
    });
}

void UsbSoftwareUpdateManager::declineRestart()
{
    setUpdateRunning(false);
    setUpdateFinished(false);
    setConfirmationRequired(false);
    setUpdateStatus(QStringLiteral("Update ready. You can continue using the current application."));
    writeState(QStringLiteral("READY_TO_SWITCH"));
}

void UsbSoftwareUpdateManager::handleStatusChanged(const QString &status)
{
    setUpdateStatus(cleanStateText(status));
}

void UsbSoftwareUpdateManager::handleProgressChanged(int progress)
{
    setUpdateProgress(progress);
}

void UsbSoftwareUpdateManager::handleErrorOccurred(const QString &errorMessage)
{
    setUpdateRunning(false);
    setUpdateFinished(true);
    setUpdateError(toUserFriendlyError(errorMessage));
    setUpdateStatus(toUserFriendlyError(errorMessage));
    setConfirmationRequired(false);
}

void UsbSoftwareUpdateManager::handleUpdateCompleted()
{
    setUpdateRunning(false);
    setUpdateFinished(true);
    setConfirmationRequired(false);
    setUpdateStatus(QStringLiteral("Application update completed successfully."));
}

void UsbSoftwareUpdateManager::handleConfirmationRequired()
{
    setUpdateRunning(false);
    setUpdateFinished(true);
    setConfirmationRequired(true);
    setUpdateStatus(QStringLiteral("Application update completed successfully."));
}

void UsbSoftwareUpdateManager::handleWorkerFinished()
{
    setUpdateRunning(false);
    if (m_updateThread.isRunning())
        m_updateThread.quit();
    m_updateThread.wait(1000);
}

void UsbSoftwareUpdateManager::setUpdateStatus(const QString &status)
{
    if (m_updateStatus == status)
        return;
    m_updateStatus = status;
    emit updateStatusChanged();
}

void UsbSoftwareUpdateManager::setUpdateProgress(int progress)
{
    if (m_updateProgress == progress)
        return;
    m_updateProgress = progress;
    emit updateProgressChanged();
}

void UsbSoftwareUpdateManager::setUpdateRunning(bool running)
{
    if (m_updateRunning == running)
        return;
    m_updateRunning = running;
    emit updateRunningChanged();
}

void UsbSoftwareUpdateManager::setUpdateFinished(bool finished)
{
    if (m_updateFinished == finished)
        return;
    m_updateFinished = finished;
    emit updateFinishedChanged();
}

void UsbSoftwareUpdateManager::setConfirmationRequired(bool required)
{
    if (m_confirmationRequired == required)
        return;
    m_confirmationRequired = required;
    emit confirmationRequiredChanged();
}

void UsbSoftwareUpdateManager::setUpdateError(const QString &errorMessage)
{
    if (m_updateError == errorMessage)
        return;
    m_updateError = errorMessage;
    emit updateErrorChanged();
}

void UsbSoftwareUpdateManager::writeStateFile(const QString &state)
{
    writeState(state.toUtf8().constData());
}

void UsbSoftwareUpdateManager::removeStagingDirectory()
{
    if (QDir(QString::fromUtf8(kAppDeployNewPath)).exists())
        removeDirectoryRecursively(QString::fromUtf8(kAppDeployNewPath));
}

#include "UsbSoftwareUpdateManager.moc"
