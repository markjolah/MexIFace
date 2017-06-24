#!/bin/bash

INSTALL_PATH=_install
BUILD_PATH=_build

rm -rf $INSTALL_PATH $BUILD_PATH

set -e

cmake -H. -B$BUILD_PATH/Debug -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH -DCMAKE_BUILD_TYPE=Debug
cmake -H. -B$BUILD_PATH/Release -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH -DCMAKE_BUILD_TYPE=Release
cmake --build $BUILD_PATH/Debug --target install
cmake --build $BUILD_PATH/Release --target install
