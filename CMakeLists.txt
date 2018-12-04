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

#Locations of the MexIFace cmake build system components
#Export all these variables in package-config also.
set(MexIFace_CMAKE_DIR ${CMAKE_SOURCE_DIR}/cmake)
set(MexIFace_CMAKE_MODULES_DIR ${MexIFace_CMAKE_DIR}/Modules)
set(MexIFace_CMAKE_TOOLCHAINS_DIR ${MexIFace_CMAKE_DIR}/Toolchains)
set(MexIFace_CMAKE_FUNCTIONS_DIR ${MexIFace_CMAKE_DIR}/Functions)
set(MexIFace_CMAKE_EXECUTABLE_DIR ${MexIFace_CMAKE_DIR}/Executables)
set(MexIFace_CMAKE_TEMPLATES_DIR ${MexIFace_CMAKE_DIR}/Templates)
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${MexIFace_CMAKE_MODULES_DIR} ${MexIFace_CMAKE_FUNCTIONS_DIR})

list(INSERT CMAKE_MODULE_PATH 0 ${CMAKE_CURRENT_LIST_DIR}/cmake/UncommonCmakeModules)

include(AddExternalDependency)
#BacktraceException allows for exceptions that encode a backtrace for debugging
set(BacktraceExceptionURL https://github.com/markjolah/BacktraceException.git)
add_external_dependency(NAME BacktraceException URL ${BacktraceExceptionURL} SHARED)

#Debugging configuration
include(ConfigureIPO)

# Armadillo
find_package(Armadillo REQUIRED)
add_definitions(-DARMA_USE_CXX11 -DARMA_DONT_USE_WRAPPER -DARMA_BLAS_LONG)
add_definitions(-DARMA_DONT_USE_OPENMP)
add_definitions(-DARMA_DONT_USE_HDF5)
if(${CMAKE_BUILD_TYPE} MATCHES Debug)
    add_definitions(-DARMA_PRINT_ERRORS)
else()
    add_definitions(-DARMA_NO_DEBUG)
endif()
# Optionally enable extra debugging from armadillo to log every call.
if( (${CMAKE_BUILD_TYPE} MATCHES Debug) AND MexIFace_EXTRA_DEBUG)
    add_definitions(-DARMA_EXTRA_DEBUG)
endif()

#Debugging configuration
include(ConfigureDebugBuilds)

include(MexIFace) #Configure necessary libraries
include(MexIFace-Doxygen) #Add Doxygen documentation targets

include(ExportPackageWizzard)
export_package_wizzard()

set(SHARED_CMAKE_INSTALL_DIR share/${PROJECT_NAME}/cmake) #Where to install shared .cmake build scripts for downstream

add_subdirectory(src)

