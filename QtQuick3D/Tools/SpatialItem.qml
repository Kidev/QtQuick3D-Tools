import QtQuick
import QtQuick.Shapes
import QtQuick3D

Item {
    id: root

    readonly property var camera: root.view.camera
    property bool closeUpScaling: false
    readonly property alias contentItem: contentItem
    readonly property vector2d coords: root.screenTargetOffsetedCenterTop
    property int cursor: Qt.ArrowCursor
    default property alias contentData: contentItem.data
    property bool depthTest: false
    readonly property real distance: root.camera ? root.camera.scenePosition.minus(root.target.scenePosition).length() : 0
    property vector2d dragStartScreenPos
    readonly property bool dragging: itemMouseArea.dragging
    property bool fixedSize: false
    property bool forceTopStacking: false
    property bool holdDragsTarget: false
    property bool hoverEnabled: false
    readonly property bool hovered: itemMouseArea.containsMouse || linkerMouseArea.containsMouse
    property vector3d initialTargetPosition
    property alias linker: linkerShape.data
    readonly property vector2d linkerEnd: root.coords
    readonly property vector2d linkerStart: root.screenTargetOffsetedCenterBase.plus(root.offsetLinkStart2D)
    readonly property alias mouseArea: itemMouseArea
    readonly property alias mouseAreaLinker: linkerMouseArea
    property bool mouseEnabled: false
    property bool mouseLinkerEnabled: false
    property vector3d offsetLinkEnd: Qt.vector3d(0, 0, 0)
    property vector2d offsetLinkEnd2D: Qt.vector2d(0, 0)
    property vector3d offsetLinkStart: Qt.vector3d(0, 0, 0)
    property vector2d offsetLinkStart2D: Qt.vector2d(0, 0)
    readonly property real scaleFactor: {
        let distanceScale = 1;
        const perspectiveCamera = root.camera as PerspectiveCamera;
        const orthographicCamera = root.camera as OrthographicCamera;
        if (perspectiveCamera) {
            let tanHalfFov = Math.tan(perspectiveCamera.fieldOfView * Math.PI / 360.0);
            if (perspectiveCamera.fieldOfViewOrientation === PerspectiveCamera.Horizontal) {
                tanHalfFov *= root.view.height / root.view.width;
            }
            distanceScale = root.view.height / (root.distance * tanHalfFov);
        } else if (orthographicCamera) {
            distanceScale = 2 * orthographicCamera.verticalMagnification;
        }
        if (root.fixedSize) {
            return root.closeUpScaling ? Math.max(1.0, distanceScale) : 1.0;
        }
        return distanceScale;
    }
    property vector2d screenInitialTargetCenterBase
    readonly property vector3d screenSize: Qt.vector3d(root.view.width, root.view.height, 1)
    property vector2d screenTargetCenterBase
    property vector2d screenTargetOffsetedCenterBase
    property vector2d screenTargetOffsetedCenterTop
    property bool showDraggingLine: false
    property bool showLinker: false
    required property size size
    property int stackingOrder: 0
    property int stackingOrderLinker: -1
    required property Model target
    readonly property vector3d targetCenterBase: root.target.scenePosition.plus(Qt.vector3d((root.target.bounds.minimum.x + root.target.bounds.maximum.x) / 2, root.target.bounds.minimum.y, (root.target.bounds.minimum.z + root.target.bounds.maximum.z) / 2).times(root.target.scale))
    readonly property vector3d targetCenterBaseOffseted: root.targetCenterBase.plus(root.offsetLinkStart)
    readonly property vector3d targetCenterTop: root.target.scenePosition.plus(Qt.vector3d((root.target.bounds.minimum.x + root.target.bounds.maximum.x) / 2, root.target.bounds.maximum.y, (root.target.bounds.minimum.z + root.target.bounds.maximum.z) / 2).times(root.target.scale))
    readonly property vector3d targetCenterTopOffseted: root.targetCenterTop.plus(root.offsetLinkEnd)
    property vector2d topLeftCorner: root.screenTargetOffsetedCenterTop
    required property View3D view
    readonly property int zDistance: root.zOffset - Math.round(root.distance)
    readonly property int zOffset: 1000000000

    signal entered
    signal exited

    function updateUIPosition() {
        if (!root.view || !root.camera || !root.target) {
            return;
        }
        const screenTargetOffsetedCenterBase = root.camera.mapToViewport(root.targetCenterBaseOffseted).times(root.screenSize);
        const screenTargetOffsetedCenterTop = root.camera.mapToViewport(root.targetCenterTopOffseted).times(root.screenSize);
        const screenTargetCenterBase = root.camera.mapToViewport(root.targetCenterBase).times(root.screenSize);
        root.screenTargetCenterBase = screenTargetCenterBase.z > 0 ? screenTargetCenterBase.toVector2d() : Qt.vector2d(-10000, -10000);
        root.screenTargetOffsetedCenterBase = screenTargetOffsetedCenterBase.z > 0 ? screenTargetOffsetedCenterBase.toVector2d() : Qt.vector2d(-10000, -10000);
        root.screenTargetOffsetedCenterTop = screenTargetOffsetedCenterTop.z > 0 ? screenTargetOffsetedCenterTop.toVector2d() : Qt.vector2d(-10000, -10000);
        if (root.dragging) {
            if (root.showDraggingLine) {
                const screenInitialTargetCenterBase = root.camera.mapToViewport(root.initialTargetPosition).times(root.screenSize);
                root.screenInitialTargetCenterBase = screenInitialTargetCenterBase.z > 0 ? screenInitialTargetCenterBase.toVector2d() : Qt.vector2d(-10000, -10000);
            }
        }
    }

    height: root.size.height
    width: root.size.width
    x: root.coords.x
    y: root.coords.y
    z: root.forceTopStacking ? root.zOffset + 1 : (root.depthTest ? root.zDistance : root.stackingOrder)

    Component.onCompleted: Qt.callLater(root.updateUIPosition)
    Window.onHeightChanged: Qt.callLater(root.updateUIPosition)
    Window.onWidthChanged: Qt.callLater(root.updateUIPosition)
    onHoveredChanged: {
        if (root.hovered) {
            root.entered();
        } else {
            root.exited();
        }
    }
    onOffsetLinkEnd2DChanged: Qt.callLater(root.updateUIPosition)
    onOffsetLinkEndChanged: Qt.callLater(root.updateUIPosition)
    onOffsetLinkStart2DChanged: Qt.callLater(root.updateUIPosition)
    onOffsetLinkStartChanged: Qt.callLater(root.updateUIPosition)

    Connections {
        function onScenePositionChanged() {
            Qt.callLater(root.updateUIPosition);
        }

        function onSceneRotationChanged() {
            Qt.callLater(root.updateUIPosition);
        }

        target: root.camera
    }

    Connections {
        function onScenePositionChanged() {
            Qt.callLater(root.updateUIPosition);
        }

        function onSceneRotationChanged() {
            Qt.callLater(root.updateUIPosition);
        }

        target: root.camera ? root.camera.parent : null
    }

    Connections {
        function onScenePositionChanged() {
            Qt.callLater(root.updateUIPosition);
        }

        target: root.target
    }

    // The camera only projects once the scene has been rendered: position again after the first frame.
    Connections {
        id: firstFrameConnection

        function onFrameSwapped() {
            firstFrameConnection.enabled = false;
            Qt.callLater(root.updateUIPosition);
        }

        target: root.Window.window
    }

    // The overlay content, scaled and centered on coords.
    Item {
        id: overlay

        anchors.fill: root

        transform: [
            Scale {
                origin.x: root.size.width / 2
                origin.y: root.size.height / 2
                xScale: root.scaleFactor
                yScale: root.scaleFactor
            },
            Translate {
                x: (root.offsetLinkEnd2D.x - root.size.width / 2)
                y: (root.offsetLinkEnd2D.y - root.size.height / 2)
            }
        ]

        Item {
            id: contentItem

            anchors.fill: overlay
        }

        MouseArea {
            id: itemMouseArea

            property bool dragging: false
            property vector3d grabOffset
            property real planeHeight: 0

            // Intersects the camera ray through viewPos (View3D coordinates) with the horizontal drag plane.
            function projectOnDragPlane(viewPos: vector2d): var {
                const nearPoint = root.camera.mapFromViewport(Qt.vector3d(viewPos.x / root.view.width, viewPos.y / root.view.height, 0));
                const farPoint = root.camera.mapFromViewport(Qt.vector3d(viewPos.x / root.view.width, viewPos.y / root.view.height, 1));
                const direction = farPoint.minus(nearPoint).normalized();
                if (Math.abs(direction.y) < 0.000001) {
                    return null;
                }
                const t = (itemMouseArea.planeHeight - nearPoint.y) / direction.y;
                if (t < 0) {
                    return null;
                }
                return nearPoint.plus(direction.times(t));
            }

            anchors.fill: overlay
            cursorShape: root.cursor
            enabled: root.mouseEnabled
            hoverEnabled: root.hoverEnabled

            onEntered: {
                if (root.holdDragsTarget) {
                    itemMouseArea.cursorShape = Qt.OpenHandCursor;
                }
            }
            onExited: {
                if (root.holdDragsTarget) {
                    itemMouseArea.cursorShape = Qt.ArrowCursor;
                }
            }
            onPositionChanged: mouse => {
                if (itemMouseArea.dragging) {
                    root.mouseArea.cursorShape = Qt.DragMoveCursor;
                    // The item follows the target, so its local coordinates shift on every move: work in View3D coordinates.
                    const current = itemMouseArea.mapToItem(root.view, mouse.x, mouse.y);
                    const hit = itemMouseArea.projectOnDragPlane(Qt.vector2d(current.x, current.y));
                    if (hit) {
                        const parentNode = root.target.parent as Node;
                        const scenePosition = hit.plus(itemMouseArea.grabOffset);
                        root.target.position = parentNode ? parentNode.mapPositionFromScene(scenePosition) : scenePosition;
                    }
                }
            }
            onPressed: mouse => {
                if (root.holdDragsTarget) {
                    root.updateUIPosition();
                    const current = itemMouseArea.mapToItem(root.view, mouse.x, mouse.y);
                    root.dragStartScreenPos = Qt.vector2d(current.x, current.y);
                    root.initialTargetPosition = root.target.scenePosition;
                    // Drag on the horizontal plane through the anchor of the item, so the grabbed point stays under the cursor.
                    itemMouseArea.planeHeight = root.targetCenterTopOffseted.y;
                    const grabPoint = itemMouseArea.projectOnDragPlane(root.dragStartScreenPos);
                    if (!grabPoint) {
                        return;
                    }
                    itemMouseArea.grabOffset = root.target.scenePosition.minus(grabPoint);
                    itemMouseArea.dragging = true;
                    root.mouseArea.cursorShape = Qt.ClosedHandCursor;
                    root.updateUIPosition();
                }
            }
            onReleased: () => {
                itemMouseArea.dragging = false;
                if (root.holdDragsTarget) {
                    root.initialTargetPosition = root.target.scenePosition;
                    if (root.mouseArea.containsMouse) {
                        root.mouseArea.cursorShape = Qt.OpenHandCursor;
                    } else {
                        root.mouseArea.cursorShape = Qt.ArrowCursor;
                    }
                }
                root.updateUIPosition();
            }
        }
    }

    // The linker and the dragging line, unscaled, in View3D coordinates. Children of root, so they stack with this overlay.
    Item {
        id: linkerLayer

        height: root.view.height
        width: root.view.width
        x: -root.x
        y: -root.y
        z: root.stackingOrderLinker

        Shape {
            id: linkerShape

            anchors.fill: parent
            containsMode: Shape.FillContains
            visible: root.showLinker
        }

        MouseArea {
            id: linkerMouseArea

            anchors.fill: linkerShape
            containmentMask: linkerShape
            cursorShape: root.cursor
            enabled: root.showLinker && root.mouseLinkerEnabled
            hoverEnabled: root.hoverEnabled
        }

        Shape {
            id: draggingLineShape

            anchors.fill: parent
            visible: root.dragging && root.showDraggingLine

            ShapePath {
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.BevelJoin
                startX: root.screenInitialTargetCenterBase.x
                startY: root.screenInitialTargetCenterBase.y
                strokeColor: "green"
                strokeWidth: 3

                PathLine {
                    x: root.screenTargetOffsetedCenterBase.x
                    y: root.screenTargetOffsetedCenterBase.y
                }
            }
        }
    }
}
