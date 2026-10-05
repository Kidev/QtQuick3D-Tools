set(EXAMPLE_SOURCES main.cpp)
set(EXAMPLE_QML MainScene.qml)
set(
    EXAMPLE_RESOURCES
    meshes/human.mesh
    img/move.png
    img/favicon.ico
    img/logo.png
    img/github.png
)

qt_add_executable(exampleExec ${EXAMPLE_SOURCES})

if (DEBUG)
    qt_add_qml_module(
        exampleExec
        URI example
        QML_FILES ${EXAMPLE_QML}
        NO_CACHEGEN NO_LINT
        RESOURCES ${EXAMPLE_RESOURCES}
        NO_RESOURCE_TARGET_PATH
    )
else ()
    qt_add_qml_module(
        exampleExec
        URI example
        QML_FILES ${EXAMPLE_QML}
        RESOURCES ${EXAMPLE_RESOURCES}
        NO_RESOURCE_TARGET_PATH
    )
endif ()

if (MSVC)
    target_compile_options(exampleExec PUBLIC /W4 /WX)
elseif (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    target_compile_options(exampleExec PUBLIC -Wall -Werror -Wpedantic)
elseif (CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
    target_compile_options(exampleExec PUBLIC -Wall -Werror -Wpedantic)
else ()
    message(WARNING "Unknown compiler, no flags set.")
endif ()

target_link_libraries(
    exampleExec
    PRIVATE Qt6::Core
            Qt6::Gui
            Qt6::Quick
            Qt6::Quick3D
            Qt6::Qml
)

if (EMSCRIPTEN)
    target_link_libraries(exampleExec PUBLIC qtquick3dtoolsplugin)
    target_compile_options(exampleExec PUBLIC -Os -DNDEBUG)
else ()
    target_link_libraries(exampleExec PUBLIC QtQuick3DTools)
endif ()

set_target_properties(
    exampleExec
    PROPERTIES MACOSX_BUNDLE_GUI_IDENTIFIER org.kidev.qtquick3d.tools
               MACOSX_BUNDLE TRUE
               WIN32_EXECUTABLE TRUE
)

install(
    TARGETS exampleExec
    BUNDLE DESTINATION .
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
)

qt_generate_deploy_qml_app_script(
    TARGET exampleExec
    OUTPUT_SCRIPT deploy_script
    MACOS_BUNDLE_POST_BUILD NO_UNSUPPORTED_PLATFORM_ERROR
    DEPLOY_USER_QML_MODULES_ON_UNSUPPORTED_PLATFORM
)
install(SCRIPT ${deploy_script})
