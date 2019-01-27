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
# MexIFace_MATLAB_FOUND
# MexIFace_MATLAB_SYSTEM_MEXEXT
# MexIFace_MATLAB_SYSTEM_ARCH
# MexIFace_SYSTEM_LIBSTDCXX_VERSION
# MexIFace_MATLAB_ROOTS
# MexIFace_MATLAB_VERSIONS
# MexIFace_MATLAB_VERSION_STRINGS
# MexIFace_MATLAB_RELEASES
# MexIFace_MATLAB_ARCHS
# MexIFace_MATLAB_LIBSTDCXX_VERSIONS
# MexIFace_MATLAB_INCOMPATABLE_ROOTS
# MexIFace_MATLAB_INCOMPATABLE_VERSIONS
# MexIFace_MATLAB_INCOMPATABLE_RELEASES
# MexIFace_MATLAB_INCOMPATABLE_ARCHS
# MexIFace_MATLAB_INCOMPATABLE_LIBSTDCXX_VERSIONS
# MexIFace_MATLAB_INCOMPATABLE_REASONS
#
# MexIFace_MATLAB_ORIGINAL_ROOTS - Saved original set of matlab roots.  Recompute roots if this changes from original call
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
# MexIFace_MATLAB_MEX_LIBRARIES_ALL_TARGETS  - All valid MATLAB::X_Y::MEX_LIBRARIES targets as a list.
#
### Useful directory and file lists for each ROOT
# MexIFace_MATLAB_INCLUDE_DIRS
# MexIFace_MATLAB_LIBRARY_DIRS
# MexIFace_MATLAB_EXTERN_LIBRARY_DIRS
# MexIFace_MATLAB_MEXAPI_VERSION_SOURCES
# MexIFace_MATLAB_LINKER_MAP_FILES #UNIX only
#
#

