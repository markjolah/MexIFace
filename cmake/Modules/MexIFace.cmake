# MexIFace.cmake
#
# Mark J. Olah (mjo@cs.unm DOT edu)
# Copyright 2014-2017
# Licensed under the Apache License, Version 2.0
# https://www.apache.org/licenses/LICENSE-2.0
# See: LICENCE file
#
# A Cross-Platform C++ / MEX Object-based interface wrapper and CMake build tool.
#
# This is the main module to enable the MexIFace support.  This should be inlcuded by target projects
#

include(MexIFace-configure) #Configure libraries and compile flags

set(MEX_INSTALL_DIR lib/${PROJECT_NAME}/mex/mex.${MATLAB_ARCH}${MexIFace_DEBUG_POSTFIX}) #Install dir for mex files
message(STATUS "[MexIFace] MEX_INSTALL_DIR:${MEX_INSTALL_DIR}")

include(MexIFace-makemex) #Import the make_mex function

#Install matlab code
set(MATLAB_CODE_INSTALL_DIR lib/${PROJECT_NAME})
install(DIRECTORY matlab DESTINATION ${MATLAB_CODE_INSTALL_DIR} COMPONENT Runtime)
#Configure and install matlab startup file named share/<PROJECT_NAME>/matlab/startuo<PROJECT_NAME>.m
set(MATLAB_STARTUP_FILE_NAME startup${PROJECT_NAME}.m)
set(MATLAB_STARTUP_FILE_INSTALL_DIR share/${PROJECT_NAME}/matlab)
configure_file(${MexIFace_CMAKE_TEMPLATES_DIR}/startupMexIFace.m.in ${CMAKE_BINARY_DIR}/matlab/${MATLAB_STARTUP_FILE_NAME} @ONLY)
install(FILES ${CMAKE_BINARY_DIR}/matlab/${MATLAB_STARTUP_FILE_NAME} 
        DESTINATION ${CMAKE_INSTALL_PREFIX}/${MATLAB_STARTUP_FILE_INSTALL_DIR} COMPONENT Runtime)

