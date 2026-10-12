// MagneticFieldPlotItem.cpp

#include "PlotItem.h"

#include <QFont>
#include <QFontMetrics>
#include <QPainter>
#include <QPainterPath>

MagneticFieldPlotItem::MagneticFieldPlotItem(QQuickItem *parent)
    : QQuickPaintedItem(parent)
{
    setAntialiasing(true);
}

// =====================================================
// FIELD DATA
// =====================================================

QVariantList MagneticFieldPlotItem::fieldData() const
{
    return m_fieldData;
}

void MagneticFieldPlotItem::setFieldData(const QVariantList &data)
{
    m_fieldData = data;

    emit fieldDataChanged();

    update();
}

QVariantList MagneticFieldPlotItem::fieldHistory() const
{
    return m_fieldHistory;
}

void MagneticFieldPlotItem::setFieldHistory(const QVariantList &history)
{
    if (m_fieldHistory == history)
        return;

    m_fieldHistory = history;

    emit fieldHistoryChanged();

    update();
}

// =====================================================
// SHOW LABELS
// =====================================================

bool MagneticFieldPlotItem::showPointLabels() const
{
    return m_showPointLabels;
}

void MagneticFieldPlotItem::setShowPointLabels(bool value)
{
    if (m_showPointLabels == value)
        return;

    m_showPointLabels = value;

    emit showPointLabelsChanged();

    update();
}

// =====================================================
// PAINT
// =====================================================

