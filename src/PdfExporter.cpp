#include "PdfExporter.h"

#include <QPdfWriter>
#include <QPainter>
#include <QPageSize>
#include <QStandardPaths>
#include <QDir>
#include <QFileInfo>
#include <QDateTime>
#include <QDebug>

#include <QDesktopServices>
#include <QUrl>
#include <QFile>
#include <QPixmap>

PdfExporter::PdfExporter(QObject *parent)
    : QObject(parent)
{
}

// ================= GET / CREATE REPORTS FOLDER =================
QString PdfExporter::getReportsFolderPath()
{
    QString basePath =
        QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation);

    QString folderPath = basePath + "/Reports Folder";

    QDir dir(folderPath);
    if (!dir.exists()) {
        dir.mkpath(".");
        qDebug() << "Reports Folder created at:" << folderPath;
    }

    return folderPath;
}
// ================= GET ALL PDFs =================
QStringList PdfExporter::getAllPdfFiles()
{
    QString folder = getReportsFolderPath();

    QDir dir(folder);
    QStringList files = dir.entryList(QStringList() << "*.pdf",
                                      QDir::Files,
                                      QDir::Time); // latest first

    QStringList fullPaths;
    for (const QString &f : files)
        fullPaths << dir.absoluteFilePath(f);

    return fullPaths;
}

// ================= DELETE PDF =================
bool PdfExporter::deletePdf(const QString &filePath)
{
    QFile file(filePath);
    if (file.exists()) {
        return file.remove();
    }
    return false;
}

// ================= OPEN PDF =================
void PdfExporter::openPdf(const QString &filePath)
{
    QDesktopServices::openUrl(QUrl::fromLocalFile(filePath));
}

// ================= EXPORT PDF =================
QString PdfExporter::exportTableToPdf(const QVariantList &data,
                                      const QString &fromDate,
                                      const QString &toDate,
                                      const QString &filePath)
{
    QString path = filePath;

    //  FORCE SAVE INSIDE REPORTS FOLDER
    if (path.isEmpty()) {
        QString ts = QDateTime::currentDateTime().toString("dd-MM-yyyy_HH-mm-ss");

        QString folder = getReportsFolderPath();

        path = folder + "/Audit_Report_" + ts + ".pdf";
    }

    QDir().mkpath(QFileInfo(path).absolutePath());

    QPdfWriter writer(path);
    writer.setPageSize(QPageSize(QPageSize::A4));
    writer.setResolution(96);
    writer.setPageMargins(QMarginsF(15,15,15,15));

    QPainter painter(&writer);

    QString logoPath =
        QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation)
        + "/Logo.png";

    QPixmap logo(logoPath);

    const int pageWidth  = writer.width();

    const int rowHeight = 20;
    const int yStart    = 160;

    const int colWidths[] = {
        50, 90, 80, 90, 100, 100,
        pageWidth - 510
    };

    int totalRows = data.size();
    QString now = QDateTime::currentDateTime().toString("dd/MM/yyyy HH:mm:ss");

    // ================= HEADER =================
    auto drawHeader = [&](int page, int totalPages)

    {

        QRect logoRect(20, 10, 55, 55);

        painter.drawPixmap(
            logoRect,
            logo.scaled(
                logoRect.size(),
                Qt::KeepAspectRatio,
                Qt::SmoothTransformation));

        painter.setFont(QFont("Arial", 12, QFont::Bold));
        painter.drawText(QRect(0, 25, pageWidth, 25),
                         Qt::AlignCenter,
                         "A&D Instruments (India) Pvt Ltd.");

        if (page == 0)
        {
            painter.drawText(QRect(0, 50, pageWidth, 25),
                             Qt::AlignCenter,
                             "AUDIT TRAIL REPORT");

            painter.setFont(QFont("Arial", 9));

            painter.drawText(20, 90, "From: " + fromDate);
            painter.drawText(pageWidth/3, 90, "Customer: ---");
            painter.drawText(2*pageWidth/3, 90, "Machine ID: PHMX");

            painter.drawText(20, 110, "To: " + toDate);
            painter.drawText(pageWidth/3, 110, "Location: ---");
            painter.drawText(2*pageWidth/3, 110,
                             "Page: " + QString::number(page+1) + "/" + QString::number(totalPages));

            painter.drawText(20, 130, "File Created: " + now);
        }
        else
        {
            painter.setFont(QFont("Arial", 9));
            painter.drawText(20, 90, "Machine ID: PHMX");
            painter.drawText(pageWidth/3, 90, "Generated: " + now);
            painter.drawText(2*pageWidth/3, 90,
                             "Page: " + QString::number(page+1) + "/" + QString::number(totalPages));
        }
    };

    // ================= FOOTER =================
    auto drawFooter = [&]()
    {
        painter.setFont(QFont("Arial", 9, QFont::Bold));

        QRect pageRect = writer.pageLayout().paintRectPixels(writer.resolution());

        int left   = pageRect.left();
        int right  = pageRect.right();
        int bottom = pageRect.bottom();

        int y = bottom - 10;

        painter.drawText(left, y, "Generated By: ADMIN");
        painter.drawText(right - 200, y, "Approved By: ADMIN");
    };

    int dataIndex = 0;
    int page = 0;

    while (dataIndex < totalRows || page == 0)
    {
        if (page > 0)
            writer.newPage();

        int totalPagesEstimate =
            (totalRows == 0) ? 1 : (totalRows / 45) + 1;

        drawHeader(page, totalPagesEstimate);

        int y = yStart;

        QRect pageRect = writer.pageLayout().paintRectPixels(writer.resolution());
        int footerTopY = pageRect.bottom() - 40;

        // ===== TABLE HEADER =====
        QStringList headers = {"S/No","Date","Time","User","Old","New","Details"};

        painter.setFont(QFont("Arial", 9, QFont::Bold));

        int x = 0;
        for (int i = 0; i < headers.size(); ++i)
        {
            painter.drawRect(x, y, colWidths[i], rowHeight);
            painter.drawText(QRect(x, y, colWidths[i], rowHeight),
                             Qt::AlignCenter, headers[i]);
            x += colWidths[i];
        }

        y += rowHeight;

        painter.setFont(QFont("Arial", 9));

        // ===== DATA ROWS =====
        while (dataIndex < totalRows)
        {
            if (y + rowHeight > footerTopY)
                break;

            QVariantMap m = data[dataIndex].toMap();

            QStringList row = {
                m["sr"].toString(),
                m["date"].toString(),
                m["time"].toString(),
                m["user"].toString(),
                m["old"].toString(),
                m["newVal"].toString(),
                m["remark"].toString()
            };

            int x = 0;

            for (int c = 0; c < row.size(); ++c)
            {
                painter.drawRect(x, y, colWidths[c], rowHeight);

                painter.drawText(QRect(x+4, y, colWidths[c]-8, rowHeight),
                                 Qt::AlignVCenter | Qt::AlignLeft,
                                 row[c]);

                x += colWidths[c];
            }

            y += rowHeight;
            dataIndex++;
        }

        drawFooter();
        page++;
    }

    painter.end();

    qDebug() << "PDF saved at:" << path;
    return path;
}

