#include "spatialitem.h"

#include <QtCore/QtMath>
#include <QtQuick/QQuickWindow>
#include <QtQuick/private/qquickevents_p_p.h>
#include <QtQuick/private/qquickitem_p.h>
#include <QtQuick/private/qquickpath_p.h>
#include <QtQuick3D/private/qquick3dorthographiccamera_p.h>
#include <QtQuick3D/private/qquick3dperspectivecamera_p.h>
#include <QtQuickShapes/private/qquickshape_p.h>

#include <cmath>

SpatialItem::SpatialItem(QQuickItem *parent)
    : QQuickItem{parent}
{
    // The overlay content, scaled around its center and centered on coords.
    m_overlay = new QQuickItem{this};
    m_overlay->setTransformOrigin(QQuickItem::Center);

    m_contentItem = new QQuickItem{m_overlay};

    m_mouseArea = new QQuickMouseArea{m_overlay};
    m_mouseArea->setEnabled(m_mouseEnabled);
    m_mouseArea->setHoverEnabled(m_hoverEnabled);
    connect(m_mouseArea, &QQuickMouseArea::hoveredChanged, this, &SpatialItem::updateHovered);
    connect(m_mouseArea, &QQuickMouseArea::pressed, this, &SpatialItem::onMousePressed);
    connect(m_mouseArea, &QQuickMouseArea::positionChanged, this, &SpatialItem::onMousePositionChanged);
    connect(m_mouseArea, &QQuickMouseArea::released, this, &SpatialItem::onMouseReleased);
    connect(m_mouseArea, &QQuickMouseArea::canceled, this, &SpatialItem::onMouseReleased);

    // The linker and the dragging line, unscaled, in View3D coordinates. Children of this item, so they stack with
    // the overlay.
    m_linkerLayer = new QQuickItem{this};
    m_linkerLayer->setZ(static_cast<qreal>(m_stackingOrderLinker));

    m_linkerShape = new QQuickShape{m_linkerLayer};
    m_linkerShape->setContainsMode(QQuickShape::FillContains);
    m_linkerShape->setVisible(m_showLinker);

    m_linkerMouseArea = new QQuickMouseArea{m_linkerLayer};
    m_linkerMouseArea->setContainmentMask(m_linkerShape);
    m_linkerMouseArea->setHoverEnabled(m_hoverEnabled);
    connect(m_linkerMouseArea, &QQuickMouseArea::hoveredChanged, this, &SpatialItem::updateHovered);

    m_draggingLineShape = new QQuickShape{m_linkerLayer};
    m_draggingLinePath = new QQuickShapePath{m_draggingLineShape};
    m_draggingLinePath->setCapStyle(QQuickShapePath::RoundCap);
    m_draggingLinePath->setJoinStyle(QQuickShapePath::BevelJoin);
    m_draggingLinePath->setStrokeColor(QColor{Qt::green});
    m_draggingLinePath->setStrokeWidth(3.0);
    m_draggingLineEnd = new QQuickPathLine{m_draggingLinePath};
    QQmlListProperty<QQuickPathElement> pathElements{m_draggingLinePath->pathElements()};
    pathElements.append(&pathElements, m_draggingLineEnd);
    QQmlListProperty<QObject> shapeData{m_draggingLineShape->data()};
    shapeData.append(&shapeData, m_draggingLinePath);

    updateMouseLinkerEnabled();
    updateDraggingLineVisible();
    updateCursor();
    updateStacking();
}

SpatialItem::~SpatialItem()
{
    // The base class destructor unparents the mouse areas, which may emit hoveredChanged: drop those connections
    // while this object is still whole.
    m_mouseArea->disconnect(this);
    m_linkerMouseArea->disconnect(this);
    disconnectAll(m_viewConnections);
    disconnectAll(m_cameraConnections);
    disconnectAll(m_cameraParentConnections);
    disconnectAll(m_targetConnections);
    disconnectAll(m_windowConnections);
}

QQuick3DViewport *SpatialItem::view() const
{
    return m_view;
}

void SpatialItem::setView(QQuick3DViewport *view)
{
    if (m_view == view) {
        return;
    }
    m_view = view;
    if (isComponentComplete()) {
        connectView();
    }
    emit viewChanged();
}

