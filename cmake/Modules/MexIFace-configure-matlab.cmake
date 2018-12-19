# MexIFace-configure-matlab.cmake
#
# Mark J. Olah (mjo@cs.unm DOT edu)
# Copyright 2018
# see file: LICENCE
#
# Find Matlab using a more modern namespace based approach than the provided /usr/share/cmake/Modules/FindMatlab.cmake.
# Built-in FindMATLAB does not produce Imported targets, and only can find a single version of Matlab.
#
#
### Input variables
# MATLAB_ROOT - Path to the matlab root.
# MATLAB_ROOTS - Path to one or more additional matlabs to add.  The matlab with highest revision
# MATLAB_FIND_VERSION
# MATLAB_FIND_RELEASE
# MATLAB_FIND_VERSIONS
# MATLAB_FIND_RELEASES
# MATLAB_ADDITIONAL_VERSIONS_MAPPING
# MATLAB_ADDITIONAL_LIBSTDCXX_MAPPING
#
### Output variables
# MEXIFACE_MATLAB_FOUND
# MEXIFACE_MATLAB_SYSTEM_MEXEXT
# MEXIFACE_MATLAB_SYSTEM_ARCH
# MEXIFACE_SYSTEM_LIBSTDCXX_VERSION
# MEXIFACE_MATLAB_ROOTS
# MEXIFACE_MATLAB_VERSIONS
# MEXIFACE_MATLAB_VERSION_STRINGS
# MEXIFACE_MATLAB_RELEASES
# MEXIFACE_MATLAB_ARCHS
# MEXIFACE_MATLAB_LIBSTDCXX_VERSIONS
# MEXIFACE_MATLAB_INCOMPATABLE_ROOTS
# MEXIFACE_MATLAB_INCOMPATABLE_VERSIONS
# MEXIFACE_MATLAB_INCOMPATABLE_RELEASES
# MEXIFACE_MATLAB_INCOMPATABLE_ARCHS
# MEXIFACE_MATLAB_INCOMPATABLE_LIBSTDCXX_VERSIONS
# MEXIFACE_MATLAB_INCOMPATABLE_REASONS
#
# MEXIFACE_MATLAB_ORIGINAL_ROOTS - Saved original set of matlab roots.  Recompute roots if this changes from original call
#
### Targets for each matlab X_Y version(e.g., 9_3, 9_5, etc.)
# MATLAB::X_Y::MEX_LIBRARIES
# MATLAB::X_Y::MX_LIBRARY
# MATLAB::X_Y::MAT_LIBRARY
# MATLAB::X_Y::DAT_LIBRARY
# MATLAB::X_Y::ENG_LIBRARY
# MATLAB::X_Y::ENGINE_LIBRARY
# MATLAB::X_Y::DATAARRAY_LIBRARY
#
###
# MEXIFACE_MATLAB_MEX_LIBRARIES_ALL_TARGETS  - All valid MATLAB::X_Y::MEX_LIBRARIES targets as a list.
#
### Useful directory and file lists for each ROOT
# MEXIFACE_MATLAB_INCLUDE_DIRS
# MEXIFACE_MATLAB_LIBRARY_DIRS
# MEXIFACE_MATLAB_EXTERN_LIBRARY_DIRS
# MEXIFACE_MATLAB_MEXAPI_VERSION_SOURCES
# MEXIFACE_MATLAB_LINKER_MAP_FILES #UNIX only
#
#

set(MATLAB_VERSIONS_MAPPING
    "R2018b=9.5"
    "R2018a=9.4"
    "R2017b=9.3"
    "R2017a=9.2"
    "R2016b=9.1"
    "R2016a=9.0"
    "R2015b=8.6"
    "R2015a=8.5"
    "R2014b=8.4"
    "R2014a=8.3"
    "R2013b=8.2"
    "R2013a=8.1"
    "R2012b=8.0"
    ${MATLAB_ADDITIONAL_VERSIONS_MAPPING}
    )

set(MATLAB_LIBSTDCXX_MAPPING
    "R2018b=6.0.22"
    "R2018a=6.0.22"
    "R2017b=6.0.20"
    "R2017a=6.0.20"
    "R2016b=6.0.20"
    "R2016a=6.0.17"
    "R2015b=6.0.17"
    "R2015a=6.0.17"
    "R2014b=6.0.17"
    "R2014a=6.0.17"
    "R2013b=6.0.17"
    "R2013a=6.0.13"
    "R2012b=6.0.13"
    ${MATLAB_ADDITIONAL_LIBSTDCXX_MAPPING}
    )

