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

#Make warnings from MXE cmake wrapper go away
if(CMAKE_CROSSCOMPILING)
    cmake_policy(SET CMP0017 NEW)
    cmake_policy(SET CMP0020 NEW)
endif()


cmake_policy(SET CMP0054 NEW) #Don't derrefernce in if() statements
cmake_policy(SET CMP0022 NEW) #LINK_INTERFACE_LIBRARIES fix

#Fixup library search paths
if(UNIX)
    execute_process(COMMAND ${MexIFace_CMAKE_EXECUTABLES_DIR}/gcc-lib-dir.sh OUTPUT_VARIABLE GCC_LIB_PATH)
    set(FIXUP_LIB_SEARCH_PATH ${CMAKE_SYSTEM_LIBRARY_PATH} ${GCC_LIB_PATH} ${CMAKE_INSTALL_PREFIX}/lib)
    list(INSERT CMAKE_LIBRARY_PATH 0 ${CMAKE_INSTALL_PREFIX})
elseif(WIN32)
    set(MXE_W64_ROOT ${CMAKE_FIND_ROOT_PATH}) #Extract MXE root path for w64 system
    set(FIXUP_LIB_SEARCH_PATH ${MXE_W64_ROOT} ${MXE_W64_ROOT}/bin ${CMAKE_INSTALL_PREFIX}/lib)
else()
endif()

include(MexIFace-configure) #Configure libraries and compile flags

message(STATUS "[MexIFace] FIXUP_LIB_SEARCH_PATH:${FIXUP_LIB_SEARCH_PATH}")
message(STATUS "[MexIFace] FIXUP_LIB_SYSTEM_PATH:${FIXUP_LIB_SYSTEM_PATH}")
include(${MexIFace_CMAKE_FUNCTIONS_DIR}/fixup_dependencies.cmake)

#Directory relative to CMAKE_INSTALL_PREFIX that the compiled mex files will be stored
set(MEX_ARCH_DIR lib/${PROJECT_NAME}/mex/mex.${MATLAB_ARCH}${MexIFace_DEBUG_POSTFIX}/+${PROJECT_NAME}) #Install dir for mex files
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