QQuick3DModel *SpatialItem::target() const
{
    return m_target;
}

void SpatialItem::setTarget(QQuick3DModel *target)
{
    if (m_target == target) {
        return;
    }
    m_target = target;
    if (isComponentComplete()) {
        connectTarget();
    }
    emit targetChanged();
}

QQmlListProperty<QObject> SpatialItem::contentData()
{
    return QQuickItemPrivate::get(m_contentItem)->data();
}

QQmlListProperty<QObject> SpatialItem::linker()
{
    return m_linkerShape->data();
}

bool SpatialItem::closeUpScaling() const
{
    return m_closeUpScaling;
}

void SpatialItem::setCloseUpScaling(bool closeUpScaling)
{
    if (m_closeUpScaling == closeUpScaling) {
        return;
    }
    m_closeUpScaling = closeUpScaling;
    updateScale();
    emit closeUpScalingChanged();
}

int SpatialItem::cursorShape() const
{
    return m_cursorShape;
}

void SpatialItem::setCursorShape(int cursorShape)
{
    if (m_cursorShape == cursorShape) {
        return;
    }
    m_cursorShape = cursorShape;
    updateCursor();
    emit cursorChanged();
}

bool SpatialItem::depthTest() const
{
    return m_depthTest;
}

void SpatialItem::setDepthTest(bool depthTest)
{
    if (m_depthTest == depthTest) {
        return;
    }
    m_depthTest = depthTest;
    updateStacking();
    emit depthTestChanged();
}

bool SpatialItem::fixedSize() const
{
    return m_fixedSize;
}

void SpatialItem::setFixedSize(bool fixedSize)
{
    if (m_fixedSize == fixedSize) {
        return;
    }
    m_fixedSize = fixedSize;
    updateScale();
    emit fixedSizeChanged();
}

bool SpatialItem::forceTopStacking() const
{
    return m_forceTopStacking;
}

void SpatialItem::setForceTopStacking(bool forceTopStacking)
{
    if (m_forceTopStacking == forceTopStacking) {
        return;
    }
    m_forceTopStacking = forceTopStacking;
    updateStacking();
    emit forceTopStackingChanged();
}

bool SpatialItem::holdDragsTarget() const
{
    return m_holdDragsTarget;
}

void SpatialItem::setHoldDragsTarget(bool holdDragsTarget)
{
    if (m_holdDragsTarget == holdDragsTarget) {
        return;
    }
    m_holdDragsTarget = holdDragsTarget;
    updateCursor();
    emit holdDragsTargetChanged();
}

bool SpatialItem::hoverEnabled() const
{
    return m_hoverEnabled;
}

void SpatialItem::setHoverEnabled(bool hoverEnabled)
{
    if (m_hoverEnabled == hoverEnabled) {
        return;
    }
    m_hoverEnabled = hoverEnabled;
    m_mouseArea->setHoverEnabled(m_hoverEnabled);
    m_linkerMouseArea->setHoverEnabled(m_hoverEnabled);
    emit hoverEnabledChanged();
}

bool SpatialItem::mouseEnabled() const
{
    return m_mouseEnabled;
}

void SpatialItem::setMouseEnabled(bool mouseEnabled)
{
    if (m_mouseEnabled == mouseEnabled) {
        return;
    }
    m_mouseEnabled = mouseEnabled;
    m_mouseArea->setEnabled(m_mouseEnabled);
    emit mouseEnabledChanged();
}

bool SpatialItem::mouseLinkerEnabled() const
{
    return m_mouseLinkerEnabled;
}

void SpatialItem::setMouseLinkerEnabled(bool mouseLinkerEnabled)
{
    if (m_mouseLinkerEnabled == mouseLinkerEnabled) {
        return;
    }
    m_mouseLinkerEnabled = mouseLinkerEnabled;
    updateMouseLinkerEnabled();
    emit mouseLinkerEnabledChanged();
}

QVector3D SpatialItem::offsetLinkEnd() const
{
    return m_offsetLinkEnd;
}

void SpatialItem::setOffsetLinkEnd(const QVector3D &offsetLinkEnd)
{
    if (m_offsetLinkEnd == offsetLinkEnd) {
        return;
    }
    m_offsetLinkEnd = offsetLinkEnd;
    scheduleUpdate();
    emit offsetLinkEndChanged();
}

