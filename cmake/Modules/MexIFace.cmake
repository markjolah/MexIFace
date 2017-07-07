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

#Fixup library search paths
if(UNIX)
    execute_process(COMMAND ${MexIFace_CMAKE_EXECUTABLES_DIR}/gcc-lib-dir.sh OUTPUT_VARIABLE GCC_LIB_PATH)
    set(FIXUP_LIB_SEARCH_PATH ${CMAKE_SYSTEM_LIBRARY_PATH} ${GCC_LIB_PATH})
elseif(WIN32)
    set(FIXUP_LIB_SEARCH_PATH ${CMAKE_FIND_ROOT_PATH} )
else()
endif()
set(FIXUP_LIB_IGNORE_PATH ${MATLAB_LIB_DIR}) # Don't include matlab directories in fixup.  Matlab will provide.


message(STATUS "[MexIFace] FIXUP_LIB_SEARCH_PATH:${FIXUP_LIB_SEARCH_PATH}")
include(${MexIFace_CMAKE_FUNCTIONS_DIR}/fixup_dependencies.cmake)

#Directory relative to CMAKE_INSTALL_PREFIX that the compiled mex files will be stored
set(MEX_ARCH_DIR lib/${PROJECT_NAME}/mex/mex.${MATLAB_ARCH}${MexIFace_DEBUG_POSTFIX}) #Install dir for mex files
message(STATUS "[MexIFace] MEX_ARCH_DIR:${MEX_ARCH_DIR}")
include(${MexIFace_CMAKE_FUNCTIONS_DIR}/make_mex.cmake) 

#Install matlab code
set(MATLAB_CODE_INSTALL_DIR lib/${PROJECT_NAME})
install(DIRECTORY matlab DESTINATION ${MATLAB_CODE_INSTALL_DIR} COMPONENT Runtime)

#Configure and install matlab startup file named share/<PROJECT_NAME>/matlab/startuo<PROJECT_NAME>.m
set(MATLAB_STARTUP_FILE_NAME startup${PROJECT_NAME}.m)
set(MATLAB_STARTUP_FILE_INSTALL_DIR share/${PROJECT_NAME}/matlab)
configure_file(${MexIFace_CMAKE_TEMPLATES_DIR}/startupMexIFace.m.in ${CMAKE_BINARY_DIR}/matlab/${MATLAB_STARTUP_FILE_NAME} @ONLY)
install(FILES ${CMAKE_BINARY_DIR}/matlab/${MATLAB_STARTUP_FILE_NAME} 
        DESTINATION ${CMAKE_INSTALL_PREFIX}/${MATLAB_STARTUP_FILE_INSTALL_DIR} COMPONENT Runtime)
