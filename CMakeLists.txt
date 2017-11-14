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

include(MexIFace) #Configure necessary libraries
include(MexIFace-Doxygen) #Add Doxygen documentation targets
include(MexIFace-PackageConfig) #Configure Package-Config and associated files for cmake exports

add_subdirectory(src)