QVector2D SpatialItem::offsetLinkEnd2D() const
{
    return m_offsetLinkEnd2D;
}

void SpatialItem::setOffsetLinkEnd2D(const QVector2D &offsetLinkEnd2D)
{
    if (m_offsetLinkEnd2D == offsetLinkEnd2D) {
        return;
    }
    m_offsetLinkEnd2D = offsetLinkEnd2D;
    updateLayout();
    scheduleUpdate();
    emit offsetLinkEnd2DChanged();
}

QVector3D SpatialItem::offsetLinkStart() const
{
    return m_offsetLinkStart;
}

void SpatialItem::setOffsetLinkStart(const QVector3D &offsetLinkStart)
{
    if (m_offsetLinkStart == offsetLinkStart) {
        return;
    }
    m_offsetLinkStart = offsetLinkStart;
    scheduleUpdate();
    emit offsetLinkStartChanged();
}

QVector2D SpatialItem::offsetLinkStart2D() const
{
    return m_offsetLinkStart2D;
}

void SpatialItem::setOffsetLinkStart2D(const QVector2D &offsetLinkStart2D)
{
    if (m_offsetLinkStart2D == offsetLinkStart2D) {
        return;
    }
    m_offsetLinkStart2D = offsetLinkStart2D;
    scheduleUpdate();
    emit offsetLinkStart2DChanged();
    emit linkerStartChanged();
}

bool SpatialItem::showDraggingLine() const
{
    return m_showDraggingLine;
}

void SpatialItem::setShowDraggingLine(bool showDraggingLine)
{
    if (m_showDraggingLine == showDraggingLine) {
        return;
    }
    m_showDraggingLine = showDraggingLine;
    updateDraggingLineVisible();
    emit showDraggingLineChanged();
}

bool SpatialItem::showLinker() const
{
    return m_showLinker;
}

void SpatialItem::setShowLinker(bool showLinker)
{
    if (m_showLinker == showLinker) {
        return;
    }
    m_showLinker = showLinker;
    m_linkerShape->setVisible(m_showLinker);
    updateMouseLinkerEnabled();
    emit showLinkerChanged();
}

int SpatialItem::stackingOrder() const
{
    return m_stackingOrder;
}

void SpatialItem::setStackingOrder(int stackingOrder)
{
    if (m_stackingOrder == stackingOrder) {
        return;
    }
    m_stackingOrder = stackingOrder;
    updateStacking();
    emit stackingOrderChanged();
}

int SpatialItem::stackingOrderLinker() const
{
    return m_stackingOrderLinker;
}

void SpatialItem::setStackingOrderLinker(int stackingOrderLinker)
{
    if (m_stackingOrderLinker == stackingOrderLinker) {
        return;
    }
    m_stackingOrderLinker = stackingOrderLinker;
    m_linkerLayer->setZ(static_cast<qreal>(m_stackingOrderLinker));
    emit stackingOrderLinkerChanged();
}

QQuick3DCamera *SpatialItem::camera() const
{
    return m_camera;
}

QQuickItem *SpatialItem::contentItem() const
{
    return m_contentItem;
}

QVector2D SpatialItem::coords() const
{
    return m_screenTargetOffsetedCenterTop;
}

qreal SpatialItem::distance() const
{
    return m_distance;
}

bool SpatialItem::dragging() const
{
    return m_dragging;
}

bool SpatialItem::hovered() const
{
    return m_hovered;
}

QVector2D SpatialItem::linkerEnd() const
{
    return coords();
}

QVector2D SpatialItem::linkerStart() const
{
    return m_screenTargetOffsetedCenterBase + m_offsetLinkStart2D;
}

QQuickMouseArea *SpatialItem::mouseArea() const
{
    return m_mouseArea;
}

QQuickMouseArea *SpatialItem::mouseAreaLinker() const
{
    return m_linkerMouseArea;
}

qreal SpatialItem::scaleFactor() const
{
    return m_scaleFactor;
}

QVector2D SpatialItem::screenTargetCenterBase() const
{
    return m_screenTargetCenterBase;
}

QVector2D SpatialItem::screenTargetOffsetedCenterBase() const
{
    return m_screenTargetOffsetedCenterBase;
}

