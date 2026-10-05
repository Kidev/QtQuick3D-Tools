#!/bin/bash

QT_ROOT=$1
QT_VERSION=$2
QT_HOST_ARCH=$3
QT_TARGET_ARCH=$4
EMSDK_VERSION=""

case "$QT_VERSION" in
    6.2*) EMSDK_VERSION="2.0.14" ;;
    6.3*) EMSDK_VERSION="3.0.0" ;;
    6.4*) EMSDK_VERSION="3.1.14" ;;
    6.5*) EMSDK_VERSION="3.1.25" ;;
    6.6*) EMSDK_VERSION="3.1.37" ;;
    6.7*) EMSDK_VERSION="3.1.50" ;;
    6.8*) EMSDK_VERSION="3.1.56" ;;
    6.10*) EMSDK_VERSION="4.0.7" ;;
    6.11*) EMSDK_VERSION="4.0.7" ;;
    *)
        echo "Unsupported Qt version: $QT_VERSION"
        exit 1
        ;;
esac

QT_VERSION_NAME="Qt${QT_VERSION:0:1}"
QT_ROOT_TARGET="${QT_ROOT}/${QT_VERSION}/${QT_TARGET_ARCH}"
QT_HOST_PATH="${QT_ROOT}/${QT_VERSION}/${QT_HOST_ARCH}"
QT_HOST_CMAKE_DIR="${QT_HOST_PATH}/lib/cmake"
QT_MODULE_PATH="${QT_ROOT_TARGET}/lib/cmake/${QT_VERSION_NAME}"
QT_TOOLCHAIN="${QT_ROOT_TARGET}/lib/cmake/${QT_VERSION_NAME}/qt.toolchain.cmake"

if [ ! -d "emsdk" ]; then
    git clone https://github.com/emscripten-core/emsdk.git
fi

INSTALLED_VERSION=$(./emsdk/emsdk list | grep '\*' | grep -oP '^\* \K[^\s]+')
if [ "$INSTALLED_VERSION" != "$EMSDK_VERSION" ]; then
    ./emsdk/emsdk install ${EMSDK_VERSION}
fi

ACTIVE_VERSION=$(./emsdk/emsdk list | grep 'ACTIVE' | grep -oP '^\* \K[^\s]+')
if [ "$ACTIVE_VERSION" != "$EMSDK_VERSION" ]; then
    ./emsdk/emsdk activate ${EMSDK_VERSION}
    source ./emsdk/emsdk_env.sh
fi

mkdir -p build
./emsdk/upstream/emscripten/emcmake cmake -G Ninja -S . -B build \
  -DQT_HOST_PATH=${QT_HOST_PATH} \
  -DQT_HOST_PATH_CMAKE_DIR=${QT_HOST_CMAKE_DIR} \
  -DQt6_DIR=${QT_MODULE_PATH} \
  -DCMAKE_TOOLCHAIN_FILE=${QT_TOOLCHAIN} \
  -DCMAKE_PREFIX_PATH=${QT_ROOT_TARGET} \
  -DEMSCRIPTEN=ON \
  -DCMAKE_BUILD_TYPE=MinSizeRel \
  -DBUILD_EXAMPLE=ON
cmake --build build/

cp example/img/favicon.ico build/example/favicon.ico -f
cp example/img/logo.png build/example/logo.png -f
cp example/img/github.png build/example/github.png -f
cp example/img/move.png build/example/move.png -f

mv build/example/exampleExec.html build/example/index.html

sed -i 's#<title>exampleExec</title>#<title>QtQuick3D Tools Demo | Kidev.org<\/title><link rel="icon" href="favicon.ico" type="image/x-icon">#g' build/example/index.html
sed -i "s#<strong>Qt for WebAssembly: exampleExec</strong>#<h1 style='color:\#ffffff;'><strong>QtQuick3D Tools</strong></h1><span style='color:\#ffffff;'>Written by Kidev using Qt</span><br><br><img src='qtlogo.svg' width='160' height='100' style='display:block'>#g" build/example/index.html
sed -i "s# height: 100% }# height: 100%; background-color:\#01010c; }#g" build/example/index.html
sed -i 's#<img src="qtlogo.svg" width="320" height="200" style="display:block"></img>#<img src="logo.png" width="260" height="260" style="display:block">#g' build/example/index.html
sed -i 's#<div id="qtstatus">#<div id="qtstatus" style="color:\#ffffff; font-weight:bold">#g' build/example/index.html
sed -i 's#undefined ? ` with code ` :#undefined ? ` with code ${exitData.code}` :#g' build/example/index.html
sed -i 's#undefined ? ` ()` :#undefined ? `<br><span style="color:\#ff0000">Error: ${exitData.text}</span>` :#g' build/example/index.html
sed -i 's/\/\*.*\*\///g' build/example/index.html
sed -i '/<!--/,/-->/d' build/example/index.html

rm -rf build/example/.[\!.]* build/example/.?*
rm -rf build/example/CMakeFiles
rm -rf build/example/example
rm -rf build/example/exampleExec_autogen
rm -rf build/example/meta_types
rm -rf build/example/qmltypes
rm -f build/example/cmake_install.cmake
rm -f build/example/*.cpp

find build/example -type f \( -name "*.js" -o -name "*.css" -o -name "*.html" -o -name "*.wasm" -o -name "*.png" -o -name "*.ico" -o -name "*.mesh" \) -exec brotli --best --force {} \;
