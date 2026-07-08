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

public:
    explicit PdfExporter(QObject *parent = nullptr);

    Q_INVOKABLE QString     getReportsFolderPath();
    Q_INVOKABLE QStringList getAllPdfFiles();
    Q_INVOKABLE bool        deletePdf(const QString &filePath);
    Q_INVOKABLE void        openPdf(const QString &filePath);


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

    Q_INVOKABLE QString exportXYPlotToPdf(const QString &imagePath);

private:
    QVariantMap getMachineDetails();
};



#endif // PDFEXPORTER_H
