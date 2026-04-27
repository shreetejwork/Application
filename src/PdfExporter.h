#ifndef PDFEXPORTER_H
#define PDFEXPORTER_H

#include <QObject>
#include <QVariantList>

class PdfExporter : public QObject
{
    Q_OBJECT

public:
    explicit PdfExporter(QObject *parent = nullptr);

    // 🔴 YOUR EXISTING FINAL EXPORT (UNCHANGED)
    Q_INVOKABLE QString exportTableToPdf(const QVariantList &data,
                                         const QString &fromDate,
                                         const QString &toDate,
                                         const QString &filePath = QString());

    // 🟢 NEW: TEMP PREVIEW PDF
    Q_INVOKABLE QString exportTempPreviewPdf(const QVariantList &data,
                                             const QString &fromDate,
                                             const QString &toDate);

    // 🟢 NEW: CLEANUP TEMP FILE
    Q_INVOKABLE void deleteTempPdf(const QString &filePath);
};

#endif // PDFEXPORTER_H
