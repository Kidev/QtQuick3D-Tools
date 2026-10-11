#ifndef SPATIALITEM_H
#define SPATIALITEM_H

#include <QtCore/QList>
#include <QtCore/QPointer>
#include <QtGui/QVector2D>
#include <QtGui/QVector3D>
#include <QtQml/QQmlListProperty>
#include <QtQml/qqmlregistration.h>
#include <QtQuick/QQuickItem>
#include <QtQuick/private/qquickmousearea_p.h>
#include <QtQuick3D/private/qquick3dcamera_p.h>
#include <QtQuick3D/private/qquick3dmodel_p.h>
#include <QtQuick3D/private/qquick3dviewport_p.h>

#include <optional>

class QQuickMouseEvent;
class QQuickPathLine;
class QQuickShape;
class QQuickShapePath;

class SpatialItem : public QQuickItem
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QQuick3DViewport *view READ view WRITE setView NOTIFY viewChanged REQUIRED FINAL)
    Q_PROPERTY(QQuick3DModel *target READ target WRITE setTarget NOTIFY targetChanged REQUIRED FINAL)
    Q_PROPERTY(QSizeF size READ size WRITE setSize NOTIFY sizeChanged REQUIRED FINAL)

    Q_PROPERTY(QQmlListProperty<QObject> contentData READ contentData FINAL)
    Q_PROPERTY(QQmlListProperty<QObject> linker READ linker FINAL)
    Q_PROPERTY(bool closeUpScaling READ closeUpScaling WRITE setCloseUpScaling NOTIFY closeUpScalingChanged FINAL)
    Q_PROPERTY(int cursor READ cursorShape WRITE setCursorShape NOTIFY cursorChanged FINAL)
    Q_PROPERTY(bool depthTest READ depthTest WRITE setDepthTest NOTIFY depthTestChanged FINAL)
    Q_PROPERTY(bool fixedSize READ fixedSize WRITE setFixedSize NOTIFY fixedSizeChanged FINAL)
    Q_PROPERTY(bool forceTopStacking READ forceTopStacking WRITE setForceTopStacking NOTIFY forceTopStackingChanged FINAL)
    Q_PROPERTY(bool holdDragsTarget READ holdDragsTarget WRITE setHoldDragsTarget NOTIFY holdDragsTargetChanged FINAL)
    Q_PROPERTY(bool hoverEnabled READ hoverEnabled WRITE setHoverEnabled NOTIFY hoverEnabledChanged FINAL)
    Q_PROPERTY(bool mouseEnabled READ mouseEnabled WRITE setMouseEnabled NOTIFY mouseEnabledChanged FINAL)
    Q_PROPERTY(bool mouseLinkerEnabled READ mouseLinkerEnabled WRITE setMouseLinkerEnabled NOTIFY mouseLinkerEnabledChanged FINAL)
    Q_PROPERTY(QVector3D offsetLinkEnd READ offsetLinkEnd WRITE setOffsetLinkEnd NOTIFY offsetLinkEndChanged FINAL)
    Q_PROPERTY(QVector2D offsetLinkEnd2D READ offsetLinkEnd2D WRITE setOffsetLinkEnd2D NOTIFY offsetLinkEnd2DChanged FINAL)
    Q_PROPERTY(QVector3D offsetLinkStart READ offsetLinkStart WRITE setOffsetLinkStart NOTIFY offsetLinkStartChanged FINAL)
    Q_PROPERTY(QVector2D offsetLinkStart2D READ offsetLinkStart2D WRITE setOffsetLinkStart2D NOTIFY offsetLinkStart2DChanged FINAL)
    Q_PROPERTY(bool showDraggingLine READ showDraggingLine WRITE setShowDraggingLine NOTIFY showDraggingLineChanged FINAL)
    Q_PROPERTY(bool showLinker READ showLinker WRITE setShowLinker NOTIFY showLinkerChanged FINAL)
    Q_PROPERTY(int stackingOrder READ stackingOrder WRITE setStackingOrder NOTIFY stackingOrderChanged FINAL)
    Q_PROPERTY(int stackingOrderLinker READ stackingOrderLinker WRITE setStackingOrderLinker NOTIFY stackingOrderLinkerChanged FINAL)

    Q_PROPERTY(QQuick3DCamera *camera READ camera NOTIFY cameraChanged FINAL)
    Q_PROPERTY(QQuickItem *contentItem READ contentItem CONSTANT FINAL)
    Q_PROPERTY(QVector2D coords READ coords NOTIFY coordsChanged FINAL)
    Q_PROPERTY(qreal distance READ distance NOTIFY distanceChanged FINAL)
    Q_PROPERTY(bool dragging READ dragging NOTIFY draggingChanged FINAL)
    Q_PROPERTY(bool hovered READ hovered NOTIFY hoveredChanged FINAL)
    Q_PROPERTY(QVector2D linkerEnd READ linkerEnd NOTIFY linkerEndChanged FINAL)
    Q_PROPERTY(QVector2D linkerStart READ linkerStart NOTIFY linkerStartChanged FINAL)
    Q_PROPERTY(QQuickMouseArea *mouseArea READ mouseArea CONSTANT FINAL)
    Q_PROPERTY(QQuickMouseArea *mouseAreaLinker READ mouseAreaLinker CONSTANT FINAL)
    Q_PROPERTY(qreal scaleFactor READ scaleFactor NOTIFY scaleFactorChanged FINAL)
    Q_PROPERTY(QVector2D screenTargetCenterBase READ screenTargetCenterBase NOTIFY screenTargetCenterBaseChanged FINAL)
    Q_PROPERTY(QVector2D screenTargetOffsetedCenterBase READ screenTargetOffsetedCenterBase NOTIFY
                   screenTargetOffsetedCenterBaseChanged FINAL)
    Q_PROPERTY(QVector2D screenTargetOffsetedCenterTop READ screenTargetOffsetedCenterTop NOTIFY
                   screenTargetOffsetedCenterTopChanged FINAL)
    Q_PROPERTY(QVector3D targetCenterBase READ targetCenterBase NOTIFY targetCenterBaseChanged FINAL)
    Q_PROPERTY(QVector3D targetCenterTop READ targetCenterTop NOTIFY targetCenterTopChanged FINAL)

    Q_CLASSINFO("DefaultProperty", "contentData")

