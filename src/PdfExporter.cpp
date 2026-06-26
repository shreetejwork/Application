#include "PdfExporter.h"



#include <QDesktopServices>
#include <QUrl>
#include <QFile>

#include <QApplication>
#include <QPdfWriter>
#include <QPainter>
#include <QFont>
#include <QFontDatabase>
#include <QPixmap>
#include <QStandardPaths>
#include <QDateTime>
#include <QDir>
#include <QFileInfo>
#include <QVariantList>
#include <QVariantMap>
#include <QStringList>
#include <QRect>
#include <QPageSize>
#include <QMarginsF>
#include <QDebug>

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
    // ── PATH SETUP ──────────────────────────────────────────────────────────
    QString path = filePath;
    if (path.isEmpty()) {
        QString ts     = QDateTime::currentDateTime().toString("dd-MM-yyyy_HH-mm-ss");
        QString folder = getReportsFolderPath();
        path = folder + "/Audit_Report_" + ts + ".pdf";
    }
    QDir().mkpath(QFileInfo(path).absolutePath());

    // ── WRITER ──────────────────────────────────────────────────────────────
    QPdfWriter writer(path);
    writer.setPageSize(QPageSize(QPageSize::A4));
    writer.setResolution(96);
    // No margins on writer — we control all layout manually
    writer.setPageMargins(QMarginsF(0, 0, 0, 0));

    QPainter painter(&writer);

    // ── FONT (Roboto Condensed) ──────────────────────────────────────────────
    // Load from app resources or system; fall back to Arial gracefully
    int fontId = QFontDatabase::addApplicationFont(":/assets/images/RobotoCondensed-Regular.ttf");
    int fontBoldId = QFontDatabase::addApplicationFont(":/assets/images/RobotoCondensed-Bold.ttf");
    QString fontFamily = "Arial";
    if (fontId != -1) {
        QStringList families = QFontDatabase::applicationFontFamilies(fontId);
        if (!families.isEmpty()) fontFamily = families.first();
    }

    auto fontR  = [&](int pt) { return QFont(fontFamily, pt, QFont::Normal); };
    auto fontB  = [&](int pt) { return QFont(fontFamily, pt, QFont::Bold); };

    // ── LOGO ────────────────────────────────────────────────────────────────
    QString logoPath = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation)
                       + "/Logo.png";
    QPixmap logo(logoPath);

    // ── PAGE GEOMETRY ───────────────────────────────────────────────────────
    const int pageW  = writer.width();
    const int pageH  = writer.height();

    const int marginL = 40;   // left margin
    const int marginR = 40;   // right margin
    const int marginT = 20;   // top margin
    const int marginB = 30;   // bottom margin

    const int contentW = pageW - marginL - marginR;

    // ── COLUMN WIDTHS (sum must equal contentW) ──────────────────────────────
    // S/No | Date | Time | User | Old | New | Details
    const int nCols = 7;
    int colW[nCols];
    colW[0] = 45;    // S/No
    colW[1] = 80;    // Date
    colW[2] = 65;    // Time
    colW[3] = 80;    // User
    colW[4] = 90;    // Old Value
    colW[5] = 90;    // New Value
    colW[6] = contentW - (colW[0]+colW[1]+colW[2]+colW[3]+colW[4]+colW[5]); // Details

    const int rowH      = 22;   // data row height
    const int thH       = 24;   // table header row height

    // ── VERTICAL ZONES ──────────────────────────────────────────────────────
    // We'll calculate header/footer heights dynamically

    const int lineThick     = 2;   // bold divider lines (px at 96dpi)
    const int thinLine      = 1;   // table cell borders (still visible at 1px on 96dpi)

    // ── PEN HELPERS ─────────────────────────────────────────────────────────
    auto setPen = [&](int width, QColor color = Qt::black) {
        QPen p(color);
        p.setWidth(width);
        painter.setPen(p);
    };

    // ── LOGO DRAW HELPER ────────────────────────────────────────────────────
    auto drawLogo = [&]() {
        if (logo.isNull()) return;
        const int logoW = 130;
        const int logoH = 55;
        QRect logoRect(pageW - marginR - logoW, marginT, logoW, logoH);
        const int pad = 4;
        QSize scaled = logo.size().scaled(logoRect.size() - QSize(2*pad, 2*pad),
                                          Qt::KeepAspectRatio);
        QRect target(logoRect.center().x() - scaled.width()/2,
                     logoRect.center().y() - scaled.height()/2,
                     scaled.width(), scaled.height());
        painter.drawPixmap(target, logo);
    };

    const int headerFullH    = 148;
    const int headerCompactH = 65;
    const int footerH        = 38;

    auto rowsPerPage = [&](int pg) -> int {
        int hdrH = (pg == 0) ? headerFullH : headerCompactH;
        int available = pageH - marginT - hdrH - footerH - marginB - thH;
        return available / rowH;
    };

    int totalRows = data.size();
    int totalPages = 0;
    {
        int counted = 0;
        int pg = 0;
        if (totalRows == 0) {
            totalPages = 1;
        } else {
            while (counted < totalRows) {
                counted += rowsPerPage(pg);
                pg++;
            }
            totalPages = pg;
        }
    }

    // ── DRAW HEADER (full — page 0) ─────────────────────────────────────────
    auto drawHeaderFull = [&](int pageNum) {
        int y = marginT;

        // Company name — centered in content area (not counting logo space)
        painter.setFont(fontB(12));
        setPen(1);
        painter.drawText(QRect(marginL, y, contentW, 22),
                         Qt::AlignHCenter | Qt::AlignVCenter,
                         "A&D Instruments (India) Pvt. Ltd.");
        y += 22;

        painter.setFont(fontB(11));
        painter.drawText(QRect(marginL, y, contentW, 20),
                         Qt::AlignHCenter | Qt::AlignVCenter,
                         "AUDIT TRAIL REPORT");
        y += 20;

        painter.setFont(fontR(9));
        painter.drawText(QRect(marginL, y, contentW, 16),
                         Qt::AlignHCenter | Qt::AlignVCenter,
                         "(Metal Detector)");
        y += 16;

        drawLogo();

        // Thin divider under title block
        setPen(lineThick);
        painter.drawLine(marginL, y + 4, pageW - marginR, y + 4);
        y += 12;

        // Meta grid: 3 columns x 2 rows
        painter.setFont(fontR(9));
        setPen(1);

        int col1x = marginL;
        int col2x = marginL + contentW / 3;
        int col3x = marginL + 2 * contentW / 3;
        int metaLineH = 18;

        // Row 1
        auto drawMeta = [&](int x, int yy, const QString &label, const QString &val)
        {
            constexpr int colonOffset = 78;   // adjust once if needed

            painter.setFont(fontB(9));
            painter.drawText(x, yy, label);

            painter.setFont(fontR(9));
            painter.drawText(x + colonOffset, yy, ": " + val);
        };

        QString now = QDateTime::currentDateTime().toString("dd/MM/yyyy @ HH:mm:ss");

        // Row 1
        drawMeta(col1x, y + metaLineH,     "User",         "---");
        drawMeta(col2x, y + metaLineH,     "File Created", now);
        drawMeta(col3x, y + metaLineH,     "Machine ID",   "PHMX");

        // Row 2
        drawMeta(col1x, y + 2*metaLineH,   "Location",     "---");
        drawMeta(col2x, y + 2*metaLineH,   "From",         fromDate);
        drawMeta(col3x, y + 2*metaLineH,   "M/C Sr. No.",  "---");

        // Row 3
        drawMeta(col2x, y + 3*metaLineH,   "To",           toDate);

        y += 3*metaLineH + 6;

        setPen(lineThick);
        painter.drawLine(marginL, y + 4, pageW - marginR, y + 4);
        y += 20;

        return y; // returns Y where table should start

    };

    // ── DRAW HEADER (compact — subsequent pages) ──────────────────────────────
    auto drawHeaderCompact = [&](int pageNum) {
        int y = marginT;

        painter.setFont(fontB(11));
        setPen(1);
        painter.drawText(QRect(marginL, y, contentW, 22),
                         Qt::AlignHCenter | Qt::AlignVCenter,
                         "A&D Instruments (India) Pvt. Ltd.");
        y += 22;

        drawLogo();

        painter.setFont(fontR(9));
        QString now = QDateTime::currentDateTime().toString("dd/MM/yyyy HH:mm:ss");

        int col1x = marginL;
        int col2x = marginL + contentW / 3;
        int col3x = marginL + 2 * contentW / 3;


        y += 22;

        setPen(lineThick);
        painter.drawLine(marginL, y + 4, pageW - marginR, y + 4);
        y += 20;

        return y;
    };

    // ── DRAW TABLE HEADER ROW ─────────────────────────────────────────────────
    QStringList headers = {"S/No", "Date", "Time", "User", "Old Value", "New Value", "Details / Remarks"};

    auto drawTableHeader = [&](int y)
    {
        const int radius = 6;
        const QColor headerBg(52, 58, 64);      // dark grey
        const QColor headerText(Qt::white);

        painter.save();

        // Header background
        painter.setPen(Qt::NoPen);
        painter.setBrush(headerBg);
        painter.drawRoundedRect(marginL, y, contentW, thH, radius, radius);

        painter.setPen(headerText);
        painter.setFont(fontB(9));

        int x = marginL;

        for (int i = 0; i < nCols; ++i)
        {
            painter.drawText(
                QRect(x + 6, y, colW[i] - 12, thH),
                Qt::AlignCenter,
                headers[i]);

            x += colW[i];
        }

        painter.restore();

        return y + thH + 4;
    };

    // ── DRAW FOOTER ───────────────────────────────────────────────────────────
    auto drawFooter = [&](int pageNum) {

        int footerY     = pageH - marginB - 22;
        int footerDivY  = footerY - 8;   // same as old divider position
        int footerTextY = footerY + 12;  // same as old text baseline

        // Divider
        setPen(lineThick);
        painter.drawLine(marginL, footerDivY, pageW - marginR, footerDivY);

        painter.setFont(fontB(9));
        setPen(1);

        // Left : Generated By / Approved By
        painter.drawText(marginL, footerTextY,
                         "Generated By: A - Admin      Approved By: A - Admin");

        QString repLabel = "Audit Trail Report";
        QString pageStr  = QString("Page No: %1 / %2")
                              .arg(pageNum + 1)
                              .arg(totalPages);

        QFontMetrics fm = painter.fontMetrics();

        int repLabelW = fm.horizontalAdvance(repLabel);
        int pageStrW  = fm.horizontalAdvance(pageStr);

        int sepW      = 10;
        int sepLineW  = 2;

        int blockW = repLabelW + sepW + sepLineW + sepW + pageStrW;
        int blockX = pageW - marginR - blockW;

        painter.drawText(blockX, footerTextY, repLabel);

        int sepX = blockX + repLabelW + sepW;

        setPen(lineThick);
        painter.drawLine(sepX,
                         footerDivY + 8,
                         sepX,
                         footerTextY - 1);

        setPen(1);
        painter.drawText(sepX + sepW, footerTextY, pageStr);
    };

    // ── MAIN RENDER LOOP ──────────────────────────────────────────────────────
    int dataIndex = 0;
    int page      = 0;

    while (dataIndex < totalRows || page == 0) {
        if (page > 0)
            writer.newPage();

        // Draw header, get Y where table starts
        int tableTop;
        if (page == 0)
            tableTop = drawHeaderFull(page);
        else
            tableTop = drawHeaderCompact(page);

        // Draw table column header
        int y = drawTableHeader(tableTop);

        // Calculate footer top so rows don't overlap it
        int footerTopY = pageH - marginB - 22 - 12; // footer divider position

        // Draw data rows
        painter.setFont(fontR(9));

        while (dataIndex < totalRows) {
            if (y + rowH > footerTopY)
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

            // Alternate row background
            if (dataIndex % 2)
            {
                painter.fillRect(
                    marginL,
                    y,
                    contentW,
                    rowH,
                    QColor(230,230,230));
            }


            int x = marginL;

            for (int c = 0; c < nCols; ++c)
            {
                painter.setFont(fontR(9));
                painter.setPen(QColor(45,45,45));

                Qt::Alignment align;

                if (c == 0)
                {
                    align = Qt::AlignCenter;
                }
                else if (c == 6)
                {
                    align = Qt::AlignLeft | Qt::AlignVCenter;
                }
                else
                {
                    align = Qt::AlignCenter;
                }

                painter.drawText(
                    QRect(
                        x + 6,
                        y,
                        colW[c] - 12,
                        rowH),
                    align,
                    row[c]);

                x += colW[c];
            }


            // separator line
            setPen(1, QColor(230,230,230));

            painter.drawLine(
                marginL + 12,
                y + rowH + 2,
                marginL + contentW - 12,
                y + rowH + 2);

           y += rowH;
            dataIndex++;
        }

        drawFooter(page);
        page++;
    }

    painter.end();

    qDebug() << "PDF saved at:" << path;
    return path;
}