// ================= EXPORT BATCH / PRODUCT PDF =================
QString PdfExporter::exportBatchToPdf(const QVariantMap &batchData,
                                      const QVariantList &rejectionData,
                                      const QString &filePath)
{
    QString path = filePath;

    if (path.isEmpty()) {
        QString ts     = QDateTime::currentDateTime().toString("dd-MM-yyyy_HH-mm-ss");
        QString folder = getReportsFolderPath();
        path = folder + "/Batch_Report" + ts + ".pdf";
    }

    QDir().mkpath(QFileInfo(path).absolutePath());

    QPdfWriter writer(path);
    writer.setPageSize(QPageSize(QPageSize::A4));
    writer.setResolution(96);
    writer.setPageMargins(QMarginsF(15, 15, 15, 15));

    QPainter painter(&writer);

    QString logoPath =
        QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation)
        + "/Logo.png";

    QPixmap logo(logoPath);

    const int pageWidth  = writer.width();
    const int pageHeight = writer.height();

    QString now = QDateTime::currentDateTime().toString("dd/MM/yyyy @ HH:mm:ss");

    // ===== Extract batch fields =====
    QString sno         = batchData["sno"].toString();
    QString batchName   = batchData["batch"].toString();
    QString productName = batchData["product"].toString();
    QString started     = batchData["started"].toString();
    QString ended       = batchData["ended"].toString();
    QString productCode = batchData.value("productCode", "default code").toString();
    QString productSno  = batchData.value("productSno",  "01-001").toString();

    int totalPages = (rejectionData.size() == 0)
                         ? 1
                         : 1 + (rejectionData.size() / 50) + (rejectionData.size() % 50 > 0 ? 1 : 0);

    // =====================================================
    // ===== HELPER: Draw page header (all pages)    =====
    // =====================================================
    auto drawPageHeader = [&](int page)
    {
        const int marginL = 24;

        // =====================================================
        // HEADER AREA
        // =====================================================

        const QRect logoRect(20, 10, 55, 55);

        if (!logo.isNull())
        {
            painter.drawPixmap(
                logoRect,
                logo.scaled(
                    logoRect.size(),
                    Qt::KeepAspectRatio,
                    Qt::SmoothTransformation));
        }

        // ---------------- Company Name ----------------

        painter.setFont(QFont("Arial", 11, QFont::Bold));

        painter.drawText(
            QRect(0, 15, pageWidth, 22),
            Qt::AlignCenter,
            "A&D Instruments (India) Pvt Ltd., Tablet Metal Detector (TMD)"
            );


        // ---------------- Report Title ----------------

        painter.setFont(QFont("Arial", 10, QFont::Bold));

        painter.drawText(
            QRect(0, 38, pageWidth, 20),
            Qt::AlignCenter,
            "PRODUCT / BATCH REPORT"
            );


        // Everything below starts after logo area
        int y = 78;


        // =====================================================
        // PAGE 1
        // =====================================================

        if (page == 0)
        {
            painter.setFont(QFont("Arial", 9));

            painter.drawText(
                marginL,
                y,
                "File created on " + now);

            y += 20;


            // ================= MACHINE SUMMARY =================

            painter.setFont(QFont("Arial", 10, QFont::Bold));

            painter.drawText(
                marginL,
                y,
                "Machine Summary");

            y += 6;


            QRect machineBox(
                marginL,
                y,
                pageWidth - 2 * marginL,
                60);

            painter.drawRect(machineBox);


            painter.setFont(QFont("Arial", 9));

            int boxY = y + 16;


            painter.drawText(
                marginL + 10,
                boxY,
                "User:");

            painter.drawText(
                marginL + 10,
                boxY + 16,
                "Location:");

            painter.drawText(
                marginL + 10,
                boxY + 32,
                "Machine ID: PHMX");


            y += machineBox.height() + 18;



            // ================= PRODUCT SUMMARY =================

            painter.setFont(QFont("Arial", 10, QFont::Bold));

            painter.drawText(
                marginL,
                y,
                "Product Summary / Batch Summary");

            y += 6;



            QRect productBox(
                marginL,
                y,
                pageWidth - 2 * marginL,
                130);

            painter.drawRect(productBox);



            painter.setFont(QFont("Arial", 9));


            int lineY  = y + 16;
            int labelX = marginL + 10;
            int valueX = marginL + 150;


            auto drawRow =
                [&](const QString &label,
                    const QString &value)
            {
                painter.drawText(labelX, lineY, label);
                painter.drawText(valueX, lineY, value);

                lineY += 16;
            };


            QString endText =
                (ended == "---" || ended.isEmpty())
                    ? "Batch is still running...."
                    : ended;


            drawRow("Product Loaded on:", started);
            drawRow("Product loaded by:", "Machine");
            drawRow("Product S/No:", productSno);
            drawRow("Product Name:", productName);
            drawRow("Product Code:", productCode);
            drawRow("Batch Number:", batchName);
            drawRow("Batch End Time:", endText);



            // Page number

            painter.drawText(
                pageWidth - 140,
                y + productBox.height() - 6,
                "Page: 1 / " + QString::number(totalPages));



            y += productBox.height() + 18;



            // ================= REJECTION SUMMARY =================

            painter.setFont(QFont("Arial", 10, QFont::Bold));

            painter.drawText(
                marginL,
                y,
                "Rejection Summary");

            y += 6;



            QRect rejBox(
                marginL,
                y,
                pageWidth - 2 * marginL,
                40);

            painter.drawRect(rejBox);



            int totalRej = 0;

            for (const QVariant &v : rejectionData)
                totalRej += v.toMap()["rejectCount"].toInt();



            painter.setFont(QFont("Arial", 9));

            painter.drawText(
                marginL + 10,
                y + 24,
                "Total Rejection Count: "
                    + QString::number(totalRej));
        }



        // =====================================================
        // DETAIL PAGES
        // =====================================================

        else
        {
            painter.setFont(QFont("Arial", 10, QFont::Bold));

            painter.drawText(
                QRect(0, 78, pageWidth, 18),
                Qt::AlignCenter,
                "Rejection Details");


            painter.setFont(QFont("Arial", 9));

            painter.drawText(
                marginL,
                100,
                "File created on " + now);


            painter.drawText(
                pageWidth - 150,
                100,
                "Page: "
                    + QString::number(page + 1)
                    + " / "
                    + QString::number(totalPages));
        }
    };

    // =====================================================
    // ===== HELPER: Draw footer                     =====
    // =====================================================
    auto drawFooter = [&]()
    {
        painter.setFont(QFont("Arial", 9, QFont::Bold));

        int y = pageHeight - 10;
        painter.drawText(20, y, "Batch REPORT");

        int midX = pageWidth / 2;
        painter.drawText(midX - 80, y, "Generated By: ADMIN");
        painter.drawText(pageWidth - 160, y, "Approved By: A_ADMIN");
    };

    // =====================================================
    // ===== PAGE 1 — Summary page                   =====
    // =====================================================
    drawPageHeader(0);
    drawFooter();

    // =====================================================
    // ===== PAGES 2+ — Rejection detail table       =====
    // =====================================================
    if (!rejectionData.isEmpty())
    {
        // Table column layout — matches your PDF exactly
        const int colWidths[] = { 60, 110, 100, pageWidth - 270 };  // S/No, Date, Time, Reject Count
        const QStringList headers = { "S/No.", "Date", "Time", "Reject Count" };
        const int rowHeight = 20;

        int dataIndex = 0;
        int page      = 1;  // page 0 is summary

        while (dataIndex < rejectionData.size())
        {
            writer.newPage();
            drawPageHeader(page);

            // Table starts lower on first detail page, same on subsequent
            int y = (page == 1) ? 72 : 72;

            QRect pageRect = writer.pageLayout().paintRectPixels(writer.resolution());
            int footerTopY = pageRect.bottom() - 30;

            // ===== TABLE HEADER =====
            painter.setFont(QFont("Arial", 9, QFont::Bold));

            int x = 20;
            for (int i = 0; i < headers.size(); ++i)
            {
                painter.drawRect(x, y, colWidths[i], rowHeight);
                painter.drawText(QRect(x + 4, y, colWidths[i] - 8, rowHeight),
                                 Qt::AlignVCenter | Qt::AlignLeft,
                                 headers[i]);
                x += colWidths[i];
            }
            y += rowHeight;

            // ===== DATA ROWS =====
            painter.setFont(QFont("Arial", 9));

            while (dataIndex < rejectionData.size())
            {
                if (y + rowHeight > footerTopY)
                    break;

                QVariantMap m = rejectionData[dataIndex].toMap();

                QStringList row = {
                    QString::number(dataIndex + 1),
                    m["date"].toString(),
                    m["time"].toString(),
                    m["rejectCount"].toString()
                };

                int x = 20;
                for (int c = 0; c < row.size(); ++c)
                {
                    painter.drawRect(x, y, colWidths[c], rowHeight);
                    painter.drawText(QRect(x + 4, y, colWidths[c] - 8, rowHeight),
                                     Qt::AlignVCenter | Qt::AlignLeft,
                                     row[c]);
                    x += colWidths[c];
                }

                // ===== LAST ROW — print total =====
                if (dataIndex == rejectionData.size() - 1)
                {
                    int totalRej = 0;
                    for (const QVariant &v : rejectionData)
                        totalRej += v.toMap()["rejectCount"].toInt();

                    y += rowHeight + 6;
                    painter.setFont(QFont("Arial", 9, QFont::Bold));
                    painter.drawText(20 + colWidths[0] + colWidths[1] + colWidths[2], y,
                                     "Total Rejection Count : " + QString::number(totalRej));
                    painter.setFont(QFont("Arial", 9));
                }

                y += rowHeight;
                dataIndex++;
            }

            drawFooter();
            page++;
        }
    }

    painter.end();

    qDebug() << "Batch PDF saved at:" << path;
    return path;
}

