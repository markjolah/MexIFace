#!/bin/bash

INSTALL_PATH=_install
BUILD_PATH=_build/Debug

rm -rf $INSTALL_PATH $BUILD_PATH

set -e

cmake -H. -B$BUILD_PATH -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH -DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=1
VERBOSE=1 cmake --build $BUILD_PATH --target install -- -j8
