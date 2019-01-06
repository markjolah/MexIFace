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
#  NOMEX - Disable mex. This flag should be added by packages that export matlab code only, no mex modules.
# Single Argument Keywords:
#  CONFIG_DIR - [Default: ${CMAKE_BINARY_DIR}] Path within build directory to make configured files before installation.  Also serves as the exported build directory.
#  PACKAGE_CONFIG_TEMPLATE -  The template file for package config.
#         [Default: Look for PackageConfig-mexiface.cmake.in under ${CMAKE_SOURCE_DIR}/cmake/<Templates|templatesModules|modules|>]
#  CONFIG_INSTALL_DIR - [Default: lib/cmake/${PROJECT_NAME}] Relative path from ${CMAKE_INSTALL_PREFIX} at which to install PackageConfig.cmake files
#  MATLAB_SRC_DIR - [Default: matlab] relative to ${CMAKE_SOURCE_DIR}
#  STARTUP_M_TEMPLATE - [Default: ${CMAKE_CURRENT_LIST_DIR}/../[Templates|templates]/startupPackage.m.in
#  STARTUP_M_FILE - [Default: startup${PROJECT_NAME}.m
#  MATLAB_CODE_INSTALL_DIR - [Default: lib/${PACKAGE_NAME}/matlab] Should be relative to CMAKE_INSTALL_PREFIX
#  MATLAB_MEX_INSTALL_DIR - [Defualt: lib/${PACKAGE_NAME}/mex] Should be relative to CMAKE_INSTALL_PREFIX
# Multi-Argument Keywords:
#  DEPENDENT_STARTUP_M_LOCATIONS - Paths for .m files that this package depends on.  Should be relative to CMAKE_INSTALL_PREFIX, or absolute for files outside the install prefix
#                                   (normally this only makes sense when using from the build directory for development)

