# MexIface - Main CMakeLists.txt
#
# A Cross-Platform C++ / MEX Object-based interface wrapper and CMake build tool.
#
# Mark J. Olah (mjo@cs.unm DOT edu)
# Copyright 2014-2019
# Licensed under the Apache License, Version 2.0
# https://www.apache.org/licenses/LICENSE-2.0
# See: LICENCE file

cmake_minimum_required( VERSION 3.9 )

project(MexIFace VERSION 0.1.1 LANGUAGES CXX)
set(BUILD_SHARED_LIBS ON CACHE BOOL "Build shared libraries Ignored. Exists for compatability. Always build shared." FORCE)

option(MexIFace_MATLAB_INTERLEAVED_COMPLEX "Enable interleaved complex API in R2018a+" OFF)
option(MexIFace_MATLAB_LARGE_ARRAY_DIMS "Enable 64-bit array indexes in R2017a+.  Probably this needs to be on." ON)
option(BUILD_TESTING "Build testing framework" OFF)
option(OPT_EXTRA_DEBUG "Support extra noisy debugging features" OFF) #Extra debug features (Armadillo)
option(OPT_EXPORT_BUILD_TREE "Configure the package so it is usable from the build tree.  Useful for development." OFF)

message(STATUS "OPTION: BUILD_TESTING: ${BUILD_TESTING}")
message(STATUS "OPTION: OPT_EXTRA_DEBUG: ${OPT_EXTRA_DEBUG}")
message(STATUS "OPTION: OPT_EXPORT_BUILD_TREE: ${OPT_EXPORT_BUILD_TREE}")
message(STATUS "OPTION: MexIFace_MATLAB_INTERLEAVED_COMPLEX: ${MexIFace_MATLAB_INTERLEAVED_COMPLEX}")
message(STATUS "OPTION: MexIFace_MATLAB_LARGE_ARRAY_DIMS: ${MexIFace_MATLAB_LARGE_ARRAY_DIMS}")

set(OPT_AUTO_FIXUP_DEPENDENCIES OFF CACHE BOOL "MexIFace disables the auto hook on install() function for fixup_dependencies()." FORCE)

#Locations of the MexIFace cmake build system components
#Export all these variables in package-config also.
set(MexIFace_CMAKE_DIR ${CMAKE_SOURCE_DIR}/cmake)
set(MexIFace_CMAKE_MODULES_DIR ${MexIFace_CMAKE_DIR}/Modules)
set(MexIFace_CMAKE_FUNCTIONS_DIR ${MexIFace_CMAKE_DIR}/Functions)
set(MexIFace_CMAKE_EXECUTABLE_DIR ${MexIFace_CMAKE_DIR}/Executables)
set(MexIFace_CMAKE_TEMPLATES_DIR ${MexIFace_CMAKE_DIR}/Templates)
list(INSERT CMAKE_MODULE_PATH 0 ${MexIFace_CMAKE_MODULES_DIR} ${MexIFace_CMAKE_FUNCTIONS_DIR})

set(MexIFace_CMAKE_TOOLCHAINS_DIR ${MexIFace_CMAKE_DIR}/UncommonCMakeModules/Toolchains)
list(INSERT CMAKE_MODULE_PATH 0 ${CMAKE_CURRENT_LIST_DIR}/cmake/UncommonCMakeModules)

