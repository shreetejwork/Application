#include "PdfExporter.h"
#include "DatabaseManager.h"

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
#include <QImage>
#include <QFile>
#include <QPageLayout>
#include <QStorageInfo>
#include <QTimer>
#include <QProcess>


PdfExporter::PdfExporter(QObject *parent)
    : QObject(parent)
{
    refreshUsbState();

    auto *usbTimer = new QTimer(this);
    usbTimer->setInterval(2000);
    connect(usbTimer, &QTimer::timeout, this, &PdfExporter::refreshUsbState);
    usbTimer->start();
}

bool PdfExporter::usbMounted() const
{
    return m_usbMounted;
}

QString PdfExporter::usbPath() const
{
    return m_usbPath;
}

QString PdfExporter::detectUsbPath() const
{
#ifdef Q_OS_LINUX
    QStringList candidates;

    for (const QStorageInfo &storage : QStorageInfo::mountedVolumes()) {
        const QString rootPath = storage.rootPath();
        const QString devicePath = QString::fromLocal8Bit(storage.device());

        if (!storage.isValid()
            || !storage.isReady()
            || storage.isReadOnly()
            || rootPath.isEmpty()
            || rootPath == "/"
            || devicePath.isEmpty()
            || !devicePath.startsWith("/dev/")) {
            continue;
        }

        QFileInfo rootInfo(rootPath);
        if (!rootInfo.isDir() || !rootInfo.isReadable() || !rootInfo.isWritable())
            continue;

        const QString deviceName = QFileInfo(devicePath).fileName();
        const QString sysDevicePath = QFileInfo(
            QString("/sys/class/block/%1").arg(deviceName)).canonicalFilePath();
        const int blockIndex = sysDevicePath.indexOf("/block/");

        if (blockIndex < 0 || !sysDevicePath.contains("/usb", Qt::CaseInsensitive))
            continue;

        const QString blockPath = sysDevicePath.mid(blockIndex + 7);
        const QString diskName = blockPath.section('/', 0, 0);
        QFile removableFile(QString("/sys/class/block/%1/removable").arg(diskName));

        if (!removableFile.open(QIODevice::ReadOnly | QIODevice::Text)
            || removableFile.readAll().trimmed() != "1") {
            continue;
        }

        candidates.append(rootPath);
    }

    candidates.sort();
    return candidates.value(0);
#else
    return QString();
#endif
}

void PdfExporter::refreshUsbState()
{
    const QString detectedPath = detectUsbPath();
    const bool detectedMounted = !detectedPath.isEmpty();
    const bool stateChanged = detectedMounted != m_usbMounted;
    const bool pathChanged = detectedPath != m_usbPath;

    if (!stateChanged && !pathChanged)
        return;

    m_usbMounted = detectedMounted;
    m_usbPath = detectedPath;

    qDebug() << "USB state changed: connected=" << m_usbMounted
             << "path=" << m_usbPath;

    if (stateChanged)
        emit usbMountedChanged();
    if (pathChanged)
        emit usbPathChanged();
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
                                      QDir::Time);

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

QVariantMap PdfExporter::getMachineDetails()
{
    DatabaseManager db;

    QVariantMap machineInfo =
        db.getMachineInfo();

    return machineInfo;
}

QString roleInitial(const QString& role)
{
    if(role.compare("Admin",Qt::CaseInsensitive)==0)
        return "A";

    if(role.compare("Supervisor",Qt::CaseInsensitive)==0)
        return "S";

    if(role.compare("Operator",Qt::CaseInsensitive)==0)
        return "O";

    return role.left(1).toUpper();
}

