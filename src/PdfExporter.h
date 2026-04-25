#ifndef PDFEXPORTER_H
#define PDFEXPORTER_H

#include <QObject>
#include <QVariantList>

class PdfExporter : public QObject
{
    Q_OBJECT

public:
    explicit PdfExporter(QObject *parent = nullptr);

    Q_INVOKABLE QString exportTableToPdf(const QVariantList &data,
                                         const QString &fromDate,
                                         const QString &toDate,
                                         const QString &filePath = QString());
};

#endif
