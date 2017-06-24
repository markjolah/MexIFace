# MexIface - Main CMakeLists.txt
#
# A Cross-Platform C++ / MEX Object-based interface wrapper and CMake build tool.
#
# Copyright 2013-2017 
# Author: Mark J. Olah 
# Email: (mjo@cs.unm DOT edu)
# 

cmake_minimum_required( VERSION 3.0 )

project(MexIFace VERSION 0.1.0 LANGUAGES CXX)

#Export all these variables in Package
set(MexIFace_CMAKE_DIR ${CMAKE_SOURCE_DIR}/cmake)
set(MexIFace_CMAKE_MODULES_DIR ${MexIFace_CMAKE_DIR}/Modules)
set(MexIFace_CMAKE_TOOLCHAINS_DIR ${MexIFace_CMAKE_DIR}/Toolchains)
set(MexIFace_CMAKE_BUILDCONFIG_DIR ${MexIFace_CMAKE_DIR}/BuildConfig)
set(MexIFace_CMAKE_SCRIPTS_DIR ${MexIFace_CMAKE_DIR}/Scripts)
set(MexIFace_CMAKE_TEMPLATES_DIR ${MexIFace_CMAKE_DIR}/Templates)
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${MexIFace_CMAKE_MODULES_DIR})

include(MexIFace)
include(MexIFace-Doxygen)
include(MexIFace-PackageConfig)

add_subdirectory(src)