include(AddExternalDependency)
#BacktraceException allows for exceptions that encode a backtrace for debugging
set(BacktraceExceptionURL https://github.com/markjolah/BacktraceException.git)
add_external_dependency(NAME BacktraceException URL ${BacktraceExceptionURL} SHARED TESTING)

# Armadillo
find_package(Armadillo REQUIRED)
add_definitions(-DARMA_USE_CXX11)
add_definitions(-DARMA_DONT_USE_LAPACK -DARMA_DONT_USE_BLAS -DARMA_DONT_USE_OPENMP -DARMA_DONT_USE_HDF5) #disable unused dependencies
set_property(DIRECTORY APPEND PROPERTY COMPILE_DEFINITIONS $<$<CONFIG:Debug>:ARMA_PRINT_ERRORS>)
set_property(DIRECTORY APPEND PROPERTY COMPILE_DEFINITIONS $<$<NOT:$<CONFIG:Debug>>:ARMA_NO_DEBUG>)
if(OPT_EXTRA_DEBUG)
    set_property(DIRECTORY APPEND PROPERTY COMPILE_DEFINITIONS $<$<CONFIG:Debug>:ARMA_EXTRA_DEBUG>)
endif()

if(CMAKE_CXX_COMPILER_ID STREQUAL GNU AND NOT MexIFace_SYSTEM_LIBSTDCXX_VERSION)
    include(get_libstdcxx_version)
    get_libstdcxx_version(MexIFace_SYSTEM_LIBSTDCXX_VERSION)
    set(MexIFace_SYSTEM_LIBSTDCXX_VERSION ${MexIFace_SYSTEM_LIBSTDCXX_VERSION} CACHE STRING "Version of libsdtc++.so linked for this set of MexIFace targets" FORCE)
endif()

#Use the MexIFace version of FindMatlab.cmake which will find multiple versions.
#Set variables on cmake command line or in environment
#MATLAB_ROOT - a single matlab 'e.g.: /usr/local/matlab/R2018a'
#MATLAB_ROOTS - a ";" delimited list of matlab roots or directories containing several roots each root dir should match
#               the RE "^[r|R]20\d\d[a|b]"
include(MexIFace-configure-matlab)

#Debugging configuration
include(ConfigureDebugBuilds)

#include(MexIFace-Doxygen) #Add Doxygen documentation targets

#Build MexIFace libraries
add_subdirectory(src)

if(BUILD_TESTING)
    set(MexIFace_COMPATABLE_MATLAB_VERSION_STRINGS ${MexIFace_MATLAB_VERSION_STRINGS}) #Normally set when MexIFaceConfig.cmake is called by other cmake project with find_package(MexIFace)
    add_subdirectory(test)
endif()

#Install Cmake modules and helper files for development
set(SHARED_CMAKE_INSTALL_DIR share/${PROJECT_NAME}/cmake)
install(DIRECTORY ${MexIFace_CMAKE_MODULES_DIR}/ DESTINATION ${SHARED_CMAKE_INSTALL_DIR}/Modules COMPONENT Development)
install(DIRECTORY ${MexIFace_CMAKE_FUNCTIONS_DIR}/ DESTINATION ${SHARED_CMAKE_INSTALL_DIR}/Functions COMPONENT Development)
install(DIRECTORY ${MexIFace_CMAKE_EXECUTABLE_DIR}/ DESTINATION ${SHARED_CMAKE_INSTALL_DIR}/Executables COMPONENT Development)
install(DIRECTORY ${MexIFace_CMAKE_TEMPLATES_DIR}/ DESTINATION ${SHARED_CMAKE_INSTALL_DIR}/Templates COMPONENT Development)

#Install cmake files from UncommonCMakeModules subrepo that consumers might use.
install(DIRECTORY ${MexIFace_CMAKE_TOOLCHAINS_DIR}/ DESTINATION ${SHARED_CMAKE_INSTALL_DIR}/Toolchains COMPONENT Development)
install(FILES ${MexIFace_CMAKE_DIR}/UncommonCMakeModules/FixupDependencies.cmake DESTINATION ${SHARED_CMAKE_INSTALL_DIR}/Modules COMPONENT Development)
install(FILES ${MexIFace_CMAKE_DIR}/UncommonCMakeModules/Templates/FixupTargetDependenciesScript.cmake.in DESTINATION ${SHARED_CMAKE_INSTALL_DIR}/Templates COMPONENT Development)

### PackageConfig
include(ExportPackageWizzard)
export_package_wizzard(EXPORT_BUILD_TREE "${OPT_EXPORT_BUILD_TREE}") #setup build-tree and install-tree exports and packageconfig files

#Give path to FindMatlab.cmake so it can be called by PackageConfig.cmake correctly from build tree or install tree
set(MATLAB_CODE_INSTALL_DIR lib/MexIFace/matlab)

#Install matlab source
if(BUILD_TESTING)
    set(_EXCLUDE)
else()
    set(_EXCLUDE REGEX "\\+Test" EXCLUDE)
endif()
install(DIRECTORY matlab/ DESTINATION ${MATLAB_CODE_INSTALL_DIR} COMPONENT Runtime ${_EXCLUDE})
unset(_EXCLUDE)

#install-tree export config MexIFaceConfig-mexiface.cmake
include(CMakePackageConfigHelpers)
set(_DEPENDENT_STARTUP_M_LOCATIONS)
set(_MATLAB_CODE_DIR ${MATLAB_CODE_INSTALL_DIR})
set(_MATLAB_STARTUP_M ${_MATLAB_CODE_DIR}/startup${PROJECT_NAME}.m)
    if(BUILD_TESTING)
        set(_MATLAB_INSTALLED_MEX_PATH lib/${PROJECT_NAME}/mex) #Test mex file installation
    else()
        set(_MATLAB_INSTALLED_MEX_PATH) #Disable mex export
    endif()
set(_CONFIGURE_TEMPLATE ${CMAKE_SOURCE_DIR}/cmake/Templates/MexIFaceConfig-mexiface.cmake.in)
set(_CONFIGURE_FILE_INSTALL_TREE ${CMAKE_BINARY_DIR}/MexIFaceConfig-mexiface.cmake.install-tree)
configure_package_config_file(${_CONFIGURE_TEMPLATE} MexIFaceConfig-mexiface.cmake.install-tree
    INSTALL_DESTINATION lib/MexIFace/cmake
    PATH_VARS _MATLAB_CODE_DIR _MATLAB_STARTUP_M
    NO_CHECK_REQUIRED_COMPONENTS_MACRO
    NO_SET_AND_CHECK_MACRO) #Set and check will have already been defined in main PackageConfig.cmake
install(FILES ${_CONFIGURE_FILE_INSTALL_TREE} RENAME MexIFaceConfig-mexiface.cmake DESTINATION lib/MexIFace/cmake COMPONENT Development)
unset(_CONFIGURE_FILE_INSTALL_TREE)

#startup.m install-tree
set(_STARTUP_M_INSTALL_DIR ${MATLAB_CODE_INSTALL_DIR}) #Install dir relative to install prefix of startupMexIFace.m
set(_STARTUP_M_TEMPLATE ${CMAKE_SOURCE_DIR}/cmake/Templates/startupPackage.m.in)
configure_file(${_STARTUP_M_TEMPLATE} ${CMAKE_BINARY_DIR}/startupMexIFace.m.install-tree)
install(FILES ${CMAKE_BINARY_DIR}/startupMexIFace.m.install-tree RENAME startupMexIFace.m
        DESTINATION ${MATLAB_CODE_INSTALL_DIR} COMPONENT Runtime)
unset(_MATLAB_CODE_DIR)
unset(_MATLAB_STARTUP_M)
unset(_MATLAB_INSTALLED_MEX_PATH)

#Build tree settings use the local matlab code dir and startupMexIFace.m
set(_MATLAB_CODE_DIR ${CMAKE_SOURCE_DIR}/matlab) #Use source repository for matlab code
file(RELATIVE_PATH _MATLAB_CODE_DIR ${CMAKE_BINARY_DIR} ${CMAKE_SOURCE_DIR}/matlab)
set(_MATLAB_STARTUP_M ${CMAKE_BINARY_DIR}/startupMexIFace.m)
if(NOT ARG_DISABLE_BUILD_EXPORT AND NOT CMAKE_EXPORT_NO_PACKAGE_REGISTRY AND NOT CMAKE_CROSSCOMPILING) # No build-tree export when crosscompiling
    #build-tree export config MexIFaceConfig-mexiface.cmake
    configure_package_config_file(${_CONFIGURE_TEMPLATE} MexIFaceConfig-mexiface.cmake
        INSTALL_DESTINATION ${CMAKE_BINARY_DIR}
        INSTALL_PREFIX ${CMAKE_BINARY_DIR}
        PATH_VARS _MATLAB_CODE_DIR _MATLAB_STARTUP_M
        NO_CHECK_REQUIRED_COMPONENTS_MACRO
        NO_SET_AND_CHECK_MACRO)  #Set and check will have already been defined in main PackageConfig.cmake
    unset(_CONFIGURE_TEMPLATE)
endif()

#startup.m build-tree
set(_STARTUP_M_INSTALL_DIR "") #Location of startupMexIFace.m relative to ${CMAKE_BINARY_DIR} for build-tree export
if(BUILD_TESTING)
    get_property(_MATLAB_BUILD_MEX_PATHS GLOBAL PROPERTY MexIFace_MODULE_BUILD_DIRS) #Test build locations
else()
    set(_MATLAB_BUILD_MEX_PATHS) #Disable mex export
endif()
configure_file(${_STARTUP_M_TEMPLATE} ${CMAKE_BINARY_DIR}/startupMexIFace.m)
unset(_STARTUP_M_TEMPLATE)
unset(_MATLAB_CODE_DIR)
unset(_MATLAB_STARTUP_M)
unset(_MATLAB_BUILD_MEX_PATHS)
unset(_DEPENDENT_STARTUP_M_LOCATIONS)