set(MATLAB_VERSIONS_MAPPING
    "R2019a=9.6"
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
    "R2019a=6.0.22"
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

if(CMAKE_CXX_COMPILER_ID STREQUAL GNU AND NOT MexIFace_SYSTEM_LIBSTDCXX_VERSION)
    include(get_libstdcxx_version)
    get_libstdcxx_version(MexIFace_SYSTEM_LIBSTDCXX_VERSION)
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
    string(REGEX MATCH "(R20[0-9][0-9][ab])=${version_re}" "\\1" _ ${MATLAB_VERSIONS_MAPPING})
    set(${release} ${CMAKE_MATCH_1} PARENT_SCOPE)
endfunction()

function(matlab_get_libstdcxx_from_release libstdcxx release)
    matlab_get_cannonical_release(release ${release})
    string(REGEX MATCH "${release}=([0-9\\.]+)" _ ${MATLAB_LIBSTDCXX_MAPPING})
    set(${libstdcxx} ${CMAKE_MATCH_1} PARENT_SCOPE)
endfunction()


set(MATLAB_PRODUCT_VERSION_DIR "appdata/products")
# Check if dir at ${root} is a valid matlab install.  Get version and arch.
function(_mexiface_check_matlab_root root is_valid version arch)
    set(MATLAB_PRODUCT_VERSION_FILENAME_REGEX "MATLAB ([0-9\\.]+) ([A-Za-z0-9_]+) [0-9]+.xml")
    if(EXISTS ${root}/${MATLAB_PRODUCT_VERSION_DIR})
        file(GLOB vers_files "${root}/${MATLAB_PRODUCT_VERSION_DIR}/MATLAB*.xml")
        string(REGEX MATCH ${MATLAB_PRODUCT_VERSION_FILENAME_REGEX} matlab_vers_files ${vers_files})
        set(${is_valid} True PARENT_SCOPE)
        set(${version} ${CMAKE_MATCH_1} PARENT_SCOPE)
        set(${arch} ${CMAKE_MATCH_2} PARENT_SCOPE)
    elseif(EXISTS ${root}/VersionInfo.xml)
        file(READ ${root}/VersionInfo.xml vers_xml)
        string(REGEX MATCH "<version>([0-9]+\\.[0-9]+)" vers_str ${vers_xml})
        set(${is_valid} True PARENT_SCOPE)
        set(${version} ${CMAKE_MATCH_1} PARENT_SCOPE)
        if(EXISTS ${root}/bin/glnxa64)
            set(${arch} glnxa64 PARENT_SCOPE)
        elseif(EXISTS ${root}/bin/glnxa64)
            set(${arch} win64 PARENT_SCOPE)
        else()
            set(${arch} unknown PARENT_SCOPE)
        endif()
    else()
#         message(STATUS "[Mexiface-MATLAB]: Unable to find appdata/products at matlab root: ${root}")
        set(${is_valid} False PARENT_SCOPE)
    endif()
#     message(STATUS "_mexiface_check_matlab_root is_valid:${${is_valid}} version:${${version}} arch:${${arch}}")
endfunction()

#Check if a given matlab root,version,arch,libstdcxx_version is valid as a target for this system
function(_mexiface_matlab_check_valid is_valid reason root version arch libstdcxx_version)
    if(NOT ${arch} STREQUAL ${MexIFace_MATLAB_SYSTEM_ARCH})
        set(${is_valid} False PARENT_SCOPE)
        set(${reason} arch PARENT_SCOPE)
    elseif((${CMAKE_CXX_COMPILER_ID} STREQUAL GNU) AND MexIFace_SYSTEM_LIBSTDCXX_VERSION AND (${libstdcxx_version} VERSION_LESS ${MexIFace_SYSTEM_LIBSTDCXX_VERSION}))
        set(${is_valid} False PARENT_SCOPE)
        set(${reason} "libstdcxx compatability" PARENT_SCOPE)
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

    #Sort the roots versions and archs vectors together
    function(sort_roots roots versions archs)
        list(LENGTH ${roots} nroots)
        math(EXPR niter "${nroots} - 1")
        if(NOT niter GREATER_EQUAL 0)
            return()
        endif()
        set(vec)
        foreach(idx RANGE ${niter})
            list(GET ${roots} ${idx} root)
            list(GET ${versions} ${idx} version)
            list(GET ${archs} ${idx} arch)
            list(APPEND vec ${version}:${root}:${arch})
        endforeach()
        list(SORT vec)
        set(_roots)
        set(_versions)
        set(_archs)
        foreach(v IN LISTS vec)
            string(REGEX MATCH "([^:]+):([^:]+):([^:]+)" _ ${v})
            list(APPEND _versions ${CMAKE_MATCH_1})
            list(APPEND _roots ${CMAKE_MATCH_2})
            list(APPEND _archs ${CMAKE_MATCH_3})
        endforeach()
        set(${roots} ${_roots} PARENT_SCOPE)
        set(${versions} ${_versions} PARENT_SCOPE)
        set(${archs} ${_archs} PARENT_SCOPE)
    endfunction()

    set(_roots)
    set(_versions)
    set(_archs)
    foreach(_root IN LISTS roots)
        _mexiface_check_matlab_root(${_root} is_valid _version _arch)
        if(is_valid)
            list(APPEND _roots ${_root})
            list(APPEND _versions ${_version})
            list(APPEND _archs ${_arch})
        else()
            _list_subdirs(sub_roots ${_root})
            foreach(_sub_root IN LISTS sub_roots)
                if(EXISTS ${_root}/${_sub_root}/${MATLAB_PRODUCT_VERSION_DIR} OR EXISTS ${_root}/${_sub_root}/VersionInfo.xml)
                    _mexiface_check_matlab_root(${_root}/${_sub_root} is_valid _version _arch)
                    if(is_valid)
                        list(APPEND _roots ${_root}/${_sub_root})
                        list(APPEND _versions ${_version})
                        list(APPEND _archs ${_arch})
                    endif()

                endif()
            endforeach()
        endif()
    endforeach()
    sort_roots(_roots _versions _archs)

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
            list(GET _versions ${idx} _version)
            list(GET _archs ${idx} _arch)
            matlab_get_release_from_version(_release ${_version})
            list(APPEND _releases ${_release})
            matlab_get_libstdcxx_from_release(_libstdcxx ${_release})
            list(APPEND _libstdcxxs ${_libstdcxx})
            #Check validity for current build
            _mexiface_matlab_check_valid(is_valid reason ${_root} ${_version} ${_arch} ${_libstdcxx})
            message(STATUS "[MexIFace::Matlab] Checking Matlab Roots --- Idx:${idx}/${niter} Root: ${_root} Version:${_version} Arch:${_arch} Release:${_release} Libstdcxx:${_libstdcxx} is_valid:${is_valid} reason:${reason}")
            if(is_valid)
                if(NOT ${_version} IN_LIST _valid_versions)
                    list(APPEND _valid_roots ${_root})
                    list(APPEND _valid_versions ${_version})
                    string(REGEX REPLACE "^([0-9]+)\\.([0-9]+)" "\\1_\\2" _version_string ${_version})
                    list(APPEND _valid_version_strings ${_version_string})
                    list(APPEND _valid_releases ${_release})
                    list(APPEND _valid_libstdcxxs ${_libstdcxx})
                else()
                    list(APPEND _invalid_roots ${_root})
                    list(APPEND _invalid_versions ${_version})
                    list(APPEND _invalid_releases ${_release})
                    list(APPEND _invalid_archs ${_arch})
                    list(APPEND _invalid_libstdcxxs ${_libstdcxx})
                    list(APPEND _invalid_reasons "duplicates version ${_version}")
                endif()
            else()
                list(APPEND _invalid_roots ${_root})
                list(APPEND _invalid_versions ${_version})
                list(APPEND _invalid_releases ${_release})
                list(APPEND _invalid_archs ${_arch})
                list(APPEND _invalid_libstdcxxs ${_libstdcxx})
                list(APPEND _invalid_reasons ${reason})
            endif()
            unset(reason)
        endforeach()
    endif()

    #Set parent variables
    set(MexIFace_MATLAB_ROOTS ${_valid_roots} PARENT_SCOPE)
    set(MexIFace_MATLAB_VERSIONS ${_valid_versions} PARENT_SCOPE)
    set(MexIFace_MATLAB_VERSION_STRINGS ${_valid_version_strings} PARENT_SCOPE)
    set(MexIFace_MATLAB_RELEASES ${_valid_releases} PARENT_SCOPE)
    set(MexIFace_MATLAB_LIBSTDCXX_VERSIONS ${_valid_libstdcxxs} PARENT_SCOPE)
    set(MexIFace_MATLAB_INCOMPATABLE_ROOTS ${_invalid_roots} PARENT_SCOPE)
    set(MexIFace_MATLAB_INCOMPATABLE_VERSIONS ${_invalid_versions} PARENT_SCOPE)
    set(MexIFace_MATLAB_INCOMPATABLE_RELEASES ${_invalid_releases} PARENT_SCOPE)
    set(MexIFace_MATLAB_INCOMPATABLE_ARCHS ${_invalid_archs} PARENT_SCOPE)
    set(MexIFace_MATLAB_INCOMPATABLE_LIBSTDCXX_VERSIONS ${_invalid_libstdcxxs} PARENT_SCOPE)
    set(MexIFace_MATLAB_INCOMPATABLE_REASONS ${_invalid_reasons} PARENT_SCOPE)
endfunction()

function(_mexiface_make_matlab_targets)
    list(LENGTH MexIFace_MATLAB_ROOTS nroots)
    math(EXPR niter "${nroots} - 1")
    set(_include_dirs)
    set(_lib_dirs)
    set(_extern_lib_dirs)
    set(_linker_map_files)
    set(_mexapi_version_sources)
    set(_targets)
    if(niter GREATER_EQUAL 0)
        foreach(idx RANGE ${niter})
            list(GET MexIFace_MATLAB_ROOTS ${idx} _root)
            list(GET MexIFace_MATLAB_VERSIONS ${idx} _vers)
            list(GET MexIFace_MATLAB_VERSION_STRINGS ${idx} _ver_string)
            message(STATUS "[MexIFace::Matlab] Making targets for root:${_root} vers:${_vers} ver str:${_ver_string}")
            set(target_prefix "MATLAB::${_ver_string}::")

            set(include_dir ${_root}/extern/include)
            set(lib_dir ${_root}/bin/${MexIFace_MATLAB_SYSTEM_ARCH})
            if(EXISTS ${_root}/extern/version/cpp_mexapi_version.cpp)
                set(versionfile ${_root}/extern/version/cpp_mexapi_version.cpp)
            else()
                set(versionfile NOTFOUND)
            endif()
            if(UNIX)
                set(extern_lib_dir ${_root}/extern/lib/${MexIFace_MATLAB_SYSTEM_ARCH})
                set(os_lib_dir ${_root}/sys/os/${MexIFace_MATLAB_SYSTEM_ARCH})
                if(EXISTS ${_root}/extern/lib/glnxa64/c_exportsmexfileversion.map)
                    set(mapfile ${_root}/extern/lib/glnxa64/c_exportsmexfileversion.map)
                elseif(EXISTS ${_root}/extern/lib/glnxa64/mexFunction.map)
                    set(mapfile ${_root}/extern/lib/glnxa64/mexFunction.map)
                endif()
            elseif(WIN32 AND CMAKE_CROSSCOMPILING)
                set(extern_lib_dir ${_root}/extern/lib/win64/mingw64)
            endif()

            add_library(${target_prefix}MEX_LIBRARIES INTERFACE IMPORTED)
            target_include_directories(${target_prefix}MEX_LIBRARIES INTERFACE ${include_dir})
            target_compile_options(${target_prefix}MEX_LIBRARIES INTERFACE -fexceptions -fno-omit-frame-pointer)
            target_compile_definitions(${target_prefix}MEX_LIBRARIES INTERFACE MATLAB_MEX_FILE)
            target_link_libraries(${target_prefix}MEX_LIBRARIES INTERFACE Pthread::Pthread)
            target_link_options(${target_prefix}MEX_LIBRARIES INTERFACE -Wl,--no-undefined)
            target_link_options(${target_prefix}MEX_LIBRARIES INTERFACE -Wl,--as-needed)
            target_link_directories(${target_prefix}MEX_LIBRARIES INTERFACE ${lib_dir} ${extern_lib_dir} ${os_lib_dir})
            target_link_libraries(${target_prefix}MEX_LIBRARIES INTERFACE -lmx -lmat -lmex)

            #Support for interleaved complex
            if(OPT_MexIFace_MATLAB_INTERLEAVED_COMPLEX AND ${_vers} VERSION_GREATER_EQUAL 9.4)
                target_compile_definitions(${target_prefix}MEX_LIBRARIES INTERFACE MATLAB_DEFAULT_RELEASE=R2018a)
            else()
                target_compile_definitions(${target_prefix}MEX_LIBRARIES INTERFACE MATLAB_DEFAULT_RELEASE=R2017b)
            endif()
            #Support for 64-bit indexed arrays
            if(OPT_MexIFace_MATLAB_LARGE_ARRAY_DIMS AND ${_vers} VERSION_GREATER_EQUAL 9.2)
                target_compile_definitions(${target_prefix}MEX_LIBRARIES INTERFACE MX_COMPAT_64)
            else()
                target_compile_definitions(${target_prefix}MEX_LIBRARIES INTERFACE MX_COMPAT_32)
            endif()
            list(APPEND _targets ${target_prefix}MEX_LIBRARIES)
            list(APPEND _include_dirs ${include_dir})
            list(APPEND _lib_dirs ${lib_dir})
            list(APPEND _extern_lib_dirs ${extern_lib_dir})
            list(APPEND _mexapi_version_sources ${versionfile})
            if(UNIX)
                list(APPEND _linker_map_files ${mapfile})
            endif()
        endforeach()
    endif()
    set(MexIFace_MATLAB_MEX_LIBRARIES_ALL_TARGETS ${_targets} PARENT_SCOPE)
    set(MexIFace_MATLAB_INCLUDE_DIRS ${_include_dirs} PARENT_SCOPE)
    set(MexIFace_MATLAB_LIBRARY_DIRS ${_lib_dirs} PARENT_SCOPE)
    set(MexIFace_MATLAB_EXTERN_LIBRARY_DIRS ${_extern_lib_dirs} PARENT_SCOPE)
    set(MexIFace_MATLAB_MEXAPI_VERSION_SOURCES ${_mexapi_version_sources} PARENT_SCOPE)
    if(UNIX)
        set(MexIFace_MATLAB_LINKER_MAP_FILES ${_linker_map_files} PARENT_SCOPE)
    endif()
endfunction()

if(WIN32)
    set(MexIFace_MATLAB_SYSTEM_MEXEXT mexw64)
    set(MexIFace_MATLAB_SYSTEM_ARCH win64)
elseif(UNIX)
    set(MexIFace_MATLAB_SYSTEM_MEXEXT mexa64)
    set(MexIFace_MATLAB_SYSTEM_ARCH glnxa64)
elseif(APPLE)
    set(MexIFace_MATLAB_SYSTEM_MEXEXT mexmaci64)
    set(MexIFace_MATLAB_SYSTEM_ARCH maci64)
endif()
string(TOUPPER ${MexIFace_MATLAB_SYSTEM_ARCH} MexIFace_MATLAB_SYSTEM_ARCH_UP)

message(STATUS "[MexIFace::Matlab] MexIFace_MATLAB_SYSTEM_MEXEXT: ${MexIFace_MATLAB_SYSTEM_MEXEXT}")
message(STATUS "[MexIFace::Matlab] MexIFace_MATLAB_SYSTEM_ARCH: ${MexIFace_MATLAB_SYSTEM_ARCH}")
message(STATUS "[MexIFace::Matlab] MexIFace_SYSTEM_LIBSTDCXX_VERSION: ${MexIFace_SYSTEM_LIBSTDCXX_VERSION}")

#Find MATLAB_ROOT environment variable
#  If cross_compiling we'll look for MATLAB_ROOT_W64 or MATLAB_ROOT_MACI64
if(NOT MATLAB_ROOTS)
    set(MATLAB_ROOTS)
endif()
if(MATLAB_ROOT)
    list(INSERT MATLAB_ROOTS 0 ${MATLAB_ROOT})
endif()
if(NOT MATLAB_ROOTS) #Look in environment VARIABLES
    if(NOT WIN32)
        set(ENV_MATLAB_ROOT "$ENV{MATLAB_ROOT}")
        if(ENV_MATLAB_ROOT)
            list(APPEND MATLAB_ROOTS ${ENV_MATLAB_ROOT})
        endif()
        set(ENV_MATLAB_ROOTS "$ENV{MATLAB_ROOTS}")
        message(STATUS "ENV_MATLAB_ROOT:${ENV_MATLAB_ROOT} MATLAB_ROOTS:${MATLAB_ROOTS}")
        if(ENV_MATLAB_ROOTS)
            list(APPEND MATLAB_ROOTS ${ENV_MATLAB_ROOTS})
        endif()
        message(STATUS "ENV_MATLAB_ROOTS:${ENV_MATLAB_ROOTS} MATLAB_ROOTS:${MATLAB_ROOTS}")
    endif()
    #Check for arch-specific environment variables
    set(ENV_MATLAB_ROOT_ARCH "$ENV{MATLAB_ROOT_${MexIFace_MATLAB_SYSTEM_ARCH_UP}}")
    set(ENV_MATLAB_ROOTS_ARCH "$ENV{MATLAB_ROOTS_${MexIFace_MATLAB_SYSTEM_ARCH_UP}}")
    if(ENV_MATLAB_ROOT_ARCH)
        list(APPEND MATLAB_ROOTS ${ENV_MATLAB_ROOT_ARCH})
    endif()
    message(STATUS "ENV_MATLAB_ROOT_ARCH:${ENV_MATLAB_ROOT_ARCH} MATLAB_ROOTS:${MATLAB_ROOTS}")
    if(ENV_MATLAB_ROOTS_ARCH)
        list(APPEND MATLAB_ROOTS ${ENV_MATLAB_ROOTS_ARCH})
    endif()
    message(STATUS "ENV_MATLAB_ROOTS_ARCH:${ENV_MATLAB_ROOTS_ARCH} MATLAB_ROOTS:${MATLAB_ROOTS}")
endif()
if(NOT MATLAB_ROOTS)
    message(FATAL_ERROR "[MexIFace::Matlab] Found no matlab roots.  Set MATLAB_ROOT or MATLAB_ROOTS in CMake Cache or in environment variables.")
endif()

#Only look for new compatable matlab versions if we have not already found valid roots or
# MATLAB_ROOTS has changed since the last time we did the search
if(MATLAB_ROOT)
    set(MATLAB_ROOT CACHE PATH "Primary matlab root to search.")
endif()
message(STATUS "[MexIFace::Matlab] MATLAB_ROOTS:'${MATLAB_ROOTS}")
message(STATUS "[MexIFace::Matlab] MexIFace_MATLAB_FOUND:${MexIFace_MATLAB_FOUND}")
if(NOT MexIFace_MATLAB_FOUND OR NOT MexIFace_MATLAB_SEARCH_ROOTS OR NOT MATLAB_ROOTS STREQUAL MexIFace_MATLAB_SEARCH_ROOTS)
    message(STATUS "[MexIFace::Matlab] Finding matlab using new roots: ${MATLAB_ROOTS}")
    set(MexIFace_MATLAB_SEARCH_ROOTS ${MATLAB_ROOTS})
    _mexiface_get_matlab_roots("${MATLAB_ROOTS}")
    if(MATLAB_ROOTS)
        set(MexIFace_MATLAB_FOUND True)
    else()
        set(MexIFace_MATLAB_FOUND False)
    endif()
    set(MexIFace_MATLAB_SEARCH_ROOTS ${MexIFace_MATLAB_SEARCH_ROOTS} CACHE INTERNAL "Original set of roots searched when looking for Matlab instances")
    set(MexIFace_MATLAB_FOUND ${MexIFace_MATLAB_FOUND} CACHE BOOL "Found one or more valid MATLAB_ROOTS for use with MexIFace" FORCE)
    set(MexIFace_MATLAB_ROOTS ${MexIFace_MATLAB_ROOTS} CACHE INTERNAL "Valid matlab roots")
    set(MexIFace_MATLAB_VERSIONS ${MexIFace_MATLAB_VERSIONS} CACHE INTERNAL "Valid matlab versions as X.Y")
    set(MexIFace_MATLAB_VERSION_STRINGS ${MexIFace_MATLAB_VERSION_STRINGS} CACHE INTERNAL "Valid matlab versions as X_Y")
    set(MexIFace_MATLAB_RELEASES ${MexIFace_MATLAB_RELEASES} CACHE INTERNAL "Valid matlab releases")
    set(MexIFace_MATLAB_LIBSTDCXX_VERSIONS ${MexIFace_MATLAB_LIBSTDCXX_VERSIONS} CACHE INTERNAL "Valid matlab libstdc++.so versions")
    set(MexIFace_MATLAB_INCOMPATABLE_ROOTS ${MexIFace_MATLAB_INCOMPATABLE_ROOTS} CACHE INTERNAL "Invalid matlab roots")
    set(MexIFace_MATLAB_INCOMPATABLE_VERSIONS ${MexIFace_MATLAB_INCOMPATABLE_VERSIONS} CACHE INTERNAL "Invalid matlab versions as X.Y")
    set(MexIFace_MATLAB_INCOMPATABLE_VERSION_STRINGS ${MexIFace_MATLAB_INCOMPATABLE_VERSION_STRINGS} CACHE INTERNAL "Invalid matlab versions as X_Y")
    set(MexIFace_MATLAB_INCOMPATABLE_RELEASES ${MexIFace_MATLAB_INCOMPATABLE_RELEASES} CACHE INTERNAL "Invalid matlab releases")
    set(MexIFace_MATLAB_INCOMPATABLE_LIBSTDCXX_VERSIONS ${MexIFace_MATLAB_INCOMPATABLE_LIBSTDCXX_VERSIONS} CACHE INTERNAL "Invalid matlab libstdc++.so versions")
    set(MexIFace_MATLAB_INCOMPATABLE_REASONS ${MexIFace_MATLAB_INCOMPATABLE_REASONS} CACHE INTERNAL "Invalid matlab releasons for invalidity")
    mark_as_advanced(MexIFace_MATLAB_ROOTS MexIFace_MATLAB_VERSIONS MexIFace_MATLAB_VERSION_STRINGS MexIFace_MATLAB_RELEASES MexIFace_MATLAB_LIBSTDCXX_VERSIONS
                     MexIFace_MATLAB_INCOMPATABLE_ROOTS MexIFace_MATLAB_INCOMPATABLE_VERSIONS MexIFace_MATLAB_INCOMPATABLE_VERSION_STRINGS MexIFace_MATLAB_INCOMPATABLE_RELEASES
                     MexIFace_MATLAB_INCOMPATABLE_LIBSTDCXX_VERSIONS MexIFace_MATLAB_INCOMPATABLE_REASONS)
endif()

message(STATUS "[MexIFace::Matlab] MexIFace_MATLAB_ROOTS:${MexIFace_MATLAB_ROOTS}")
message(STATUS "[MexIFace::Matlab] MexIFace_MATLAB_VERSIONS:${MexIFace_MATLAB_VERSIONS}")
message(STATUS "[MexIFace::Matlab] MexIFace_MATLAB_VERSION_STRINGS:${MexIFace_MATLAB_VERSION_STRINGS}")
message(STATUS "[MexIFace::Matlab] MexIFace_MATLAB_RELEASES:${MexIFace_MATLAB_RELEASES}")
message(STATUS "[MexIFace::Matlab] MexIFace_MATLAB_LIBSTDCXX_VERSIONS:${MexIFace_MATLAB_LIBSTDCXX_VERSIONS}")
message(STATUS "[MexIFace::Matlab] MexIFace_MATLAB_INCOMPATABLE_ROOTS:${MexIFace_MATLAB_INCOMPATABLE_ROOTS}")
message(STATUS "[MexIFace::Matlab] MexIFace_MATLAB_INCOMPATABLE_VERSIONS:${MexIFace_MATLAB_INCOMPATABLE_VERSIONS}")
message(STATUS "[MexIFace::Matlab] MexIFace_MATLAB_INCOMPATABLE_RELEASES:${MexIFace_MATLAB_INCOMPATABLE_RELEASES}")
message(STATUS "[MexIFace::Matlab] MexIFace_MATLAB_INCOMPATABLE_ARCHS:${MexIFace_MATLAB_INCOMPATABLE_ARCHS}")
message(STATUS "[MexIFace::Matlab] MexIFace_MATLAB_INCOMPATABLE_LIBSTDCXX_VERSIONS:${MexIFace_MATLAB_INCOMPATABLE_LIBSTDCXX_VERSIONS}")
message(STATUS "[MexIFace::Matlab] MexIFace_MATLAB_INCOMPATABLE_REASONS:${MexIFace_MATLAB_INCOMPATABLE_REASONS}")


find_package(Pthread REQUIRED)
message(STATUS "[MexIFace::Matlab]  Found Pthread Libarary: ${PTHREAD_LIBRARY}")

_mexiface_make_matlab_targets()

message(STATUS "[MexIFace::Matlab] OPT_MexIFace_MATLAB_INTERLEAVED_COMPLEX:${OPT_MexIFace_MATLAB_INTERLEAVED_COMPLEX}")
message(STATUS "[MexIFace::Matlab] OPT_MexIFace_MATLAB_LARGE_ARRAY_DIMS:${OPT_MexIFace_MATLAB_LARGE_ARRAY_DIMS}")
message(STATUS "[MexIFace::Matlab] MexIFace_MATLAB_MEX_LIBRARIES_ALL_TARGETS:${MexIFace_MATLAB_MEX_LIBRARIES_ALL_TARGETS}")
message(STATUS "[MexIFace::Matlab] MexIFace_MATLAB_INCLUDE_DIRS:${MexIFace_MATLAB_INCLUDE_DIRS}")
message(STATUS "[MexIFace::Matlab] MexIFace_MATLAB_LIBRARY_DIRS:${MexIFace_MATLAB_LIBRARY_DIRS}")
message(STATUS "[MexIFace::Matlab] MexIFace_MATLAB_EXTERN_LIBRARY_DIRS:${MexIFace_MATLAB_EXTERN_LIBRARY_DIRS}")
message(STATUS "[MexIFace::Matlab] MexIFace_MATLAB_MEXAPI_VERSION_SOURCES:${MexIFace_MATLAB_MEXAPI_VERSION_SOURCES}")
message(STATUS "[MexIFace::Matlab] MexIFace_MATLAB_LINKER_MAP_FILES:${MexIFace_MATLAB_LINKER_MAP_FILES}")


set(_Print_Properties TYPE IMPORTED_CONFIGURATIONS INTERFACE_INCLUDE_DIRECTORIES INTERFACE_LINK_LIBRARIES INTERFACE_LINK_DIRECTORIES INTERFACE_COMPILE_FEATURES)
foreach(target IN LISTS MexIFace_MATLAB_MEX_LIBRARIES_ALL_TARGETS)
    foreach(prop IN LISTS _Print_Properties)
        get_target_property(v ${target} ${prop})
        if(v)
            message(STATUS "[MexIFace::Matlab] [${target}] ${prop}: ${v}")
        endif()
    endforeach()
endforeach()
unset(_Print_Properties)

if(NOT MexIFace_MATLAB_ROOTS)
    if(MexIFace_MATLAB_INCOMPATABLE_VERSIONS)
        message(FATAL_ERROR "[Mexiface]: No compatable MATLAB_ROOTS found.  Incompatable MATLAB versions:${MexIFace_MATLAB_INCOMPATABLE_VERSIONS} incompatable reasons:${MexIFace_MATLAB_INCOMPATABLE_REASONS}")
    else()
        message(FATAL_ERROR "[Mexiface]: No valid MATLAB_ROOTS.  Set MATLAB_ROOT or MATLAB_ROOTS as a CMake variable or environment variable to a valid matlab install directory(s).")
    endif()
endif()
