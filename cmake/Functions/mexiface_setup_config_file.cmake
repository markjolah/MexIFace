# mexiface_configure_install.cmake
# Copyright 2018
# Author: Mark J. Olah
# Email: (mjo@cs.unm DOT edu)
#
# Sets up a ${PACKAGE_NAME}config-mexiface.cmake file for passing mexiface and matlab configuration to dependencies
# Installs matlab code and startup${PACKAGE_NAME}.m file for matlab integration, which is able to run dependennt startup.m file
# from DEPENDENT_STARTUP_M_LOCATIONS
#
# Configures a build-tree export which enables editing of the sources .m files in-repository.  Disable with DISABLE_BUILD_EXPORT
#
# Options:
#  DISABLE_BUILD_EXPORT - Disable exporting from the build tree
# Single Argument Keywords:
#  CONFIG_DIR - [Default: ${CMAKE_BINARY_DIR}] Path within build directory to make configured files before installation.  Also serves as the exported build directory.
#  PACKAGE_CONFIG_TEMPLATE -  The template file for package config.
#         [Default: Look for PackageConfig-mexiface.cmake.in under ${CMAKE_SOURCE_DIR}/cmake/<Templates|templatesModules|modules|>]
#  CONFIG_INSTALL_DIR - [Default: lib/cmake/${NAME}] Relative path from ${CMAKE_INSTALL_PREFIX} at which to install PackageConfig.cmake files
#  MATLAB_SRC_DIR - [Default: matlab] relative to ${CMAKE_SOURCE_DIR}
#  STARTUP_M_TEMPLATE - [Default: ${CMAKE_CUURENT_LIST_DIR}/../[Templates|templates]/startup-InstallTree.m.in
#  BUILD_TREE_STARTUP_M_TEMPLATE - [Default: ${CMAKE_CUURENT_LIST_DIR}/../[Templates|templates]/startup-BuildTree.m.in
#  MATLAB_CODE_INSTALL_DIR - [Default: lib/${PACKAGE_NAME}/matlab
#  MATLAB_MEX_INSTALL_DIR - [Defualt: lib/${PACKAGE_NAME}/mex
#  STARTUP_M_LOCATION - [Default: lib/${PACKAGE_NAME}/matlab/startup${PACKAGE_NAME}.m
#  BUILD_TREE_STARTUP_M_LOCATION - [Default: ${CMAKE_BINARY_DIR}/startup${PACKAGE_NAME}.m
# Multi-Argument Keywords:
#  DEPENDENT_STARTUP_M_LOCATIONS

set(_mexiface_configure_install_PATH ${CMAKE_CURRENT_LIST_DIR})
function(mexiface_configure_install)
    set(options DISABLE_BUILD_EXPORT)
    set(oneValueArgs NAME CONFIG_DIR CONFIG_INSTALL_DIR CONFIGURE_MEXIFACE_TEMPLATE)
    set(multiValueArgs)
    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}"  ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "Unknown keywords given to install_smarter_package_version_file(): \"${_SVF_UNPARSED_ARGUMENTS}\"")
    endif()

    if(NOT ARG_NAME)
        set(ARG_NAME ${PROJECT_NAME})
    endif()

    if(NOT ARG_PACKAGE_CONFIG_TEMPLATE)
        find_file(ARG_PACKAGE_CONFIG_TEMPLATE PackageConfig-mexiface.cmake.in
                PATHS ${_configure_mexiface_config_file_PATH}/../Templates NO_DEFAULT_PATH)
        mark_as_advanced(ARG_PACKAGE_CONFIG_TEMPLATE)
        if(NOT ARG_PACKAGE_CONFIG_TEMPLATE)
            message(FATAL_ERROR "Unable to find PackageConfig-mexiface.cmake.in. Cannot configure exports.")
        endif()
    endif()

    if(NOT ARG_CONFIG_INSTALL_DIR)
        set(ARG_CONFIG_INSTALL_DIR lib/cmake/${ARG_NAME}) #Where to install project Config.cmake and ConfigVersion.cmake files
    endif()

    set(ARG_PACKAGE_CONFIG_FILE ${ARG_NAME}Config-mexiface.cmake)
    if(NOT ARG_DISABLE_BUILD_EXPORT)
        set(ARG_PACKAGE_CONFIG_INSTALL_TREE_FILE ${ARG_NAME}Config-mexiface.cmake.install_tree) #Generated <Package>Config.cmake Version meant for the install tree but name mangled to prevent use in build tree
    else()
        set(ARG_PACKAGE_CONFIG_INSTALL_TREE_FILE ${ARG_PACKAGE_CONFIG_FILE}) #Generated <Package>Config.cmake Version meant for the install tree but name mangled to prevent use in build tree
    endif()

    #install-tree export
    set(_MATLAB_PATH ${CMAKE_SOURCE_DIR}/matlab)
    set(_MATLAB_STARTUP_M ${ARG_CONFIG_DIR}/startup@PROJECT_NAME@.m)
    configure_file(${ARG_PACKAGE_CONFIG_TEMPLATE} ${ARG_CONFIG_DIR}/${ARG_PACKAGE_CONFIG_INSTALL_TREE_FILE})
    install(FILES ${ARG_CONFIG_DIR}/${ARG_PACKAGE_CONFIG_INSTALL_TREE_FILE} RENAME ${ARG_PACKAGE_CONFIG_FILE}
            DESTINATION ${ARG_CONFIG_INSTALL_DIR} COMPONENT Development)
    #build-tree export
    if(NOT ARG_DISABLE_BUILD_EXPORT)
        #Note setting INSTALL_DESTINATION to ${_WIZ_CONFIG_DIR} for build tree PackageConfig.cmake as it is never installed to install tree
        set(_MATLAB_PATH ${CMAKE_SOURCE_DIR}/matlab)
        set(_MATLAB_STARTUP_M ${ARG_CONFIG_DIR}/startup@PROJECT_NAME@.m)
        configure_file(${ARG_PACKAGE_CONFIG_TEMPLATE} ${ARG_CONFIG_DIR}/${ARG_PACKAGE_CONFIG_FILE})
    endif()
endfunction()

