#!/bin/bash

QT_ROOT=$1
QT_VERSION=$2
QT_ARCH=$3

QT_ROOT_ARCH="${QT_ROOT}/${QT_VERSION}/${QT_ARCH}"

mkdir -p build
cmake -G Ninja -S . -B build -DCMAKE_PREFIX_PATH=${QT_ROOT_ARCH} -DBUILD_EXAMPLE=ON
cmake --build build/
