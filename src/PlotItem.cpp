// MagneticFieldPlotItem.cpp

#include "PlotItem.h"

#include <QFont>
#include <QFontMetrics>
#include <QPainter>
#include <QPainterPath>
#include <QColor>

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

QVariantList MagneticFieldPlotItem::axisData() const
{
    return m_axisData;
}

void MagneticFieldPlotItem::setAxisData(const QVariantList &data)
{
    if (m_axisData == data)
        return;

    m_axisData = data;
    emit axisDataChanged();
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

    struct PlotTrace {
        QVariantList points;
        QColor color;
    };
    const QColor traceColors[] = {
        QColor("#1A4DB5"),
        QColor("#D64545"),
        QColor("#0F8A60"),
        QColor("#8B5CF6"),
        QColor("#E58A00")
    };
    const QVariantList traceValues = m_fieldHistory.isEmpty()
                                         ? QVariantList{m_fieldData}
                                         : m_fieldHistory;
    QVector<PlotTrace> traces;
    traces.reserve(traceValues.size());
    qreal xLimit = 0;
    qreal yLimit = 0;
    for (int traceIndex = 0; traceIndex < traceValues.size(); ++traceIndex) {
        const QVariant traceValue = traceValues.at(traceIndex);
        const QVariantMap traceMap = traceValue.toMap();
        const QVariantList points = traceMap.contains(QStringLiteral("points"))
                                        ? traceMap.value(QStringLiteral("points")).toList()
                                        : traceValue.toList();
        const QColor color = traceMap.contains(QStringLiteral("color"))
                                 ? QColor(traceMap.value(QStringLiteral("color")).toString())
                                 : traceColors[traceIndex % 5];
        traces.append({points, color.isValid()
                                   ? color
                                   : traceColors[traceIndex % 5]});
        for (const QVariant &pointValue : points) {
            const QVariantMap point = pointValue.toMap();
            const qreal x = point.value(QStringLiteral("x")).toReal();
            const qreal y = point.value(QStringLiteral("y")).toReal();
            xLimit = qMax(xLimit, qAbs(x));
            yLimit = qMax(yLimit, qAbs(y));
        }
    }
    for (const QVariant &pointValue : m_axisData) {
        const QVariantMap point = pointValue.toMap();
        xLimit = qMax(xLimit, qAbs(point.value(QStringLiteral("x")).toReal()));
        yLimit = qMax(yLimit, qAbs(point.value(QStringLiteral("y")).toReal()));
    }
    xLimit = qBound(qreal(1), xLimit, qreal(10000));
    yLimit = qBound(qreal(1), yLimit, qreal(10000));

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
        const QString xLabel = QString::number(qRound(fraction * xLimit));
        const QString yLabel = QString::number(qRound(fraction * yLimit));
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

    QVector<QVector<QPointF>> tracePoints;
    QVector<QVariantList> pointTraces;
    painter->save();
    painter->setClipRect(QRectF(center.x() - axisX,
                                center.y() - axisY,
                                axisX * 2,
                                axisY * 2));

    for (const PlotTrace &plotTrace : traces) {
        const QVariantList &trace = plotTrace.points;
        if (trace.isEmpty())
            continue;

        QPen curvePen(plotTrace.color);
        curvePen.setWidthF(1.0);
        curvePen.setCapStyle(Qt::RoundCap);
        curvePen.setJoinStyle(Qt::RoundJoin);
        painter->setPen(curvePen);

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
        pointTraces.append(trace);
    }
    painter->restore();

    // =====================================================
    // POINTS
    // =====================================================

    QFont valueFont;
    valueFont.setPixelSize(13);
    valueFont.setBold(true);

    painter->setFont(valueFont);

    for (int traceIndex = 0; traceIndex < tracePoints.size(); ++traceIndex) {
        if (!m_showPointLabels)
            continue;

        const QVariantList &trace = pointTraces[traceIndex];
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
            painter->setBrush(traces[traceIndex].color);

            painter->drawEllipse(p, 4, 4);
        }
    }
}
