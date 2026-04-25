#include "PdfExporter.h"

#include <QTextDocument>
#include <QPrinter>
#include <QPageSize>
#include <QStandardPaths>
#include <QDir>
#include <QFileInfo>
#include <QDebug>
#include <QDesktopServices>
#include <QUrl>

PdfExporter::PdfExporter(QObject *parent)
    : QObject(parent)
{
}

QString PdfExporter::exportTableToPdf(const QVariantList &data,
                                      const QString &fromDate,
                                      const QString &toDate,
                                      const QString &filePath)
{
    QString path = filePath;

    if (path.isEmpty()) {
        QString timeStamp = QDateTime::currentDateTime()
        .toString("dd-MM-yyyy_HH-mm-ss");

        path = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation)
               + "/Audit_Report_" + timeStamp + ".pdf";
    }

    QDir().mkpath(QFileInfo(path).absolutePath());

    QString html;

    html += "<h2 style='color:#1A4DB5;'>Audit Trail Report</h2>";
    html += "<p><b>From:</b> " + fromDate + " | <b>To:</b> " + toDate + "</p>";

    html += R"(
    <style>
        table { width:100%; border-collapse:collapse; font-size:12px; }
        th { background:#1A4DB5; color:white; padding:8px; text-align:left; }
        td { border:1px solid #D0D8EC; padding:6px; }
        tr:nth-child(even) { background:#F4F7FF; }
    </style>
    )";

    html += "<table>";
    html += "<tr><th>Sr</th><th>Date</th><th>Time</th><th>User</th><th>Old</th><th>New</th><th>Remark</th></tr>";

    for (const QVariant &v : data)
    {
        QVariantMap m = v.toMap();

        html += "<tr>";
        html += "<td>" + m.value("sr").toString() + "</td>";
        html += "<td>" + m.value("date").toString() + "</td>";
        html += "<td>" + m.value("time").toString() + "</td>";
        html += "<td>" + m.value("user").toString() + "</td>";
        html += "<td>" + m.value("old").toString() + "</td>";
        html += "<td>" + m.value("newVal").toString() + "</td>";
        html += "<td>" + m.value("remark").toString() + "</td>";
        html += "</tr>";
    }

    html += "</table>";

    QTextDocument doc;
    doc.setHtml(html);

    QPrinter printer(QPrinter::HighResolution);
    printer.setOutputFormat(QPrinter::PdfFormat);
    printer.setOutputFileName(path);
    printer.setPageSize(QPageSize(QPageSize::A4));

    doc.print(&printer);

    qDebug() << "PDF saved at:" << path;

    return path;
}
