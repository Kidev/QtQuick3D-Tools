cmake_minimum_required(VERSION 3.20)
project(QtQuick3DTools LANGUAGES CXX)

set(CMAKE_AUTOMOC ON)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

option(DEBUG "Set debug mode, disable QML compilation" OFF)
option(BUILD_EXAMPLE "Build the example application" OFF)
option(BUILD_TESTS "Build the QML tests" OFF)

find_package(
    Qt6 6.11 REQUIRED
    COMPONENTS Core
               Gui
               Quick
               Quick3D
               Qml
)

qt_standard_project_setup(REQUIRES 6.11)

if (EMSCRIPTEN)
    set(QT_WASM_INITIAL_MEMORY 33554432)
endif ()

add_subdirectory(QtQuick3D/Tools)
if (BUILD_EXAMPLE)
    add_subdirectory(example)
endif ()
if (BUILD_TESTS)
    enable_testing()
    add_subdirectory(tests)
endif ()
