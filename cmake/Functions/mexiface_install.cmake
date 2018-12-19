# mexiface_install.cmake
#
# Mark J. Olah (mjo@cs.unm DOT edu)
# Copyright 2017-2018
# Licensed under the Apache License, Version 2.0
# https://www.apache.org/licenses/LICENSE-2.0
# See: LICENCE file
#
# install the matlab code and configure startup.m for use from build tree or from install tree
#
# Options:
#  DISABLE_BUILD_EXPORT - Disable exporting from the build tree
# Single Argument Keywords:
#  MATLAB_SRC_DIR - [Default: matlab] relative to ${CMAKE_SOURCE_DIR}
#  STARTUP_M_TEMPLATE - [Default: ${CMAKE_CUURENT_LIST_DIR}/../[Templates|templates]/startup-InstallTree.m.in
#  BUILD_TREE_STARTUP_M_TEMPLATE - [Default: ${CMAKE_CUURENT_LIST_DIR}/../[Templates|templates]/startup-BuildTree.m.in
#  MATLAB_CODE_INSTALL_DIR - [Default: lib/${PACKAGE_NAME}/matlab
#  MATLAB_MEX_INSTALL_DIR - [Defualt: lib/${PACKAGE_NAME}/mex
#  STARTUP_M_LOCATION - [Default: lib/${PACKAGE_NAME}/matlab/startup${PACKAGE_NAME}.m
#  BUILD_TREE_STARTUP_M_LOCATION - [Default: ${CMAKE_BINARY_DIR}/startup${PACKAGE_NAME}.m
# Multi-Argument Keywords:
#  DEPENDENT_STARTUP_M_LOCATIONS
set(_mexiface_install_PATH ${CMAKE_CURRENT_LIST_DIR})
function(mexiface_install)

### Parse arguments and set defaults
set(options DISABLE_BUILD_EXPORT)
set(oneValueArgs MATLAB_SRC_DIR STARTUP_M_TEMPLATE BUILD_TREE_STARTUP_M_TEMPLATE
                 MATLAB_CODE_INSTALL_DIR MATLAB_MEX_INSTALL_DIR
                 STARTUP_M_LOCATION BUILD_TREE_STARTUP_M_LOCATION)
set(multiValueArgs DEPENDENT_STARTUP_M_LOCATIONS)
cmake_parse_arguments(ARG "${options}" "${oneValueArgs}"  "${multiValueArgs}"  ${ARGN})
if(ARG_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "Unknown keywords given to mexiface_install(): \"${ARG_UNPARSED_ARGUMENTS}\"")
endif()

if(NOT ARG_MATLAB_SRC_DIR)
    set(ARG_MATLAB_SRC_DIR matlab)
endif()

if(NOT ARG_STARTUP_M_TEMPLATE)
    set( matlab)
    find_file(ARG_STARTUP_M_TEMPLATE PackageConfig-mexiface.cmake.in
                PATHS ${_configure_mexiface_config_file_PATH}/../Templates NO_DEFAULT_PATH)
        mark_as_advanced(ARG_PACKAGE_CONFIG_TEMPLATE)
        if(NOT ARG_PACKAGE_CONFIG_TEMPLATE)
            message(FATAL_ERROR "Unable to find PackageConfig-mexiface.cmake.in. Cannot configure exports.")
        endif()
endif()

endfunction()
