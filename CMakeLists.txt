# MexIface - Main CMakeLists.txt
#
# A Cross-Platform C++ / MEX Object-based interface wrapper and CMake build tool.
#
# Mark J. Olah (mjo@cs.unm DOT edu)
# Copyright 2014-2017
# Licensed under the Apache License, Version 2.0
# https://www.apache.org/licenses/LICENSE-2.0
# See: LICENCE file

cmake_minimum_required( VERSION 3.9 )

project(MexIFace VERSION 0.1.0 LANGUAGES CXX)

option(OPT_EXTRA_DEBUG "Support extra noisy debugging features" OFF) #Extra debug features (Armadillo)


#Locations of the MexIFace cmake build system components
#Export all these variables in package-config also.
set(MexIFace_CMAKE_DIR ${CMAKE_SOURCE_DIR}/cmake)
set(MexIFace_CMAKE_MODULES_DIR ${MexIFace_CMAKE_DIR}/Modules)
set(MexIFace_CMAKE_TOOLCHAINS_DIR ${MexIFace_CMAKE_DIR}/Toolchains)
set(MexIFace_CMAKE_FUNCTIONS_DIR ${MexIFace_CMAKE_DIR}/Functions)
set(MexIFace_CMAKE_EXECUTABLE_DIR ${MexIFace_CMAKE_DIR}/Executables)
set(MexIFace_CMAKE_TEMPLATES_DIR ${MexIFace_CMAKE_DIR}/Templates)
list(INSERT CMAKE_MODULE_PATH 0 ${MexIFace_CMAKE_MODULES_DIR} ${MexIFace_CMAKE_FUNCTIONS_DIR})
list(INSERT CMAKE_MODULE_PATH 0 ${CMAKE_CURRENT_LIST_DIR}/cmake/UncommonCmakeModules)

include(AddExternalDependency)
#BacktraceException allows for exceptions that encode a backtrace for debugging
set(BacktraceExceptionURL https://github.com/markjolah/BacktraceException.git)
add_external_dependency(NAME BacktraceException URL ${BacktraceExceptionURL} SHARED)

include(MexIFace-configure)

# Optionally enable extra debugging from armadillo to log every call.
if( (${CMAKE_BUILD_TYPE} MATCHES Debug) AND MexIFace_EXTRA_DEBUG)
    add_definitions(-DARMA_EXTRA_DEBUG)
endif()

#Debugging configuration
include(ConfigureDebugBuilds)

include(MexIFace-configure) #Add Doxygen documentation targets
include(MexIFace-Doxygen) #Add Doxygen documentation targets

include(ExportPackageWizzard)
export_package_wizzard()

#Matlab code install
set(MATLAB_CODE_INSTALL_DIR lib/${PROJECT_NAME})
install(DIRECTORY matlab DESTINATION ${MATLAB_CODE_INSTALL_DIR} COMPONENT Runtime)

#Configure and install matlab startup file named share/<PROJECT_NAME>/matlab/startup<PROJECT_NAME>.m
set(MATLAB_STARTUP_FILE_NAME startup${PROJECT_NAME}.m)
set(MATLAB_STARTUP_FILE_INSTALL_DIR share/${PROJECT_NAME}/matlab)
configure_file(${MexIFace_CMAKE_TEMPLATES_DIR}/startupMexIFace.m.in ${CMAKE_BINARY_DIR}/matlab/${MATLAB_STARTUP_FILE_NAME} @ONLY)
install(FILES ${CMAKE_BINARY_DIR}/matlab/${MATLAB_STARTUP_FILE_NAME}
        DESTINATION ${CMAKE_INSTALL_PREFIX}/${MATLAB_STARTUP_FILE_INSTALL_DIR} COMPONENT Runtime)

#Install Cmake modules and helper files for development
set(SHARED_CMAKE_INSTALL_DIR share/${PROJECT_NAME}/cmake)
install(DIRECTORY ${MexIFace_CMAKE_MODULES_DIR}/ DESTINATION ${SHARED_CMAKE_INSTALL_DIR}/Modules COMPONENT Development)
install(DIRECTORY ${MexIFace_CMAKE_TOOLCHAINS_DIR}/ DESTINATION ${SHARED_CMAKE_INSTALL_DIR}/Toolchains COMPONENT Development)
install(DIRECTORY ${MexIFace_CMAKE_FUNCTIONS_DIR}/ DESTINATION ${SHARED_CMAKE_INSTALL_DIR}/Functions COMPONENT Development)
install(DIRECTORY ${MexIFace_CMAKE_EXECUTABLE_DIR}/ DESTINATION ${SHARED_CMAKE_INSTALL_DIR}/Excecutables COMPONENT Development)
install(DIRECTORY ${MexIFace_CMAKE_TEMPLATES_DIR}/ DESTINATION ${SHARED_CMAKE_INSTALL_DIR}/Templates COMPONENT Development)

add_subdirectory(src)