public:
    explicit SpatialItem(QQuickItem *parent = nullptr);
    ~SpatialItem() override;

    QQuick3DViewport *view() const;
    void setView(QQuick3DViewport *view);

    QQuick3DModel *target() const;
    void setTarget(QQuick3DModel *target);

    QQmlListProperty<QObject> contentData();
    QQmlListProperty<QObject> linker();

    bool closeUpScaling() const;
    void setCloseUpScaling(bool closeUpScaling);

    int cursorShape() const;
    void setCursorShape(int cursorShape);

    bool depthTest() const;
    void setDepthTest(bool depthTest);

    bool fixedSize() const;
    void setFixedSize(bool fixedSize);

    bool forceTopStacking() const;
    void setForceTopStacking(bool forceTopStacking);

    bool holdDragsTarget() const;
    void setHoldDragsTarget(bool holdDragsTarget);

    bool hoverEnabled() const;
    void setHoverEnabled(bool hoverEnabled);

    bool mouseEnabled() const;
    void setMouseEnabled(bool mouseEnabled);

    bool mouseLinkerEnabled() const;
    void setMouseLinkerEnabled(bool mouseLinkerEnabled);

    QVector3D offsetLinkEnd() const;
    void setOffsetLinkEnd(const QVector3D &offsetLinkEnd);

    QVector2D offsetLinkEnd2D() const;
    void setOffsetLinkEnd2D(const QVector2D &offsetLinkEnd2D);

    QVector3D offsetLinkStart() const;
    void setOffsetLinkStart(const QVector3D &offsetLinkStart);

    QVector2D offsetLinkStart2D() const;
    void setOffsetLinkStart2D(const QVector2D &offsetLinkStart2D);

    bool showDraggingLine() const;
    void setShowDraggingLine(bool showDraggingLine);

    bool showLinker() const;
    void setShowLinker(bool showLinker);

    int stackingOrder() const;
    void setStackingOrder(int stackingOrder);

    int stackingOrderLinker() const;
    void setStackingOrderLinker(int stackingOrderLinker);

    QQuick3DCamera *camera() const;
    QQuickItem *contentItem() const;
    QVector2D coords() const;
    qreal distance() const;
    bool dragging() const;
    bool hovered() const;
    QVector2D linkerEnd() const;
    QVector2D linkerStart() const;
    QQuickMouseArea *mouseArea() const;
    QQuickMouseArea *mouseAreaLinker() const;
    qreal scaleFactor() const;
    QVector2D screenTargetCenterBase() const;
    QVector2D screenTargetOffsetedCenterBase() const;
    QVector2D screenTargetOffsetedCenterTop() const;
    QVector3D targetCenterBase() const;
    QVector3D targetCenterTop() const;