// =========== Check USB =========

bool PdfExporter::isUsbMounted()
{
    QDir mediaDir("/media");
    if (!mediaDir.exists())
        return false;

    QStringList users = mediaDir.entryList(QDir::Dirs | QDir::NoDotAndDotDot);

    for (const QString &user : users)
    {
        QDir userDir("/media/" + user);
        QStringList devices = userDir.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
        if (!devices.isEmpty())
            return true;
    }

    return false;
}

// ============= Get USB path ==========

QString PdfExporter::getUsbPath()
{
    QDir mediaDir("/media");

    QStringList users = mediaDir.entryList(QDir::Dirs | QDir::NoDotAndDotDot);

    for (const QString &user : users)
    {
        QDir userDir("/media/" + user);
        QStringList devices = userDir.entryList(QDir::Dirs | QDir::NoDotAndDotDot);

        if (!devices.isEmpty())
            return "/media/" + user + "/" + devices.first();
    }

    return "";
}

// ============ Move selected files to USB ===========

bool PdfExporter::moveFilesToUsb(const QStringList &filePaths)
{
    QString usbPath = getUsbPath();
    if (usbPath.isEmpty())
        return false;

    QDir().mkpath(usbPath + "/Reports");

    bool allOk = true;

    for (const QString &file : filePaths)
    {
        QFileInfo info(file);
        QString dest = usbPath + "/Reports/" + info.fileName();

        if (QFile::exists(dest))
            QFile::remove(dest);

        if (!QFile::copy(file, dest))
            allOk = false;
    }

    return allOk;
}
