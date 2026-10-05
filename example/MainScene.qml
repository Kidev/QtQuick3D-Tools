import QtQuick
import QtQuick.Window
import QtQuick.Shapes
import QtQuick3D
import QtQuick3D.Tools

Window {
    id: root

    height: 1000
    title: "QtQuick3D Tools"
    visible: true
    width: 1000

    Shortcut {
        sequence: "Esc"

        onActivated: Qt.exit(0)
    }

    View3D {
        id: view3D

        anchors.fill: parent
        camera: perspectiveCamera

        environment: SceneEnvironment {
            antialiasingMode: SceneEnvironment.MSAA
            antialiasingQuality: SceneEnvironment.Medium
            backgroundMode: SceneEnvironment.Color
            clearColor: "black"
        }

        Model {
            id: xAxis

            position: Qt.vector3d(5000, 0, 0)
            scale: Qt.vector3d(100, .05, .05)
            source: "#Cube"

            materials: DefaultMaterial {
                diffuseColor: "red"
            }
        }

        Model {
            id: zAxis

            position: Qt.vector3d(0, 0, 5000)
            scale: Qt.vector3d(0.05, 0.05, 100)
            source: "#Cube"

            materials: DefaultMaterial {
                diffuseColor: "blue"
            }
        }

        SpotLight {
            id: modelDynamicLight

            function updateLight() {
                const rayOrigin = perspectiveCamera.scenePosition;
                const rayDirection = originNode.forward;
                if (Math.abs(rayDirection.y) < 0.0001) {
                    return;
                }
                const t = -rayOrigin.y / rayDirection.y;
                if (t >= 0) {
                    modelDynamicLight.x = rayOrigin.x + t * rayDirection.x;
                    modelDynamicLight.y = 1000;
                    modelDynamicLight.z = rayOrigin.z + t * rayDirection.z;
                }
            }

            ambientColor: Qt.rgba(0.1, 0.1, 0.1, 1.0)
            brightness: 1
            castsShadow: true
            coneAngle: orbitCameraController.isTracking ? 80 : 160
            constantFade: 0
            eulerRotation.x: -90
            innerConeAngle: 0.9 * coneAngle
            quadraticFade: 0.01
            shadowFactor: 50
            shadowMapQuality: Light.ShadowMapQualityHigh

            Behavior on coneAngle {
                SmoothedAnimation {
                    duration: 250
                }
            }
        }

        PointLight {
            ambientColor: Qt.rgba(0.1, 0.1, 0.1, 1.0)
            brightness: 1
            castsShadow: true
            constantFade: 0
            quadraticFade: 0.01
            shadowFactor: 50
            shadowMapQuality: Light.ShadowMapQualityHigh
            x: modelDynamicLight.x
            y: modelDynamicLight.y
            z: modelDynamicLight.z + 500
        }

        Model {
            id: groundPlane

            castsShadows: true
            eulerRotation.x: -90
            objectName: "notSelectable"
            pickable: true
            position: Qt.vector3d(0, 0, 0)
            receivesShadows: true
            scale: Qt.vector3d(1000, 1000, 1)
            source: "#Rectangle"

            materials: [
                DefaultMaterial {
                    diffuseColor: "grey"
                }
            ]
        }

        Node {
            id: originNode

            PropertyAnimation on eulerRotation.x {
                duration: 100
                from: 0
                loops: 1
                to: -10
            }
            PropertyAnimation on eulerRotation.y {
                duration: 100
                from: 0
                loops: 1
                to: -45
            }

            onEulerRotationChanged: {
                modelDynamicLight.updateLight();
            }
            onPositionChanged: {
                modelDynamicLight.updateLight();
            }

            PerspectiveCamera {
                id: perspectiveCamera

                clipFar: 100000
                clipNear: 1
                fieldOfView: 45
                position: Qt.vector3d(0, 0, 2000)
            }
        }

        ExtendedOrbitCameraController {
            id: orbitCameraController

            anchors.fill: parent
            buttonsToPan: Qt.RightButton
            invertScroll: false
            modifiersToPan: Qt.NoModifier
            mouseEnabled: !spatialUI.dragging
            origin: originNode
            panEnabled: true
            scrollSpeed: 0.5
            view: view3D
            xInvert: false
            xInvertPanning: false
            xMaxAngle: -1
            xMinAngle: -90
            xSpeed: 0.1
            xSpeedPanning: 0.5
            yInvert: true
            yInvertPanning: false
            yMaxAngle: 361
            yMinAngle: -361
            ySpeed: 0.1
            ySpeedPanning: 0.5
            zoomEnabled: true
        }

        Model {
            id: targetModel

            castsShadows: true
            pickable: true
            position: Qt.vector3d(0, 50, 0)
            receivesShadows: true
            source: "#Cube"

            materials: [
                DefaultMaterial {
                    diffuseColor: "green"
                }
            ]
        }

        ResourceLoader {
            meshSources: [targetHuman.source]
        }

        Model {
            id: targetHuman

            castsShadows: true
            pickable: true
            pivot: Qt.vector3d(-20, 0, 0)
            position: Qt.vector3d(100, 0, 0)
            receivesShadows: true
            scale: Qt.vector3d(20, 20, 20)
            source: "qrc:/meshes/human.mesh"

            RotationAnimation on eulerRotation.y {
                direction: RotationAnimation.Counterclockwise
                duration: 10000
                from: 360
                loops: Animation.Infinite
                to: 0
            }
            materials: [
                PrincipledMaterial {
                    id: principledMaterial

                    alphaMode: PrincipledMaterial.Opaque
                    baseColor: "black"
                    metalness: 0
                    roughness: 1
                }
            ]

            Component.onCompleted: () => targetHuman.eulerRotation.y = 360
        }
    }

    SpatialItem {
        id: spatialUI

        closeUpScaling: true
        depthTest: true
        fixedSize: spatialUI.hovered || spatialUI.dragging
        forceTopStacking: spatialUI.hovered || spatialUI.dragging
        holdDragsTarget: orbitCameraController.trackedModel != spatialUI.target
        hoverEnabled: true
        mouseEnabled: true
        mouseLinkerEnabled: true
        offsetLinkEnd: Qt.vector3d(0, 150, 0)
        offsetLinkEnd2D: Qt.vector2d(0, 0)
        offsetLinkStart: Qt.vector3d(0, 50, 0)
        offsetLinkStart2D: Qt.vector2d(0, 0)
        showDraggingLine: true
        showLinker: spatialUI.holdDragsTarget
        size: Qt.size(100, 50)
        target: targetModel
        view: view3D

        linker: ShapePath {
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.BevelJoin
            startX: spatialUI.linkerStart.x
            startY: spatialUI.linkerStart.y
            strokeColor: spatialUI.hovered || spatialUI.dragging ? "black" : "white"
            strokeWidth: 3 * spatialUI.scaleFactor

            PathLine {
                x: spatialUI.linkerEnd.x
                y: spatialUI.linkerEnd.y
            }
        }

        Text {
            color: "#FF00A9"
            font.bold: !spatialUI.holdDragsTarget && spatialUI.hovered
            font.pixelSize: 24
            opacity: 1
            text: "kidev"
            visible: !spatialUI.holdDragsTarget
            z: 1

            anchors {
                centerIn: spatialRectangle
            }
        }

        Text {
            color: "#295095"
            font.bold: !spatialUI.holdDragsTarget && spatialUI.hovered
            font.pixelSize: 26
            opacity: 1
            text: "kidev"
            visible: !spatialUI.holdDragsTarget
            z: 0

            anchors {
                centerIn: spatialRectangle
            }
        }

        Rectangle {
            id: spatialRectangle

            anchors.fill: parent
            border.color: spatialUI.hovered || spatialUI.dragging ? "white" : "black"
            border.width: spatialUI.holdDragsTarget ? (spatialUI.hovered || spatialUI.dragging ? 4 : 2) : 0
            color: spatialUI.holdDragsTarget ? (spatialUI.dragging || spatialUI.dragging ? "white" : (spatialUI.hovered || spatialUI.dragging ? "black" : "white")) : "#000000"
            opacity: spatialUI.holdDragsTarget ? 1 : 0.2
            radius: 10

            Text {
                anchors.centerIn: parent
                color: (spatialUI.hovered || spatialUI.dragging ? "white" : "black")
                font.bold: !spatialUI.holdDragsTarget && spatialUI.hovered
                font.pixelSize: spatialUI.holdDragsTarget ? 16 : 24
                opacity: 1
                text: "SpatialUI"
                visible: !spatialUI.dragging && spatialUI.holdDragsTarget
            }

            Text {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 3
                anchors.horizontalCenter: parent.horizontalCenter
                color: spatialUI.hovered || spatialUI.dragging ? "white" : "black"
                enabled: !spatialUI.dragging
                font.pixelSize: 8
                text: !spatialUI.dragging ? "Click and hold to move" : ""
                visible: spatialUI.holdDragsTarget && !spatialUI.dragging
            }

            Image {
                id: moveIcon

                anchors.centerIn: parent
                height: 20
                source: "qrc:/img/move.png"
                visible: spatialUI.holdDragsTarget && spatialUI.dragging
                width: 20
            }

            Text {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                color: "black"
                enabled: spatialUI.dragging
                font.pixelSize: 8
                text: spatialUI.dragging ? `${spatialUI.target.scenePosition.x.toFixed(0)} ${spatialUI.target.scenePosition.z.toFixed(0)}` : ""
                visible: spatialUI.holdDragsTarget && spatialUI.dragging
            }
        }
    }

    SpatialItem {
        id: spatialNameTag

        property bool textClicked: false

        closeUpScaling: true
        cursor: spatialNameTag.hovered ? Qt.PointingHandCursor : Qt.ArrowCursor
        depthTest: true
        fixedSize: false
        holdDragsTarget: false
        hoverEnabled: true
        mouseEnabled: true
        mouseLinkerEnabled: true
        offsetLinkEnd: Qt.vector3d(0, 50, 0)
        offsetLinkEnd2D: Qt.vector2d(spatialNameTag.size.width * spatialNameTag.scaleFactor / 4, 1 - spatialNameTag.size.height * spatialNameTag.scaleFactor / 2)
        offsetLinkStart: Qt.vector3d(0, (targetHuman.bounds.maximum.y - targetHuman.bounds.minimum.y) * targetHuman.scale.y, 0)
        offsetLinkStart2D: Qt.vector2d(0, 0)
        showLinker: true
        size: Qt.size(200, 50)
        stackingOrderLinker: spatialNameTag.linkerStart.y <= spatialNameTag.linkerEnd.y + uiRectangle.height * spatialNameTag.scaleFactor / 2 ? -1 : 1
        target: targetHuman
        view: view3D

        linker: [
            ShapePath {
                capStyle: ShapePath.FlatCap
                fillColor: "white"
                joinStyle: ShapePath.BevelJoin
                startX: spatialNameTag.linkerEnd.x - (0.1 * uiRectangle.width) * spatialNameTag.scaleFactor
                startY: spatialNameTag.linkerEnd.y - 1 - (uiRectangle.border.width * spatialNameTag.scaleFactor)
                strokeColor: uiRectangle.border.color
                strokeWidth: uiRectangle.border.width * spatialNameTag.scaleFactor

                PathLine {
                    x: spatialNameTag.linkerStart.x
                    y: spatialNameTag.linkerStart.y
                }

                PathLine {
                    x: spatialNameTag.linkerEnd.x + (0.1 * uiRectangle.width) * spatialNameTag.scaleFactor
                    y: spatialNameTag.linkerEnd.y - 1 - (uiRectangle.border.width * spatialNameTag.scaleFactor)
                }
            }
        ]

        mouseArea.onClicked: {
            spatialNameTag.textClicked = !spatialNameTag.textClicked;
        }
        mouseAreaLinker.onClicked: {
            spatialNameTag.textClicked = !spatialNameTag.textClicked;
        }

        Rectangle {
            id: uiRectangle

            anchors.fill: parent
            border.color: spatialNameTag.hovered ? "black" : "white"
            border.width: 2
            color: "white"
            radius: 25

            Text {
                anchors.centerIn: parent
                color: "black"
                font.pixelSize: 13.0
                horizontalAlignment: Text.AlignHCenter
                text: !spatialNameTag.textClicked ? "You spin me right 'round\nbaby, right 'round\n" : "Like a record, baby\nright 'round, 'round, 'round"
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    Image {
        id: githubLogo

        anchors.margins: 10
        anchors.right: parent.right
        anchors.top: parent.top
        height: 32
        source: "qrc:/img/github.png"
        width: 32
        z: 10

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor

            onClicked: {
                Qt.openUrlExternally("https://github.com/Kidev/QML-3D-Tools");
            }
        }
    }

    Image {
        id: kidevLogo

        anchors.margins: 10
        anchors.right: githubLogo.left
        anchors.top: parent.top
        height: 32
        source: "qrc:/img/logo.png"
        sourceSize: Qt.size(32, 32)
        width: 32
        z: 10

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor

            onClicked: {
                Qt.openUrlExternally("https://www.kidev.org");
            }
        }
    }
}
