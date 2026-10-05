QT_ROOT ?= /opt/Qt
QT_VERSION ?= 6.11.3
QT_ARCH ?= gcc_64
QT_HOST_ARCH ?= gcc_64
QT_TARGET_ARCH ?= wasm_singlethread

all: desktop run

desktop: clean
	./example/build.sh "$(QT_ROOT)" "$(QT_VERSION)" "$(QT_ARCH)"

web: clean
	./example/build-web.sh "$(QT_ROOT)" "$(QT_VERSION)" "$(QT_HOST_ARCH)" "$(QT_TARGET_ARCH)"

run-web:
	./emsdk/upstream/emscripten/emrun ./build/example/index.html --kill_start --kill_exit

run:
	./build/example/exampleExec

clean:
	rm -rf build CMakeLists.txt.user

.PHONY: clean run run-web