if(CMAKE_CXX_COMPILER_ID STREQUAL GNU AND NOT MEXIFACE_SYSTEM_LIBSTDCXX_VERSION)
    include(get_libstdcxx_version)
    get_libstdcxx_version(MEXIFACE_SYSTEM_LIBSTDCXX_VERSION)
endif()

# Function: matlab_get_cannonical_release_name
# Translate a generalize matlab release name eg: r2018b or R2018b_pre into a cannonical form eg: R2018b.
# We use the cannonical name for mapping releases to versions and libstdc++
function(matlab_get_cannonical_release canonical release)
    string(REGEX REPLACE "^[rR](20[0-9][0-9][ab])" "R\\1" _release ${release})
    set(${canonical} ${_release} PARENT_SCOPE)
endfunction()

function(matlab_get_version_from_release version release)
    matlab_get_cannonical_release(release ${release})
    string(REGEX REPLACE "${release})=([0-9\\.]+)" "\\1" _version ${MATLAB_VERSIONS_MAPPING})
    set(${version} ${_version} PARENT_SCOPE)
endfunction()

function(matlab_get_release_from_version release version)
    string(REGEX REPLACE "^([0-9]+)\\.([0-9]+)" "\\1\\\\.\\2" version_re ${version})
    string(REGEX REPLACE "(R20[0-9][0-9][ab])=${version_re}" "\\1" _release ${MATLAB_VERSIONS_MAPPING})
    set(${release} ${_release} PARENT_SCOPE)
endfunction()

function(matlab_get_libstdcxx_from_release libstdcxx release)
    matlab_get_cannonical_release(release ${release})
    string(REGEX REPLACE "${release})=([0-9\\.]+)" "\\1" _version ${MATLAB_LIBSTDCXX_MAPPING})
    set(${libstdcxx} ${_version} PARENT_SCOPE)
endfunction()


set(MATLAB_PRODUCT_VERSION_DIR "appdata/products")
# Check if dir at ${root} is a valid matlab install.  Get version and arch.
function(_mexiface_check_matlab_root root is_valid version arch)
    set(MATLAB_PRODUCT_VERSION_FILENAME_REGEX "MATLAB ([0-9\\.]+) ([A-Za-z0-9_]+) \\d+.xml")
    if(EXISTS ${root}/${MATLAB_PRODUCT_VERSION_DIR})
        file(GLOB vers_files "MATLAB*.xml")
        string(REGEX MATCH ${MATLAB_PRODUCT_VERSION_FILENAME_REGEX} matlab_vers_files ${vers_files})
        set(${is_valid} True PARENT_SCOPE)
        set(${version} ${CMAKE_MATCH_1} PARENT_SCOPE)
        set(${arch} ${CMAKE_MATCH_2} PARENT_SCOPE)
    else()
        message(MESSAGE "[Mexiface-MATLAB]: Unable to find appdata/products at matlab root: ${root}")
        set(${is_valid} False PARENT_SCOPE)
    endif()
endfunction()

#Check if a given matlab root,version,arch,libstdcxx_version is valid as a target for this system
function(_mexiface_matlab_check_valid is_valid reason root version arch libsdtcxx_version)
    if(NOT ${arch} STREQUAL ${MEXIFACE_MATLAB_SYSTEM_ARCH})
        set(${is_valid} False PARENT_SCOPE)
        set(${reason} arch PARENT_SCOPE)
    elseif(CMAKE_CXX_COMPILER_ID STREQUAL GNU AND MEXIFACE_SYSTEM_LIBSTDCXX_VERSION AND ${libstdcxx_version} VERSION_LESS ${MEXIFACE_SYSTEM_LIBSTDCXX_VERSION})
        set(${is_valid} False PARENT_SCOPE)
        set(${reason} libstdcxx PARENT_SCOPE)
    else()
        set(${is_valid} True PARENT_SCOPE)
    endif()
endfunction()

