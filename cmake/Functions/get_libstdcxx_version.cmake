# get_libstdcxx_version.cmake
#
# Mark J. Olah (mjo@cs.unm DOT edu)
# Copyright 2018
# see file: LICENCE
#
# If CMAKE_CXX_COMPILER_ID = GCC gets version of libstdc++.so that will be linked
#
#
# out_var: return variable name
#
#One Value Args:
# COMPILER_ID: [default: ${CMAKE_CXX_COMPILER_ID}]
# COMPILER_VERSION: [default: ${CMAKE_CXX_COMPILER_VERSION}]
#Many Value Args:
# ADDITIONAL_LIBSTDCXX_MAPPINGS: Additional mapping strings e.g. "7.3=6.0.24" "8.=6.0.25"

function(get_libstdcxx_version out_var)
    set(options)
    set(oneValueArgs COMPILER_ID COMPILER_VERSION)
    set(multiValueArgs ADDITIONAL_LIBSTDCXX_MAPPINGS)
    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}"  "${multiValueArgs}"  ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "Unknown keywords given to mexiface_install(): \"${ARG_UNPARSED_ARGUMENTS}\"")
    endif()

    if(NOT ARG_COMPILER_ID)
        set(ARG_COMPILER_ID  ${CMAKE_CXX_COMPILER_ID})
    endif()
    if(NOT ARG_COMPILER_ID STREQUAL GNU)
        set(${out_var} False PARENT_SCOPE)
        return()
    endif()
    if(NOT ARG_COMPILER_VERSION)
        set(ARG_COMPILER_VERSION  ${CMAKE_CXX_COMPILER_VERSION})
    endif()
    if(NOT ADDITIONAL_LIBSTDCXX_MAPPINGS)
        set(ADDITIONAL_LIBSTDCXX_MAPPINGS)
    endif()

    set(GCC_LIBSTDCXX_MAPPING
        "9.0=6.0.26"
        "8.2=6.0.25"
        "7.3=6.0.24"
        "7.2=6.0.24"
        "7.1=6.0.23"
        "6.5=6.0.22"
        "6.4=6.0.22"
        "6.3=6.0.22"
        "6.2=6.0.22"
        "6.1=6.0.22"
        "5.5=6.0.21"
        "5.4=6.0.21"
        "5.3=6.0.21"
        "5.2=6.0.21"
        "5.1=6.0.21"
        "4.9=6.0.20"
        "4.8=6.0.19"
        "4.7=6.0.17"
        ${ADDITIONAL_LIBSTDCXX_MAPPINGS}
        )

    string(REGEX MATCH "^([0-9]+)\\.([0-9]+)" comp_vers ${ARG_COMPILER_VERSION})
    if(GCC_LIBSTDCXX_MAPPING MATCHES "${CMAKE_MATCH_1}\\.${CMAKE_MATCH_2}=([0-9]+\\.[0-9]+\\.[0-9]+)")
        set(${out_var} ${CMAKE_MATCH_1} PARENT_SCOPE)
    else()
        set(${out_var} False PARENT_SCOPE)
    endif()
endfunction()
