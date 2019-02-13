#!/bin/bash
# doc-build.sh <cmake args ...>
# Build documentation into the build tree

BUILD_PATH=_build/documentation
NUM_PROCS=`grep -c ^processor /proc/cpuinfo`

ARGS=""
ARGS="${ARGS} -DOPT_DOC=On"

set -ex
#rm -rf $BUILD_PATH

cmake -H. -B$BUILD_PATH -DCMAKE_BUILD_TYPE=Debug -Wdev ${ARGS} $@
VERBOSE=1 cmake --build $BUILD_PATH --target doc -- -j${NUM_PROCS}