function(_mexiface_get_matlab_roots roots)
    function(_list_subdirs result curdir)
        file(GLOB children RELATIVE ${curdir} ${curdir}/*)
        set(dirlist "")
        foreach(child IN LISTS children)
            if(IS_DIRECTORY ${curdir}/${child})
            list(APPEND dirlist ${child})
            endif()
        endforeach()
        set(${result} ${dirlist} PARENT_SCOPE)
    endfunction()

    set(_roots)
    set(_versions)
    set(_archs)
    foreach(_root IN LISTS ROOTS)
        _mexiface_check_matlab_root(${_root} is_valid version release arch)
        if(is_valid)
            list(APPEND _roots ${_root})
            list(APPEND _versions ${version})
            list(APPEND _archs ${arch})
        else()
            _list_subdirs(sub_roots ${_root})
            foreach(sub_root IN LISTS sub_roots)
                if(EXISTS ${sub_root}/${MATLAB_PRODUCT_VERSION_DIR})
                    _mexiface_check_matlab_root(${sub_root} is_valid version release arch)
                    if(is_valid)
                        list(APPEND _roots ${sub_root})
                        list(APPEND _versions ${verion})
                        list(APPEND _archs ${arch})
                    endif()
                endif()
            endforeach()
        endif()
    endforeach()

    set(_releases)
    set(_libstdcxxs)
    set(_valid_roots)
    set(_valid_releases)
    set(_valid_versions)
    set(_valid_version_strings)
    set(_valid_libstdcxxs)
    set(_invalid_roots)
    set(_invalid_releases)
    set(_invalid_versions)
    set(_invalid_archs)
    set(_invalid_libstdcxxs)
    set(_invalid_reasons)
    list(LENGTH _roots nroots)
    math(EXPR niter "${nroots} - 1")
    if(niter GREATER_EQUAL 0)
        foreach(idx RANGE ${niter})
            list(GET _roots ${idx} _root)
            list(GET _version ${idx} _versions)
            list(GET _arch ${idx} _archs)
            matlab_get_release_from_version(_release ${_version})
            list(APPEND _releases ${_release})
            matlab_get_libstdcxx_from_release(_libstdxx ${_release})
            list(APPEND _libstdcxxs ${_libstdxx})
            #Check validity for current build
            _mexiface_matlab_check_valid(is_valid reason ${_root} ${_version} ${_arch} ${_libstdcxx})
            if(is_valid)
                if(NOT ${_version} IN_LIST _valid_versions)
                    list(APPEND _valid_roots ${_root})
                    list(APPEND _valid_versions ${_version})
                    string(REGEX REPLACE "^([0-9]+)\\.([0-9]+)" "\\1_\\2" _version_string ${_version})
                    list(APPEND _valid_version_strings ${_version_string})
                    list(APPEND _valid_releases ${_release})
                    list(APPEND _valid_libstdcxxs ${_libstdxx})
                else()
                    list(APPEND _invalid_roots ${_root})
                    list(APPEND _invalid_versions ${_version})
                    list(APPEND _invalid_releases ${_release})
                    list(APPEND _invalid_archs ${_arch})
                    list(APPEND _invalid_libstdcxxs ${_libstdxx})
                    list(APPEND _invalid_reasons "duplicates version ${_version}")
                endif()
            else()
                list(APPEND _invalid_roots ${_root})
                list(APPEND _invalid_versions ${_version})
                list(APPEND _invalid_releases ${_release})
                list(APPEND _invalid_archs ${_arch})
                list(APPEND _invalid_libstdcxxs ${_libstdxx})
                list(APPEND _invalid_reasons ${reason})
            endif()
        endforeach()
    endif()

    #Set parent variables
    set(MEXIFACE_MATLAB_ROOTS ${_valid_roots} PARENT_SCOPE)
    set(MEXIFACE_MATLAB_VERSIONS ${_valid_versions} PARENT_SCOPE)
    set(MEXIFACE_MATLAB_VERSION_STRINGS ${_valid_version_strings} PARENT_SCOPE)
    set(MEXIFACE_MATLAB_RELEASES ${_valid_releases} PARENT_SCOPE)
    set(MEXIFACE_MATLAB_LIBSTDCXX_VERSIONS ${_valid_libstdcxxs} PARENT_SCOPE)
    set(MEXIFACE_MATLAB_INCOMPATABLE_ROOTS ${_invalid_roots} PARENT_SCOPE)
    set(MEXIFACE_MATLAB_INCOMPATABLE_VERSIONS ${_valid_versions} PARENT_SCOPE)
    set(MEXIFACE_MATLAB_INCOMPATABLE_RELEASES ${_valid_releases} PARENT_SCOPE)
    set(MEXIFACE_MATLAB_INCOMPATABLE_ARCHS ${_invalid_archs} PARENT_SCOPE)
    set(MEXIFACE_MATLAB_INCOMPATABLE_LIBSTDCXX_VERSIONS ${_invalid_libstdcxxs} PARENT_SCOPE)
    set(MEXIFACE_MATLAB_INCOMPATABLE_REASONS ${_invalid_reasons} PARENT_SCOPE)
endfunction()

function(_mexiface_make_matlab_targets)
    list(LENGTH _roots nroots)
    math(EXPR niter "${nroots} - 1")
    set(_include_dirs)
    set(_lib_dirs)
    set(_extern_lib_dirs)
    set(_linker_map_files)
    set(_mexapi_version_sources)
    if(niter GREATER_EQUAL 0)
        foreach(idx RANGE ${niter})
            list(GET ${MEXIFACE_MATLAB_ROOTS} ${idx} _root)
            list(GET ${MEXIFACE_MATLAB_VERSIONS} ${idx} _vers)
            list(GET ${MEXIFACE_MATLAB_VERSION_STRINGS} ${idx} _ver_string)
            set(target_prefix "MATLAB${_ver_string}::")

            set(include_dir ${root}/extern/include)
            set(lib_dir ${root}/bin/${MEXIFACE_MATLAB_SYSTEM_ARCH})
            set(versionfile ${root}/extern/version/cpp_mexapi_version.cpp)

            if(UNIX)
                set(extern_lib_dir ${root}/extern/lib/glnxa64)
                set(mapfile ${root}/extern/lib/glnxa64/c_exportsmexfileversion.map)
            elseif(WIN32 AND CMAKE_CROSSCOMPILING)
                set(extern_lib_dir ${root}/extern/lib/win64/mingw64)
            endif()

            add_library(${target_prefix}MEX_LIBRARIES INTERFACE IMPORTED)
            set_target_properties(${target_prefix}MEX_LIBRARIES INTERFACE_INCLUDE_DIRECTORIES ${include_dir})
            set_target_properties(${target_prefix}MEX_LIBRARIES INTERFACE_COMPILE_OPTIONS -fexceptions -fPIC -fno-omit-frame-pointer)
            set_target_properties(${target_prefix}MEX_LIBRARIES INTERFACE_COMPILE_DEFINITIONS MATLAB_MEX_FILE)
            set_target_properties(${target_prefix}MEX_LIBRARIES INTERFACE_LINK_LIBRARIES Pthread::Pthreads)
            set_target_properties(${target_prefix}MEX_LIBRARIES INTERFACE_LINK_OPTIONS "-Wl,--no-undefined -Wl,--as-needed")
            if(UNIX)
                set_target_properties(${target_prefix}MEX_LIBRARIES INTERFACE_LINK_OPTIONS "-Wl,--version-script,${mapfile}") #Declares visibility of symbols.
            endif()
            set_target_properties(${target_prefix}MEX_LIBRARIES INTERFACE_LINK_DIRECTORIES ${lib_dir} ${extern_lib_dir})
            set_target_properties(${target_prefix}MEX_LIBRARIES INTERFACE_LINK_LIBRARIES "-leng -lmx -lmat -lmex -lmwlapack -lmwblas")
            #set_target_properties(${target_prefix}MEX_LIBRARIES INTERFACE_COMPILE_DEFINITIONS _GNU_SOURCE) #Unsure if we need this one.  Got from offical matlab makefile.

            #Support for interleaved complex
            if(MEXIFACE_MATLAB_INTERLEAVED_COMPLEX AND ${_vers} VERSION_GREATER_EQUAL 9.4)
                set_target_properties(${target_prefix}MEX_LIBRARIES INTERFACE_COMPILE_DEFINITIONS MATLAB_DEFAULT_RELEASE=R2018a)
            else()
                set_target_properties(${target_prefix}MEX_LIBRARIES INTERFACE_COMPILE_DEFINITIONS MATLAB_DEFAULT_RELEASE=R2017b)
            endif()
            #Support for 64-bit indexed arrays
            if(MEXIFACE_MATLAB_LARGE_ARRAY_DIMS AND ${_vers} VERSION_GREATER_EQUAL 9.2)
                set_target_properties(${target_prefix}MEX_LIBRARIES INTERFACE_COMPILE_DEFINITIONS MX_COMPAT_64)
            else()
                set_target_properties(${target_prefix}MEX_LIBRARIES INTERFACE_COMPILE_DEFINITIONS MX_COMPAT_32)
            endif()
            list(APPEND _include_dirs ${indlude_dir})
            list(APPEND _lib_dirs ${lib_dir})
            list(APPEND _extern_lib_dirs ${extern_lib_dir})
            list(APPEND _mexapi_version_sources ${versionfile})
            if(UNIX)
                list(APPEND _linker_map_files ${mapfile})
            endif()
        endforeach()
    endif()
    set(MEXIFACE_MATLAB_INCLUDE_DIRS ${_include_dirs} PARENT_SCOPE)
    set(MEXIFACE_MATLAB_LIBRARY_DIRS ${_lib_dirs} PARENT_SCOPE)
    set(MEXIFACE_MATLAB_EXTERN_LIBRARY_DIRS ${_extern_lib_dirs} PARENT_SCOPE)
    set(MEXIFACE_MATLAB_MEXAPI_VERSION_SOURCES ${_mexapi_version_sources} PARENT_SCOPE)
    if(UNIX)
        set(MEXIFACE_MATLAB_LINKER_MAP_FILES ${_linker_map_files} PARENT_SCOPE)
    endif()
endfunction()

option(MEXIFACE_MATLAB_INTERLEAVED_COMPLEX "Enable interleaved complex API in R2018a+" OFF)
option(MEXIFACE_MATLAB_LARGE_ARRAY_DIMS "Enable 64-bit array indexes in R2017a+" OFF)

if(WIN32)
    set(MEXIFACE_MATLAB_SYSTEM_MEXEXT mexw64)
    set(MEXIFACE_MATLAB_SYSTEM_ARCH win64)
elseif(UNIX)
    set(MEXIFACE_MATLAB_SYSTEM_MEXEXT mexa64)
    set(MEXIFACE_MATLAB_SYSTEM_ARCH glnxa64)
elseif(APPLE)
    set(MEXIFACE_MATLAB_SYSTEM_MEXEXT mexmaci64)
    set(MEXIFACE_MATLAB_SYSTEM_ARCH maci64)
endif()
string(TOUPPER ${MEXIFACE_MATLAB_SYSTEM_ARCH} MEXIFACE_MATLAB_SYSTEM_ARCH_UP)

message(STATUS "[MexIFace::Matlab] MEXIFACE_MATLAB_SYSTEM_MEXEXT:${MEXIFACE_MATLAB_SYSTEM_MEXEXT}]")
message(STATUS "[MexIFace::Matlab] MEXIFACE_MATLAB_SYSTEM_ARCH:${MEXIFACE_MATLAB_SYSTEM_ARCH}]")
message(STATUS "[MexIFace::Matlab] MEXIFACE_SYSTEM_LIBSTDCXX_VERSION:${MEXIFACE_SYSTEM_LIBSTDCXX_VERSION}]")

#Find MATLAB_ROOT environment variable
#  If cross_compiling we'll look for MATLAB_ROOT_W64 or MATLAB_ROOT_MACI64
if(NOT MATLAB_ROOTS)
    set(MATLAB_ROOTS)
endif()
if(MATLAB_ROOT)
    list(INSERT MATLAB_ROOTS 0 ${MATLAB_ROOT})
endif()
if(NOT MATLAB_ROOTS) #Look in environment VARIABLES
    if(NOT CMAKE_CROSSCOMPILING)
        if($ENV{MATLAB_ROOT})
            list(APPEND MATLAB_ROOTS $ENV{MATLAB_ROOT})
        endif()
        if($ENV{MATLAB_ROOTS})
            list(APPEND MATLAB_ROOTS $ENV{MATLAB_ROOTS})
        endif()
    endif()
    #Check for arch-specific environment variables
    if($ENV{MATLAB_ROOT_${MEXIFACE_MATLAB_SYSTEM_ARCH_UP}})
        list(APPEND MATLAB_ROOTS $ENV{MATLAB_ROOT_${MEXIFACE_MATLAB_SYSTEM_ARCH_UP}})
    endif()
    if($ENV{MATLAB_ROOTS_${MEXIFACE_MATLAB_SYSTEM_ARCH_UP}})
        list(APPEND MATLAB_ROOTS $ENV{MATLAB_ROOTS_${MEXIFACE_MATLAB_SYSTEM_ARCH_UP}})
    endif()
endif()
if(NOT MATLAB_ROOTS)
    message(SEND_ERROR "[MexIFace::Matlab] Found no matlab roots.  Set MATLAB_ROOT or MATLAB_ROOTS in CMake Cache or in environment variables.")
endif()

#Only look for new compatable matlab versions if we have not already found valid roots or
# MATLAB_ROOTS has changed since the last time we did the search
if(NOT MEXIFACE_MATLAB_FOUND OR (MEXIFACE_MATLAB_ORIGINAL_ROOTS AND NOT MATLAB_ROOTS STREQUAL MEXIFACE_MATLAB_ORIGINAL_ROOTS))
    message(STATUS "[MexIFace::Matlab] Finding matlab using new roots: ${MATLAB_ROOTS}")
    set(MEXIFACE_MATLAB_ORIGINAL_ROOTS ${MATLAB_ROOTS})
    _mexiface_matlab_get_roots(${MATLAB_ROOTS})
    if(MATLAB_ROOTS)
        set(MEXIFACE_MATLAB_FOUND True)
    else()
        set(MEXIFACE_MATLAB_FOUND False)
    endif()
    set(MEXIFACE_MATLAB_FOUND ${MEXIFACE_MATLAB_FOUND} CACHE BOOL "Found one or more valid MATLAB_ROOTS for use with MexIFace" FORCE)
    set(MEXIFACE_MATLAB_ORIGINAL_ROOTS ${MEXIFACE_MATLAB_ORIGINAL_ROOTS} CACHE STRING "Original list of MATLAB_ROOTS used to find Matlab versions for MexIFace." FORCE)
endif()

message(STATUS "[MexIFace::Matlab] MEXIFACE_MATLAB_ROOTS:${MEXIFACE_MATLAB_ROOTS}]")
message(STATUS "[MexIFace::Matlab] MEXIFACE_MATLAB_VERSIONS:${MEXIFACE_MATLAB_VERSIONS}]")
message(STATUS "[MexIFace::Matlab] MEXIFACE_MATLAB_RELEASES:${MEXIFACE_MATLAB_RELEASES}]")
message(STATUS "[MexIFace::Matlab] MEXIFACE_MATLAB_VERSIONS:${MEXIFACE_MATLAB_ARCHS}]")
message(STATUS "[MexIFace::Matlab] MEXIFACE_MATLAB_LIBSDTCXX_VERSIONS:${MEXIFACE_MATLAB_LIBSDTCXX_VERSIONS}]")
message(STATUS "[MexIFace::Matlab] MEXIFACE_INCOMPATABLE_MATLAB_ROOTS:${MEXIFACE_INCOMPATABLE_MATLAB_ROOTS}]")
message(STATUS "[MexIFace::Matlab] MEXIFACE_INCOMPATABLE_MATLAB_VERSIONS:${MEXIFACE_INCOMPATABLE_MATLAB_VERSIONS}]")
message(STATUS "[MexIFace::Matlab] MEXIFACE_INCOMPATABLE_MATLAB_RELEASES:${MEXIFACE_INCOMPATABLE_MATLAB_RELEASES}]")
message(STATUS "[MexIFace::Matlab] MEXIFACE_INCOMPATABLE_MATLAB_VERSIONS:${MEXIFACE_INCOMPATABLE_MATLAB_ARCHS}]")
message(STATUS "[MexIFace::Matlab] MEXIFACE_INCOMPATABLE_MATLAB_LIBSDTCXX_VERSIONS:${MEXIFACE_INCOMPATABLE_MATLAB_LIBSDTCXX_VERSIONS}]")
message(STATUS "[MexIFace::Matlab] MEXIFACE_INCOMPATABLE_RESONS:${MEXIFACE_INCOMPATABLE_REASONS}]")

# Pthreads
if (WIN32)
    find_library(PTHREAD_LIBRARY libwinpthread.dll REQUIRED)
elseif(UNIX)
    find_library(PTHREAD_LIBRARY libpthread.so REQUIRED)
endif()
message(STATUS "[MexIFace::Matlab]  Found Pthread Libarary: ${PTHREAD_LIBRARY}")

_mexiface_make_matlab_targets()