// ================= EXPORT AUDIT TRAIL PDF =================
QString PdfExporter::exportTableToPdf(const QVariantList &data,
                                      const QString &fromDate,
                                      const QString &toDate,
                                      const QString &filePath,
                                      const QVariantMap &sessionData)
{
    // ── PATH SETUP ──────────────────────────────────────────────────────────
    QString path = filePath;
    if (path.isEmpty()) {
        QString ts     = QDateTime::currentDateTime().toString("dd-MM-yyyy_HH-mm-ss");
        QString folder = getReportsFolderPath();
        path = folder + "/Audit_Report_" + ts + ".pdf";
    }
    QDir().mkpath(QFileInfo(path).absolutePath());

    QVariantMap machineInfo = getMachineDetails();


    QString companyName =
        machineInfo.value("supplierName")
            .toString();

    QString machineId =
        machineInfo.value("machineId")
            .toString();

    QString machineSerial =
        machineInfo.value("serialNumber")
            .toString();

    QString machineType =
        machineInfo.value("machineType").toString();

    QString location =
        machineInfo.value("location")
            .toString();

    QString userName =
        machineInfo.value("userName")
            .toString();


    QString loggedUser =
        sessionData.value("loggedInUserName","---")
            .toString();

    QString loggedRole =
        sessionData.value("loggedInUserRole","---")
            .toString();

    QString initial =
        roleInitial(loggedRole);

    // Footer left string built once, reused on every page
    QString footerLeftStr =
        QString("Generated By: %1 - %2      Approved By: %3 - %4")
            .arg(initial)
            .arg(loggedUser)
            .arg(initial)
            .arg(loggedUser);

    // ── WRITER ──────────────────────────────────────────────────────────────
    QPdfWriter writer(path);
    writer.setPageSize(QPageSize(QPageSize::A4));
    writer.setResolution(96);
    writer.setPageMargins(QMarginsF(0, 0, 0, 0));

    QPainter painter(&writer);

    // ── FONT ────────────────────────────────────────────────────────────────
    int fontId     = QFontDatabase::addApplicationFont(":/assets/images/RobotoCondensed-Regular.ttf");
    int fontBoldId = QFontDatabase::addApplicationFont(":/assets/images/RobotoCondensed-Bold.ttf");
    QString fontFamily = "Arial";
    if (fontId != -1) {
        QStringList families = QFontDatabase::applicationFontFamilies(fontId);
        if (!families.isEmpty()) fontFamily = families.first();
    }

    auto fontR = [&](int pt) { return QFont(fontFamily, pt, QFont::Normal); };
    auto fontB = [&](int pt) { return QFont(fontFamily, pt, QFont::Bold);   };

    // ── LOGO ────────────────────────────────────────────────────────────────
    QString logoPath = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation)
                       + "/Logo.png";
    QPixmap logo(logoPath);

    // ── PAGE GEOMETRY ───────────────────────────────────────────────────────
    const int pageW    = writer.width();
    const int pageH    = writer.height();
    const int marginL  = 40;
    const int marginR  = 40;
    const int marginT  = 20;
    const int marginB  = 30;
    const int contentW = pageW - marginL - marginR;

    // ── COLUMN WIDTHS ────────────────────────────────────────────────────────
    const int nCols = 7;
    int colW[nCols];

    colW[0] = 40;     // S/No
    colW[1] = 95;     // Date
    colW[2] = 70;     // Time
    colW[3] = 115;    // User
    colW[4] = 100;    // Old Value
    colW[5] = 140;    // New Value

    // Remaining width for remarks
    colW[6] = contentW
              - (colW[0]
                 + colW[1]
                 + colW[2]
                 + colW[3]
                 + colW[4]
                 + colW[5]);

    const int rowH      = 26;
    const int thH       = 24;
    const int lineThick = 2;
    const int thinLine  = 1;

    // ── PEN HELPER ───────────────────────────────────────────────────────────
    auto setPen = [&](int width, QColor color = Qt::black) {
        QPen p(color);
        p.setWidth(width);
        painter.setPen(p);
    };

    // ── LOGO HELPER ──────────────────────────────────────────────────────────
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
    const int headerCompactH = 88;
    const int footerH        = 38;

    auto rowsPerPage = [&](int pg) -> int {
        int hdrH      = (pg == 0) ? headerFullH : headerCompactH;
        int available = pageH - marginT - hdrH - footerH - marginB - thH;
        return available / rowH;
    };

    int totalRows  = data.size();
    int totalPages = 0;
    {
        int counted = 0;
        int pg      = 0;
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

    // ── DRAW HEADER FULL (page 0) ────────────────────────────────────────────
    auto drawHeaderFull = [&](int pageNum) {
        int y = marginT;

        painter.setFont(fontB(12));
        setPen(1);
        painter.drawText(QRect(marginL, y, contentW, 22),
                         Qt::AlignHCenter | Qt::AlignVCenter,
                         companyName);                          // ← was hardcoded
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

        setPen(lineThick);
        painter.drawLine(marginL, y + 4, pageW - marginR, y + 4);
        y += 12;

        painter.setFont(fontR(9));
        setPen(1);

        int col1x     = marginL;
        int col2x     = marginL + contentW / 3;
        int col3x     = marginL + 2 * contentW / 3;
        int metaLineH = 18;

        auto drawMeta = [&](int x, int yy, const QString &label, const QString &val) {
            constexpr int colonOffset = 78;
            painter.setFont(fontB(9));
            painter.drawText(x, yy, label);
            painter.setFont(fontR(9));
            painter.drawText(x + colonOffset, yy, ": " + val);
        };

        QString now = QDateTime::currentDateTime().toString("dd/MM/yyyy @ HH:mm:ss");

        // Row 1
        drawMeta(col1x, y + metaLineH,   "User",         userName);      // ← was "---"
        drawMeta(col2x, y + metaLineH,   "File Created", now);
        drawMeta(col3x, y + metaLineH,   "Machine ID",   machineId);     // ← was "PHMX"

        // Row 2
        drawMeta(col1x, y + 2*metaLineH, "Location",     location);      // ← was "---"
        drawMeta(col2x, y + 2*metaLineH, "From",         fromDate);
        drawMeta(col3x, y + 2*metaLineH, "M/c Sr. No.",  machineSerial); // ← was "---"
        drawMeta(col3x, y + 3*metaLineH, "M/c Type",     machineType);

        // Row 3
        drawMeta(col2x, y + 3*metaLineH, "To",           toDate);

        y += 3*metaLineH + 6;

        setPen(lineThick);
        painter.drawLine(marginL, y + 4, pageW - marginR, y + 4);
        y += 20;

        return y;
    };

    // ── DRAW HEADER COMPACT (page 1+) ────────────────────────────────────────

    auto drawHeaderCompact = [&](int pageNum) -> int
    {
        Q_UNUSED(pageNum);

        // ============================================================
        // HEADER DIMENSIONS
        // ============================================================

        const int headerTop = marginT;

        // Company name
        const int companyY = headerTop;
        const int companyH = 22;

        // Logo
        const int logoW   = 100;
        const int logoH   = 42;
        const int logoTop = headerTop + 2;

        // Metadata
        const int metaY = headerTop + 52;
        const int metaH = 18;

        // Separator
        const int separatorGap = 8;
        const int separatorY   = metaY + metaH + separatorGap;


        // ============================================================
        // LOGO
        // ============================================================

        if (!logo.isNull())
        {
            const int logoBoxX = pageW - marginR - logoW;

            QRect logoBox(
                logoBoxX,
                logoTop,
                logoW,
                logoH
                );

            QPixmap scaledLogo =
                logo.scaled(
                    logoBox.size(),
                    Qt::KeepAspectRatio,
                    Qt::SmoothTransformation
                    );

            QRect logoTarget(
                logoBox.center().x() - scaledLogo.width() / 2,
                logoBox.center().y() - scaledLogo.height() / 2,
                scaledLogo.width(),
                scaledLogo.height()
                );

            painter.drawPixmap(
                logoTarget,
                scaledLogo
                );
        }


        // ============================================================
        // COMPANY NAME
        // ============================================================

        painter.setFont(fontB(11));
        setPen(1);

        QRect companyRect(
            marginL,
            companyY,
            contentW,
            companyH
            );

        painter.drawText(
            companyRect,
            Qt::AlignCenter | Qt::AlignVCenter,
            companyName
            );


        // ============================================================
        // META INFORMATION
        // ============================================================


        const QString fileCreated =
            QDateTime::currentDateTime()
                .toString("dd/MM/yyyy @ HH:mm:ss");


        // ------------------------------------------------------------
        // TOTAL METADATA GROUP WIDTH
        // ------------------------------------------------------------

        const int fileLabelW = 82;
        const int fileValueW = 190;

        const int machineLabelW = 78;
        const int machineValueW = 100;

        const int gapBetween = 35;

        const int fileBlockW =
            fileLabelW + fileValueW;

        const int machineBlockW =
            machineLabelW + machineValueW;

        const int totalMetaW =
            fileBlockW
            + gapBetween
            + machineBlockW;


        // ------------------------------------------------------------
        // CENTER THE COMPLETE GROUP
        // ------------------------------------------------------------

        const int metaStartX =
            marginL
            + (contentW - totalMetaW) / 2;


        // ============================================================
        // FILE CREATED
        // ============================================================

        const int fileX = metaStartX;

        painter.setFont(fontB(9));
        setPen(1);

        painter.drawText(
            QRect(
                fileX,
                metaY,
                fileLabelW,
                metaH
                ),
            Qt::AlignRight | Qt::AlignVCenter,
            "File Created"
            );


        painter.setFont(fontR(9));

        painter.drawText(
            QRect(
                fileX + fileLabelW + 6,
                metaY,
                fileValueW,
                metaH
                ),
            Qt::AlignLeft | Qt::AlignVCenter,
            ": " + fileCreated
            );


        // ============================================================
        // MACHINE ID
        // ============================================================

        const int machineX =
            fileX
            + fileBlockW
            + gapBetween;


        painter.setFont(fontB(9));

        painter.drawText(
            QRect(
                machineX,
                metaY,
                machineLabelW,
                metaH
                ),
            Qt::AlignRight | Qt::AlignVCenter,
            "Machine ID"
            );


        painter.setFont(fontR(9));

        painter.drawText(
            QRect(
                machineX + machineLabelW + 6,
                metaY,
                machineValueW,
                metaH
                ),
            Qt::AlignLeft | Qt::AlignVCenter,
            ": " + machineId
            );


        // ============================================================
        // SEPARATOR
        // ============================================================

        setPen(lineThick);

        painter.drawLine(
            marginL,
            separatorY,
            pageW - marginR,
            separatorY
            );


        // ============================================================
        // RETURN TABLE START POSITION
        // ============================================================

        return separatorY + 10;
    };

    // ── TABLE HEADER ROW ─────────────────────────────────────────────────────
    QStringList headers = {"S/No", "Date", "Time", "User", "Old Value", "New Value", "Details / Remarks"};

    auto drawTableHeader = [&](int y) {
        const int    radius    = 6;
        const QColor headerBg  (52, 58, 64);
        const QColor headerText(Qt::white);

        painter.save();
        painter.setPen(Qt::NoPen);
        painter.setBrush(headerBg);
        painter.drawRoundedRect(marginL, y, contentW, thH, radius, radius);
        painter.setPen(headerText);
        painter.setFont(fontB(9));

        int x = marginL;
        for (int i = 0; i < nCols; ++i) {
            painter.drawText(QRect(x + 6, y, colW[i] - 12, thH),
                             Qt::AlignCenter, headers[i]);
            x += colW[i];
        }
        painter.restore();
        return y + thH + 4;
    };

    // ── FOOTER ───────────────────────────────────────────────────────────────
    auto drawFooter = [&](int pageNum) {
        int footerY     = pageH - marginB - 22;
        int footerDivY  = footerY - 8;
        int footerTextY = footerY + 12;

        setPen(lineThick);
        painter.drawLine(marginL, footerDivY, pageW - marginR, footerDivY);

        painter.setFont(fontB(9));
        setPen(1);

        painter.drawText(marginL, footerTextY, footerLeftStr); // ← was hardcoded

        QString repLabel = "Audit Trail Report";
        QString pageStr  = QString("Page No: %1 / %2")
                              .arg(pageNum + 1).arg(totalPages);

        QFontMetrics fm       = painter.fontMetrics();
        int repLabelW         = fm.horizontalAdvance(repLabel);
        int pageStrW          = fm.horizontalAdvance(pageStr);
        int sepW              = 10;
        int sepLineW          = 2;
        int blockW            = repLabelW + sepW + sepLineW + sepW + pageStrW;
        int blockX            = pageW - marginR - blockW;

        painter.drawText(blockX, footerTextY, repLabel);

        int sepX = blockX + repLabelW + sepW;
        setPen(lineThick);
        painter.drawLine(sepX, footerDivY + 8, sepX, footerTextY - 1);

        setPen(1);
        painter.drawText(sepX + sepW, footerTextY, pageStr);
    };

    // ── MAIN RENDER LOOP ─────────────────────────────────────────────────────
    int dataIndex = 0;
    int page      = 0;

    while (dataIndex < totalRows || page == 0) {
        if (page > 0)
            writer.newPage();

        int tableTop;
        if (page == 0)
            tableTop = drawHeaderFull(page);
        else
            tableTop = drawHeaderCompact(page);

        int y          = drawTableHeader(tableTop);
        int footerTopY = pageH - marginB - 22 - 12;

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

            if (dataIndex % 2)
                painter.fillRect(marginL, y, contentW, rowH, QColor(220, 235, 255));

            int x = marginL;
            for (int c = 0; c < nCols; ++c) {
                painter.setFont(fontR(9));
                painter.setPen(QColor(45, 45, 45));

                Qt::Alignment align;
                if      (c == 0) align = Qt::AlignCenter;
                else if (c == 6) align = Qt::AlignLeft | Qt::AlignVCenter;
                else             align = Qt::AlignCenter;

                painter.drawText(QRect(x + 6, y, colW[c] - 12, rowH), align, row[c]);
                x += colW[c];
            }

            setPen(1, QColor(230, 230, 230));
            painter.drawLine(marginL + 12, y + rowH + 2,
                             marginL + contentW - 12, y + rowH + 2);

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
QString PdfExporter::exportBatchToPdf(const QVariantMap &batchData,
                                      const QVariantList &rejectionData,
                                      const QVariantMap &sessionData,
                                      const QString &filePath)
{
    // ── PATH SETUP ───────────────────────────────────────────────────────────
    QString path = filePath;

    if (path.isEmpty()) {
        QString ts = QDateTime::currentDateTime().toString("dd-MM-yyyy_HH-mm-ss");
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
    int fontId =
        QFontDatabase::addApplicationFont(
            ":/fonts/RobotoCondensed-Regular.ttf"
            );

    QFontDatabase::addApplicationFont(
        ":/fonts/RobotoCondensed-Bold.ttf"
        );

    QString fontFamily = "Arial";

    if (fontId != -1) {
        QStringList fams =
            QFontDatabase::applicationFontFamilies(fontId);

        if (!fams.isEmpty())
            fontFamily = fams.first();
    }

    auto fontR = [&](int pt) {
        return QFont(fontFamily, pt, QFont::Normal);
    };

    auto fontB = [&](int pt) {
        return QFont(fontFamily, pt, QFont::Bold);
    };


    // ── LOGO ─────────────────────────────────────────────────────────────────
    QString logoPath =
        QStandardPaths::writableLocation(
            QStandardPaths::DocumentsLocation
            ) + "/Logo.png";

    QPixmap logo(logoPath);


    // ── PAGE GEOMETRY ────────────────────────────────────────────────────────
    const int pageW = writer.width();
    const int pageH = writer.height();

    const int marginL = 40;
    const int marginR = 40;
    const int marginT = 20;
    const int marginB = 30;

    const int contentW =
        pageW - marginL - marginR;


    // ── DUAL TABLE GEOMETRY ──────────────────────────────────────────────────
    const int tableSectionGap = 14;

    const int sectionW =
        (contentW - tableSectionGap) / 2;

    const int nCols = 4;

    int colW[nCols];

    colW[0] = 36;
    colW[1] = 68;
    colW[2] = 54;
    colW[3] =
        sectionW -
        colW[0] -
        colW[1] -
        colW[2] +
        32;

    const int rowH = 22;
    const int thH = 26;
    const int lineThick = 2;


    // ── PEN HELPER ───────────────────────────────────────────────────────────
    auto setPen = [&](int w, QColor c = Qt::black) {

        QPen p(c);

        p.setWidth(w);

        painter.setPen(p);
    };


    // ── LOGO HELPER ──────────────────────────────────────────────────────────
    auto drawLogo = [&]() {

        if (logo.isNull())
            return;

        const int lw = 130;
        const int lh = 52;
        const int pad = 4;

        QRect lr(
            pageW - marginR - lw,
            marginT,
            lw,
            lh
            );

        QSize sc =
            logo.size().scaled(
                lr.size() -
                    QSize(2 * pad, 2 * pad),
                Qt::KeepAspectRatio
                );

        QRect tg(
            lr.center().x() - sc.width() / 2,
            lr.center().y() - sc.height() / 2,
            sc.width(),
            sc.height()
            );

        painter.drawPixmap(tg, logo);
    };


    // ── BATCH DATA ───────────────────────────────────────────────────────────
    QString now =
        QDateTime::currentDateTime().toString(
            "dd/MM/yyyy @ HH:mm:ss"
            );

    QString batchName =
        batchData["batch"].toString();

    QString productName =
        batchData["product"].toString();

    QString started =
        batchData["started"].toString();

    QString ended =
        batchData["ended"].toString();

    if (ended.isEmpty() || ended == "---") {
        for (const QVariant &v : rejectionData) {
            QVariantMap m = v.toMap();
            QString eventType =
                m.value("eventType", "").toString()
                .trimmed()
                .toLower();

            if (eventType == "end") {
                QString eventTime =
                    m.value("eventTime", "").toString().trimmed();

                if (!eventTime.isEmpty()) {
                    ended = eventTime;
                    break;
                }
            }
        }
    }

    QString productCode =
        batchData.value(
                     "productCode",
                     "default code"
                     ).toString();

    QString productSno =
        batchData.value(
                     "productSno",
                     "01-001"
                     ).toString();

    QString totalDur =
        batchData.value(
                     "totalDuration",
                     "---"
                     ).toString();

    QString runDur =
        batchData.value(
                     "runDuration",
                     "---"
                     ).toString();

    QString pauseDur =
        batchData.value(
                     "pauseDuration",
                     "---"
                     ).toString();


    // ── IDENTITY / SESSION DATA ──────────────────────────────────────────────
    QVariantMap machineInfo =
        getMachineDetails();

    QString companyName =
        machineInfo.value(
                       "supplierName",
                       "---"
                       ).toString();

    QString machineId =
        machineInfo.value(
                       "machineId",
                       "---"
                       ).toString();

    QString serialNo =
        machineInfo.value(
                       "serialNumber",
                       "---"
                       ).toString();

    QString machineType =
        machineInfo.value(
                       "machineType",
                       "---"
                       ).toString();

    QString location =
        machineInfo.value(
                       "location",
                       "---"
                       ).toString();

    QString userName =
        machineInfo.value(
                       "userName",
                       "---"
                       ).toString();


    QString loggedUser =
        sessionData.value(
                       "loggedInUserName",
                       "---"
                       ).toString();

    QString loggedRole =
        sessionData.value(
                       "loggedInUserRole",
                       "---"
                       ).toString();

    QString initial =
        roleInitial(loggedRole);


    QString footerLeftStr =
        QString(
            "Generated By: %1 - %2      Approved By: %3 - %4"
            )
            .arg(initial)
            .arg(loggedUser)
            .arg(initial)
            .arg(loggedUser);


    // ── TOTAL REJECTION COUNT ────────────────────────────────────────────────
    int totalRej = 0;

    for (const QVariant &v : rejectionData) {

        QVariantMap m = v.toMap();

        QString eventType =
            m.value(
                 "eventType",
                 ""
                 ).toString().toLower();

        if (
            eventType.isEmpty() ||
            eventType == "reject"
            ) {
            totalRej +=
                m["rejectCount"].toInt();
        }
    }


    QString endText =
        (
            ended == "---" ||
            ended.isEmpty()
            )
            ? "Batch is still running...."
            : ended;


    // ── FOOTER ZONE ──────────────────────────────────────────────────────────
    const int footerDivY =
        pageH - marginB - 28;

    const int footerTextY =
        pageH - marginB - 10;


    // ── DRAW FOOTER ──────────────────────────────────────────────────────────
    auto drawFooter =
        [&](int pageNum, int totalPages) {

            setPen(lineThick);

            painter.drawLine(
                marginL,
                footerDivY,
                pageW - marginR,
                footerDivY
                );

            painter.setFont(fontB(9));

            setPen(1);

            painter.drawText(
                marginL,
                footerTextY,
                footerLeftStr
                );


            QString repLabel =
                "Batch Report";

            QString pageStr =
                QString(
                    "Page No: %1 / %2"
                    )
                    .arg(pageNum + 1)
                    .arg(totalPages);


            QFontMetrics fm =
                painter.fontMetrics();

            int repLabelW =
                fm.horizontalAdvance(
                    repLabel
                    );

            int pageStrW =
                fm.horizontalAdvance(
                    pageStr
                    );

            int sepW = 10;
            int sepLineW = 2;

            int blockW =
                repLabelW +
                sepW +
                sepLineW +
                sepW +
                pageStrW;

            int blockX =
                pageW -
                marginR -
                blockW;


            painter.drawText(
                blockX,
                footerTextY,
                repLabel
                );


            int sepX =
                blockX +
                repLabelW +
                sepW;

            setPen(lineThick);

            painter.drawLine(
                sepX,
                footerDivY + 8,
                sepX,
                footerTextY - 1
                );

            setPen(1);

            painter.setFont(fontB(9));

            painter.drawText(
                sepX + sepW,
                footerTextY,
                pageStr
                );
        };


    // ── DRAW FULL HEADER ─────────────────────────────────────────────────────
    auto drawHeaderFull = [&]() -> int {

        int y = marginT;

        drawLogo();

        setPen(1);

        painter.setFont(fontB(12));

        painter.drawText(
            QRect(
                marginL,
                y,
                contentW,
                22
                ),
            Qt::AlignHCenter |
                Qt::AlignVCenter,
            companyName
            );

        y += 22;


        painter.setFont(fontB(10));

        painter.drawText(
            QRect(
                marginL,
                y,
                contentW,
                20
                ),
            Qt::AlignHCenter |
                Qt::AlignVCenter,
            "PRODUCT / BATCH REPORT"
            );

        y += 20;


        painter.setFont(fontR(9));

        painter.drawText(
            QRect(
                marginL,
                y,
                contentW,
                16
                ),
            Qt::AlignHCenter |
                Qt::AlignVCenter,
            "(Metal Detector)"
            );

        y += 16;


        int logoBottom =
            marginT + 52 + 6;

        if (y + 3 < logoBottom)
            y = logoBottom;


        setPen(lineThick);

        painter.drawLine(
            marginL,
            y + 3,
            pageW - marginR,
            y + 3
            );

        y += 10;


        setPen(1);

        painter.setFont(fontR(9));

        painter.drawText(
            marginL,
            y + 12,
            "File created on: " + now
            );

        y += 25;

        return y;
    };


    // ── DRAW COMPACT HEADER ──────────────────────────────────────────────────
    auto drawHeaderCompact =
        [&](int pageNum, int totalPages) -> int {

        Q_UNUSED(totalPages);

        int y = marginT;

        drawLogo();

        setPen(1);

        painter.setFont(fontB(11));

        painter.drawText(
            QRect(
                marginL,
                y,
                contentW,
                22
                ),
            Qt::AlignHCenter |
                Qt::AlignVCenter,
            companyName
            );

        y += 22;


        int logoBottom =
            marginT + 52 + 6;

        if (y + 2 < logoBottom)
            y = logoBottom;


        setPen(lineThick);

        painter.drawLine(
            marginL,
            y + 2,
            pageW - marginR,
            y + 2
            );

        y += 12;


        int c1 = marginL;

        int c2 =
            marginL +
            contentW / 3;


        painter.setFont(fontB(9));

        setPen(1);

        painter.drawText(
            c1,
            y + 12,
            "Machine ID:"
            );

        painter.setFont(fontR(9));

        painter.drawText(
            c1 + 72,
            y + 12,
            machineId
            );


        painter.setFont(fontB(9));

        painter.drawText(
            c2,
            y + 12,
            "Generated:"
            );

        painter.setFont(fontR(9));

        painter.drawText(
            c2 + 68,
            y + 12,
            now
            );

        y += 20;


        setPen(lineThick);

        painter.drawLine(
            marginL,
            y + 2,
            pageW - marginR,
            y + 2
            );

        y += 10;

        return y;
    };


    // ── DRAW TABLE HEADER ────────────────────────────────────────────────────
    QStringList tHeaders = {
        "S/No.",
        "Date",
        "Time",
        "Reject Count / Batch Status"
    };


    auto drawTableHeader =
        [&](int xOffset, int y) -> int {

        const int radius = 6;

        const QColor headerBg(
            52,
            58,
            64
            );

        const QColor headerText(
            Qt::white
            );


        painter.save();

        painter.setPen(Qt::NoPen);

        painter.setBrush(headerBg);

        painter.drawRoundedRect(
            xOffset,
            y,
            sectionW,
            thH,
            radius,
            radius
            );


        painter.setPen(headerText);

        painter.setFont(fontB(9));


        int x = xOffset;

        for (int i = 0; i < nCols; ++i) {

            painter.drawText(
                QRect(
                    x + 4,
                    y,
                    colW[i] - 8,
                    thH
                    ),
                Qt::AlignCenter,
                tHeaders[i]
                );

            x += colW[i];
        }

        painter.restore();

        return y + thH + 4;
    };


    // ── STATUS DISPLAY HELPER ────────────────────────────────────────────────
    struct RowDisplay {
        QString text;
        QColor color;
        bool bold;
    };


    auto resolveRowDisplay =
        [&](const QVariantMap &m) -> RowDisplay {

        QString eventType =
            m.value(
                 "eventType",
                 ""
                 ).toString()
                .trimmed()
                .toLower();


        if (eventType == "start") {

            return {
                "Batch Start",
                QColor(20, 130, 20),
                true
            };
        }


        if (eventType == "pause") {

            return {
                "Batch Paused",
                QColor(200, 80, 0),
                true
            };
        }


        if (eventType == "resume") {

            return {
                "Batch Resumed",
                QColor(0, 80, 180),
                true
            };
        }


        if (eventType == "end") {

            return {
                "Batch End",
                QColor(60, 60, 60),
                true
            };
        }


        int rejectCount =
            m.value(
                 "rejectCount",
                 0
                 ).toInt();


        return {
            QString("Rejected: %1")
            .arg(rejectCount),

                QColor(180, 0, 0),

                false
        };
    };

    // ── TIMESTAMP PARSER ─────────────────────────────────────────────────────
    auto parseEventDateTime =
        [&](const QVariantMap &m) -> QDateTime {

        QString eventType =
            m.value("eventType", "").toString().trimmed().toLower();

        // First preference: direct timestamp fields
        QStringList timestampKeys;

        if (eventType == "start") {
            timestampKeys << "startTime";
        } else if (eventType == "pause") {
            timestampKeys << "pauseTime";
        } else if (eventType == "resume") {
            timestampKeys << "resumeTime";
        } else if (eventType == "end") {
            timestampKeys << "endTime";
        }

        // Fallback keys
        timestampKeys
            << "timestamp"
            << "dateTime"
            << "datetime"
            << "createdAt"
            << "eventTime";

        for (const QString &key : timestampKeys) {

            QString value =
                m.value(key).toString().trimmed();

            if (value.isEmpty())
                continue;

            QStringList formats = {
                "dd/MM/yyyy @ HH:mm:ss",
                "dd/MM/yyyy HH:mm:ss",
                "dd-MM-yyyy HH:mm:ss",
                "dd-MM-yyyy @ HH:mm:ss",
                "yyyy-MM-dd HH:mm:ss",
                "yyyy-MM-ddTHH:mm:ss",
                "yyyy-MM-ddTHH:mm:ss.zzz",
                "dd/MM/yyyy",
                "dd-MM-yyyy"
            };

            for (const QString &format : formats) {

                QDateTime dt =
                    QDateTime::fromString(
                        value,
                        format
                        );

                if (dt.isValid())
                    return dt;
            }

            // Try ISO format as final fallback
            QDateTime isoDt =
                QDateTime::fromString(
                    value,
                    Qt::ISODate
                    );

            if (isoDt.isValid())
                return isoDt;
        }

        // If date and time are stored separately
        QString date =
            m.value("date").toString().trimmed();

        QString time =
            m.value("time").toString().trimmed();

        if (!date.isEmpty() && !time.isEmpty()) {

            QStringList formats = {
                "dd/MM/yyyy HH:mm:ss",
                "dd/MM/yyyy HH:mm",
                "dd-MM-yyyy HH:mm:ss",
                "dd-MM-yyyy HH:mm",
                "yyyy-MM-dd HH:mm:ss",
                "yyyy-MM-dd HH:mm"
            };

            for (const QString &format : formats) {

                QDateTime dt =
                    QDateTime::fromString(
                        date + " " + time,
                        format
                        );

                if (dt.isValid())
                    return dt;
            }
        }

        return QDateTime();
    };

    // ── DRAW ONE DATA ROW ─────────────────────────────────────────────────────
    auto drawDataRow =
        [&](int xOffset,
            int y,
            int idx,
            const QVariantMap &m) {

            // Alternate row background
            if (idx % 2 == 1) {

                painter.fillRect(
                    xOffset,
                    y,
                    sectionW,
                    rowH,
                    QColor(230, 230, 230)
                    );
            }


            // ── RESOLVE STATUS ────────────────────────────────────────────────────
            RowDisplay rd =
                resolveRowDisplay(m);


            // ── RESOLVE DATE / TIME ───────────────────────────────────────────────
            QDateTime eventDateTime =
                parseEventDateTime(m);

            QString eventDate;
            QString eventTime;

            if (eventDateTime.isValid()) {

                eventDate =
                    eventDateTime.date().toString(
                        "dd/MM/yyyy"
                        );

                eventTime =
                    eventDateTime.time().toString(
                        "  HH:mm:ss"
                        );

            } else {

                // Final fallback
                eventDate =
                    m.value("date", "---").toString();

                eventTime =
                    m.value("time", "---").toString();
            }


            // ── ROW DATA ──────────────────────────────────────────────────────────
            QStringList row = {

            QString::number(idx + 1),

                eventDate,

                eventTime,

                rd.text
        };


    // ── DRAW COLUMNS ─────────────────────────────────────────────────────
    int x = xOffset;

    for (int c = 0; c < nCols; ++c) {

        // Bottom separator
        setPen(
            1,
            QColor(210, 210, 210)
            );

        painter.drawLine(
            xOffset + 8,
            y + rowH - 1,
            xOffset + sectionW - 8,
            y + rowH - 1
            );


        // Alignment
        Qt::Alignment al;

        if (c == 0) {

            al =
                Qt::AlignVCenter |
                Qt::AlignHCenter;

        } else if (c == nCols - 1) {

            al =
                Qt::AlignVCenter |
                Qt::AlignLeft;

        } else {

            al =
                Qt::AlignVCenter |
                Qt::AlignLeft;
        }


        // Font + color
        if (c == nCols - 1) {

            painter.setFont(
                rd.bold
                    ? fontB(8)
                    : fontR(9)
                );

            setPen(
                1,
                rd.color
                );

        } else {

            painter.setFont(
                fontR(9)
                );

            setPen(
                1,
                QColor(45, 45, 45)
                );
        }


        // Draw cell
        const int statusLeftPadding = 50;

        painter.drawText(
            QRect(
                x + (c == nCols - 1 ? statusLeftPadding : 4),
                y,
                colW[c] - (c == nCols - 1 ? statusLeftPadding + 4 : 8),
                rowH
                ),
            al,
            row[c]
            );


        x += colW[c];
    }
};


// ── SECTION BOX HELPER ───────────────────────────────────────────────────
auto drawSectionTitle =
    [&](int y,
        const QString &title) -> int {

    painter.setFont(fontB(10));

    setPen(1);

    painter.drawText(
        marginL,
        y + 12,
        title
        );

    return y + 16;
};


auto drawKVLine =
    [&](int x,
        int y,
        const QString &lbl,
        const QString &val,
        int valueOffsetX = 145) {

        painter.setFont(fontB(9));

        setPen(1);

        painter.drawText(
            x + 8,
            y,
            lbl
            );


        painter.setFont(fontR(9));

        painter.drawText(
            x + 8 + valueOffsetX,
            y,
            val
            );
    };


// ── DRAW DUAL TABLE HEADERS ──────────────────────────────────────────────
auto drawBothTableHeaders =
    [&](int y) -> int {

    int leftX = marginL;

    int rightX =
        marginL +
        sectionW +
        tableSectionGap;


    drawTableHeader(
        leftX,
        y
        );

    drawTableHeader(
        rightX,
        y
        );

    return y + thH + 4;
};


// ── DRAW VERTICAL SECTION DIVIDER ─────────────────────────────────────────
auto drawSectionDivider =
    [&](int yTop,
        int yBottom) {

        int divX =
            marginL +
            sectionW +
            tableSectionGap / 2;


        QPen dp(
            QColor(180, 180, 180)
            );

        dp.setWidth(1);

        dp.setStyle(
            Qt::DashLine
            );

        painter.setPen(dp);

        painter.drawLine(
            divX,
            yTop,
            divX,
            yBottom
            );

        setPen(1);
    };


// ── DRAW TOTAL ROW ───────────────────────────────────────────────────────
auto drawTotalRow =
    [&](int xOffset, int y) {

        painter.setFont(fontB(9));

        setPen(
            1,
            Qt::black
            );

        QString totalStr =
            "Total Rejection Count: " +
            QString::number(totalRej);

        painter.drawText(
            QRect(
                xOffset,
                y + 2,
                sectionW - 4,
                rowH - 4
                ),
            Qt::AlignVCenter |
                Qt::AlignRight,
            totalStr
            );
    };


// ── PRE-CALCULATE TOTAL PAGES ────────────────────────────────────────────
const int footerH =
    pageH - footerDivY + 10;

const int summaryH =
    74 +
    16 +
    62 +
    16 +
    172 +
    16 +
    34 +
    16 +
    24;

const int availPage0 =
    pageH -
    summaryH -
    footerH -
    10;

const int rowPairsPage0 =
    qMax(
        0,
        availPage0 / rowH
        );

const int rowsPage0 =
    rowPairsPage0 * 2;


const int compactHdrH = 76;

const int availPageN =
    pageH -
    compactHdrH -
    thH -
    footerH -
    marginB -
    20;

const int rowPairsPageN =
    qMax(
        1,
        availPageN / rowH
        );

const int rowsPageN =
    rowPairsPageN * 2;


int totalPages = 1;

if (
    !rejectionData.isEmpty() &&
    rejectionData.size() > rowsPage0
    ) {

    int remaining =
        rejectionData.size() -
        rowsPage0;

    totalPages +=
        (
            remaining +
            rowsPageN -
            1
            ) /
        rowsPageN;
}


// ════════════════════════════════════════════════════════════════════
// PAGE 0
// ════════════════════════════════════════════════════════════════════
int y = drawHeaderFull();


// ── Machine Summary ──────────────────────────────────────────────────────
y = drawSectionTitle(
    y,
    "Machine Summary :"
    );

y += 10;

int boxTop = y;

int lColX = marginL;

int rColX =
    marginL +
    contentW / 2;

int r1y =
    boxTop + 26;

int r2y =
    boxTop + 43;

y += 10;


drawKVLine(
    lColX,
    r1y,
    "User",
    ": " + userName
    );

drawKVLine(
    rColX,
    r1y,
    "Machine ID.",
    ": " + machineId,
    90
    );

drawKVLine(
    rColX,
    r2y,
    "M/c Sr. No.",
    ": " + serialNo,
    90
    );

drawKVLine(
    lColX,
    r2y + 17,
    "M/c Type",
    ": " + machineType
    );

drawKVLine(
    lColX,
    r2y,
    "Location",
    ": " + location
    );


int machineBoxH = 72;

setPen(lineThick);

painter.drawRect(
    marginL,
    boxTop,
    contentW,
    machineBoxH
    );

y =
    boxTop +
    machineBoxH +
    10;


// ── Product / Batch Summary ──────────────────────────────────────────────
y = drawSectionTitle(
    y,
    "Product / Batch Summary :"
    );

y += 10;

boxTop = y;


struct KVPair {
    QString lbl;
    QString val;
};


QList<KVPair> leftRows = {

{
    "Product Code",
    ": " + productCode
},

    {
        "Product S/No.",
        ": " + productSno
    },

    {
        "Product Name",
        ": " + productName
    },

    {
        "",
        ""
    },
    {
        "",
        ""
    },

    {
        "",
        ""
    },
};


QList<KVPair> rightRows = {

{
    "Batch ID",
    ": " + batchName
},

    {
        "Batch Start Time",
        ": " + started
    },

    {
        "Batch End Time",
        ": " + endText
    },

    {
        "Batch Run Duration",
        ": " + runDur
    },

    {
        "Batch Pause Duration",
        ": " + pauseDur
    },

{
    "Total Batch Duration",
        ": " + totalDur
}
};


int nKVRows =
    leftRows.size();

int lineH = 17;

int boxPadTop = 24;


for (int i = 0;
     i < nKVRows;
     ++i) {

    int rowY =
        boxTop +
        boxPadTop +
        i * lineH;


    drawKVLine(
        lColX,
        rowY,
        leftRows[i].lbl,
        leftRows[i].val
        );


    if (!rightRows[i].lbl.isEmpty()) {

        drawKVLine(
            rColX,
            rowY,
            rightRows[i].lbl,
            rightRows[i].val,
            155
            );
    }
}


int productBoxH =
    boxPadTop +
    nKVRows * lineH +
    8;


setPen(lineThick);

painter.drawRect(
    marginL,
    boxTop,
    contentW,
    productBoxH
    );


y =
    boxTop +
    productBoxH +
    10;


// ── Rejection Summary ────────────────────────────────────────────────────
y = drawSectionTitle(
    y,
    "Rejection Summary :"
    );

y += 10;

boxTop = y;


drawKVLine(
    lColX,
    boxTop + 16,
    "Total Rejection Count  :",
    QString::number(totalRej)
    );


int rejBoxH = 28;

setPen(lineThick);

painter.drawRect(
    marginL,
    boxTop,
    contentW,
    rejBoxH
    );


y =
    boxTop +
    rejBoxH +
    10;

y += 10;


// ── Rejection Details ────────────────────────────────────────────────────
int dataIndex = 0;


if (!rejectionData.isEmpty()) {

    painter.setFont(
        fontB(10)
        );

    setPen(1);

    painter.drawText(
        marginL,
        y + 12,
        "Rejection Details"
        );

    y += 16;


    int leftX = marginL;

    int rightX =
        marginL +
        sectionW +
        tableSectionGap;


    y =
        drawBothTableHeaders(y);


    int tableTopY = y;

    int leftIdx = dataIndex;

    int rightIdx =
        dataIndex +
        rowPairsPage0;

    int rowY = y;

    bool drewAnyRow = false;


    while (
        leftIdx <
        rejectionData.size()
        ) {

        if (
            rowY + rowH >
            footerDivY - 6
            )
            break;


        drawDataRow(
            leftX,
            rowY,
            leftIdx,
            rejectionData[leftIdx].toMap()
            );


        if (
            rightIdx <
            rejectionData.size()
            ) {

            drawDataRow(
                rightX,
                rowY,
                rightIdx,
                rejectionData[rightIdx].toMap()
                );
        }


        drewAnyRow = true;

        rowY++;

        rowY += rowH - 1;

        leftIdx++;

        rightIdx++;
    }


    if (drewAnyRow) {

        drawSectionDivider(
            tableTopY - 4,
            rowY
            );
    }


    dataIndex = rightIdx;


    if (
        dataIndex >
        rejectionData.size()
        )
        dataIndex =
            rejectionData.size();


    if (
        dataIndex >=
            rejectionData.size() &&
        rowY + rowH <=
            footerDivY - 6
        ) {

        drawTotalRow(
            rightX,
            rowY
            );
    }
}


drawFooter(
    0,
    totalPages
    );


// ════════════════════════════════════════════════════════════════════
// PAGES 1+ — rejection table continuation
// ════════════════════════════════════════════════════════════════════
int page = 1;


while (
    dataIndex <
    rejectionData.size()
    ) {

    writer.newPage();


    y =
        drawHeaderCompact(
            page,
            totalPages
            );


    painter.setFont(
        fontB(10)
        );

    setPen(1);


    painter.drawText(
        marginL,
        y + 12,
        "Rejection Details (continued)"
        );


    y += 18;


    int leftX = marginL;

    int rightX =
        marginL +
        sectionW +
        tableSectionGap;


    y =
        drawBothTableHeaders(y);


    int tableTopY = y;


    int rowsAvail = 0;

    {
        int testY = y;

        while (
            testY + rowH <=
            footerDivY - 6
            ) {

            testY += rowH;

            rowsAvail++;
        }
    }


    int leftIdx = dataIndex;

    int rightIdx =
        dataIndex +
        rowsAvail;

    int rowY = y;

    bool drewAny = false;


    while (
        leftIdx <
        rejectionData.size()
        ) {

        if (
            rowY + rowH >
            footerDivY - 6
            )
            break;


        drawDataRow(
            leftX,
            rowY,
            leftIdx,
            rejectionData[leftIdx].toMap()
            );


        if (
            rightIdx <
            rejectionData.size()
            ) {

            drawDataRow(
                rightX,
                rowY,
                rightIdx,
                rejectionData[rightIdx].toMap()
                );
        }


        drewAny = true;

        rowY += rowH;

        leftIdx++;

        rightIdx++;
    }


    if (drewAny) {

        drawSectionDivider(
            tableTopY - 4,
            rowY
            );
    }


    dataIndex = rightIdx;


    if (
        dataIndex >
        rejectionData.size()
        )
        dataIndex =
            rejectionData.size();


    if (
        dataIndex >=
            rejectionData.size() &&
        rowY + rowH <=
            footerDivY - 6
        ) {

        drawTotalRow(
            rightX,
            rowY
            );
    }


    drawFooter(
        page,
        totalPages
        );

    page++;
}


painter.end();


qDebug()
    << "Batch PDF saved at:"
    << path;


return path;
}

// =========== Check USB =========
bool PdfExporter::isUsbMounted()
{
    refreshUsbState();
    return m_usbMounted;
}

// ============= Get USB path ==========
QString PdfExporter::getUsbPath()
{
    refreshUsbState();
    return m_usbPath;
}

// ============ Move selected files to USB ===========
bool PdfExporter::moveFilesToUsb(const QStringList &filePaths,
                                 const QString &serialNumber)
{
    refreshUsbState();
    const QString usbPath = m_usbPath.trimmed();
    qDebug() << "USB destination path:" << usbPath;

    QFileInfo usbInfo(usbPath);
    if (!m_usbMounted || usbPath.isEmpty() || !usbInfo.isDir()
        || !usbInfo.isReadable() || !usbInfo.isWritable()) {
        qWarning() << "USB destination is not a writable mounted storage device";
        return false;
    }

    QString folderName = serialNumber.trimmed().isEmpty()
                             ? "Reports_MD"
                             : QString("Reports_MD_%1").arg(serialNumber.trimmed());

    QDir    usbDir(usbPath);
    QString destDir = usbDir.filePath(folderName);
    qDebug() << "Destination directory:" << destDir;

    if (!QDir().mkpath(destDir)) {
        qWarning() << "Failed to create USB destination directory:" << destDir;
        return false;
    }

    bool allOk = true;
    for (const QString &srcFile : filePaths) {
        QFileInfo fi(srcFile);
        qDebug() << "PDF source:" << srcFile
                 << "exists=" << fi.exists()
                 << "readable=" << fi.isReadable();
        if (!fi.isFile() || !fi.isReadable() || fi.size() <= 0) {
            qWarning() << "PDF source is not a readable completed file:" << srcFile;
            allOk = false;
            continue;
        }

        QString dstFile = QDir(destDir).filePath(fi.fileName());
        qDebug() << "PDF destination:" << dstFile;

        if (QFile::exists(dstFile) && !QFile::remove(dstFile)) {
            qWarning() << "Unable to replace existing PDF:" << dstFile;
            allOk = false;
            continue;
        }

        QFile sourceFile(srcFile);
        if (!sourceFile.copy(dstFile)) {
            qWarning() << "PDF copy failed:" << sourceFile.errorString();
            allOk = false;
        } else {
            qDebug() << "PDF copy success:" << dstFile;
        }
    }
    return allOk;
}

//====================== X-Y PLOT PDF ============================

QString PdfExporter::exportXYPlotToPdf(const QString &imagePath,
                                       const QString &productPhase,
                                       const QString &signal,
                                       const QString &amplitude,
                                       const QVariantMap &sessionData)
{
    // ── PATH SETUP ──────────────────────────────────────────────────────────
    QString reportsFolder = getReportsFolderPath();
    qDebug() << "[XYPlot] Reports folder resolved to:" << reportsFolder;

    if (reportsFolder.isEmpty()) {
        qDebug() << "[XYPlot] ERROR: Reports folder path is empty. "
                    "QStandardPaths::DocumentsLocation likely failed to resolve.";
        return QString();
    }

    QDir().mkpath(reportsFolder);

    qDebug() << "[XYPlot] Image path received:" << imagePath;

    // ── NORMALIZE file:// URL TO A LOCAL PATH ──────────────────────────────
    QString localImagePath = imagePath;
    if (localImagePath.startsWith("file://")) {
        localImagePath = QUrl(localImagePath).toLocalFile();
    }
    qDebug() << "[XYPlot] Normalized local image path:" << localImagePath;

    if (localImagePath.isEmpty() || !QFile::exists(localImagePath)) {
        qDebug() << "[XYPlot] ERROR: Source grab image does not exist at:" << localImagePath;
        return QString();
    }

    QString ts   = QDateTime::currentDateTime().toString("dd-MM-yyyy_HH-mm-ss");
    QString path = reportsFolder + "/XYPlot_Report_" + ts + ".pdf";
    qDebug() << "[XYPlot] Target PDF path:" << path;

    // ── WRITABILITY PRE-CHECK (QPdfWriter has no isValid(), so test manually) ─
    {
        QFile testFile(path);
        if (!testFile.open(QIODevice::WriteOnly)) {
            qDebug() << "[XYPlot] ERROR: Target path is not writable:" << path
                     << "Reason:" << testFile.errorString();
            return QString();
        }
        testFile.close();
        testFile.remove(); // clean up the empty test file; QPdfWriter will recreate it
    }

    // ── IDENTITY / SESSION DATA ──────────────────────────────────────────────
    QVariantMap machineInfo = getMachineDetails();

    QString companyName   = machineInfo.value("supplierName",  "---").toString();
    QString machineId     = machineInfo.value("machineId",     "---").toString();
    QString machineSerial = machineInfo.value("serialNumber",  "---").toString();
    QString machineType   = machineInfo.value("machineType",   "---").toString();
    QString location      = machineInfo.value("location",      "---").toString();
    QString userName      = machineInfo.value("userName",      "---").toString();

    QString loggedUser = sessionData.value("loggedInUserName", "---").toString();
    QString loggedRole = sessionData.value("loggedInUserRole", "---").toString();
    QString initial    = roleInitial(loggedRole);

    QString footerLeftStr =
        QString("Generated By: %1 - %2      Approved By: %3 - %4")
            .arg(initial).arg(loggedUser).arg(initial).arg(loggedUser);

    // ── WRITER ──────────────────────────────────────────────────────────────
    QPdfWriter writer(path);
    writer.setPageSize(QPageSize(QPageSize::A4));
    writer.setResolution(96);
    writer.setPageMargins(QMarginsF(0, 0, 0, 0));

    QPainter painter(&writer);

    if (!painter.isActive()) {
        qDebug() << "[XYPlot] ERROR: QPainter failed to begin painting on writer for:" << path;
        return QString();
    }

    // ── FONT ────────────────────────────────────────────────────────────────
    int fontId = QFontDatabase::addApplicationFont(":/assets/images/RobotoCondensed-Regular.ttf");
    QFontDatabase::addApplicationFont(":/assets/images/RobotoCondensed-Bold.ttf");
    QString fontFamily = "Arial";
    if (fontId != -1) {
        QStringList families = QFontDatabase::applicationFontFamilies(fontId);
        if (!families.isEmpty()) fontFamily = families.first();
    } else {
        qDebug() << "[XYPlot] WARNING: Custom font failed to load, falling back to Arial.";
    }
    auto fontR = [&](int pt) { return QFont(fontFamily, pt, QFont::Normal); };
    auto fontB = [&](int pt) { return QFont(fontFamily, pt, QFont::Bold);   };

    // ── LOGO ────────────────────────────────────────────────────────────────
    QString logoPath = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation)
                       + "/Logo.png";
    QPixmap logo(logoPath);
    if (logo.isNull()) {
        qDebug() << "[XYPlot] Note: Logo not found at:" << logoPath << "(continuing without it)";
    }

    // ── PAGE GEOMETRY ───────────────────────────────────────────────────────
    const int pageW    = writer.width();
    const int pageH    = writer.height();
    const int marginL  = 40;
    const int marginR  = 40;
    const int marginT  = 20;
    const int marginB  = 30;
    const int contentW = pageW - marginL - marginR;
    const int lineThick = 2;

    auto setPen = [&](int w, QColor c = Qt::black) {
        QPen p(c); p.setWidth(w); painter.setPen(p);
    };

    auto drawLogo = [&]() {
        if (logo.isNull()) return;
        const int logoW = 130, logoH = 55, pad = 4;
        QRect logoRect(pageW - marginR - logoW, marginT, logoW, logoH);
        QSize scaled = logo.size().scaled(logoRect.size() - QSize(2*pad, 2*pad),
                                          Qt::KeepAspectRatio);
        QRect target(logoRect.center().x() - scaled.width()/2,
                     logoRect.center().y() - scaled.height()/2,
                     scaled.width(), scaled.height());
        painter.drawPixmap(target, logo);
    };

    // ── HEADER (same pattern as Audit Trail / Batch report) ─────────────────
    int y = marginT;

    painter.setFont(fontB(12)); setPen(1);
    painter.drawText(QRect(marginL, y, contentW, 22),
                     Qt::AlignHCenter | Qt::AlignVCenter, companyName);
    y += 22;

    painter.setFont(fontB(11));
    painter.drawText(QRect(marginL, y, contentW, 20),
                     Qt::AlignHCenter | Qt::AlignVCenter, "X-Y PLOT REPORT");
    y += 20;

    painter.setFont(fontR(9));
    painter.drawText(QRect(marginL, y, contentW, 16),
                     Qt::AlignHCenter | Qt::AlignVCenter, "(Metal Detector)");
    y += 16;

    drawLogo();

    setPen(lineThick);
    painter.drawLine(marginL, y + 4, pageW - marginR, y + 4);
    y += 12;

    painter.setFont(fontR(9)); setPen(1);

    int col1x = marginL;
    int col2x = marginL + contentW / 3;
    int col3x = marginL + 2 * contentW / 3;
    int metaLineH = 18;

    auto drawMeta = [&](int x, int yy, const QString &label, const QString &val) {
        constexpr int colonOffset = 78;
        painter.setFont(fontB(9));
        painter.drawText(x, yy, label);
        painter.setFont(fontR(9));
        painter.drawText(x + colonOffset, yy, ": " + val);
    };

    QString now = QDateTime::currentDateTime().toString("dd/MM/yyyy @ HH:mm:ss");

    drawMeta(col1x, y + metaLineH,   "User",        userName);
    drawMeta(col2x, y + metaLineH,   "Generated",   now);
    drawMeta(col3x, y + metaLineH,   "Machine ID",  machineId);

    drawMeta(col1x, y + 2*metaLineH, "Location",    location);
    drawMeta(col2x, y + 2*metaLineH, "M/c Sr. No.", machineSerial);
    drawMeta(col3x, y + 2*metaLineH, "M/c Type",    machineType);

    y += 2*metaLineH + 10;

    setPen(lineThick);
    painter.drawLine(marginL, y + 4, pageW - marginR, y + 4);
    y += 20;

    // ── PARAMETER CARDS: Product Phase / Signal / Amplitude ─────────────────
    painter.setFont(fontB(10)); setPen(1);
    painter.drawText(marginL, y + 12, "Plot Parameters:");
    y += 20;

    const int paramBoxH = 46;
    const int paramGap  = 12;
    const int paramW    = (contentW - 2*paramGap) / 3;

    struct ParamBox { QString label; QString value; QColor color; };
    QList<ParamBox> params = {
        { "Product Phase", productPhase, QColor(26, 77, 181) },
        { "Signal",        signal,       QColor(15, 138, 96) },
        { "Amplitude",     amplitude,    QColor(214, 69, 69) }
    };

    int px = marginL;
    for (const ParamBox &pb : params) {
        setPen(1, QColor(220, 229, 245));
        painter.setBrush(QColor(247, 249, 253));
        painter.drawRoundedRect(px, y, paramW, paramBoxH, 8, 8);
        painter.setBrush(Qt::NoBrush);

        painter.setFont(fontB(9));
        setPen(1, pb.color);
        painter.drawText(QRect(px + 10, y + 6, paramW - 20, 16),
                         Qt::AlignLeft | Qt::AlignVCenter, pb.label);

        painter.setFont(fontB(13));
        painter.drawText(QRect(px + 10, y + 22, paramW - 20, 20),
                         Qt::AlignLeft | Qt::AlignVCenter, pb.value);

        px += paramW + paramGap;
    }
    y += paramBoxH + 16;

    // ── GRAPH IMAGE (fills remaining space above footer) ─────────────────────
    const int footerDivY   = pageH - marginB - 28;
    const int graphAreaTop = y;
    const int graphAreaH   = footerDivY - 10 - graphAreaTop;

    setPen(1, QColor(220, 229, 245));
    painter.setBrush(Qt::white);
    painter.drawRoundedRect(marginL, graphAreaTop, contentW, graphAreaH, 10, 10);
    painter.setBrush(Qt::NoBrush);

    QImage image(localImagePath);
    if (image.isNull()) {
        qDebug() << "[XYPlot] WARNING: Grabbed graph image failed to load into QImage from:" << localImagePath;
    } else {
        const int pad = 12;
        QRect avail(marginL + pad, graphAreaTop + pad,
                    contentW - 2*pad, graphAreaH - 2*pad);
        QSize scaled = image.size().scaled(avail.size(), Qt::KeepAspectRatio);
        QRect target(avail.center().x() - scaled.width()/2,
                     avail.center().y() - scaled.height()/2,
                     scaled.width(), scaled.height());
        painter.drawImage(target, image);
    }

    // ── FOOTER (same pattern as Audit Trail / Batch report) ──────────────────
    int footerTextY = pageH - marginB - 10;

    setPen(lineThick);
    painter.drawLine(marginL, footerDivY, pageW - marginR, footerDivY);

    painter.setFont(fontB(9)); setPen(1);
    painter.drawText(marginL, footerTextY, footerLeftStr);

    QString repLabel = "X-Y Plot Report";
    QString pageStr  = "Page No: 1 / 1";

    QFontMetrics fm = painter.fontMetrics();
    int repLabelW = fm.horizontalAdvance(repLabel);
    int pageStrW  = fm.horizontalAdvance(pageStr);
    int sepW = 10, sepLineW = 2;
    int blockW = repLabelW + sepW + sepLineW + sepW + pageStrW;
    int blockX = pageW - marginR - blockW;

    painter.drawText(blockX, footerTextY, repLabel);

    int sepX = blockX + repLabelW + sepW;
    setPen(lineThick);
    painter.drawLine(sepX, footerDivY + 8, sepX, footerTextY - 1);

    setPen(1);
    painter.drawText(sepX + sepW, footerTextY, pageStr);

    painter.end();

    // Delete temporary grab image
    QFile::remove(localImagePath);

    // Final confirmation the file actually landed on disk
    if (QFile::exists(path)) {
        qDebug() << "[XYPlot] SUCCESS: PDF confirmed on disk at:" << path;
    } else {
        qDebug() << "[XYPlot] ERROR: painter.end() completed but file does NOT exist at:" << path
                 << "— check disk space / write permissions on that path.";
        return QString();
    }

    return path;
}

//====================== COIL OUTPUT PDF ============================

QString PdfExporter::exportCoilOutputToPdf(
    const QString &imagePath,
    const QString &avg,
    const QString &min,
    const QString &max,
    const QVariantMap &sessionData)
{

    QString reportsFolder = getReportsFolderPath();

    if(reportsFolder.isEmpty())
        return QString();


    QDir().mkpath(reportsFolder);



    QString localImagePath = imagePath;

    if(localImagePath.startsWith("file://"))
        localImagePath = QUrl(localImagePath).toLocalFile();



    if(!QFile::exists(localImagePath))
    {
        qDebug()<<"[Coil] Image missing:"<<localImagePath;
        return QString();
    }



    QString ts =
        QDateTime::currentDateTime()
            .toString("dd-MM-yyyy_HH-mm-ss");



    QString path =
        reportsFolder+
        "/Coil_Output_Report_"+
        ts+
        ".pdf";



    //=========================================================
    // MACHINE DETAILS
    //=========================================================

    QVariantMap machineInfo = getMachineDetails();


    QString companyName =
        machineInfo.value("supplierName","---").toString();

    QString machineId =
        machineInfo.value("machineId","---").toString();

    QString machineSerial =
        machineInfo.value("serialNumber","---").toString();

    QString machineType =
        machineInfo.value("machineType","---").toString();

    QString location =
        machineInfo.value("location","---").toString();


    QString userName =
        machineInfo.value("userName","---").toString();



    QString loggedUser =
        sessionData.value(
                       "loggedInUserName",
                       "---"
                       ).toString();


    QString loggedRole =
        sessionData.value(
                       "loggedInUserRole",
                       "---"
                       ).toString();



    QString initial =
        roleInitial(loggedRole);



    QString footerLeftStr =
        QString(
            "Generated By: %1 - %2      Approved By: %3 - %4"
            )
            .arg(initial)
            .arg(loggedUser)
            .arg(initial)
            .arg(loggedUser);



    //=========================================================
    // PDF WRITER
    //=========================================================

    QPdfWriter writer(path);

    writer.setPageSize(
        QPageSize(QPageSize::A4)
        );

    writer.setResolution(96);

    writer.setPageMargins(
        QMarginsF(0,0,0,0)
        );



    QPainter painter(&writer);


    if(!painter.isActive())
        return QString();



    //=========================================================
    // FONT
    //=========================================================

    int fontId =
        QFontDatabase::addApplicationFont(
            ":/assets/images/RobotoCondensed-Regular.ttf"
            );


    QFontDatabase::addApplicationFont(
        ":/assets/images/RobotoCondensed-Bold.ttf"
        );


    QString fontFamily="Arial";


    if(fontId!=-1)
    {
        QStringList families =
            QFontDatabase::applicationFontFamilies(fontId);

        if(!families.isEmpty())
            fontFamily=families.first();
    }


    auto fontR =
        [&](int pt)
    {
        return QFont(
            fontFamily,
            pt,
            QFont::Normal
            );
    };


    auto fontB =
        [&](int pt)
    {
        return QFont(
            fontFamily,
            pt,
            QFont::Bold
            );
    };




    //=========================================================
    // PAGE GEOMETRY
    //=========================================================

    const int pageW = writer.width();
    const int pageH = writer.height();


    const int marginL=40;
    const int marginR=40;
    const int marginT=20;
    const int marginB=30;


    const int contentW =
        pageW-marginL-marginR;



    auto setPen =
        [&](int w,QColor c=Qt::black)
    {
        QPen p(c);
        p.setWidth(w);
        painter.setPen(p);
    };




    //=========================================================
    // LOGO
    //=========================================================

    QString logoPath =
        QStandardPaths::writableLocation(
            QStandardPaths::DocumentsLocation
            )
        +"/Logo.png";


    QPixmap logo(logoPath);



    auto drawLogo=[&]()
    {

        if(logo.isNull())
            return;


        QRect logoRect(
            pageW-marginR-130,
            marginT,
            130,
            55
            );


        QSize scaled =
            logo.size()
                .scaled(
                    logoRect.size(),
                    Qt::KeepAspectRatio
                    );


        QRect target(
            logoRect.center().x()-scaled.width()/2,
            logoRect.center().y()-scaled.height()/2,
            scaled.width(),
            scaled.height()
            );


        painter.drawPixmap(
            target,
            logo
            );
    };



    //=========================================================
    // HEADER
    //=========================================================


    int y=marginT;


    painter.setFont(fontB(12));

    painter.drawText(
        QRect(
            marginL,
            y,
            contentW,
            22
            ),
        Qt::AlignCenter,
        companyName
        );


    y+=22;



    painter.setFont(fontB(11));

    painter.drawText(
        QRect(
            marginL,
            y,
            contentW,
            20
            ),
        Qt::AlignCenter,
        "COIL OUTPUT REPORT"
        );


    y+=20;



    painter.setFont(fontR(9));

    painter.drawText(
        QRect(
            marginL,
            y,
            contentW,
            16
            ),
        Qt::AlignCenter,
        "(Metal Detector)"
        );


    y+=16;



    drawLogo();



    setPen(2);


    painter.drawLine(
        marginL,
        y+4,
        pageW-marginR,
        y+4
        );


    y+=12;




    //=========================================================
    // MACHINE DETAILS
    //=========================================================


    int col1x=marginL;
    int col2x=marginL+contentW/3;
    int col3x=marginL+2*contentW/3;


    int metaLineH=18;



    auto drawMeta =
        [&](int x,int yy,
            QString label,
            QString value)
    {

        painter.setFont(fontB(9));

        painter.drawText(
            x,
            yy,
            label
            );


        painter.setFont(fontR(9));


        painter.drawText(
            x+78,
            yy,
            ": "+value
            );
    };



    QString now =
        QDateTime::currentDateTime()
            .toString(
                "dd/MM/yyyy @ HH:mm:ss"
                );



    drawMeta(col1x,y+metaLineH,"User",userName);

    drawMeta(col2x,y+metaLineH,"Generated",now);

    drawMeta(col3x,y+metaLineH,"Machine ID",machineId);



    drawMeta(col1x,y+2*metaLineH,"Location",location);

    drawMeta(col2x,y+2*metaLineH,"M/c Sr. No.",machineSerial);

    drawMeta(col3x,y+2*metaLineH,"M/c Type",machineType);



    y+=2*metaLineH+10;



    setPen(2);

    painter.drawLine(
        marginL,
        y+4,
        pageW-marginR,
        y+4
        );


    y+=20;



    //=========================================================
    // STAT CARDS
    //=========================================================


    painter.setFont(fontB(10));


    painter.drawText(
        marginL,
        y+12,
        "Coil Output Parameters:"
        );


    y+=20;



    int boxH=46;

    int gap=12;

    int boxW =
        (contentW-2*gap)/3;



    struct Card
    {
        QString label;
        QString value;
        QColor color;
    };



    QList<Card> cards=
        {
            {"Average",avg,QColor(26,77,181)},
            {"Minimum",min,QColor(15,138,96)},
            {"Maximum",max,QColor(214,69,69)}
        };



    int x=marginL;


    for(auto c:cards)
    {

        setPen(
            1,
            QColor(220,229,245)
            );


        painter.setBrush(
            QColor(247,249,253)
            );


        painter.drawRoundedRect(
            x,
            y,
            boxW,
            boxH,
            8,
            8
            );


        painter.setBrush(Qt::NoBrush);



        painter.setFont(fontB(9));

        setPen(1,c.color);


        painter.drawText(
            QRect(
                x+10,
                y+6,
                boxW-20,
                16
                ),
            Qt::AlignLeft,
            c.label
            );


        painter.setFont(fontB(13));


        painter.drawText(
            QRect(
                x+10,
                y+22,
                boxW-20,
                20
                ),
            Qt::AlignLeft,
            c.value
            );


        x+=boxW+gap;

    }



    y+=boxH+16;



    //=========================================================
    // FULL WIDTH GRAPH
    //=========================================================


    int footerDivY =
        pageH-marginB-28;


    int graphH =
        footerDivY-y-10;



    painter.setBrush(Qt::white);

    setPen(
        1,
        QColor(220,229,245)
        );


    painter.drawRoundedRect(
        marginL,
        y,
        contentW,
        graphH,
        10,
        10
        );



    QImage image(localImagePath);



    if(!image.isNull())
    {

        QRect avail(
            marginL+12,
            y+12,
            contentW-24,
            graphH-24
            );


        QSize scaled =
            image.size()
                .scaled(
                    avail.size(),
                    Qt::KeepAspectRatio
                    );


        QRect target(
            avail.center().x()-scaled.width()/2,
            avail.center().y()-scaled.height()/2,
            scaled.width(),
            scaled.height()
            );


        painter.drawImage(
            target,
            image
            );
    }



    //=========================================================
    // FOOTER
    //=========================================================


    int footerTextY =
        pageH-marginB-10;


    setPen(2);


    painter.drawLine(
        marginL,
        footerDivY,
        pageW-marginR,
        footerDivY
        );



    painter.setFont(fontB(9));

    setPen(1);


    painter.drawText(
        marginL,
        footerTextY,
        footerLeftStr
        );



    QString report="Coil Output Report";

    QString page="Page No: 1 / 1";



    painter.drawText(
        pageW-marginR-200,
        footerTextY,
        report
        );


    painter.drawText(
        pageW-marginR-80,
        footerTextY,
        page
        );



    painter.end();



    QFile::remove(localImagePath);



    if(QFile::exists(path))
    {
        qDebug()
        << "[Coil] PDF created:"
        << path;
    }


    return path;
}

bool PdfExporter::isPrinterAvailable()
{
    QProcess process;

    process.start(
        "lpstat",
        QStringList() << "-p"
        );

    if (!process.waitForStarted(5000)) {
        qDebug() << "Failed to start lpstat";
        return false;
    }

    if (!process.waitForFinished(5000)) {
        qDebug() << "Printer check timeout";
        return false;
    }

    QString output =
        QString::fromUtf8(
            process.readAllStandardOutput()
            );

    QString error =
        QString::fromUtf8(
            process.readAllStandardError()
            );

    qDebug() << "Available printers:";
    qDebug().noquote() << output;

    qDebug() << "Printer check error:";
    qDebug().noquote() << error;

    if (process.exitStatus() != QProcess::NormalExit) {
        qDebug() << "lpstat crashed";
        return false;
    }

    if (process.exitCode() != 0) {
        qDebug() << "lpstat failed";
        return false;
    }

    const QStringList lines =
        output.split('\n', Qt::SkipEmptyParts);

    for (const QString &line : lines) {

        /*
         Example:

         printer HP_LaserJet_P1007 is idle. enabled since ...
         printer Epson_L3150 is idle. enabled since ...
        */

        if (line.startsWith("printer ")
            && !line.contains("disabled", Qt::CaseInsensitive)) {

            return true;
        }
    }

    return false;
}

QString PdfExporter::getAvailablePrinter()
{
    QProcess process;

    process.start(
        "lpstat",
        QStringList() << "-p"
        );

    if (!process.waitForStarted(5000)) {
        qDebug() << "Failed to start lpstat";
        return QString();
    }

    if (!process.waitForFinished(5000)) {
        qDebug() << "Printer detection timeout";
        return QString();
    }

    if (process.exitStatus() != QProcess::NormalExit
        || process.exitCode() != 0) {

        qDebug() << "Failed to get printer list";
        return QString();
    }

    QString output =
        QString::fromUtf8(
            process.readAllStandardOutput()
            );

    qDebug() << "lpstat -p output:";
    qDebug().noquote() << output;

    const QStringList lines =
        output.split('\n', Qt::SkipEmptyParts);

    for (const QString &line : lines) {

        /*
         Example:

         printer HP_LaserJet_P1007 is idle. enabled since ...
        */

        if (!line.startsWith("printer "))
            continue;

        if (line.contains(
                "disabled",
                Qt::CaseInsensitive)) {
            continue;
        }

        QString printerName =
            line.section(' ', 1, 1).trimmed();

        if (!printerName.isEmpty()) {

            qDebug()
            << "Selected printer:"
            << printerName;

            return printerName;
        }
    }

    qDebug() << "No enabled printer found";

    return QString();
}

bool PdfExporter::printPdfFiles(
    const QStringList &filePaths)
{
    if (filePaths.isEmpty()) {

        qDebug()
        << "No files selected for printing";

        return false;
    }


    // =========================================================
    // VALIDATE PDF FILES
    // =========================================================

    QStringList validFiles;

    for (const QString &filePath : filePaths) {

        QFileInfo fileInfo(filePath);

        if (!fileInfo.exists()) {

            qDebug()
            << "File does not exist:"
            << filePath;

            continue;
        }

        if (fileInfo.suffix()
                .compare(
                    "pdf",
                    Qt::CaseInsensitive
                    ) != 0) {

            qDebug()
            << "Not a PDF file:"
            << filePath;

            continue;
        }

        validFiles.append(filePath);
    }


    if (validFiles.isEmpty()) {

        qDebug()
        << "No valid PDF files to print";

        return false;
    }


    // =========================================================
    // FIND AVAILABLE PRINTER
    // =========================================================

    const QString printerName =
        getAvailablePrinter();

    if (printerName.isEmpty()) {

        qDebug()
        << "No available printer found";

        return false;
    }


    qDebug()
        << "Printing to printer:"
        << printerName;


    // =========================================================
    // BUILD LP COMMAND
    // =========================================================

    QStringList arguments;

    arguments
        << "-d"
        << printerName
        << "--";

    for (const QString &filePath : validFiles) {

        arguments
            << filePath;
    }


    // =========================================================
    // SEND PRINT JOB
    // =========================================================

    QProcess process;

    process.start(
        "lp",
        arguments
        );


    if (!process.waitForStarted(5000)) {

        qDebug()
        << "Failed to start lp command";

        qDebug()
            << process.errorString();

        return false;
    }


    if (!process.waitForFinished(15000)) {

        qDebug()
        << "Printing command timeout";

        return false;
    }


    QString output =
        QString::fromUtf8(
            process.readAllStandardOutput()
            );

    QString error =
        QString::fromUtf8(
            process.readAllStandardError()
            );


    qDebug()
        << "Print output:";

    qDebug().noquote()
        << output;


    qDebug()
        << "Print error:";

    qDebug().noquote()
        << error;


    if (process.exitStatus()
        != QProcess::NormalExit) {

        qDebug()
        << "Print process crashed";

        return false;
    }


    if (process.exitCode() != 0) {

        qDebug()
        << "Print failed with exit code:"
        << process.exitCode();

        return false;
    }


    qDebug()
        << "Print job successfully submitted to:"
        << printerName;

    return true;
}
