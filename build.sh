#!/bin/bash
# build.sh <cmake-args...>
#
# MexIFace default build script.
#
# Requires a base system with gcc-6.5 for matlab 2018a+ or gcc-4.9.4 for matlab 2016b+
#
# Clean release-only build to local install prefix with build-tree export support.
# Cleans up build and install directories.  For safety, deletes the install dir
# if and only if INSTALL_PATH hasn't been modified from the default "_install"


INSTALL_PATH=_install
BUILD_PATH=_build
NUM_PROCS=`grep -c ^processor /proc/cpuinfo`

ARGS="-DCMAKE_INSTALL_PREFIX=$INSTALL_PATH"
ARGS="${ARGS} -DBUILD_STATIC_LIBS=ON"
ARGS="${ARGS} -DBUILD_SHARED_LIBS=ON"
ARGS="${ARGS} -DOPT_DOC=Off"
ARGS="${ARGS} -DBUILD_TESTING=On"
ARGS="${ARGS} -DOPT_INSTALL_TESTING=On"
ARGS="${ARGS} -DOPT_EXPORT_BUILD_TREE=On"
ARGS="${ARGS} -DCMAKE_FIND_PACKAGE_NO_PACKAGE_REGISTRY=On" #Otherwise dependencies found in build directories won't be found in install tree unless LD_LIBRARY_PATH is modified
ARGS="${ARGS} -DOPT_BLAS_INT64=ON"

set -ex

if [ "$INSTALL_PATH" == "_install" ]; then
    rm -rf _install
fi

rm -rf $BUILD_PATH/Release
cmake -H. -B$BUILD_PATH/Release -DCMAKE_BUILD_TYPE=Release ${ARGS}
cmake --build $BUILD_PATH/Release --target install -- -j${NUM_PROCS}
