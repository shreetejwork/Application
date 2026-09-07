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

    for (int i = 0; i <= 8; ++i) {

        qreal y = r.top() + (r.height() / 8.0) * i;

        painter->drawLine(
            QPointF(r.left(), y),
            QPointF(r.right(), y)
            );
    }

    // =====================================================
    // AXIS
    // =====================================================

    QPointF center(
        r.width() / 2.0,
        r.height() / 2.0
        );

    qreal axisX = r.width() * 0.42;
    qreal axisY = r.height() * 0.40;

    QPen axisPen(QColor("#111111"));
    axisPen.setWidthF(3);

    painter->setPen(axisPen);

    painter->drawLine(
        QPointF(center.x() - axisX, center.y()),
        QPointF(center.x() + axisX, center.y())
        );

    painter->drawLine(
        QPointF(center.x(), center.y() - axisY),
        QPointF(center.x(), center.y() + axisY)
        );

    // =====================================================
    // LABELS
    // =====================================================

    QFont labelFont;
    labelFont.setPixelSize(20);
    labelFont.setBold(true);

    painter->setFont(labelFont);
    painter->setPen(QColor("#111111"));

    painter->drawText(
        QPointF(center.x() + axisX + 12,
                center.y() + 8),
        "X"
        );

    painter->drawText(
        QPointF(center.x() - axisX - 42,
                center.y() + 8),
        "-X"
        );

    painter->drawText(
        QPointF(center.x() + 10,
                center.y() - axisY - 14),
        "Y"
        );

    painter->drawText(
        QPointF(center.x() + 10,
                center.y() + axisY + 28),
        "-Y"
        );

    const QVariantList traces = m_fieldHistory.isEmpty()
                                    ? QVariantList{m_fieldData}
                                    : m_fieldHistory;

    if (traces.isEmpty() || traces.first().toList().isEmpty())
        return;

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
                center.x() + (xValue / 100.0) * axisX,
                center.y() - (yValue / 100.0) * axisY);

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

        for (int i = 0; i < points.size(); ++i) {
            const QPointF p = points[i];
            const QVariantMap pointMap = trace[i].toMap();

        // =============================================
        // OPTIONAL LABELS
        // =============================================

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
