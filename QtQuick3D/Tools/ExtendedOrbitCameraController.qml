// Copyright (C) 2022 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only
// Improved for additional controls and possibilities by Kidev

import QtQuick
import QtQuick3D

Item {
    id: root

    readonly property real _pinchZoomFactor: 2 * (root.invertScroll ? -root.pinchZoomSpeed : root.pinchZoomSpeed)
    readonly property real _scrollSpeed: invertScroll ? -scrollSpeed : scrollSpeed
    readonly property vector2d _speedPanning: Qt.vector2d(xInvertPanning ? -xSpeedPanning : xSpeedPanning, yInvertPanning ? -ySpeedPanning : ySpeedPanning)
    readonly property real _xSpeed: xInvert ? -xSpeed : xSpeed
    readonly property real _ySpeed: yInvert ? -ySpeed : ySpeed
    property int buttonsToPan: Qt.RightButton
    property Camera camera: root.view.camera
    readonly property bool inputsNeedProcessing: status.useMouse || status.isPanning
    property bool invertScroll: false
    property bool isTracking: false
    property int modifiersToPan: Qt.NoModifier
    property bool mouseEnabled: true
    required property Node origin
    property bool panEnabled: true
    readonly property bool panning: status.isPanning
    property real pinchZoomSpeed: 0.5
    property real scrollSpeed: 1
    property var trackedModel: null
    required property View3D view
    property bool xInvert: false
    property bool xInvertPanning: false
    property real xMaxAngle: 90
    property real xMinAngle: -90
    property real xSpeed: 0.1
    property real xSpeedPanning: 0.5
    property bool yInvert: true
    property bool yInvertPanning: false
    property real yMaxAngle: 361
    property real yMinAngle: -361
    property real ySpeed: 0.1
    property real ySpeedPanning: 0.5
    property bool zoomEnabled: true

    function _endPan() {
        status.isPanning = false;
    }

    function _mouseMoved(newPos: vector2d) {
        status.currentPos = newPos;
    }

    function _mousePressed(newPos) {
        root.forceActiveFocus();
        status.currentPos = newPos;
        status.lastPos = newPos;
        status.useMouse = true;
    }

    function _mouseReleased(newPos) {
        status.useMouse = false;
    }

    function _panEvent(newPos: vector2d) {
        status.currentPanPos = newPos;
    }

    function _panEventDelta(delta: vector2d) {
        status.currentPanPos = delta.plus(status.lastPanPos);
    }

    function _startPan(pos: vector2d) {
        isTracking = false;
        trackedModel = null;
        status.isPanning = true;
        status.currentPanPos = pos;
        status.lastPanPos = pos;
    }

    function _trackModel() {
        if (root.isTracking && root.trackedModel) {
            let bounds = root.trackedModel.bounds;
            let baseCenter = root.trackedModel.scenePosition.plus(Qt.vector3d((bounds.minimum.x + bounds.maximum.x) / 2, bounds.minimum.y, (bounds.minimum.z + bounds.maximum.z) / 2));
            baseCenter.y = 0;
            root.view.camera.parent.position = baseCenter;
        }
    }

    implicitHeight: parent.height
    implicitWidth: parent.width

    Connections {
        function onScenePositionChanged() {
            root._trackModel();
        }

        target: root.trackedModel
    }

    // Double tap/click to select/unselect object
    TapHandler {
        id: doubleTapHandler

        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchScreen
        enabled: root.mouseEnabled
        exclusiveSignals: TapHandler.DoubleTap
        gesturePolicy: TapHandler.WithinBounds
        target: null

        onDoubleTapped: (eventPoint, button) => {
            let pickResult = root.view.pick(eventPoint.position.x, eventPoint.position.y);
            if (pickResult.objectHit) {
                let hitModel = pickResult.objectHit;
                if (root.isTracking) {
                    if (hitModel === root.trackedModel || hitModel !== root.trackedModel) {
                        root.isTracking = false;
                        root.trackedModel = null;
                    }
                } else if (!hitModel.objectName.startsWith("notSelectable")) {
                    root.trackedModel = hitModel;
                    root.isTracking = true;
                    root._trackModel();
                }
            } else {
                root.isTracking = false;
                root.trackedModel = null;
            }
        }
    }

    // Mouse rotation
    DragHandler {
        id: moveDragHandler

        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        acceptedModifiers: Qt.NoModifier
        enabled: root.mouseEnabled
        target: null

        onActiveChanged: {
            if (active) {
                root._mousePressed(Qt.vector2d(centroid.position.x, centroid.position.y));
            } else {
                root._mouseReleased(Qt.vector2d(centroid.position.x, centroid.position.y));
            }
        }
        onCentroidChanged: {
            root._mouseMoved(Qt.vector2d(centroid.position.x, centroid.position.y), false);
        }
    }

    // Mouse pan
    DragHandler {
        id: panDragHandler

        acceptedButtons: root.buttonsToPan
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        acceptedModifiers: root.modifiersToPan
        enabled: root.mouseEnabled && root.panEnabled
        target: null

        onActiveChanged: {
            if (active) {
                root._startPan(Qt.vector2d(centroid.position.x, centroid.position.y));
            } else {
                root._endPan();
            }
        }
        onCentroidChanged: {
            root._panEvent(Qt.vector2d(centroid.position.x, centroid.position.y));
        }
    }

    // Mouse zoom
    WheelHandler {
        id: wheelHandler

        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        enabled: root.zoomEnabled
        orientation: Qt.Vertical
        target: null

        onWheel: event => {
            let delta = -event.angleDelta.y * 0.01;
            root.camera.z += root.camera.z * 0.1 * delta * root._scrollSpeed;
        }
    }

    // Single finger rotation
    DragHandler {
        id: rotationHandler

        acceptedDevices: PointerDevice.TouchScreen
        acceptedModifiers: Qt.NoModifier
        enabled: root.mouseEnabled
        maximumPointCount: 1
        minimumPointCount: 1
        target: null

        onActiveChanged: {
            if (rotationHandler.active) {
                root._mousePressed(Qt.vector2d(rotationHandler.centroid.position.x, rotationHandler.centroid.position.y));
            } else {
                root._mouseReleased(Qt.vector2d(rotationHandler.centroid.position.x, rotationHandler.centroid.position.y));
            }
        }
        onCentroidChanged: {
            if (rotationHandler.active) {
                root._mouseMoved(Qt.vector2d(rotationHandler.centroid.position.x, rotationHandler.centroid.position.y));
            }
        }
    }

    // Double finger pinch zoom
    PinchHandler {
        id: pinchHandler

        property real zoomThreshold: 0.025

        enabled: root.zoomEnabled
        scaleAxis.maximum: 20.0
        scaleAxis.minimum: 0.01
        target: null

        onScaleChanged: delta => {
            if (Math.abs(1 - delta) > zoomThreshold) {
                let zoomFactor = 1 + (1 - delta) * root._pinchZoomFactor;
                root.camera.z *= zoomFactor;
            }
        }
    }

    // Double+ finger pan
    DragHandler {
        id: touchPanHandler

        property real lastCentroidX: 0
        property real lastCentroidY: 0
        property real panThreshold: 5

        acceptedDevices: PointerDevice.TouchScreen
        enabled: root.mouseEnabled && root.panEnabled
        maximumPointCount: 3
        minimumPointCount: 2
        target: null

        onActiveChanged: {
            if (active) {
                lastCentroidX = centroid.position.x;
                lastCentroidY = centroid.position.y;
                root._startPan(Qt.vector2d(centroid.position.x, centroid.position.y));
            } else {
                root._endPan();
            }
        }
        onCentroidChanged: {
            let deltaX = centroid.position.x - lastCentroidX;
            let deltaY = centroid.position.y - lastCentroidY;
            if (Math.abs(deltaX) > panThreshold || Math.abs(deltaY) > panThreshold) {
                root._panEvent(Qt.vector2d(centroid.position.x, centroid.position.y));
                lastCentroidX = centroid.position.x;
                lastCentroidY = centroid.position.y;
            }
        }
    }

    FrameAnimation {
        running: root.inputsNeedProcessing

        onTriggered: status.processInput(frameTime * 100)
    }

    QtObject {
        id: status

        property vector2d currentPanPos: Qt.vector2d(0, 0)
        property vector2d currentPos: Qt.vector2d(0, 0)
        property bool isPanning: false
        property vector2d lastPanPos: Qt.vector2d(0, 0)
        property vector2d lastPos: Qt.vector2d(0, 0)
        property bool useMouse: false

        function clamp(val, min, max) {
            return Math.min(Math.max(val, min), max);
        }

        function negate(vector) {
            return Qt.vector3d(-vector.x, -vector.y, -vector.z);
        }

        function processInput(frameDelta) {
            if (useMouse) {
                // Get the delta
                var rotationVector = root.origin.eulerRotation;
                var delta = Qt.vector2d(lastPos.x - currentPos.x, lastPos.y - currentPos.y);
                // rotate x
                var rotateX = delta.x * root._xSpeed * frameDelta;
                rotationVector.y = clamp((rotationVector.y + rotateX) % 360, root.yMinAngle, root.yMaxAngle);

                // rotate y
                var rotateY = delta.y * -root._ySpeed * frameDelta;
                rotationVector.x = clamp((rotationVector.x + rotateY) % 360, root.xMinAngle, root.xMaxAngle);
                root.origin.setEulerRotation(rotationVector);
                lastPos = currentPos;
            }
            if (isPanning) {
                let delta = currentPanPos.minus(lastPanPos).times(root._speedPanning);
                delta.x = -delta.x;
                delta.x = (delta.x / root.width) * root.camera.z * frameDelta;
                delta.y = (delta.y / root.height) * root.camera.z * frameDelta;
                let velocity = Qt.vector3d(0, 0, 0);
                // X Movement
                let xDirection = root.origin.right;
                velocity = velocity.plus(Qt.vector3d(xDirection.x * delta.x, xDirection.y * delta.x, xDirection.z * delta.x));
                // Y Movement
                let yDirection = root.origin.up;
                velocity = velocity.plus(Qt.vector3d(yDirection.x * delta.y, yDirection.y * delta.y, yDirection.z * delta.y));
                root.origin.position = root.origin.position.plus(velocity);
                lastPanPos = currentPanPos;
            }
        }
    }
}
