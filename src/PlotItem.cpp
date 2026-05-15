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

    if (m_fieldData.isEmpty())
        return;

    // =====================================================
    // CURVE
    // =====================================================

    QVector<QPointF> points;

    QPainterPath curvePath;

    bool firstPoint = true;

    for (const QVariant &v : m_fieldData) {

        QVariantMap pointMap = v.toMap();

        qreal xValue = pointMap["x"].toReal();
        qreal yValue = pointMap["y"].toReal();

        qreal px =
            center.x()
            + (xValue / 100.0) * axisX;

        qreal py =
            center.y()
            - (yValue / 100.0) * axisY;

        QPointF point(px, py);

        points.append(point);

        if (firstPoint) {

            curvePath.moveTo(point);

            firstPoint = false;

        } else {

            curvePath.lineTo(point);
        }
    }

    QPen curvePen(QColor("#3B6FD8"));
    curvePen.setWidthF(4);
    curvePen.setCapStyle(Qt::RoundCap);
    curvePen.setJoinStyle(Qt::RoundJoin);

    painter->setPen(curvePen);

    painter->drawPath(curvePath);

    // =====================================================
    // POINTS
    // =====================================================

    QFont valueFont;
    valueFont.setPixelSize(13);
    valueFont.setBold(true);

    painter->setFont(valueFont);

    for (int i = 0; i < points.size(); ++i) {

        QPointF p = points[i];

        QVariantMap pointMap =
            m_fieldData[i].toMap();

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

        painter->drawEllipse(
            p,
            8,
            8
            );
    }
}
