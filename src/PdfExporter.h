#ifndef PDFEXPORTER_H
#define PDFEXPORTER_H

#include "DatabaseManager.h"


#include <QObject>
#include <QVariantList>
#include <QVariantMap>
#include <QString>
#include <QStringList>



class PdfExporter : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool usbMounted READ usbMounted NOTIFY usbMountedChanged)
    Q_PROPERTY(QString usbPath READ usbPath NOTIFY usbPathChanged)

public:
    explicit PdfExporter(QObject *parent = nullptr);

    Q_INVOKABLE QString     getReportsFolderPath();
    Q_INVOKABLE QStringList getAllPdfFiles();
    Q_INVOKABLE bool        deletePdf(const QString &filePath);
    Q_INVOKABLE void        openPdf(const QString &filePath);

    Q_INVOKABLE bool isPrinterAvailable();

    QString getAvailablePrinter();

    Q_INVOKABLE bool printPdfFiles(const QStringList &filePaths);


    Q_INVOKABLE QString exportTableToPdf(const QVariantList &data,
                                         const QString &fromDate,
                                         const QString &toDate,
                                         const QString &filePath,
                                         const QVariantMap &sessionData = QVariantMap());


    Q_INVOKABLE QString exportBatchToPdf(
        const QVariantMap &batchData,
        const QVariantList &rejectionData,
        const QVariantMap &sessionData,
        const QString &filePath = "");


    Q_INVOKABLE bool isUsbMounted();
    Q_INVOKABLE QString getUsbPath();
    Q_INVOKABLE bool moveFilesToUsb(const QStringList &filePaths,
                                    const QString &serialNumber);

    bool usbMounted() const;
    QString usbPath() const;

    Q_INVOKABLE QString exportXYPlotToPdf(
        const QString &imagePath,
        const QString &productPhase,
        const QString &signal,
        const QString &amplitude,
        const QVariantMap &sessionData = QVariantMap());

    Q_INVOKABLE QString exportCoilOutputToPdf(
        const QString &imagePath,
        const QString &avg,
        const QString &min,
        const QString &max,
        const QVariantMap &sessionData
        );

signals:
    void usbMountedChanged();
    void usbPathChanged();


private:
    QVariantMap getMachineDetails();
    QString detectUsbPath() const;
    void refreshUsbState();

    bool m_usbMounted = false;
    QString m_usbPath;
};



#endif // PDFEXPORTER_H
