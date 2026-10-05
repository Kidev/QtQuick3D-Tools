# Fails when a copy of the Qt version pin differs from the Makefile default.
# Usage: cmake -DSOURCE_DIR=<repository root> -P check_qt_pin.cmake

file(READ "${SOURCE_DIR}/Makefile" makefile)
string(REGEX MATCH "QT_VERSION \\?= ([0-9]+\\.[0-9]+\\.[0-9]+)" _ "${makefile}")
set(pin "${CMAKE_MATCH_1}")
if (NOT pin)
    message(FATAL_ERROR "Makefile: no QT_VERSION default")
endif ()
string(REGEX MATCH "^[0-9]+\\.[0-9]+" pin_minor "${pin}")

set(failed FALSE)

function (check_copies file regex expected)
    file(READ "${SOURCE_DIR}/${file}" content)
    string(REGEX MATCHALL "${regex}" matches "${content}")
    if (NOT matches)
        message(SEND_ERROR "${file}: no Qt version found")
    endif ()
    foreach (match IN LISTS matches)
        string(REGEX MATCH "[0-9]+\\.[0-9]+(\\.[0-9]+)?" version "${match}")
        if (NOT version STREQUAL expected)
            message(SEND_ERROR "${file}: '${match}' does not match ${expected}")
        endif ()
    endforeach ()
endfunction ()

check_copies(.github/workflows/build-check.yml "qt_version: '[0-9.]+'" "${pin}")
check_copies(.github/workflows/build-deploy-demo.yml "qt_version: '[0-9.]+'" "${pin}")
check_copies(.github/workflows/tests.yml "qt_version: '[0-9.]+'" "${pin}")
check_copies(README.md "QT_VERSION=\"[0-9.]+\"" "${pin}")
check_copies(CMakeLists.txt "Qt6 [0-9.]+ REQUIRED" "${pin_minor}")
check_copies(CMakeLists.txt "REQUIRES [0-9.]+" "${pin_minor}")