QVector2D SpatialItem::screenTargetOffsetedCenterTop() const
{
    return m_screenTargetOffsetedCenterTop;
}

QVector3D SpatialItem::targetCenterBase() const
{
    if (!m_target) {
        return {};
    }
    const QQuick3DBounds3 bounds{m_target->bounds()};
    const QVector3D centerBase{(bounds.minimum().x() + bounds.maximum().x()) / 2, bounds.minimum().y(),
                               (bounds.minimum().z() + bounds.maximum().z()) / 2};
    return m_target->scenePosition() + centerBase * m_target->scale();
}

QVector3D SpatialItem::targetCenterTop() const
{
    if (!m_target) {
        return {};
    }
    const QQuick3DBounds3 bounds{m_target->bounds()};
    const QVector3D centerTop{(bounds.minimum().x() + bounds.maximum().x()) / 2, bounds.maximum().y(),
                              (bounds.minimum().z() + bounds.maximum().z()) / 2};
    return m_target->scenePosition() + centerTop * m_target->scale();
}

void SpatialItem::componentComplete()
{
    QQuickItem::componentComplete();
    connectView();
    connectTarget();
    updateLayout();
}

void SpatialItem::geometryChange(const QRectF &newGeometry, const QRectF &oldGeometry)
{
    QQuickItem::geometryChange(newGeometry, oldGeometry);
    if (newGeometry.size() != oldGeometry.size()) {
        updateLayout();
        emit sizeChanged();
    }
}

void SpatialItem::itemChange(ItemChange change, const ItemChangeData &value)
{
    QQuickItem::itemChange(change, value);
    if (change == ItemSceneChange) {
        connectWindow();
    }
}

void SpatialItem::connectView()
{
    disconnectAll(m_viewConnections);
    if (m_view) {
        const auto onViewResized{[this]() {
            updateLinkerLayer();
            updateScale();
            scheduleUpdate();
        }};
        m_viewConnections.append(connect(m_view, &QQuick3DViewport::cameraChanged, this, &SpatialItem::connectCamera));
        m_viewConnections.append(connect(m_view, &QQuickItem::widthChanged, this, onViewResized));
        m_viewConnections.append(connect(m_view, &QQuickItem::heightChanged, this, onViewResized));
    }
    updateLinkerLayer();
    connectCamera();
}

void SpatialItem::connectCamera()
{
    QQuick3DCamera *camera{m_view ? m_view->camera() : nullptr};
    disconnectAll(m_cameraConnections);
    const bool changed{m_camera != camera};
    m_camera = camera;
    if (m_camera) {
        const auto onCameraMoved{[this]() {
            updateScale();
            scheduleUpdate();
        }};
        m_cameraConnections.append(connect(m_camera, &QQuick3DNode::scenePositionChanged, this, onCameraMoved));
        m_cameraConnections.append(connect(m_camera, &QQuick3DNode::sceneRotationChanged, this, onCameraMoved));
        m_cameraConnections.append(connect(m_camera, &QQuick3DObject::parentChanged, this, &SpatialItem::connectCameraParent));
        if (auto *perspectiveCamera{qobject_cast<QQuick3DPerspectiveCamera *>(m_camera)}) {
            m_cameraConnections.append(
                connect(perspectiveCamera, &QQuick3DPerspectiveCamera::fieldOfViewChanged, this, onCameraMoved));
            m_cameraConnections.append(connect(perspectiveCamera,
                                               &QQuick3DPerspectiveCamera::fieldOfViewOrientationChanged, this,
                                               onCameraMoved));
        } else if (auto *orthographicCamera{qobject_cast<QQuick3DOrthographicCamera *>(m_camera)}) {
            m_cameraConnections.append(connect(orthographicCamera,
                                               &QQuick3DOrthographicCamera::verticalMagnificationChanged, this,
                                               onCameraMoved));
        }
    }
    connectCameraParent();
    updateScale();
    scheduleUpdate();
    if (changed) {
        emit cameraChanged();
    }
}

