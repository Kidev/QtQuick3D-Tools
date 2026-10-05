import QtQuick
import QtQuick.Shapes
import QtQuick3D
import QtQuick3D.Tools
import QtTest

Item {
    id: root

    height: 600
    width: 800

    View3D {
        id: view3D

        anchors.fill: parent
        camera: camera

        environment: SceneEnvironment {
            backgroundMode: SceneEnvironment.Color
            clearColor: "black"
        }

        PerspectiveCamera {
            id: camera

            eulerRotation.x: -30
            position: Qt.vector3d(0, 600, 1000)
        }

        PerspectiveCamera {
            id: verticalCamera

            fieldOfView: 45
            position: Qt.vector3d(0, 50, 1000)
        }

        PerspectiveCamera {
            id: horizontalCamera

            fieldOfView: 60
            fieldOfViewOrientation: PerspectiveCamera.Horizontal
            position: Qt.vector3d(0, 50, 1000)
        }

        OrthographicCamera {
            id: orthographicCamera

            position: Qt.vector3d(0, 50, 1000)
            verticalMagnification: 1.5
        }

        Model {
            id: targetModel

            position: Qt.vector3d(0, 50, 0)
            source: "#Cube"
        }
    }

    SpatialItem {
        id: spatialItem

        fixedSize: true
        holdDragsTarget: true
        hoverEnabled: true
        mouseEnabled: true
        offsetLinkEnd: Qt.vector3d(0, 150, 0)
        showLinker: true
        size: Qt.size(100, 50)
        target: targetModel
        view: view3D

        linker: ShapePath {
            fillColor: "magenta"
            startX: spatialItem.linkerEnd.x - 30
            startY: spatialItem.linkerEnd.y
            strokeColor: "magenta"
            strokeWidth: 2

            PathLine {
                x: spatialItem.linkerStart.x
                y: spatialItem.linkerStart.y
            }

            PathLine {
                x: spatialItem.linkerEnd.x + 30
                y: spatialItem.linkerEnd.y
            }
        }
    }

    SignalSpy {
        id: linkerClickedSpy

        signalName: "clicked"
        target: spatialItem.mouseAreaLinker
    }

    TestCase {
        id: testCase

        function fuzzyCompareVector(actual, expected, tolerance, message) {
            verify(Math.abs(actual.x - expected.x) <= tolerance && Math.abs(actual.y - expected.y) <= tolerance, `${message}: got (${actual.x}, ${actual.y}), expected (${expected.x}, ${expected.y})`);
        }

        function cleanup() {
            if (spatialItem.dragging) {
                mouseRelease(view3D, 0, 0);
            }
            spatialItem.holdDragsTarget = true;
            spatialItem.fixedSize = true;
            spatialItem.offsetLinkEnd2D = Qt.vector2d(0, 0);
            spatialItem.mouseLinkerEnabled = false;
            spatialItem.showLinker = true;
            view3D.camera = camera;
            linkerClickedSpy.clear();
        }

        function init() {
            targetModel.position = Qt.vector3d(0, 50, 0);
            tryVerify(() => spatialItem.coords.x > 0 && spatialItem.coords.y > 0);
        }

        function test_dragFollowsCursor() {
            const start = spatialItem.coords;
            const startTargetY = targetModel.position.y;
            mousePress(view3D, start.x, start.y);
            verify(spatialItem.dragging);

            const steps = [Qt.vector2d(10, 0), Qt.vector2d(40, 15), Qt.vector2d(90, 40), Qt.vector2d(60, -30), Qt.vector2d(-80, -50)];
            for (const step of steps) {
                const cursor = start.plus(step);
                mouseMove(view3D, cursor.x, cursor.y);
                wait(0);
                fuzzyCompareVector(spatialItem.coords, cursor, 1.5, `anchor under cursor after moving by (${step.x}, ${step.y})`);
                fuzzyCompare(targetModel.position.y, startTargetY, 0.001);
            }

            mouseRelease(view3D, start.x + steps[steps.length - 1].x, start.y + steps[steps.length - 1].y);
            verify(!spatialItem.dragging);
        }

        // Screen pixels covered by one scene unit at the target, measured through the camera projection.
        function pixelsPerUnit() {
            const base = targetModel.scenePosition;
            const a = view3D.camera.mapToViewport(base);
            const b = view3D.camera.mapToViewport(base.plus(view3D.camera.up));
            return Math.hypot((b.x - a.x) * view3D.width, (b.y - a.y) * view3D.height);
        }

        function test_scaleFactor_data() {
            return [
                {
                    tag: "perspective vertical",
                    camera: verticalCamera
                },
                {
                    tag: "perspective horizontal",
                    camera: horizontalCamera
                },
                {
                    tag: "orthographic",
                    camera: orthographicCamera
                }
            ];
        }

        function test_scaleFactor(data) {
            spatialItem.fixedSize = false;
            view3D.camera = data.camera;
            waitForRendering(view3D);
            const expected = 2 * pixelsPerUnit();
            verify(expected > 0);
            verify(Math.abs(spatialItem.scaleFactor - expected) <= 0.01 * expected, `scaleFactor ${spatialItem.scaleFactor}, expected ${expected}`);
        }

        // A point inside the linker triangle, between the target and the overlay.
        function linkerPoint() {
            const y = (spatialItem.linkerEnd.y + spatialItem.size.height / 2 + spatialItem.linkerStart.y) / 2;
            return Qt.vector2d(spatialItem.linkerEnd.x, y);
        }

        function isMagenta(image, point) {
            return image.red(point.x, point.y) > 200 && image.green(point.x, point.y) < 60 && image.blue(point.x, point.y) > 200;
        }

        function test_linkerDrawnAboveView() {
            waitForRendering(view3D);
            const point = linkerPoint();
            verify(point.y > spatialItem.linkerEnd.y + spatialItem.size.height / 2, "the linker point is below the overlay");
            verify(isMagenta(grabImage(root), point), "linker visible at its default stacking");
        }

        function test_linkerHiddenWithoutShowLinker() {
            spatialItem.showLinker = false;
            waitForRendering(view3D);
            verify(!isMagenta(grabImage(root), linkerPoint()), "linker hidden while showLinker is false");
        }

        function test_linkerMouse_data() {
            return [
                {
                    tag: "enabled, inside the linker",
                    enabled: true,
                    offset: 0,
                    expected: true
                },
                {
                    tag: "disabled, inside the linker",
                    enabled: false,
                    offset: 0,
                    expected: false
                },
                {
                    tag: "enabled, outside the linker",
                    enabled: true,
                    offset: 100,
                    expected: false
                }
            ];
        }

        function test_linkerMouse(data) {
            spatialItem.mouseLinkerEnabled = data.enabled;
            mouseMove(view3D, 5, 5);
            verify(!spatialItem.hovered);
            const point = linkerPoint().plus(Qt.vector2d(data.offset, 0));
            mouseMove(view3D, point.x, point.y);
            compare(spatialItem.hovered, data.expected);
            mouseClick(view3D, point.x, point.y);
            compare(linkerClickedSpy.count, data.expected ? 1 : 0);
            mouseMove(view3D, 5, 5);
        }

        function test_offsetLinkEnd2D() {
            const offset = Qt.vector2d(40, -30);
            spatialItem.offsetLinkEnd2D = offset;
            tryVerify(() => spatialItem.linkerEnd.x > 0);
            fuzzyCompareVector(spatialItem.linkerEnd, spatialItem.screenTargetOffsetedCenterTop, 0.01, "linker end on the projected offsetLinkEnd point");
            const center = spatialItem.contentItem.mapToItem(root, spatialItem.size.width / 2, spatialItem.size.height / 2);
            fuzzyCompareVector(Qt.vector2d(center.x, center.y), spatialItem.linkerEnd.plus(offset), 0.5, "overlay center offset once from the linker end");
        }

        function test_holdDragsTargetOff() {
            spatialItem.holdDragsTarget = false;
            const start = spatialItem.coords;
            mousePress(view3D, start.x, start.y);
            verify(!spatialItem.dragging);
            mouseMove(view3D, start.x + 50, start.y + 20);
            mouseRelease(view3D, start.x + 50, start.y + 20);
            compare(targetModel.position, Qt.vector3d(0, 50, 0));
            spatialItem.holdDragsTarget = true;
        }

        name: "SpatialItem"
        when: windowShown
    }
}
