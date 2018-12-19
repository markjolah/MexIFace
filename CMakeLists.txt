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

project(MexIFace VERSION 0.1.1 LANGUAGES CXX)

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

# Armadillo
find_package(Armadillo REQUIRED)
add_definitions(-DARMA_USE_CXX11)
add_definitions(-DARMA_DONT_USE_LAPACK -DARMA_DONT_USE_BLAS -DARMA_DONT_USE_OPENMP -DARMA_DONT_USE_HDF5) #disable unused dependencies
set_property(DIRECTORY APPEND PROPERTY COMPILE_DEFINITIONS $<$<CONFIG:Debug>:ARMA_PRINT_ERRORS>)
set_property(DIRECTORY APPEND PROPERTY COMPILE_DEFINITIONS $<$<NOT:$<CONFIG:Debug>>:ARMA_NO_DEBUG>)
if(OPT_EXTRA_DEBUG)
    set_property(DIRECTORY APPEND PROPERTY COMPILE_DEFINITIONS $<$<CONFIG:Debug>:ARMA_EXTRA_DEBUG>)
endif()

# #libc++.so compatability
# if(OPT_LIBCXX)
#     find_package(LibCXX)
#     if(LibCXX_FOUND)
#         set(MEXIFACE_LIBCXX_VERSION ${LIBCXX_VERSION_STRING})
#     else()
#         set(MEXIFACE_LIBSTDCXX_VERSION False)
#     endif()
# else()
#     set(MEXIFACE_LIBSTDCXX_VERSION False)
# endif()

if(CMAKE_CXX_COMPILER_ID STREQUAL GNU AND NOT MEXIFACE_SYSTEM_LIBSTDCXX_VERSION)
    include(get_libstdcxx_version)
    get_libstdcxx_version(MEXIFACE_SYSTEM_LIBSTDCXX_VERSION)
    set(MEXIFACE_SYSTEM_LIBSTDCXX_VERSION ${MEXIFACE_SYSTEM_LIBSTDCXX_VERSION} CACHE STRING "Version of libsdtc++.so linked for this set of MexIFace targets" FORCE)
endif()

#Use the MexIFace version of FindMatlab.cmake which will find multiple versions.
#Set variables on cmake command line or in environment
#MATLAB_ROOT - a single matlab 'e.g.: /usr/local/matlab/R2018a'
#MATLAB_ROOTS - a ";" delimited list of matlab roots or directories containing several roots each root dir should match
#               the RE "^[r|R]20\d\d[a|b]"
include(MexIface-configure-matlab)

#Enable Inter-proceedural optimization
include(ConfigureIPO)

#Debugging configuration
include(ConfigureDebugBuilds)

#include(MexIFace-Doxygen) #Add Doxygen documentation targets

#Build MexIFace libraries
add_subdirectory(src)

#Install Cmake modules and helper files for development
set(SHARED_CMAKE_INSTALL_DIR share/${PROJECT_NAME}/cmake)
install(DIRECTORY ${MexIFace_CMAKE_MODULES_DIR}/ DESTINATION ${SHARED_CMAKE_INSTALL_DIR}/Modules COMPONENT Development)
install(DIRECTORY ${MexIFace_CMAKE_TOOLCHAINS_DIR}/ DESTINATION ${SHARED_CMAKE_INSTALL_DIR}/Toolchains COMPONENT Development)
install(DIRECTORY ${MexIFace_CMAKE_FUNCTIONS_DIR}/ DESTINATION ${SHARED_CMAKE_INSTALL_DIR}/Functions COMPONENT Development)
install(DIRECTORY ${MexIFace_CMAKE_EXECUTABLE_DIR}/ DESTINATION ${SHARED_CMAKE_INSTALL_DIR}/Excecutables COMPONENT Development)
install(DIRECTORY ${MexIFace_CMAKE_TEMPLATES_DIR}/ DESTINATION ${SHARED_CMAKE_INSTALL_DIR}/Templates COMPONENT Development)


### PackageConfig
include(ExportPackageWizzard)
#Call after "src" subdirectory because MEXIFACE_TARGETS list is set there and we export it in packageconfig
#Give path to FindMatlab.cmake so it can be called by PackageConfig.cmake correctly from build tree or install tree
export_package_wizzard(FIND_MODULES "cmake/Modules/FindMatlab.cmake")

#Install matlab source
install(DIRECTORY matlab DESTINATION lib/MexIFace/matlab COMPONENT Runtime)

#install-tree export config MexIFaceConfig-mexiface.cmake
set(_DEPENDENT_STARTUP_M_LOCATIONS)
set(_MATLAB_CODE_DIR lib/MexIFace/matlab)
set(_MATLAB_STARTUP_M ${CMAKE_BINARY_DIR}/startup@PROJECT_NAME@.m)
set(_MATLAB_INSTALLED_MEX_PATH lib/MexIFace/mex)
set(CONFIGURE_MEXIFACE_TEMPLATE ${CMAKE_SOURCE_DIR}/cmake/Templates/MexIFaceConfig-mexiface.cmake.in)
set(MEXIFACE_CONFIGURE_FILE_INSTALL_TREE ${CMAKE_BINARY_DIR}/MexIFaceConfig-mexiface.cmake.install-tree)
configure_file(${CONFIGURE_MEXIFACE_TEMPLATE} ${MEXIFACE_CONFIGURE_FILE_INSTALL_TREE})
install(FILES ${MEXIFACE_CONFIGURE_FILE_INSTALL_TREE} RENAME MexIFaceConfig-mexiface.cmake DESTINATION lib/MexIFace COMPONENT Development)

#startup.m install-tree
configure_file(${CMAKE_SOURCE_DIR}/cmake/Templates/startupPackage.m.in ${CMAKE_BINARY_DIR}/startupMexIFace.m.install-tree)
install(FILES ${CMAKE_BINARY_DIR}/startupMexIFace.m.install-tree RENAME startupMexIFace.m
        DESTINATION lib/MexIFace/matlab COMPONENT Runtime)
unset(_MATLAB_CODE_DIR)
unset(_MATLAB_STARTUP_M)
unset(_MATLAB_INSTALLED_MEX_PATH)

if(NOT CMAKE_CROSSCOMPILING) # No build-tree export when crosscompiling
    #build-tree export config MexIFaceConfig-mexiface.cmake
    set(_MATLAB_CODE_DIR ${CMAKE_SOURCE_DIR}/matlab) #Use source repository for matlab code
    set(_MATLAB_STARTUP_M lib/MexIFace/matlab/startupMexIFace.m)
    set(_MATLAB_BUILD_MEX_PATHS lib/MexIFace/mex)
    configure_file(${ARG_PACKAGE_CONFIG_TEMPLATE} ${ARG_CONFIG_DIR}/${ARG_PACKAGE_CONFIG_FILE})

    #startup.m build-tree
    get_property(PACKAGE_MATLAB_BUILD_MEX_PATHS GLOBAL PROPERTY MEXIFACE_MODULE_BUILD_DIRS)
    configure_file(${ARG_STARTUP_M_TEMPLATE} ${ARG_BUILD_TREE_STARTUP_M_LOCATION})
    unset(_MATLAB_CODE_DIR)
    unset(_MATLAB_STARTUP_M)
    unset(_MATLAB_BUILD_MEX_PATHS)
    unset(_DEPENDENT_STARTUP_M_LOCATIONS)
endif()