void SpatialItem::connectCameraParent()
{
    disconnectAll(m_cameraParentConnections);
    QQuick3DNode *parentNode{m_camera ? m_camera->parentNode() : nullptr};
    if (parentNode) {
        const auto onParentMoved{[this]() {
            updateScale();
            scheduleUpdate();
        }};
        m_cameraParentConnections.append(connect(parentNode, &QQuick3DNode::scenePositionChanged, this, onParentMoved));
        m_cameraParentConnections.append(connect(parentNode, &QQuick3DNode::sceneRotationChanged, this, onParentMoved));
    }
}

void SpatialItem::connectTarget()
{
    disconnectAll(m_targetConnections);
    if (m_target) {
        const auto onTargetChanged{[this]() {
            emitTargetCentersChanged();
            updateScale();
            scheduleUpdate();
        }};
        m_targetConnections.append(connect(m_target, &QQuick3DNode::scenePositionChanged, this, onTargetChanged));
        m_targetConnections.append(connect(m_target, &QQuick3DNode::scaleChanged, this, onTargetChanged));
        m_targetConnections.append(connect(m_target, &QQuick3DModel::boundsChanged, this, onTargetChanged));
    }
    emitTargetCentersChanged();
    updateScale();
    scheduleUpdate();
}

void SpatialItem::connectWindow()
{
    disconnectAll(m_windowConnections);
    QQuickWindow *quickWindow{window()};
    if (!quickWindow) {
        return;
    }
    m_windowConnections.append(connect(quickWindow, &QWindow::widthChanged, this, &SpatialItem::scheduleUpdate));
    m_windowConnections.append(connect(quickWindow, &QWindow::heightChanged, this, &SpatialItem::scheduleUpdate));
    // The camera only projects once the scene has been rendered: position again after the first frame. The signal
    // comes from the render thread, so the slot runs queued on this thread.
    if (!m_firstFrameSeen) {
        m_windowConnections.append(connect(
            quickWindow, &QQuickWindow::frameSwapped, this,
            [this]() {
                if (!m_firstFrameSeen) {
                    m_firstFrameSeen = true;
                    scheduleUpdate();
                }
            },
            Qt::SingleShotConnection));
    }
}

void SpatialItem::disconnectAll(QList<QMetaObject::Connection> &connections)
{
    for (const QMetaObject::Connection &connection : std::as_const(connections)) {
        disconnect(connection);
    }
    connections.clear();
}

void SpatialItem::scheduleUpdate()
{
    if (m_updateScheduled) {
        return;
    }
    m_updateScheduled = true;
    QMetaObject::invokeMethod(
        this,
        [this]() {
            m_updateScheduled = false;
            updateUIPosition();
        },
        Qt::QueuedConnection);
}

void SpatialItem::updateUIPosition()
{
    if (!m_view || !m_camera || !m_target) {
        return;
    }

    const QVector2D screenTargetCenterBase{projectToView(targetCenterBase())};
    const QVector2D screenTargetOffsetedCenterBase{projectToView(targetCenterBaseOffseted())};
    const QVector2D screenTargetOffsetedCenterTop{projectToView(targetCenterTopOffseted())};

    if (m_screenTargetCenterBase != screenTargetCenterBase) {
        m_screenTargetCenterBase = screenTargetCenterBase;
        emit screenTargetCenterBaseChanged();
    }
    if (m_screenTargetOffsetedCenterBase != screenTargetOffsetedCenterBase) {
        m_screenTargetOffsetedCenterBase = screenTargetOffsetedCenterBase;
        emit screenTargetOffsetedCenterBaseChanged();
        emit linkerStartChanged();
    }
    if (m_screenTargetOffsetedCenterTop != screenTargetOffsetedCenterTop) {
        m_screenTargetOffsetedCenterTop = screenTargetOffsetedCenterTop;
        updateLayout();
        emit screenTargetOffsetedCenterTopChanged();
        emit coordsChanged();
        emit linkerEndChanged();
    }

    if (m_dragging && m_showDraggingLine) {
        m_screenInitialTargetCenterBase = projectToView(m_initialTargetPosition);
    }
    m_draggingLinePath->setStartX(m_screenInitialTargetCenterBase.x());
    m_draggingLinePath->setStartY(m_screenInitialTargetCenterBase.y());
    m_draggingLineEnd->setX(m_screenTargetOffsetedCenterBase.x());
    m_draggingLineEnd->setY(m_screenTargetOffsetedCenterBase.y());
}

