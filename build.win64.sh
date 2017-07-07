#!/bin/bash

ARCH=win64
INSTALL_PATH=_${ARCH}.install
BUILD_PATH=_${ARCH}.build
CMAKE="${MEXIFACE_MXE_ROOT}/usr/x86_64-unknown-linux-gnu/bin/cmake"
CMAKE="cmake"
TOOLCHAIN="${MEXIFACE_MXE_ROOT}/usr/x86_64-w64-mingw32.shared/share/cmake/mxe-conf.cmake"
rm -rf $INSTALL_PATH $BUILD_PATH

set -e

${CMAKE} -H. -B$BUILD_PATH/Debug -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH -DCMAKE_BUILD_TYPE=Debug -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN}
#${CMAKE} -H. -B$BUILD_PATH/Release -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH -DCMAKE_BUILD_TYPE=Release -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN}
VERBOSE=1 ${CMAKE} --build $BUILD_PATH/Debug --target install -- -j4
#VERBOSE=1 ${CMAKE} --build $BUILD_PATH/Release --target install -- -j4
