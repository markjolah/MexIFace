# MexIface - Main CMakeLists.txt
#
# A Cross-Platform C++ / MEX Object-based interface wrapper and CMake build tool.
#
# Mark J. Olah (mjo@cs.unm DOT edu)
# Copyright 2014-2017
# Licensed under the Apache License, Version 2.0
# https://www.apache.org/licenses/LICENSE-2.0
# See: LICENCE file

cmake_minimum_required( VERSION 3.5 )

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

include(AddExternalDependency)
#BacktraceException allows for exceptions that encode a backtrace for debugging
set(BacktraceExceptionURL https://github.com/markjolah/BacktraceException.git)
AddExternalDependency(BacktraceException ${BacktraceExceptionURL} SHARED)

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
add_compile_options($<$<AND:$<CONFIG:Debug>,$<CXX_COMPILER_ID:GNU>>:-O0>) #No optimization for debugging
#Add warnings in debug configurations
add_compile_options($<$<CONFIG:Debug>:-W>)
add_compile_options($<$<CONFIG:Debug>:-Wall>)
add_compile_options($<$<CONFIG:Debug>:-Wextra>)
set_property(DIRECTORY APPEND PROPERTY COMPILE_DEFINITIONS $<$<CONFIG:Debug>:DEBUG>) 
set(CMAKE_DEBUG_POSTFIX ".debug" CACHE STRING "Debug file extension")
#Limit # of errors reported by gcc
set_property(DIRECTORY APPEND PROPERTY COMPILE_OPTIONS $<$<AND:$<CONFIG:Debug>,$<CXX_COMPILER_ID:GNU>>:-fmax-errors=5>)

include(MexIFace) #Configure necessary libraries
include(MexIFace-Doxygen) #Add Doxygen documentation targets
include(MexIFace-PackageConfig) #Configure Package-Config and associated files for cmake exports

add_subdirectory(src)