void SpatialItem::updateScale()
{
    qreal distance{0.0};
    if (m_camera && m_target) {
        distance = static_cast<qreal>((m_camera->scenePosition() - m_target->scenePosition()).length());
    }

    qreal distanceScale{1.0};
    if (auto *perspectiveCamera{qobject_cast<QQuick3DPerspectiveCamera *>(m_camera)}) {
        const qreal viewWidth{m_view ? m_view->width() : 0.0};
        const qreal viewHeight{m_view ? m_view->height() : 0.0};
        qreal tanHalfFov{std::tan(qDegreesToRadians(static_cast<qreal>(perspectiveCamera->fieldOfView())) / 2.0)};
        if (perspectiveCamera->fieldOfViewOrientation() == QQuick3DPerspectiveCamera::Horizontal && viewWidth > 0.0) {
            tanHalfFov *= viewHeight / viewWidth;
        }
        if (distance > 0.0 && tanHalfFov > 0.0) {
            distanceScale = viewHeight / (distance * tanHalfFov);
        }
    } else if (auto *orthographicCamera{qobject_cast<QQuick3DOrthographicCamera *>(m_camera)}) {
        distanceScale = 2.0 * static_cast<qreal>(orthographicCamera->verticalMagnification());
    }

    qreal scaleFactor{distanceScale};
    if (m_fixedSize) {
        scaleFactor = m_closeUpScaling ? std::max(1.0, distanceScale) : 1.0;
    }

    const bool distanceDiffers{m_distance != distance};
    const bool scaleDiffers{m_scaleFactor != scaleFactor};
    m_distance = distance;
    m_scaleFactor = scaleFactor;
    if (scaleDiffers) {
        m_overlay->setScale(m_scaleFactor);
    }
    if (distanceDiffers) {
        updateStacking();
        emit distanceChanged();
    }
    if (scaleDiffers) {
        emit scaleFactorChanged();
    }
}

void SpatialItem::updateStacking()
{
    if (m_forceTopStacking) {
        setZ(static_cast<qreal>(ZOffset + 1));
    } else if (m_depthTest) {
        setZ(static_cast<qreal>(ZOffset - std::lround(m_distance)));
    } else {
        setZ(static_cast<qreal>(m_stackingOrder));
    }
}

void SpatialItem::updateLayout()
{
    setPosition(m_screenTargetOffsetedCenterTop.toPointF());
    const QSizeF overlaySize{size()};
    m_overlay->setSize(overlaySize);
    m_overlay->setPosition(m_offsetLinkEnd2D.toPointF() - QPointF{overlaySize.width() / 2, overlaySize.height() / 2});
    m_contentItem->setSize(overlaySize);
    m_mouseArea->setSize(overlaySize);
    updateLinkerLayer();
}

void SpatialItem::updateLinkerLayer()
{
    m_linkerLayer->setPosition(-m_screenTargetOffsetedCenterTop.toPointF());
    const QSizeF viewSize{m_view ? m_view->size() : QSizeF{}};
    m_linkerLayer->setSize(viewSize);
    m_linkerShape->setSize(viewSize);
    m_linkerMouseArea->setSize(viewSize);
    m_draggingLineShape->setSize(viewSize);
}

void SpatialItem::updateCursor()
{
    Qt::CursorShape shape{static_cast<Qt::CursorShape>(m_cursorShape)};
    if (m_holdDragsTarget) {
        if (m_dragging) {
            shape = m_dragMoved ? Qt::DragMoveCursor : Qt::ClosedHandCursor;
        } else {
            shape = Qt::OpenHandCursor;
        }
    }
    m_mouseArea->setCursorShape(shape);
    m_linkerMouseArea->setCursorShape(static_cast<Qt::CursorShape>(m_cursorShape));
}

void SpatialItem::updateHovered()
{
    const bool hovered{m_mouseArea->hovered() || m_linkerMouseArea->hovered()};
    if (m_hovered == hovered) {
        return;
    }
    m_hovered = hovered;
    emit hoveredChanged();
    if (m_hovered) {
        emit entered();
    } else {
        emit exited();
    }
}

