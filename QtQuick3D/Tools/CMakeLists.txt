# SpatialItem uses the C++ classes of Qt Quick, Qt Quick Shapes and Qt Quick 3D, which Qt ships as private API.
set(QT_NO_PRIVATE_MODULE_WARNING ON)
find_package(
    Qt6 REQUIRED
    COMPONENTS QuickPrivate
               QuickShapesPrivate
               Quick3DPrivate
)

qt_add_qml_module(
    QtQuick3DTools
    URI "QtQuick3D.Tools"
    CLASS_NAME QtQuick3DToolsPlugin
    PLUGIN_TARGET qtquick3dtoolsplugin
    SOURCES spatialitem.h spatialitem.cpp
    DEPENDENCIES QtQuick QtQuick3D
    QML_FILES ExtendedOrbitCameraController.qml
    RESOURCE_PREFIX "/qt/qml"
)

set_target_properties(QtQuick3DTools PROPERTIES AUTOMOC ON)

target_link_libraries(
    QtQuick3DTools
    PRIVATE Qt6::QuickPrivate
            Qt6::QuickShapesPrivate
            Qt6::Quick3DPrivate
)
