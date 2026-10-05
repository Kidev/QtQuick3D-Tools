# QtQuick3D Tools
QtQuick3D Tools is a QML module that attaches 2D overlays (labels, icons, controls) to models in a Qt Quick 3D scene. An overlay follows its model as the camera or the model moves, and an optional linker shape joins the two. Uses include annotations, game UI and augmented reality interfaces.

## Demo

 [A demo of SpatialItem in your browser is available here](https://demo.kidev.org/QtQuick3D-Tools/). \
 The demo shows 2D overlays following 3D objects as the camera moves. Press and hold the left mouse button on the "SpatialUI" overlay and drag to move its target. Left click the other bubble to cycle its text. Elsewhere, dragging with the left button orbits around a point and dragging with the right button pans that point.
 
## Features

- **Anchored overlays**: Any Qt Quick content placed in a `SpatialItem` stays attached to its target model.
- **Perspective scaling**: Overlays scale with the distance to the camera, or keep a fixed screen size.
- **Linkers**: `ShapePath` objects drawn between the overlay and its target, styled like any Qt Quick Shape.
- **Depth ordering**: Overlays can stack by distance to the camera, or be forced on top.
- **Offsets**: Offsets in scene units and in pixels move the overlay and the linker start relative to the target.
- **Drag to move**: With `holdDragsTarget`, dragging an overlay moves its target across the scene, keeping the grabbed point under the cursor.
- **Orbit camera controller**: `ExtendedOrbitCameraController` orbits, pans and zooms a camera, with angle limits and model tracking.
- **Mouse signals**: `entered()` and `exited()` on the overlay, and every `MouseArea` signal through the `mouseArea` property.

## Documentation: SpatialItem

`SpatialItem` is a 2D item that follows a `Model` rendered by a `View3D`. Declare it next to the `View3D`, in an item that shares the view's top-left corner (for example, both filling the window). Its children form the overlay.

### Required properties

- **view [View3D]**: The view that renders `target`. The overlay is projected through `view.camera` and the view size. Perspective and orthographic cameras are supported.
- **target [Model]**: The model the overlay follows.
- **size [size]**: The size of the overlay before scaling.

### Properties

- **contentData (_default_) [list&lt;QtObject&gt;]**: The overlay content. Children declared inside a `SpatialItem` are added to it.
- **linker [list&lt;QtObject&gt;]**: The `ShapePath` objects drawn between the target and the overlay while `showLinker` is true. The linker is drawn in view coordinates without scaling, so multiply stroke widths by `scaleFactor`. There is no default.
  <details><summary>Linker examples</summary>

    - A simple line
    ```QML
    SpatialItem {
        id: label

        showLinker: true
        size: Qt.size(100, 50)
        target: targetModel
        view: view3D

        linker: ShapePath {
            startX: label.linkerStart.x
            startY: label.linkerStart.y
            strokeColor: "black"
            strokeWidth: 4 * label.scaleFactor

            PathLine {
                x: label.linkerEnd.x
                y: label.linkerEnd.y
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "white"
            radius: 10

            Text {
                anchors.centerIn: parent
                color: "black"
                font.pixelSize: 16
                text: "SpatialUI"
            }
        }
    }
    ```
    - A speech bubble
    ```QML
    SpatialItem {
        id: bubble

        hoverEnabled: true
        mouseEnabled: true
        mouseLinkerEnabled: true
        showLinker: true
        size: Qt.size(200, 50)
        target: targetModel
        view: view3D

        linker: ShapePath {
            capStyle: ShapePath.FlatCap
            fillColor: "white"
            joinStyle: ShapePath.BevelJoin
            startX: bubble.linkerEnd.x - 20 * bubble.scaleFactor
            startY: bubble.linkerEnd.y
            strokeColor: bubble.hovered ? "black" : "white"
            strokeWidth: 2 * bubble.scaleFactor

            PathLine {
                x: bubble.linkerStart.x
                y: bubble.linkerStart.y
            }

            PathLine {
                x: bubble.linkerEnd.x + 20 * bubble.scaleFactor
                y: bubble.linkerEnd.y
            }
        }

        Rectangle {
            anchors.fill: parent
            border.color: bubble.hovered ? "black" : "white"
            border.width: 2
            color: "white"
            radius: 25

            Text {
                anchors.centerIn: parent
                color: "black"
                font.pixelSize: 15
                text: "Hello!"
            }
        }
    }
    ```
  </details>

- **closeUpScaling [bool]**: If true and `fixedSize` is true, the overlay grows when the camera comes close, so the fixed size becomes a minimum size. Defaults to false.
- **cursor [int]**: The cursor shape over the overlay. While `holdDragsTarget` is true, hand cursors replace it. Defaults to `Qt.ArrowCursor`.
- **depthTest [bool]**: If true, overlays are stacked by distance: the overlay of the target closest to the camera is on top. Defaults to false.
- **fixedSize [bool]**: If true, the overlay keeps its `size` on screen whatever the distance to the camera. Defaults to false.
- **forceTopStacking [bool]**: If true, the overlay is placed above its siblings. Several overlays with this set stack in declaration order. Use it for hover effects. Defaults to false.
- **holdDragsTarget [bool]**: If true, pressing the overlay and dragging moves `target` on the horizontal plane through the overlay anchor; the grabbed point stays under the cursor. Needs `mouseEnabled`. Defaults to false.
- **hoverEnabled [bool]**: If true, `hovered` follows the mouse and the `entered()` and `exited()` signals are emitted. Defaults to false.
- **mouseEnabled [bool]**: If true, the overlay receives mouse events through `mouseArea`. Defaults to false.
- **mouseLinkerEnabled [bool]**: If true and `showLinker` is true, the linker receives mouse events through `mouseAreaLinker`, and hovering it sets `hovered`. Hit testing uses the filled area of the linker paths, so a linker drawn as a plain line receives no events. Defaults to false.
- **offsetLinkEnd [vector3d]**: An offset in scene units from the top center of the target bounds. The end of the linker is the projection of this point. Defaults to `Qt.vector3d(0, 0, 0)`.
- **offsetLinkEnd2D [vector2d]**: The offset in pixels from the end of the linker to the overlay center. Defaults to `Qt.vector2d(0, 0)`.
- **offsetLinkStart [vector3d]**: An offset in scene units from the bottom center of the target bounds. The linker starts at the projection of this point. Defaults to `Qt.vector3d(0, 0, 0)`.
- **offsetLinkStart2D [vector2d]**: An offset in pixels added to the projected linker start. Defaults to `Qt.vector2d(0, 0)`.
- **showDraggingLine [bool]**: If true, a line joins the start position of the target to its current position during a drag. Defaults to false.
- **showLinker [bool]**: If true, the paths in `linker` are drawn. Defaults to false.
- **stackingOrder [int]**: The z value of the overlay while `depthTest` and `forceTopStacking` are false. Defaults to 0.
- **stackingOrderLinker [int]**: The z value of the linker relative to its overlay: negative draws it behind the overlay, positive in front. The linker always stacks with its own overlay, above whatever the overlay is above. Defaults to -1.

### Read-only properties

- **camera [Camera]**: The camera of `view`.
- **contentItem [Item]**: The item holding the overlay content.
- **coords [vector2d]**: The end of the linker in view coordinates, equal to `linkerEnd`.
- **distance [real]**: The distance between the camera and the target, in scene units.
- **dragging [bool]**: True while a `holdDragsTarget` drag is in progress.
- **hovered [bool]**: True while the mouse is over the overlay.
- **linkerEnd [vector2d]**: The end of the linker, at the projected `offsetLinkEnd` point. The overlay center is `offsetLinkEnd2D` away from it.
- **linkerStart [vector2d]**: The start of the linker, at the projected `offsetLinkStart` point.
- **mouseArea [MouseArea]**: The MouseArea covering the overlay. Handle clicks and other mouse signals through it, for example `mouseArea.onClicked: ...`.
- **mouseAreaLinker [MouseArea]**: The MouseArea of the linker, active while `mouseLinkerEnabled` and `showLinker` are true.
- **scaleFactor [real]**: The scale applied to the overlay. When `fixedSize` is false, it keeps the overlay at a constant size in the scene (twice the number of pixels one scene unit covers at the target). When `fixedSize` is true, it is 1, or at least 1 with `closeUpScaling`. The overlay content is already scaled; use it for the linker.
- **screenTargetCenterBase [vector2d]**: The projected bottom center of the target bounds.
- **screenTargetOffsetedCenterBase [vector2d]**: The projected bottom center of the target bounds, moved by `offsetLinkStart`.
- **screenTargetOffsetedCenterTop [vector2d]**: The projected top center of the target bounds, moved by `offsetLinkEnd`.
- **targetCenterBase [vector3d]**, **targetCenterTop [vector3d]**: The bottom and top centers of the target bounds, in scene coordinates.

### Signals

- `entered()`: The mouse entered the overlay.
- `exited()`: The mouse left the overlay.

The `MouseArea` signals (`clicked`, `pressed`, `released`, `positionChanged`, `pressAndHold`, `doubleClicked`, `wheel`, `canceled`) are available through `mouseArea`, and through `mouseAreaLinker` for the linker.

## Documentation: ExtendedOrbitCameraController

`ExtendedOrbitCameraController` turns mouse, wheel and touch input into orbit, pan and zoom moves of a camera. It is an extended version of the `OrbitCameraController` of Qt Quick 3D Helpers. Put the camera inside a `Node` and pass that node as `origin`: orbiting rotates the origin, panning moves it, and zooming changes the `z` position of the camera.

```qml
View3D {
    id: view3D

    anchors.fill: parent
    camera: camera

    Node {
        id: originNode

        PerspectiveCamera {
            id: camera

            position: Qt.vector3d(0, 0, 2000)
        }
    }

    ExtendedOrbitCameraController {
        anchors.fill: parent
        origin: originNode
        view: view3D
    }
}
```

Input:
- Dragging with the left button, or with one finger, orbits around the origin.
- Dragging with `buttonsToPan` and `modifiersToPan`, or with two or three fingers, pans the origin in the camera plane.
- The wheel and pinching zoom.
- Double clicking a model tracks it: the origin follows the bottom center of the model, at height 0. Models whose `objectName` starts with `notSelectable` are ignored. Double clicking again, or starting a pan, stops tracking.

### Required properties

- **origin [Node]**: The node the camera orbits around. The camera is a child of it.
- **view [View3D]**: The view the controller drives.

### Properties

- **buttonsToPan [int]**: The mouse buttons that pan. Defaults to `Qt.RightButton`.
- **camera [Camera]**: The camera that zooms. Defaults to `view.camera`.
- **invertScroll [bool]**: If true, the wheel and pinch zoom in the opposite direction. Defaults to false.
- **isTracking [bool]**: True while the origin follows `trackedModel`. Defaults to false.
- **modifiersToPan [int]**: The keyboard modifiers that must be held to pan. Defaults to `Qt.NoModifier`.
- **mouseEnabled [bool]**: Enables orbiting, panning and double click tracking. Defaults to true.
- **panEnabled [bool]**: Enables panning. Defaults to true.
- **pinchZoomSpeed [real]**: The zoom speed of pinching. Defaults to 0.5.
- **scrollSpeed [real]**: The zoom speed of the wheel. Defaults to 1.
- **trackedModel [Model]**: The model the origin follows while `isTracking` is true. Defaults to null.
- **xInvert [bool]**, **yInvert [bool]**: Invert the horizontal and vertical mouse movement when orbiting. Default to false and true.
- **xInvertPanning [bool]**, **yInvertPanning [bool]**: Invert the horizontal and vertical mouse movement when panning. Default to false.
- **xMinAngle [real]**, **xMaxAngle [real]**: The limits, in degrees, of the origin rotation around the X axis. Default to -90 and 90.
- **yMinAngle [real]**, **yMaxAngle [real]**: The limits, in degrees, of the origin rotation around the Y axis. Default to -361 and 361, which leaves it free.
- **xSpeed [real]**, **ySpeed [real]**: The orbit speed for horizontal mouse movement (rotation around the Y axis) and vertical mouse movement (rotation around the X axis). Default to 0.1.
- **xSpeedPanning [real]**, **ySpeedPanning [real]**: The horizontal and vertical pan speed. Default to 0.5.
- **zoomEnabled [bool]**: Enables the wheel and pinch zoom. Defaults to true.

### Read-only properties

- **inputsNeedProcessing [bool]**: True while an orbit or a pan is in progress.
- **panning [bool]**: True while a pan is in progress.

## Add to your project
- Add the project as a submodule from your project root
    - Don't forget to add `--recurse-submodules` when cloning, or run `git submodule update --init`
    - To update the version in your project, run `git submodule update --remote`
```bash
git submodule add -b main https://github.com/Kidev/QtQuick3D-Tools libs/
```
- Add in your `CMakeLists.txt`, after finding the `Quick` and `Quick3D` components of Qt 6, and link your application to the module:
```cmake
add_subdirectory(libs/QtQuick3D/Tools)
target_link_libraries(yourApp PRIVATE QtQuick3DTools)
```
- Then you can import in QML and use `SpatialItem`:
```qml
import QtQuick3D.Tools
```

### Simple example
```qml
import QtQuick
import QtQuick.Shapes
import QtQuick3D
import QtQuick3D.Helpers
import QtQuick3D.Tools

Window {
    id: root

    height: 480
    title: qsTr("QtQuick3D Tools Example")
    visible: true
    width: 640

    View3D {
        id: view3D

        anchors.fill: parent
        camera: perspectiveCamera

        environment: SceneEnvironment {
            backgroundMode: SceneEnvironment.Color
            clearColor: "skyblue"
        }

        Node {
            id: originNode

            PerspectiveCamera {
                id: perspectiveCamera

                fieldOfView: 45
                position: Qt.vector3d(0, 0, 2000)
            }
        }

        OrbitCameraController {
            anchors.fill: parent
            camera: perspectiveCamera
            origin: originNode
            panEnabled: true
        }

        Model {
            id: targetModel

            position: Qt.vector3d(0, 0, 0)
            source: "#Cube"

            materials: [
                DefaultMaterial {
                    diffuseColor: "red"
                }
            ]
        }

        DirectionalLight {
            eulerRotation.x: -30
            eulerRotation.y: -70
        }
    }

    SpatialItem {
        id: spatialUI

        closeUpScaling: true
        fixedSize: spatialUI.hovered
        hoverEnabled: true
        mouseEnabled: true
        offsetLinkEnd: Qt.vector3d(0, 250, 50)
        showLinker: true
        size: Qt.size(100, 50)
        target: targetModel
        view: view3D

        linker: ShapePath {
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.BevelJoin
            startX: spatialUI.linkerStart.x
            startY: spatialUI.linkerStart.y
            strokeColor: spatialUI.hovered ? "black" : "white"
            strokeWidth: 4 * spatialUI.scaleFactor

            PathLine {
                x: spatialUI.linkerEnd.x
                y: spatialUI.linkerEnd.y
            }
        }

        mouseArea.onClicked: console.log("clicked")

        Rectangle {
            anchors.fill: parent
            border.color: spatialUI.hovered ? "white" : "black"
            border.width: spatialUI.hovered ? 4 : 2
            color: spatialUI.hovered ? "black" : "white"
            radius: 10

            Text {
                anchors.centerIn: parent
                color: spatialUI.hovered ? "white" : "black"
                font.pixelSize: 16
                text: "SpatialUI"
            }
        }
    }
}
```

For more advanced uses, tricks, and deploys, you can check [the code of the demo here](https://github.com/Kidev/QtQuick3D-Tools/tree/main/example)

## Building the demo
This works on Linux, Windows and macOS for the architectures `gcc_64`, `clang_64`, `win64_msvc2022_64`, `win64_mingw`, `wasm_singlethread` and `wasm_multithread`. The arm64 architectures are untested.  

- For desktop:
  - Install Qt for your architecture, for example `gcc_64`.  
  - Set `QT_ROOT`, `QT_VERSION`, `QT_ARCH` to the appropriate values for your Qt installation and run: \
    `make desktop QT_ROOT="/opt/Qt" QT_VERSION="6.11.3" QT_ARCH="gcc_64"`  
- For the web:
  - Install Qt for your host and target architectures, for example `gcc_64` AND `wasm_singlethread`.  
  - Enable the following headers (COOP and COEP) on your server:  
    ```
    Cross-Origin-Opener-Policy: same-origin
    Cross-Origin-Embedder-Policy: require-corp
    ```
  - Set `QT_ROOT`, `QT_VERSION`, `QT_HOST_ARCH` and `QT_TARGET_ARCH` to the appropriate values for your Qt installation and run: \
    `make web QT_ROOT="/opt/Qt" QT_VERSION="6.11.3" QT_HOST_ARCH="gcc_64" QT_TARGET_ARCH="wasm_singlethread"`
- You can use `make run` / `make run-web` to run the desktop version / to run the web version in your favorite browser.
- To run the tests, configure with `-DBUILD_TESTS=ON`, build, then run `ctest --test-dir build`. They need a display because Qt Quick 3D only projects the camera after rendering a frame; on a headless Linux machine, wrap the command in `xvfb-run -a`.
- If you use QtCreator, you may get the error `You need to set an executable in the custom run configuration`. To fix it, simply go to `Projects` on the left, select your kit, click on `Current Configuration` and make sure the option `BUILD_EXAMPLE` is ticked ON.

## Credits
- [aaravanimates](https://free3d.com/user/aaravanimates) for the [human 3D model](https://free3d.com/3d-model/rigged-male-human-442626.html) of the example (Personal Use License)
- [Roundicons](https://www.flaticon.com/authors/roundicons) for the [move icon](https://www.flaticon.com/free-icons/move) of the example (Flaticon License)