void SpatialItem::updateMouseLinkerEnabled()
{
    m_linkerMouseArea->setEnabled(m_showLinker && m_mouseLinkerEnabled);
}

void SpatialItem::updateDraggingLineVisible()
{
    m_draggingLineShape->setVisible(m_dragging && m_showDraggingLine);
}

void SpatialItem::setDragging(bool dragging)
{
    if (m_dragging == dragging) {
        return;
    }
    m_dragging = dragging;
    updateDraggingLineVisible();
    emit draggingChanged();
}

void SpatialItem::emitTargetCentersChanged()
{
    emit targetCenterBaseChanged();
    emit targetCenterTopChanged();
}

void SpatialItem::onMousePressed(QQuickMouseEvent *mouse)
{
    if (!m_holdDragsTarget || !m_view || !m_camera || !m_target) {
        return;
    }
    updateUIPosition();
    const QPointF current{m_mouseArea->mapToItem(m_view, QPointF{mouse->x(), mouse->y()})};
    m_initialTargetPosition = m_target->scenePosition();
    // Drag on the horizontal plane through the anchor of the item, so the grabbed point stays under the cursor.
    m_dragPlaneHeight = targetCenterTopOffseted().y();
    const std::optional<QVector3D> grabPoint{projectOnDragPlane(QVector2D{current})};
    if (!grabPoint) {
        return;
    }
    m_grabOffset = m_target->scenePosition() - *grabPoint;
    m_dragMoved = false;
    setDragging(true);
    updateCursor();
    updateUIPosition();
}

void SpatialItem::onMousePositionChanged(QQuickMouseEvent *mouse)
{
    if (!m_dragging || !m_view || !m_camera || !m_target) {
        return;
    }
    m_dragMoved = true;
    updateCursor();
    // The item follows the target, so its local coordinates shift on every move: work in View3D coordinates.
    const QPointF current{m_mouseArea->mapToItem(m_view, QPointF{mouse->x(), mouse->y()})};
    const std::optional<QVector3D> hit{projectOnDragPlane(QVector2D{current})};
    if (!hit) {
        return;
    }
    const QVector3D scenePosition{*hit + m_grabOffset};
    QQuick3DNode *parentNode{m_target->parentNode()};
    m_target->setPosition(parentNode ? parentNode->mapPositionFromScene(scenePosition) : scenePosition);
}

void SpatialItem::onMouseReleased()
{
    m_dragMoved = false;
    setDragging(false);
    updateCursor();
    updateUIPosition();
}

QVector2D SpatialItem::projectToView(const QVector3D &scenePosition) const
{
    const QVector3D viewport{m_camera->mapToViewport(scenePosition)};
    if (viewport.z() <= 0.0f) {
        return {OffscreenCoordinate, OffscreenCoordinate};
    }
    return {viewport.x() * static_cast<float>(m_view->width()), viewport.y() * static_cast<float>(m_view->height())};
}

// Intersects the camera ray through viewPosition (View3D coordinates) with the horizontal drag plane.
std::optional<QVector3D> SpatialItem::projectOnDragPlane(const QVector2D &viewPosition) const
{
    const float viewWidth{static_cast<float>(m_view->width())};
    const float viewHeight{static_cast<float>(m_view->height())};
    if (viewWidth <= 0.0f || viewHeight <= 0.0f) {
        return std::nullopt;
    }
    const QVector2D normalized{viewPosition.x() / viewWidth, viewPosition.y() / viewHeight};
    const QVector3D nearPoint{m_camera->mapFromViewport(QVector3D{normalized, 0.0f})};
    const QVector3D farPoint{m_camera->mapFromViewport(QVector3D{normalized, 1.0f})};
    const QVector3D direction{(farPoint - nearPoint).normalized()};
    if (std::abs(direction.y()) < 0.000001f) {
        return std::nullopt;
    }
    const float t{(m_dragPlaneHeight - nearPoint.y()) / direction.y()};
    if (t < 0.0f) {
        return std::nullopt;
    }
    return nearPoint + direction * t;
}

QVector3D SpatialItem::targetCenterBaseOffseted() const
{
    return targetCenterBase() + m_offsetLinkStart;
}

QVector3D SpatialItem::targetCenterTopOffseted() const
{
    return targetCenterTop() + m_offsetLinkEnd;
}