// ================= EXPORT BATCH / PRODUCT PDF =================
QString PdfExporter::exportBatchToPdf(const QVariantMap  &batchData,
                                      const QVariantList &rejectionData,
                                      const QString      &filePath)
{
    // ── PATH SETUP ───────────────────────────────────────────────────────────
    QString path = filePath;
    if (path.isEmpty()) {
        QString ts     = QDateTime::currentDateTime().toString("dd-MM-yyyy_HH-mm-ss");
        QString folder = getReportsFolderPath();
        path = folder + "/Batch_Report_" + ts + ".pdf";
    }
    QDir().mkpath(QFileInfo(path).absolutePath());

    // ── WRITER ───────────────────────────────────────────────────────────────
    QPdfWriter writer(path);
    writer.setPageSize(QPageSize(QPageSize::A4));
    writer.setResolution(96);
    writer.setPageMargins(QMarginsF(0, 0, 0, 0));

    QPainter painter(&writer);

    // ── FONT ─────────────────────────────────────────────────────────────────
    int fontId = QFontDatabase::addApplicationFont(":/fonts/RobotoCondensed-Regular.ttf");
    QFontDatabase::addApplicationFont(":/fonts/RobotoCondensed-Bold.ttf");
    QString fontFamily = "Arial";
    if (fontId != -1) {
        QStringList fams = QFontDatabase::applicationFontFamilies(fontId);
        if (!fams.isEmpty()) fontFamily = fams.first();
    }
    auto fontR = [&](int pt) { return QFont(fontFamily, pt, QFont::Normal); };
    auto fontB = [&](int pt) { return QFont(fontFamily, pt, QFont::Bold);   };

    // ── LOGO ─────────────────────────────────────────────────────────────────
    QString logoPath = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation)
                       + "/Logo.png";
    QPixmap logo(logoPath);

    // ── PAGE GEOMETRY ────────────────────────────────────────────────────────
    const int pageW    = writer.width();
    const int pageH    = writer.height();
    const int marginL  = 40;
    const int marginR  = 40;
    const int marginT  = 20;
    const int marginB  = 30;
    const int contentW = pageW - marginL - marginR;

    // ── TABLE GEOMETRY ───────────────────────────────────────────────────────
    const int rowH  = 22;
    const int thH   = 24;
    const int nCols = 4;
    int colW[nCols];
    colW[0] = 55;
    colW[1] = 110;
    colW[2] = 100;
    colW[3] = contentW - colW[0] - colW[1] - colW[2];

    const int lineThick = 2;

    // ── PEN HELPER ───────────────────────────────────────────────────────────
    auto setPen = [&](int w, QColor c = Qt::black) {
        QPen p(c); p.setWidth(w); painter.setPen(p);
    };

    // ── LOGO HELPER ──────────────────────────────────────────────────────────
    auto drawLogo = [&]() {
        if (logo.isNull()) return;
        const int lw = 130, lh = 52, pad = 4;
        QRect lr(pageW - marginR - lw, marginT, lw, lh);
        QSize sc = logo.size().scaled(lr.size() - QSize(2*pad, 2*pad), Qt::KeepAspectRatio);
        QRect tg(lr.center().x() - sc.width()/2,
                 lr.center().y() - sc.height()/2,
                 sc.width(), sc.height());
        painter.drawPixmap(tg, logo);
    };

    // ── BATCH DATA ───────────────────────────────────────────────────────────
    QString now         = QDateTime::currentDateTime().toString("dd/MM/yyyy @ HH:mm:ss");
    QString batchName   = batchData["batch"].toString();
    QString productName = batchData["product"].toString();
    QString started     = batchData["started"].toString();
    QString ended       = batchData["ended"].toString();
    QString productCode = batchData.value("productCode", "default code").toString();
    QString productSno  = batchData.value("productSno",  "01-001").toString();
    QString totalDur    = batchData.value("totalDuration",  "---").toString();
    QString runDur      = batchData.value("runDuration",    "---").toString();
    QString pauseDur    = batchData.value("pauseDuration",  "---").toString();
    QString serialNo = batchData.value("M/C Sr. No.", "---").toString();

    int totalRej = 0;
    for (const QVariant &v : rejectionData)
        totalRej += v.toMap()["rejectCount"].toInt();

    QString endText = (ended == "---" || ended.isEmpty())
                          ? "Batch is still running...."
                          : ended;

    // ── FOOTER ZONE ──────────────────────────────────────────────────────────
    const int footerDivY  = pageH - marginB - 28;
    const int footerTextY = pageH - marginB - 10;

    // ── DRAW FOOTER ──────────────────────────────────────────────────────────
    auto drawFooter = [&](int pageNum, int totalPages) {
        // divider
        setPen(lineThick);
        painter.drawLine(marginL, footerDivY, pageW - marginR, footerDivY);

        painter.setFont(fontB(9));
        setPen(1);

        // left: Generated By / Approved By
        painter.drawText(marginL, footerTextY,
                         "Generated By: A - Admin      Approved By: A - Admin");

        // right: "Batch Report  |  Page No: X / Y"
        // Build strings and measure them to avoid overlap
        QString repLabel = "Batch Report";
        QString pageStr  = QString("Page No: %1 / %2").arg(pageNum + 1).arg(totalPages);

        QFontMetrics fm = painter.fontMetrics();
        int repLabelW = fm.horizontalAdvance(repLabel);
        int pageStrW  = fm.horizontalAdvance(pageStr);
        int sepW      = 10;   // gap each side of separator
        int sepLineW  = 2;

        // total right block width = repLabelW + sepW + sepLineW + sepW + pageStrW
        int blockW   = repLabelW + sepW + sepLineW + sepW + pageStrW;
        int blockX   = pageW - marginR - blockW;

        painter.drawText(blockX, footerTextY, repLabel);

        int sepX = blockX + repLabelW + sepW;
        setPen(lineThick);
        painter.drawLine(sepX, footerDivY + 8, sepX, footerTextY -1);

        setPen(1);
        painter.setFont(fontB(9));
        painter.drawText(sepX + sepW, footerTextY, pageStr);
    };

    // ── DRAW FULL HEADER (page 0) ─────────────────────────────────────────
    auto drawHeaderFull = [&]() -> int {
        int y = marginT;
        drawLogo();

        setPen(1);
        painter.setFont(fontB(12));
        painter.drawText(QRect(marginL, y, contentW, 22),
                         Qt::AlignHCenter | Qt::AlignVCenter,
                         "A&D Instruments (India) Pvt. Ltd.");
        y += 22;

        painter.setFont(fontB(10));
        painter.drawText(QRect(marginL, y, contentW, 20),
                         Qt::AlignHCenter | Qt::AlignVCenter,
                         "PRODUCT / BATCH REPORT");
        y += 20;

        painter.setFont(fontR(9));
        painter.drawText(QRect(marginL, y, contentW, 16),
                         Qt::AlignHCenter | Qt::AlignVCenter,
                         "(Metal Detector)");
        y += 16;

        // ensure divider clears the logo (logo top = marginT, height = 52, + 6px gap)
        int logoBottom = marginT + 52 + 6;
        if (y + 3 < logoBottom)
            y = logoBottom;

        // bold divider under title block
        setPen(lineThick);
        painter.drawLine(marginL, y + 3, pageW - marginR, y + 3);
        y += 10;

        // file created
        setPen(1);
        painter.setFont(fontR(9));
        painter.drawText(marginL, y + 12, "File created on: " + now);
        y += 25;

        return y;
    };

    // ── DRAW COMPACT HEADER (page 1+) ────────────────────────────────────
    auto drawHeaderCompact = [&](int pageNum, int totalPages) -> int {
        Q_UNUSED(totalPages)
        int y = marginT;
        drawLogo();

        setPen(1);
        painter.setFont(fontB(11));
        painter.drawText(QRect(marginL, y, contentW, 22),
                         Qt::AlignHCenter | Qt::AlignVCenter,
                         "A&D Instruments (India) Pvt. Ltd.");
        y += 22;

        // ensure divider clears the logo
        int logoBottom = marginT + 52 + 6;
        if (y + 2 < logoBottom)
            y = logoBottom;

        setPen(lineThick);
        painter.drawLine(marginL, y + 2, pageW - marginR, y + 2);
        y += 12;

        int c1 = marginL;
        int c2 = marginL + contentW / 3;

        painter.setFont(fontB(9)); setPen(1);
        painter.drawText(c1, y + 12, "Machine ID:");
        painter.setFont(fontR(9));
        painter.drawText(c1 + 72, y + 12, "PHMX");

        painter.setFont(fontB(9));
        painter.drawText(c2, y + 12, "Generated:");
        painter.setFont(fontR(9));
        painter.drawText(c2 + 68, y + 12, now);

        y += 20;

        setPen(lineThick);
        painter.drawLine(marginL, y + 2, pageW - marginR, y + 2);
        y += 10;

        return y;
    };

    // ── DRAW TABLE HEADER ROW ────────────────────────────────────────────
    QStringList tHeaders = {"S/No.", "Date", "Time", "Reject Count"};
    auto drawTableHeader = [&](int y) -> int {
        painter.fillRect(marginL, y, contentW, thH, QColor(220, 220, 220));
        painter.setFont(fontB(9));
        int x = marginL;
        for (int i = 0; i < nCols; ++i) {
            setPen(lineThick);
            painter.drawRect(x, y, colW[i], thH);
            setPen(1);
            painter.drawText(QRect(x + 3, y, colW[i] - 6, thH),
                             Qt::AlignVCenter | Qt::AlignHCenter, tHeaders[i]);
            x += colW[i];
        }
        return y + thH;
    };

    // ── DRAW ONE DATA ROW ────────────────────────────────────────────────
    auto drawDataRow = [&](int y, int idx, const QVariantMap &m) {
        if (idx % 2 == 1)
            painter.fillRect(marginL, y, contentW, rowH, QColor(247, 247, 247));
        QStringList row = {
            QString::number(idx + 1),
            m["date"].toString(),
            m["time"].toString(),
            m["rejectCount"].toString()
        };
        int x = marginL;
        for (int c = 0; c < nCols; ++c) {
            setPen(lineThick);
            painter.drawRect(x, y, colW[c], rowH);
            setPen(1);
            painter.setFont(fontR(9));
            Qt::Alignment al = (c == 0)
                                   ? (Qt::AlignVCenter | Qt::AlignHCenter)
                                   : (Qt::AlignVCenter | Qt::AlignLeft);
            painter.drawText(QRect(x + 4, y, colW[c] - 8, rowH), al, row[c]);
            x += colW[c];
        }
    };

    // ── SECTION BOX HELPER ───────────────────────────────────────────────
    // Draws bold section title, returns Y after title
    auto drawSectionTitle = [&](int y, const QString &title) -> int {
        painter.setFont(fontB(10));
        setPen(1);
        painter.drawText(marginL, y + 12, title);
        return y + 16;
    };

    // Key-value pair inside a box: lbl in bold, val in regular
    // valueOffsetX = px from cell left to value text
    auto drawKVLine = [&](int x, int y, const QString &lbl, const QString &val,
                          int valueOffsetX = 145) {
        painter.setFont(fontB(9)); setPen(1);
        painter.drawText(x + 8, y, lbl);
        painter.setFont(fontR(9));
        painter.drawText(x + 8 + valueOffsetX, y, val);
    };

    // ── PRE-CALCULATE TOTAL PAGES ────────────────────────────────────────
    const int footerH     = pageH - footerDivY + 10;
    // Page 0 fixed content height estimate:
    //   header ~74, machine box ~52, product box ~172, rej summary box ~34
    //   section titles: 3 × 16 = 48, gaps ~30, table header 24
   const int summaryH    = 74 + 16 + 62 + 16 + 172 + 16 + 34 + 16 + 24;
    const int availPage0  = pageH - summaryH - footerH - 10;
    const int rowsPage0   = qMax(0, availPage0 / rowH);

    const int compactHdrH = 76;
    const int availPageN  = pageH - compactHdrH - thH - footerH - marginB;
    const int rowsPageN   = qMax(1, availPageN / rowH);

    int totalPages = 1;
    if (!rejectionData.isEmpty() && rejectionData.size() > rowsPage0) {
        int remaining = rejectionData.size() - rowsPage0;
        totalPages += (remaining + rowsPageN - 1) / rowsPageN;
    }

    // ════════════════════════════════════════════════════════════════════
    // PAGE 0
    // ════════════════════════════════════════════════════════════════════
    int y = drawHeaderFull();

    // ── Machine Summary ──────────────────────────────────────────────────
    y = drawSectionTitle(y, "Machine Summary :");
    y += 10;
    int boxTop = y;
    int lColX  = marginL;
    int rColX  = marginL + contentW / 2;
    // 2 rows: row1 = User + Machine ID, row2 = Location
    int r1y = boxTop + 26;
    int r2y = boxTop + 43;
    int r3y = boxTop + 50;
    y += 10;
    drawKVLine(lColX, r1y, "User",      ": ---");
    drawKVLine(rColX, r1y, "Machine ID", ": PHMX", 90);
    drawKVLine(rColX, r2y, "M/C Sr. No.", ": " + serialNo, 90);
    drawKVLine(lColX, r2y, "Location",  ": ---");
    int machineBoxH = 72;
    setPen(lineThick);
    painter.drawRect(marginL, boxTop, contentW, machineBoxH);
    y = boxTop + machineBoxH + 10;

    // ── Product / Batch Summary ──────────────────────────────────────────
    y = drawSectionTitle(y, "Product Summary / Batch Summary :");
    y += 10;
    boxTop = y;

    // Left column rows
    struct KVPair { QString lbl; QString val; };
    QList<KVPair> leftRows = {
        {"Product Loaded on", ": " + started},
        {"Product Loaded by", ": Machine"},
        {"Product Code",      ": " + productCode},
        {"Product S/No",         ": " + productSno},
        {"Product Name",         ": " + productName},
        {"", ""}
    };

    QList<KVPair> rightRows = {
        {"Batch Name",         ": " + batchName},
        {"Batch Start Time",  ": " + started},
        {"Batch End Time",    ": " + endText},
        {"Batch Run Duration",": " + runDur},
        {"Batch Pause Duration", ": " + pauseDur},
        {"Total Batch Duration", ": " + totalDur},

    };

    int nRows     = leftRows.size();
    int lineH     = 17;
    int boxPadTop = 24;

    for (int i = 0; i < nRows; ++i) {
        int rowY = boxTop + boxPadTop + i * lineH;
        drawKVLine(lColX, rowY, leftRows[i].lbl,  leftRows[i].val);
        if (!rightRows[i].lbl.isEmpty())
            drawKVLine(rColX, rowY, rightRows[i].lbl, rightRows[i].val, 155);
    }

    int productBoxH = boxPadTop + nRows * lineH + 8;
    setPen(lineThick);
    painter.drawRect(marginL, boxTop, contentW, productBoxH);
    y = boxTop + productBoxH + 10;

    // ── Rejection Summary ────────────────────────────────────────────────
    y = drawSectionTitle(y, "Rejection Summary :");
    y += 10;
    boxTop = y;
    drawKVLine(lColX, boxTop + 16, "Total Rejection Count  :",QString::number(totalRej));
    int rejBoxH = 28;
    setPen(lineThick);
    painter.drawRect(marginL, boxTop, contentW, rejBoxH);
    y = boxTop + rejBoxH + 10;

    y += 10;

    // ── Rejection Details table (starts page 0 if space available) ───────
    int dataIndex = 0;
    if (!rejectionData.isEmpty()) {
        painter.setFont(fontB(10)); setPen(1);
        painter.drawText(marginL, y + 12, "Rejection Details");
        y += 16;
        y = drawTableHeader(y);

        while (dataIndex < rejectionData.size()) {
            if (y + rowH > footerDivY - 6) break;
            drawDataRow(y, dataIndex, rejectionData[dataIndex].toMap());
            y += rowH;
            dataIndex++;
        }

        // total row if all fit on page 0
        if (dataIndex == rejectionData.size() && y + 16 <= footerDivY - 6) {
            painter.setFont(fontB(9)); setPen(1);
            painter.drawText(marginL + colW[0] + colW[1] + colW[2] + 6,
                             y + 14,
                             "Total Rejection Count : " + QString::number(totalRej));
        }
    }

    drawFooter(0, totalPages);

    // ════════════════════════════════════════════════════════════════════
    // PAGES 1+ — rejection table continuation
    // ════════════════════════════════════════════════════════════════════
    int page = 1;
    while (dataIndex < rejectionData.size()) {
        writer.newPage();
        y = drawHeaderCompact(page, totalPages);
        y = drawTableHeader(y);

        while (dataIndex < rejectionData.size()) {
            if (y + rowH > footerDivY - 6) break;
            drawDataRow(y, dataIndex, rejectionData[dataIndex].toMap());
            y += rowH;
            dataIndex++;
        }

        if (dataIndex == rejectionData.size() && y + 16 <= footerDivY - 6) {
            painter.setFont(fontB(9)); setPen(1);
            painter.drawText(marginL + colW[0] + colW[1] + colW[2] + 6,
                             y + 14,
                             "Total Rejection Count: " + QString::number(totalRej));
        }

        drawFooter(page, totalPages);
        page++;
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
