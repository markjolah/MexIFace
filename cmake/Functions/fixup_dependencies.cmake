# fixup_dependencies.cmake
#
# Mark J. Olah (mjo@cs.unm DOT edu)
# Copyright 2014-2017
# Licensed under the Apache License, Version 2.0
# https://www.apache.org/licenses/LICENSE-2.0
# See: LICENCE file
#
# Variable Dependencies:
# FIXUP_LIB_SEARCH_PATH - Search path for libraries on the target system

function(fixup_dependencies target)
    if(NOT TARGET ${target})
        message(FATAL_ERROR "fixup_dependencies works on cmake targets.  Got target=${target}")
    endif()
    cmake_parse_arguments(FIXUP "" "TARGET_DESTINATION;COPY_DESTINATION" "RPATH" ${ARGN})
    if(NOT FIXUP_TARGET_DESTINATION)
        set(FIXUP_TARGET_DESTINATION 0) #Signal to use find_file in FixupTarget script
    endif()
    if(NOT FIXUP_COPY_DESTINATION)
        set(FIXUP_COPY_DESTINATION ".")  #Must be relative to TARGET_DESTINATION
    endif()
    set(FIXUP_RPATH "." ${FIXUP_COPY_DESTINATION} ${FIXUP_RPATH})
    list(REMOVE_DUPLICATES FIXUP_RPATH)
    set(FIXUP_SCRIPT ${CMAKE_BINARY_DIR}/Fixup-${target}.cmake)
    if(WIN32)
        set(TARGET_OS WIN64)
    elseif(UNIX AND NOT APPLE)
        set(TARGET_OS LINUX)
    else()
        set(TARGET_OS OSX)
    endif()
    
    configure_file(${MexIFace_CMAKE_TEMPLATES_DIR}/FixupTarget.cmake.in ${FIXUP_SCRIPT}.gen @ONLY)
    file(GENERATE OUTPUT ${FIXUP_SCRIPT} INPUT ${FIXUP_SCRIPT}.gen )
    install (SCRIPT ${FIXUP_SCRIPT})
endfunction()