void MagneticFieldPlotItem::paint(QPainter *painter)
{
    painter->setRenderHint(QPainter::Antialiasing, true);

    QRectF r = boundingRect();

    painter->fillRect(r, QColor("#FBFCFF"));

    // =====================================================
    // GRID
    // =====================================================

    QPen gridPen(QColor("#EDF2FA"));
    gridPen.setWidthF(1);

    painter->setPen(gridPen);

    for (int i = 0; i <= 10; ++i) {

        qreal x = r.left() + (r.width() / 10.0) * i;

        painter->drawLine(
            QPointF(x, r.top()),
            QPointF(x, r.bottom())
            );
    }

    for (int i = 0; i <= 10; ++i) {

        qreal y = r.top() + (r.height() / 10.0) * i;

        painter->drawLine(
            QPointF(r.left(), y),
            QPointF(r.right(), y)
            );
    }

    const QVariantList traces = m_fieldHistory.isEmpty()
                                    ? QVariantList{m_fieldData}
                                    : m_fieldHistory;
    qreal minX = 0;
    qreal maxX = 0;
    qreal minY = 0;
    qreal maxY = 0;
    bool hasPoint = false;
    for (const QVariant &traceValue : traces) {
        for (const QVariant &pointValue : traceValue.toList()) {
            const QVariantMap point = pointValue.toMap();
            const qreal x = point.value(QStringLiteral("x")).toReal();
            const qreal y = point.value(QStringLiteral("y")).toReal();
            if (!hasPoint) {
                minX = maxX = x;
                minY = maxY = y;
                hasPoint = true;
            } else {
                minX = qMin(minX, x);
                maxX = qMax(maxX, x);
                minY = qMin(minY, y);
                maxY = qMax(maxY, y);
            }
        }
    }
    const qreal xLimit = hasPoint
            ? qMax(qMax(qAbs(minX), qAbs(maxX)) * 1.08, qreal(0.001)) : 100.0;
    const qreal yLimit = hasPoint
            ? qMax(qMax(qAbs(minY), qAbs(maxY)) * 1.08, qreal(0.001)) : 100.0;

    // =====================================================
    // AXIS
    // =====================================================

    QPointF center(
        r.width() / 2.0,
        r.height() / 2.0
        );

    qreal axisX = r.width() * 0.42;
    qreal axisY = r.height() * 0.42;

    QPen axisPen(QColor("#334155"));
    axisPen.setWidthF(qMax(1.8, r.width() * 0.003));

    painter->setPen(axisPen);

    painter->drawLine(
        QPointF(center.x() - axisX, center.y()),
        QPointF(center.x() + axisX, center.y())
        );

    painter->drawLine(
        QPointF(center.x(), center.y() - axisY),
        QPointF(center.x(), center.y() + axisY)
        );

    QFont tickFont;
    tickFont.setPixelSize(qBound(12, qRound(r.width() * 0.024), 17));
    painter->setFont(tickFont);
    painter->setPen(QColor("#526174"));
    for (int tick = 0; tick <= 4; ++tick) {
        const qreal fraction = (tick - 2) / 2.0;
        const qreal x = center.x() + fraction * axisX;
        const qreal y = center.y() - fraction * axisY;
        const QString xLabel = QString::number(fraction * xLimit, 'g', 2);
        const QString yLabel = QString::number(fraction * yLimit, 'g', 2);
        painter->drawText(QRectF(x - 34, center.y() + 7, 68, 20),
                          Qt::AlignHCenter | Qt::AlignTop, xLabel);
        painter->drawText(QRectF(center.x() - 48, y - 10, 40, 20),
                          Qt::AlignRight | Qt::AlignVCenter, yLabel);
    }

    QFont labelFont;
    labelFont.setPixelSize(qBound(14, qRound(r.width() * 0.03), 20));
    labelFont.setBold(true);
    painter->setFont(labelFont);
    painter->setPen(QColor("#1A4DB5"));
    painter->drawText(QPointF(center.x() + axisX + 8, center.y() + 5), "X");
    painter->drawText(QPointF(center.x() - axisX - 22, center.y() + 5), "-X");
    painter->drawText(QPointF(center.x() + 6, center.y() - axisY - 8), "Y");
    painter->drawText(QPointF(center.x() + 6, center.y() + axisY + 20), "-Y");

    // =====================================================
    // CURVE
    // =====================================================

    QPen curvePen(QColor("#3B6FD8"));
    curvePen.setWidthF(4);
    curvePen.setCapStyle(Qt::RoundCap);
    curvePen.setJoinStyle(Qt::RoundJoin);

    painter->setPen(curvePen);

    QVector<QVector<QPointF>> tracePoints;

    for (const QVariant &traceValue : traces) {
        const QVariantList trace = traceValue.toList();
        if (trace.isEmpty())
            continue;

        QPainterPath curvePath;
        QVector<QPointF> points;

        for (const QVariant &v : trace) {
            const QVariantMap pointMap = v.toMap();
            const qreal xValue = pointMap["x"].toReal();
            const qreal yValue = pointMap["y"].toReal();
            const QPointF point(
                center.x() + (xValue / xLimit) * axisX,
                center.y() - (yValue / yLimit) * axisY);

            points.append(point);
            if (points.size() == 1)
                curvePath.moveTo(point);
            else
                curvePath.lineTo(point);
        }

        painter->drawPath(curvePath);
        tracePoints.append(points);
    }

    // =====================================================
    // POINTS
    // =====================================================

    QFont valueFont;
    valueFont.setPixelSize(13);
    valueFont.setBold(true);

    painter->setFont(valueFont);

    for (int traceIndex = 0; traceIndex < tracePoints.size(); ++traceIndex) {
        const QVariantList trace = traces[traceIndex].toList();
        const QVector<QPointF> &points = tracePoints[traceIndex];
        const int markerStride = qMax(1, (points.size() + 99) / 100);

        for (int i = 0; i < points.size(); ++i) {
            const QPointF p = points[i];
            const QVariantMap pointMap = trace[i].toMap();

            if (i % markerStride != 0)
                continue;

            if (m_showPointLabels) {

                QString valueText =
                QString("(%1, %2)")
                    .arg(pointMap["x"].toInt())
                    .arg(pointMap["y"].toInt());

                QFontMetrics fm(valueFont);

                QRect textRect =
                fm.boundingRect(valueText);

                QRectF valueBox(
                p.x() - textRect.width()/2.0 - 12,
                p.y() - 42,
                textRect.width() + 24,
                28
                );

                painter->setPen(Qt::NoPen);
                painter->setBrush(QColor("#1B365D"));

                painter->drawRoundedRect(
                valueBox,
                8,
                8
                );

                painter->setPen(Qt::white);

                painter->drawText(
                valueBox,
                Qt::AlignCenter,
                valueText
                );
            }

        // =============================================
        // POINT
        // =============================================

            painter->setPen(QPen(Qt::white, 3));
            painter->setBrush(QColor("#3B6FD8"));

            painter->drawEllipse(p, 4, 4);
        }
    }
}
