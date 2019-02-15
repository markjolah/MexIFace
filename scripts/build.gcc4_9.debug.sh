#!/bin/bash
#
# scripts/build.gcc4_9.debug.sh
# Build with gcc4_9 toolchain

ARCH=gcc4_9
FULL_ARCH=x86_64-${ARCH}-linux-gnu
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SRC_PATH=${SCRIPT_DIR}/..
TOOLCHAIN_FILE=${SRC_PATH}/cmake/UncommonCMakeModules/Toolchains/Toolchain-${FULL_ARCH}.cmake
INSTALL_PATH=${SRC_PATH}/_${ARCH}.install
BUILD_PATH=${SRC_PATH}/_${ARCH}.build/Debug
NUM_PROCS=`grep -c ^processor /proc/cpuinfo`

ARGS="-DCMAKE_TOOLCHAIN_FILE=$TOOLCHAIN_FILE"
ARGS="${ARGS} -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH"
ARGS="${ARGS} -DBUILD_TESTING=On"
ARGS="${ARGS} -DOPT_DOC=On"
ARGS="${ARGS} -DOPT_EXTRA_DEBUG=Off"
ARGS="${ARGS} -DOPT_INSTALL_TESTING=On"
ARGS="${ARGS} -DOPT_EXPORT_BUILD_TREE=On"
ARGS="${ARGS} -DOPT_FIXUP_DEPENDENCIES=On"
ARGS="${ARGS} -DOPT_FIXUP_DEPENDENCIES_BUILD_TREE=On"
ARGS="${ARGS} -DOPT_FIXUP_DEPENDENCIES_COPY_GCC_LIBS=On"
ARGS="${ARGS} -DOPT_MexIFace_PROFILE=Off"

set -ex
rm -rf $BUILD_PATH
cmake -H${SRC_PATH} -B$BUILD_PATH -DCMAKE_BUILD_TYPE=Debug $ARGS $@
VERBOSE=1 cmake --build $BUILD_PATH --target pdf -- -j$NUM_PROCS
VERBOSE=1 cmake --build $BUILD_PATH --target install -- -j$NUM_PROCS
