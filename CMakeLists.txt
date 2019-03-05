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

project(MexIFace VERSION 0.2 LANGUAGES CXX)
set(BUILD_SHARED_LIBS ON CACHE BOOL "Build shared libraries Ignored. Exists for comparability. Always build shared." FORCE)

option(OPT_MexIFace_MATLAB_INTERLEAVED_COMPLEX "Enable interleaved complex API in R2018a+" OFF)
option(OPT_MexIFace_MATLAB_LARGE_ARRAY_DIMS "Enable 64-bit array indexes in R2017a+.  If BLAS or LAPACK are used this needs to be on." ON)
option(OPT_MexIFace_INSTALL_DISTRIBUTION_STARTUP "Install an additional copy of startupPackage.m at the INSTALL_PREFIX root in addition to the normal directory.  This makes it easy to distribute as a zip file." Off)
option(OPT_MexIFace_PROFILE "Built-in gperftools profiling ProfileStart()/ProfileStop() for every method call to a MexIFace object." OFF)
option(OPT_MexIFace_VERBOSE "Verbose output for MexIFace CMake configuration." OFF)
option(OPT_MexIFace_SILENT  "Silent output for MexIFace CMake configuration.  Warnings and errors only." OFF)
if(${CMAKE_BUILD_TYPE} MATCHES Debug)
    option(BUILD_TESTING "Build testing framework" ON)
else()
    option(BUILD_TESTING "Build testing framework" OFF)
endif()
option(OPT_DOC "Build documentation" OFF)
option(OPT_INSTALL_TESTING "Install testing executables" OFF)
option(OPT_EXPORT_BUILD_TREE "Configure the package so it is usable from the build tree.  Useful for development." OFF)
option(OPT_EXTRA_DEBUG "Support extra noisy debugging features" OFF) #Extra debug features (Armadillo)

message(STATUS "OPTION: BUILD_TESTING: ${BUILD_TESTING}")
message(STATUS "OPTION: OPT_DOC: ${OPT_DOC}")
message(STATUS "OPTION: OPT_INSTALL_TESTING: ${OPT_INSTALL_TESTING}")
message(STATUS "OPTION: OPT_EXTRA_DEBUG: ${OPT_EXTRA_DEBUG}")
message(STATUS "OPTION: OPT_EXPORT_BUILD_TREE: ${OPT_EXPORT_BUILD_TREE}")
message(STATUS "OPTION: OPT_MexIFace_MATLAB_INTERLEAVED_COMPLEX: ${OPT_MexIFace_MATLAB_INTERLEAVED_COMPLEX}")
message(STATUS "OPTION: OPT_MexIFace_MATLAB_LARGE_ARRAY_DIMS: ${OPT_MexIFace_MATLAB_LARGE_ARRAY_DIMS}")
message(STATUS "OPTION: OPT_MexIFace_INSTALL_DISTRIBUTION_STARTUP: ${OPT_MexIFace_INSTALL_DISTRIBUTION_STARTUP}")
message(STATUS "OPTION: OPT_MexIFace_PROFILE: ${OPT_MexIFace_PROFILE}")
message(STATUS "OPTION: OPT_MexIFace_VERBOSE: ${OPT_MexIFace_VERBOSE}")
message(STATUS "OPTION: OPT_MexIFace_SILENT: ${OPT_MexIFace_SILENT}")