Q_SIGNALS:
    void viewChanged();
    void targetChanged();
    void sizeChanged();
    void closeUpScalingChanged();
    void cursorChanged();
    void depthTestChanged();
    void fixedSizeChanged();
    void forceTopStackingChanged();
    void holdDragsTargetChanged();
    void hoverEnabledChanged();
    void mouseEnabledChanged();
    void mouseLinkerEnabledChanged();
    void offsetLinkEndChanged();
    void offsetLinkEnd2DChanged();
    void offsetLinkStartChanged();
    void offsetLinkStart2DChanged();
    void showDraggingLineChanged();
    void showLinkerChanged();
    void stackingOrderChanged();
    void stackingOrderLinkerChanged();
    void cameraChanged();
    void coordsChanged();
    void distanceChanged();
    void draggingChanged();
    void hoveredChanged();
    void linkerEndChanged();
    void linkerStartChanged();
    void scaleFactorChanged();
    void screenTargetCenterBaseChanged();
    void screenTargetOffsetedCenterBaseChanged();
    void screenTargetOffsetedCenterTopChanged();
    void targetCenterBaseChanged();
    void targetCenterTopChanged();

    void entered();
    void exited();

protected:
    void componentComplete() override;
    void geometryChange(const QRectF &newGeometry, const QRectF &oldGeometry) override;
    void itemChange(ItemChange change, const ItemChangeData &value) override;

private:
    static constexpr int ZOffset{1000000000};
    static constexpr float OffscreenCoordinate{-10000.0f};

    void connectView();
    void connectCamera();
    void connectCameraParent();
    void connectTarget();
    void connectWindow();
    static void disconnectAll(QList<QMetaObject::Connection> &connections);

    void scheduleUpdate();
    void updateUIPosition();
    void updateScale();
    void updateStacking();
    void updateLayout();
    void updateLinkerLayer();
    void updateCursor();
    void updateHovered();
    void updateMouseLinkerEnabled();
    void updateDraggingLineVisible();
    void setDragging(bool dragging);
    void emitTargetCentersChanged();

    void onMousePressed(QQuickMouseEvent *mouse);
    void onMousePositionChanged(QQuickMouseEvent *mouse);
    void onMouseReleased();

    QVector2D projectToView(const QVector3D &scenePosition) const;
    std::optional<QVector3D> projectOnDragPlane(const QVector2D &viewPosition) const;
    QVector3D targetCenterBaseOffseted() const;
    QVector3D targetCenterTopOffseted() const;

    QPointer<QQuick3DViewport> m_view;
    QPointer<QQuick3DModel> m_target;
    QPointer<QQuick3DCamera> m_camera;

    QList<QMetaObject::Connection> m_viewConnections;
    QList<QMetaObject::Connection> m_cameraConnections;
    QList<QMetaObject::Connection> m_cameraParentConnections;
    QList<QMetaObject::Connection> m_targetConnections;
    QList<QMetaObject::Connection> m_windowConnections;

    QQuickItem *m_overlay{nullptr};
    QQuickItem *m_contentItem{nullptr};
    QQuickMouseArea *m_mouseArea{nullptr};
    QQuickItem *m_linkerLayer{nullptr};
    QQuickShape *m_linkerShape{nullptr};
    QQuickMouseArea *m_linkerMouseArea{nullptr};
    QQuickShape *m_draggingLineShape{nullptr};
    QQuickShapePath *m_draggingLinePath{nullptr};
    QQuickPathLine *m_draggingLineEnd{nullptr};

    bool m_closeUpScaling{false};
    int m_cursorShape{Qt::ArrowCursor};
    bool m_depthTest{false};
    bool m_fixedSize{false};
    bool m_forceTopStacking{false};
    bool m_holdDragsTarget{false};
    bool m_hoverEnabled{false};
    bool m_mouseEnabled{false};
    bool m_mouseLinkerEnabled{false};
    QVector3D m_offsetLinkEnd;
    QVector2D m_offsetLinkEnd2D;
    QVector3D m_offsetLinkStart;
    QVector2D m_offsetLinkStart2D;
    bool m_showDraggingLine{false};
    bool m_showLinker{false};
    int m_stackingOrder{0};
    int m_stackingOrderLinker{-1};

    qreal m_distance{0.0};
    qreal m_scaleFactor{1.0};
    bool m_dragging{false};
    bool m_dragMoved{false};
    bool m_hovered{false};
    bool m_updateScheduled{false};
    bool m_firstFrameSeen{false};
    QVector2D m_screenTargetCenterBase;
    QVector2D m_screenTargetOffsetedCenterBase;
    QVector2D m_screenTargetOffsetedCenterTop;
    QVector2D m_screenInitialTargetCenterBase;
    QVector3D m_initialTargetPosition;
    QVector3D m_grabOffset;
    float m_dragPlaneHeight{0.0f};
};

#endif // SPATIALITEM_H