set(_mexiface_configure_install_PATH ${CMAKE_CURRENT_LIST_DIR})
function(mexiface_configure_install)
    set(options DISABLE_BUILD_EXPORT NOMEX)
    set(oneValueArgs CONFIG_DIR PACKAGE_CONFIG_TEMPLATE CONFIG_INSTALL_DIR MATLAB_SRC_DIR STARTUP_M_TEMPLATE STARTUP_M_FILE
                     MATLAB_CODE_INSTALL_DIR MATLAB_MEX_INSTALL_DIR)
    set(multiValueArgs DEPENDENT_STARTUP_M_LOCATIONS)
    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}"  ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "Unknown keywords given to install_smarter_package_version_file(): \"${_SVF_UNPARSED_ARGUMENTS}\"")
    endif()
    if(NOT ARG_CONFIG_DIR)
        set(ARG_CONFIG_DIR ${CMAKE_BINARY_DIR})
    endif()

    if(NOT ARG_PACKAGE_CONFIG_TEMPLATE)
        find_file(ARG_PACKAGE_CONFIG_TEMPLATE PackageConfig-mexiface.cmake.in
                PATHS ${_mexiface_configure_install_PATH}/../Templates NO_DEFAULT_PATH NO_CMAKE_FIND_ROOT_PATH)
        mark_as_advanced(ARG_PACKAGE_CONFIG_TEMPLATE)
        if(NOT ARG_PACKAGE_CONFIG_TEMPLATE)
            message(FATAL_ERROR "Unable to find PackageConfig-mexiface.cmake.in. Cannot configure exports.")
        endif()
    endif()

    if(NOT ARG_CONFIG_INSTALL_DIR)
        set(ARG_CONFIG_INSTALL_DIR lib/${PROJECT_NAME}/cmake) #Where to install project Config.cmake and ConfigVersion.cmake files
    endif()

    if(NOT ARG_MATLAB_SRC_DIR)
        set(ARG_MATLAB_SRC_DIR ${CMAKE_SOURCE_DIR}/matlab)
    endif()

    if(NOT ARG_STARTUP_M_TEMPLATE)
        find_file(ARG_STARTUP_M_TEMPLATE startupPackage.m.in
                PATHS ${_mexiface_configure_install_PATH}/../Templates NO_DEFAULT_PATH NO_CMAKE_FIND_ROOT_PATH)
        mark_as_advanced(ARG_PACKAGE_CONFIG_TEMPLATE)
        if(NOT ARG_PACKAGE_CONFIG_TEMPLATE)
            message(FATAL_ERROR "Unable to find PackageConfig-mexiface.cmake.in. Cannot configure exports.")
        endif()
    endif()

    if(NOT ARG_STARTUP_M_FILE)
        set(ARG_STARTUP_M_FILE startup${PROJECT_NAME}.m)
    endif()


    if(NOT ARG_MATLAB_CODE_INSTALL_DIR)
        set(ARG_MATLAB_CODE_INSTALL_DIR lib/${PROJECT_NAME}/matlab)
    elseif(IS_ABSOLUTE ARG_MATLAB_CODE_INSTALL_DIR)
        file(RELATIVE_PATH ARG_MATLAB_CODE_INSTALL_DIR ${CMAKE_INSTALL_PREFIX} ${ARG_MATLAB_CODE_INSTALL_DIR})
    endif()

    if(NOT ARG_MATLAB_MEX_INSTALL_DIR)
        set(ARG_MATLAB_MEX_INSTALL_DIR lib/${PROJECT_NAME}/mex)
    elseif(IS_ABSOLUTE ARG_MATLAB_MEX_INSTALL_DIR)
        file(RELATIVE_PATH ARG_MATLAB_MEX_INSTALL_DIR ${CMAKE_INSTALL_PREFIX} ${ARG_MATLAB_MEX_INSTALL_DIR})
    endif()

    if(NOT ARG_BUILD_TREE_STARTUP_M_LOCATION)
        set(ARG_BUILD_TREE_STARTUP_M_LOCATION ${CMAKE_BINARY_DIR}/startup${PACKAGE_NAME}.m)
    endif()
    if(NOT ARG_DEPENDENT_STARTUP_M_LOCATIONS)
        set(ARG_DEPENDENT_STARTUP_M_LOCATIONS)
    endif()
    list(APPEND ARG_DEPENDENT_STARTUP_M_LOCATIONS ${MexIFace_MATLAB_STARTUP_M})

    # Set different names for build-tree and install-tree files
    set(ARG_PACKAGE_CONFIG_FILE ${PROJECT_NAME}Config-mexiface.cmake)
    if(NOT ARG_DISABLE_BUILD_EXPORT)
        set(ARG_PACKAGE_CONFIG_INSTALL_TREE_FILE ${PROJECT_NAME}Config-mexiface.cmake.install_tree) #Generated <Package>Config.cmake Version meant for the install tree but name mangled to prevent use in build tree
        set(ARG_STARTUP_M_INSTALL_TREE_FILE ${ARG_STARTUP_M_FILE}.install_tree)
    else()
        set(ARG_PACKAGE_CONFIG_INSTALL_TREE_FILE ${ARG_PACKAGE_CONFIG_FILE}) #Generated <Package>Config.cmake Version meant for the install tree but name mangled to prevent use in build tree
        set(ARG_STARTUP_M_INSTALL_TREE_FILE ${ARG_STARTUP_M_FILE})
    endif()


    #Install matlab source
    if(BUILD_TESTING)
        set(_EXCLUDE)
    else()
        set(_EXCLUDE REGEX "\\+Test" EXCLUDE)
    endif()
    install(DIRECTORY matlab/ DESTINATION ${ARG_MATLAB_CODE_INSTALL_DIR} COMPONENT Runtime ${_EXCLUDE})
    unset(_EXCLUDE)

    include(CMakePackageConfigHelpers)
    #install-tree export config @PACKAGE_NAME@Config-mexiface.cmake

    if(IS_ABSOLUTE ARG_CONFIG_INSTALL_DIR)
        set(ABSOLUTE_CONFIG_INSTALL_DIR ${ARG_CONFIG_INSTALL_DIR})
    else()
        set(ABSOLUTE_CONFIG_INSTALL_DIR ${CMAKE_INSTALL_PREFIX}/${ARG_CONFIG_INSTALL_DIR})
    endif()
    set(_MATLAB_CODE_DIR ${ARG_MATLAB_CODE_INSTALL_DIR})
    set(_MATLAB_STARTUP_M ${ARG_CONFIG_DIR}/${STARTUP_M_FILE})
    configure_package_config_file(${ARG_PACKAGE_CONFIG_TEMPLATE} ${ARG_CONFIG_DIR}/${ARG_PACKAGE_CONFIG_INSTALL_TREE_FILE}
                                    INSTALL_DESTINATION ${ARG_CONFIG_INSTALL_DIR}
                                    PATH_VARS _MATLAB_CODE_DIR _MATLAB_STARTUP_M
                                    NO_CHECK_REQUIRED_COMPONENTS_MACRO)
    install(FILES ${ARG_CONFIG_DIR}/${ARG_PACKAGE_CONFIG_INSTALL_TREE_FILE} RENAME ${ARG_PACKAGE_CONFIG_FILE}
            DESTINATION ${ARG_CONFIG_INSTALL_DIR} COMPONENT Development)


    #startup.m install-tree
    set(_STARTUP_M_INSTALL_DIR ${ARG_MATLAB_CODE_INSTALL_DIR}) #Install dir relative to install prefix
    if(ARG_NOMEX)
        set(_MATLAB_INSTALLED_MEX_PATH) #Disable mex exporting in startup.m
    else()
        set(_MATLAB_INSTALLED_MEX_PATH ${ARG_MATLAB_MEX_INSTALL_DIR})
    endif()
    set(_DEPENDENT_STARTUP_M_LOCATIONS)
    foreach(location IN LISTS ARG_DEPENDENT_STARTUP_M_LOCATIONS)
        string(REGEX REPLACE "^${CMAKE_INSTALL_PREFIX}/" "" location ${location})
        list(APPEND _DEPENDENT_STARTUP_M_LOCATIONS ${location})
    endforeach()
    configure_file(${ARG_STARTUP_M_TEMPLATE} ${ARG_CONFIG_DIR}/${ARG_STARTUP_M_INSTALL_TREE_FILE})
    install(FILES ${ARG_CONFIG_DIR}/${ARG_STARTUP_M_INSTALL_TREE_FILE} RENAME ${ARG_STARTUP_M_FILE}
            DESTINATION ${ARG_MATLAB_CODE_INSTALL_DIR} COMPONENT Runtime)
    unset(_MATLAB_INSTALLED_MEX_PATH)

    #build-tree export
    set(_MATLAB_CODE_DIR ${ARG_MATLAB_SRC_DIR})
    set(_MATLAB_STARTUP_M ${ARG_CONFIG_DIR}/${ARG_STARTUP_M_FILE})
    if(NOT ARG_DISABLE_BUILD_EXPORT)
        #build-tree export config @PACKAGE_NAME@Config-mexiface.cmake
        configure_package_config_file(${ARG_PACKAGE_CONFIG_TEMPLATE} ${ARG_PACKAGE_CONFIG_FILE}
                                    INSTALL_DESTINATION ${ARG_CONFIG_DIR}
                                    INSTALL_PREFIX ${ARG_CONFIG_DIR}
                                    PATH_VARS _MATLAB_CODE_DIR _MATLAB_STARTUP_M
                                    NO_CHECK_REQUIRED_COMPONENTS_MACRO)
    endif()

    #startup.m build-tree
    set(_STARTUP_M_INSTALL_DIR "") #Install dir for build-tree export startup.m to install location at ${ARG_CONFIG_DIR}
    get_property(_MATLAB_BUILD_MEX_PATHS GLOBAL PROPERTY MexIFace_MODULE_BUILD_DIRS)
    if(NOT _MATLAB_BUILD_MEX_PATHS OR ARG_NOMEX)
        set(_MATLAB_BUILD_MEX_PATHS) #Disable mex exporting
    endif()
    set(_DEPENDENT_STARTUP_M_LOCATIONS)
    if(IS_ABSOLUTE ${ARG_CONFIG_DIR})
        set(_prefix ${ARG_CONFIG_DIR})
    else()
        set(_prefix ${CMAKE_BINARY_DIR}/${ARG_CONFIG_DIR})
    endif()
    foreach(location IN LISTS ARG_DEPENDENT_STARTUP_M_LOCATIONS)
        #Remap dependent startup.m locations to be relative to the install prefix for this file
        string(REGEX REPLACE "^${_prefix}/" "" location ${location})
        list(APPEND _DEPENDENT_STARTUP_M_LOCATIONS ${location})
    endforeach()
    configure_file(${ARG_STARTUP_M_TEMPLATE} ${ARG_CONFIG_DIR}/${ARG_STARTUP_M_FILE})

endfunction()

