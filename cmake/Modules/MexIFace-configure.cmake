# MexIFace CMake build system
# Mark J. Olah (mjo@cs.unm DOT edu)
# 03-2014
# Common Configuration for Project Libraries and Dependencies
# Configures armadillo and OpenMP for x-platform builds

## Find and Configure Required Libraries ##
message(STATUS "[MexIFace]: Configure Libraries")
# Armadillo
find_package(Armadillo REQUIRED)
add_definitions(-DARMA_USE_CXX11 -DARMA_DONT_USE_WRAPPER -DARMA_BLAS_LONG)
add_definitions(-DARMA_DONT_USE_OPENMP) #Want to explicitly use openMP when required
if(${CMAKE_BUILD_TYPE} MATCHES Debug)
    add_definitions(-DARMA_PRINT_ERRORS)
endif()
# Optionally enable extra debugging from armadillo to log every call.
if(MexIFace_EXTRA_DEBUG)
    add_definitions(-DARMA_EXTRA_DEBUG)
endif()

# OpenMP
find_package(OpenMP REQUIRED)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${OpenMP_CXX_FLAGS}")
if(WIN32)
    find_library(OPENMP_LIBRARY libgomp-1.dll REQUIRED)
endif()

# Pthreads
if (WIN32)
    find_library(PTHREAD_LIBRARY libwinpthread.dll REQUIRED)
elseif(UNIX)
    find_library(PTHREAD_LIBRARY libpthread.so REQUIRED)
endif()
message(STATUS "Found Pthread Libarary: ${PTHREAD_LIBRARY}")
# LAPACK & BLAS
find_package(LAPACK REQUIRED)
find_package(BLAS REQUIRED)

# Matlab
# User must set environment/cmake variable: MATLAB_ROOT
if(WIN32)
    set(MEX_EXT mexw64)
    set(MATLAB_ARCH w64)
elseif(UNIX)
    set(MEX_EXT mexa64)
    set(MATLAB_ARCH glnxa64)
elseif(APPLE)
    set(MEX_EXT mexi64)
    set(MATLAB_ARCH maci64)
endif()
message(STATUS "MATLAB arch: ${MATLAB_ARCH}")
message(STATUS "MATLAB MEX ext: ${MEX_EXT}")
#Find MATLAB_ROOT environment variable
#If cross_compiling we'll look for MATLAB_ROOT_W64 or MATLAB_ROOT_MACI64
if(NOT MATLAB_ROOT)
    string(TOUPPER ${MATLAB_ARCH} MATLAB_ARCH_UP)
    set(MATLAB_ROOT $ENV{MATLAB_ROOT_${MATLAB_ARCH_UP}})
    if(NOT MATLAB_ROOT)
        set(MATLAB_ROOT $ENV{MATLAB_ROOT})
    endif()
endif()
message(STATUS "MATLAB root: ${MATLAB_ROOT}")
if(NOT MATLAB_ROOT)
    message(FATAL_ERROR "Set MATLAB_ROOT to the root of a matlab directory for this arch")
endif()

set(MATLAB_LIB_DIR ${MATLAB_ROOT}/bin/${MATLAB_ARCH})
message(STATUS "MATLAB lib dir: ${MATLAB_LIB_DIR}")
find_library(MATLAB_MWLAPACK_LIBRARY mwlapack PATHS ${MATLAB_LIB_DIR})
find_library(MATLAB_MWBLAS_LIBRARY mwblas PATHS ${MATLAB_LIB_DIR})
find_library(MATLAB_MEX_LIBRARY mex PATHS ${MATLAB_LIB_DIR})
find_library(MATLAB_MX_LIBRARY mx PATHS ${MATLAB_LIB_DIR})
find_library(MATLAB_ENG_LIBRARY eng PATHS ${MATLAB_LIB_DIR})
find_library(MATLAB_MAT_LIBRARY mat PATHS ${MATLAB_LIB_DIR})
set(MATLAB_LIBRARIES ${MATLAB_MWLAPACK_LIBRARY} ${MATLAB_MWBLAS_LIBRARY} ${MATLAB_MEX_LIBRARY} ${MATLAB_MX_LIBRARY} ${MATLAB_ENG_LIBRARY} ${MATLAB_MAT_LIBRARY})
#set(MATLAB_LIBRARIES ${MATLAB_MEX_LIBRARY} ${MATLAB_MX_LIBRARY} ${MATLAB_ENG_LIBRARY} ${MATLAB_MAT_LIBRARY})
set(MATLAB_INCLUDE ${MATLAB_ROOT}/extern/include ) #Matlab include dir
if(UNIX)
    set(MATLAB_LINK_MAPFILE ${MATLAB_ROOT}/extern/lib/${MATLAB_ARCH}/mexFunction.map)
endif()

# Compiler Definitions
if (WIN32)
    add_definitions( -DWIN32 )
endif()

## CFLAGS ##
set(GCC_WARN_FLAGS "-W -Wall -Wextra -Werror -Wno-unused-parameter")
set(GCC_STD_FLAGS "-std=c++11")
set(GCC_ARCH_FLAGS "-mtune=native")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${GCC_WARN_FLAGS} ${GCC_STD_FLAGS} ${GCC_ARCH_FLAGS}")

#Debug compiler options
set(CMAKE_DEBUG_POSTFIX ".debug" CACHE STRING "Debug file extension")
set(CMAKE_CXX_FLAGS_DEBUG "-g -O -Wfatal-errors")
#Release compiler options
set(CMAKE_CXX_FLAGS_RELEASE "-O3 -DARMA_NO_DEBUG -DNDEBUG")
#Detect if we are a debug build at configure time which is cannot be done with a gererator expression
if(${CMAKE_BUILD_TYPE} MATCHES Debug)
    set(MexIFace_DEBUG_POSTFIX ${CMAKE_DEBUG_POSTFIX})
else()
    set(MexIFace_DEBUG_POSTFIX "")
endif()
message(STATUS "[MexIFace] DebugPostfix: ${MexIFace_DEBUG_POSTFIX}")



