find_package(Qt6 REQUIRED COMPONENTS QuickTest)

qt_add_executable(tst_qtquick3dtools tst_qtquick3dtools.cpp)

target_compile_definitions(
    tst_qtquick3dtools PRIVATE QUICK_TEST_SOURCE_DIR="${CMAKE_CURRENT_SOURCE_DIR}"
)

target_link_libraries(
    tst_qtquick3dtools
    PRIVATE Qt6::Gui
            Qt6::Quick
            Qt6::Quick3D
            Qt6::QuickTest
)

add_test(NAME tst_qtquick3dtools COMMAND tst_qtquick3dtools -import ${CMAKE_BINARY_DIR})

add_test(
    NAME qt_version_pin
    COMMAND ${CMAKE_COMMAND} -DSOURCE_DIR=${PROJECT_SOURCE_DIR} -P ${CMAKE_CURRENT_SOURCE_DIR}/check_qt_pin.cmake
)
