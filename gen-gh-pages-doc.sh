#!/bin/bash

GH_PAGES_DIR=./_gh-pages
BUILD_PATH=_build/gh-pages
HTML_DIR="${BUILD_PATH}/doc/html"
rm -rf $BUILD_PATH
set -e

cmake -H. -B$BUILD_PATH -DCMAKE_BUILD_TYPE=Release
cmake --build $BUILD_PATH --target pdf
rsync -r --delete ${HTML_DIR}/ ${GH_PAGES_DIR}/html/doc
cp ${BUILD_PATH}/doc/pdf/*.pdf ${GH_PAGES_DIR}/html/doc/
cd ${GH_PAGES_DIR} 
git add -A html/doc/
git ci -m "gh-pages autobuild `date`"
