qt_add_qml_module(
    QtQuick3DTools
    URI "QtQuick3D.Tools"
    CLASS_NAME QtQuick3DToolsPlugin
    PLUGIN_TARGET qtquick3dtoolsplugin
    QML_FILES SpatialItem.qml ExtendedOrbitCameraController.qml
    RESOURCE_PREFIX "/qt/qml"
)
