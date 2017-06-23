#!/bin/bash

DIRS=`gcc-config -L`
DIRS_ARR=(${DIRS//:/ })
echo -n ${DIRS_ARR[0]}

