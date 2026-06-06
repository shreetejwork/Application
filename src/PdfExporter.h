#ifndef PDFEXPORTER_H
#define PDFEXPORTER_H

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
                                         const QString &filePath = QString());

    Q_INVOKABLE QString exportBatchToPdf(const QVariantMap  &batchData,
                                         const QVariantList &rejectionData,
                                         const QString      &filePath = QString());

    Q_INVOKABLE bool isUsbMounted();
    Q_INVOKABLE QString getUsbPath();
    Q_INVOKABLE bool moveFilesToUsb(const QStringList &filePaths);
};

#endif // PDFEXPORTER_H
