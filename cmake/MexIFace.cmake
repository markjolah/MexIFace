# MexIFace CMake build system
# Mark J. Olah (mjo@cs.unm DOT edu)
# 03-2014
#
#copyright Mark J. Olah and The Regents of the University of New Mexico (2014).
# This code is free for non-commercial use and modification, provided
# this copyright notice remains unmodified and attached to the code
#
# X-Platform .mex file generation
#
# MATLAB_ROOT - should be set in environment or earlier in build script

## Matlab Libraries and Directories ##

if(NOT MATLAB_ROOT)
    set(MATLAB_ROOT $ENV{MATLAB_ROOT})
endif()
if(WIN32)
    set(MEXEXT mexw64)
    set(MATLAB_ARCH win64)
    find_library(MATLAB_MEX_LIBRARY libmex.dll )
    find_library(MATLAB_MX_LIBRARY  libmx.dll )
    find_library(MATLAB_ENG_LIBRARY libeng.dll )
    find_library(MATLAB_MAT_LIBRARY libmat.dll )
    find_library(MATLAB_MWLAPACK_LIBRARY libmwlapack.dll )
    find_library(MATLAB_MWBLAS_LIBRARY libmwblas.dll )
elseif(UNIX)
    set(MEXEXT mexa64)
    set(MATLAB_ARCH glnxa64)
    set(MATLAB_LINK_MAPFILE ${MATLAB_ROOT}/extern/lib/${MATLAB_ARCH}/mexFunction.map)
    set(MATLAB_LIB ${MATLAB_ROOT}/bin/${MATLAB_ARCH})
    find_library(MATLAB_MEX_LIBRARY libmex.so PATHS ${MATLAB_LIB})
    find_library(MATLAB_MX_LIBRARY libmx.so PATHS ${MATLAB_LIB})
    find_library(MATLAB_ENG_LIBRARY libeng.so PATHS ${MATLAB_LIB})
    find_library(MATLAB_MAT_LIBRARY libmat.so PATHS ${MATLAB_LIB})
endif()

set(MATLAB_INCLUDE_DIR ${MATLAB_ROOT}/extern/include)
set(MEX_LINK_FLAGS "-Wl,-g" "-Wl,--no-undefined")
if (WIN32)
    set(MEX_LINK_FLAGS ${MEX_LINK_FLAGS} "-Wl,--export-all-symbols")
elseif(UNIX)
    set(MEX_LINK_FLAGS ${MEX_LINK_FLAGS} "-Wl,--version-script,${MATLAB_LINK_MAPFILE}")
endif()

include_directories( ${MATLAB_INCLUDE_DIR} )
include_directories( ${CMAKE_CURRENT_SOURCE_DIR}/../MexIface/src)
add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/../MexIface/src src/MexIFace)

## X-Platform Mex function Linking!##
function(make_mex mexfile)
    add_library( ${mexfile} SHARED ${mexfile}.cpp $<TARGET_OBJECTS:iface-core> )
#     target_link_libraries( ${mexfile} ${BLAS_LIBRARIES} ${LAPACK_LIBRARIES} )
    target_link_libraries( ${mexfile} ${MEX_LINK_FLAGS} )
    target_link_libraries( ${mexfile} ${MATLAB_MEX_LIBRARY} ${MATLAB_MX_LIBRARY} )
    target_link_libraries( ${mexfile} ${MATLAB_ENG_LIBRARY} ${MATLAB_MAT_LIBRARY} )
    target_link_libraries( ${mexfile} ${MATLAB_MWLAPACK_LIBRARY} ${MATLAB_MWBLAS_LIBRARY} )
    target_link_libraries( ${mexfile} ${PTHREAD_LIBRARY})
    set_property(TARGET ${mexfile} PROPERTY OUTPUT_NAME ${mexfile})
    set_property(TARGET ${mexfile} PROPERTY SUFFIX .${MEXEXT})
    set_property(TARGET ${mexfile} PROPERTY PREFIX "")
    set_property(TARGET ${mexfile} APPEND PROPERTY COMPILE_DEFINITIONS MATLAB_MEX_FILE)
    if(UNIX)
        install(TARGETS ${mexfile} LIBRARY DESTINATION mex/mex.glnxa64${DEBUG_FILE_EXT} COMPONENT Runtime)
    elseif(WIN32)
        install(TARGETS ${mexfile}
            RUNTIME DESTINATION .  COMPONENT Runtime
            LIBRARY DESTINATION .  COMPONENT Runtime)
    endif()
endfunction()
