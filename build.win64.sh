#!/bin/bash

ARCH=win64
INSTALL_PATH=_${ARCH}.install
BUILD_PATH=_${ARCH}.build
CMAKE="${MEXIFACE_MXE_ROOT}/usr/bin/x86_64-w64-mingw32.shared-cmake"
rm -rf $INSTALL_PATH $BUILD_PATH

set -e

${CMAKE} -H. -B$BUILD_PATH/Debug -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH -DCMAKE_BUILD_TYPE=Debug
VERBOSE=1 ${CMAKE} --build $BUILD_PATH/Debug --target install -- -j4
