import QtQuick
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

        Node {
            id: originNode

            PerspectiveCamera {
                id: camera

                position: Qt.vector3d(0, 0, 1000)
            }
        }
    }

    ExtendedOrbitCameraController {
        id: controller

        anchors.fill: parent
        origin: originNode
        view: view3D
    }

    TestCase {
        function cleanup() {
            controller.invertScroll = false;
            controller.pinchZoomSpeed = 0.5;
            controller.scrollSpeed = 1;
        }

        function test_pinchZoomSpeed() {
            controller.pinchZoomSpeed = 0.25;
            controller.scrollSpeed = 3;
            compare(controller._pinchZoomFactor, 0.5);
            controller.invertScroll = true;
            compare(controller._pinchZoomFactor, -0.5);
        }

        name: "ExtendedOrbitCameraController"
        when: windowShown
    }
}