#Force the install() hook off [default:on in the toolchains].  MexIFace is fixup_dependencies aware and we will call manually
set(OPT_FIXUP_DEPENDENCIES_AUTO OFF CACHE BOOL "MexIFace disables the auto hook on install() function for fixup_dependencies()." FORCE)

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
# message(STATUS "CMAKE_MODULE_PATH:${CMAKE_MODULE_PATH}")
#BacktraceException allows for exceptions that encode a backtrace for debugging
set(BacktraceExceptionURL https://github.com/markjolah/BacktraceException.git)
add_external_dependency(NAME BacktraceException URL ${BacktraceExceptionURL} VARS OPT_INSTALL_TESTING)

# message(STATUS "CMAKE_MODULE_PATH:${CMAKE_MODULE_PATH}")
# Armadillo
find_package(Armadillo REQUIRED COMPONENTS CXX11 INT64) #INT64 required by Matlab BLAS and LAPACK
set_property(DIRECTORY APPEND PROPERTY COMPILE_DEFINITIONS ${ARMADILLO_PRIVATE_COMPILE_DEFINITIONS})

#Google profiler tools
if(OPT_MexIFace_PROFILE)
    find_package(GPerfTools REQUIRED)
endif()

#Check the GCC libstdc++.so version
if(CMAKE_CXX_COMPILER_ID STREQUAL GNU AND NOT MexIFace_SYSTEM_LIBSTDCXX_VERSION)
    include(get_libstdcxx_version)
    get_libstdcxx_version(MexIFace_SYSTEM_LIBSTDCXX_VERSION)
    set(MexIFace_SYSTEM_LIBSTDCXX_VERSION ${MexIFace_SYSTEM_LIBSTDCXX_VERSION} CACHE STRING "Version of libsdtc++.so linked for this set of MexIFace targets" FORCE)
endif()

#Find MATLAB roots:
#MATLAB_ROOT - a single matlab 'e.g.: /usr/local/matlab/R2018a'
#MATLAB_ROOTS - a ";" delimited list of matlab roots or directories containing several roots each root dir should match
#               the RE "^[r|R]20\d\d[a|b]"
include(MexIFace-configure-matlab)

#Debugging configuration - from cmake/UncommonCMakeModules
include(ConfigureDebugBuilds)

#Build MexIFace libraries
add_subdirectory(src)

#MexIFace testing consists of succefully building and using simple MexIFace modules
#Test modules are exposed in Matlab subpackage MexIFace.Test
if(BUILD_TESTING)
    #Normally MexIFace_COMPATIBLE_MATLAB_VERSION_STRINGS is set when MexIFaceConfig.cmake is called by other cmake
    #projects with find_package(MexIFace).  This is needed for mexiface_make_mex() to work correctly.
    set(MexIFace_COMPATIBLE_MATLAB_VERSION_STRINGS ${MexIFace_MATLAB_VERSION_STRINGS})
    add_subdirectory(test)
endif()

### Documentation
if(OPT_DOC)
    add_subdirectory(doc)
endif()

#Install Cmake modules and helper files for development
set(SHARED_CMAKE_INSTALL_DIR share/${PROJECT_NAME}/cmake)
install(DIRECTORY ${MexIFace_CMAKE_MODULES_DIR}/ DESTINATION ${SHARED_CMAKE_INSTALL_DIR}/Modules COMPONENT Development)
install(DIRECTORY ${MexIFace_CMAKE_FUNCTIONS_DIR}/ DESTINATION ${SHARED_CMAKE_INSTALL_DIR}/Functions COMPONENT Development)
install(DIRECTORY ${MexIFace_CMAKE_TEMPLATES_DIR}/ DESTINATION ${SHARED_CMAKE_INSTALL_DIR}/Templates COMPONENT Development)
install(DIRECTORY ${MexIFace_CMAKE_DIR}/UncommonCMakeModules/Toolchains DESTINATION ${SHARED_CMAKE_INSTALL_DIR}/Toolchains COMPONENT Development)
install(DIRECTORY ${MexIFace_CMAKE_DIR}/UncommonCMakeModules/
        DESTINATION ${SHARED_CMAKE_INSTALL_DIR}/Modules COMPONENT Development
        REGEX UncommonCMakeModules/Toolchains EXCLUDE)

### PackageConfig
include(ExportPackageWizzard)
if(MexIFace_TARGETS)
    #Only export if we actually made any targets.  This allows DOC to be built without Matlab on CI.
    set(EXPORTED_FIND_MODULES cmake/UncommonCMakeModules/FindArmadillo.cmake
                          cmake/UncommonCMakeModules/FindBLAS.cmake
                          cmake/UncommonCMakeModules/FindLAPACK.cmake
                          cmake/UncommonCMakeModules/MakePkgConfigTarget.cmake)
    export_package_wizzard(FIND_MODULES ${EXPORTED_FIND_MODULES}) #setup build-tree and install-tree exports and packageconfig files
endif()

#Configure Matlab arch dependent variables
set(_CONFIG_MATLAB_ARCH_FILE MexIFaceConfig-Matlab-${MexIFace_MATLAB_SYSTEM_ARCH}.cmake)
configure_file(${CMAKE_SOURCE_DIR}/cmake/Templates/PackageConfig-Matlab-Arch.cmake.in ${_CONFIG_MATLAB_ARCH_FILE} @ONLY)
install(FILES ${CMAKE_BINARY_DIR}/${_CONFIG_MATLAB_ARCH_FILE} DESTINATION lib/MexIFace/cmake COMPONENT Development)

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
set(_MATLAB_CODE_DIR ${MATLAB_CODE_INSTALL_DIR}) #Set relative to install prefix for configure_package_config_file
set(_MATLAB_STARTUP_M ${_MATLAB_CODE_DIR}/startup${PROJECT_NAME}.m)
if(BUILD_TESTING AND OPT_INSTALL_TESTING)
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
set(_MATLAB_CODE_DIR ".") # Relative to startup<PACKAGE_NAME>.m file startup.m
set(_STARTUP_M_INSTALL_DIR ${MATLAB_CODE_INSTALL_DIR}) #Install dir relative to install prefix of startupMexIFace.m
set(_STARTUP_M_TEMPLATE ${CMAKE_SOURCE_DIR}/cmake/Templates/startupPackage.m.in)
configure_file(${_STARTUP_M_TEMPLATE} ${CMAKE_BINARY_DIR}/startupMexIFace.m.install-tree)
install(FILES ${CMAKE_BINARY_DIR}/startupMexIFace.m.install-tree RENAME startupMexIFace.m
        DESTINATION ${MATLAB_CODE_INSTALL_DIR} COMPONENT Runtime)
if(OPT_MexIFace_INSTALL_DISTRIBUTION_STARTUP)
    #Install a copy of the startup at the root of install-tree for convenience of end MATLAB users
    install(FILES ${CMAKE_BINARY_DIR}/startupMexIFace.m.install-tree RENAME startupMexIFace.m
            DESTINATION "." COMPONENT Runtime)
endif()
unset(_MATLAB_CODE_DIR)
unset(_MATLAB_STARTUP_M)
unset(_MATLAB_INSTALLED_MEX_PATH)

if(OPT_EXPORT_BUILD_TREE)
    #Build tree settings use the local matlab code dir and startupMexIFace.m
    #Use source repository for matlab code
    file(RELATIVE_PATH _MATLAB_CODE_DIR ${CMAKE_BINARY_DIR} ${CMAKE_SOURCE_DIR}/matlab) #Relative to CMAKE_BINARY_DIR
    set(_MATLAB_STARTUP_M ${CMAKE_BINARY_DIR}/startupMexIFace.m)
    if(OPT_EXPORT_BUILD_TREE AND NOT CMAKE_EXPORT_NO_PACKAGE_REGISTRY AND NOT CMAKE_CROSSCOMPILING)
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
    set(_STARTUP_M_INSTALL_DIR) #Set to empty in build tree export to signal to startup.m that it is run from build tree
    if(BUILD_TESTING)
        get_property(_MATLAB_BUILD_MEX_PATHS GLOBAL PROPERTY MexIFace_MODULE_BUILD_DIRS) #Test build locations
    else()
        set(_MATLAB_BUILD_MEX_PATHS) #Disable mex export
    endif()
    configure_file(${_STARTUP_M_TEMPLATE} ${CMAKE_BINARY_DIR}/startupMexIFace.m @ONLY)
endif()
unset(_STARTUP_M_TEMPLATE)
unset(_MATLAB_CODE_DIR)
unset(_MATLAB_STARTUP_M)
unset(_MATLAB_BUILD_MEX_PATHS)
unset(_DEPENDENT_STARTUP_M_LOCATIONS)
