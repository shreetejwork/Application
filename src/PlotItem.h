// MagneticFieldPlotItem.h

#pragma once

#include <QQuickPaintedItem>
#include <QVariantList>

class MagneticFieldPlotItem : public QQuickPaintedItem
{
    Q_OBJECT

    // =====================================================
    // FIELD DATA
    // =====================================================

    Q_PROPERTY(QVariantList fieldData
                   READ fieldData
                       WRITE setFieldData
                           NOTIFY fieldDataChanged)

    Q_PROPERTY(QVariantList fieldHistory
                   READ fieldHistory
                       WRITE setFieldHistory
                           NOTIFY fieldHistoryChanged)

    // =====================================================
    // SHOW / HIDE POINT LABELS
    // =====================================================

    Q_PROPERTY(bool showPointLabels
                   READ showPointLabels
                       WRITE setShowPointLabels
                           NOTIFY showPointLabelsChanged)

public:
    explicit MagneticFieldPlotItem(QQuickItem *parent = nullptr);

    void paint(QPainter *painter) override;

    // =====================================================
    // FIELD DATA
    // =====================================================

    QVariantList fieldData() const;
    void setFieldData(const QVariantList &data);

    QVariantList fieldHistory() const;
    void setFieldHistory(const QVariantList &history);

    // =====================================================
    // POINT LABELS
    // =====================================================

    bool showPointLabels() const;
    void setShowPointLabels(bool value);

signals:
    void fieldDataChanged();

    void fieldHistoryChanged();

    void showPointLabelsChanged();

private:
    // =====================================================
    // DATA STORAGE
    // =====================================================

    QVariantList m_fieldData;

    QVariantList m_fieldHistory;

    // =====================================================
    // LABEL VISIBILITY
    // =====================================================

    bool m_showPointLabels = true;
};
