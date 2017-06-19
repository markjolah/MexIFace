# MexIFace CMake build system
# Mark J. Olah (mjo@cs.unm DOT edu)
# 03-2014
# Common Configuration for Project Libraries and Dependencies
# Configures armadillo and OpenMP for x-platform builds

#Armadillo
find_package(Armadillo)
add_definitions(-DARMA_USE_CXX11 -DARMA_DONT_USE_WRAPPER -DARMA_32BIT_WORD)

if(WIN32)
    #Libraries to copy into lib directory for W64
    set(W64_DLLS ${W64_DLLS} libstdc++-6.dll libgcc_s_seh-1.dll libgfortran-3.dll)
endif()

#OpenMP
if(WIN32)
    find_library(LIBGOMP_LIBRARY libgomp-1.dll ${MXE_ROOT}/usr/bin)
    set(W64_DLLS ${W64_DLLS} libgomp-1.dll)
endif()

## Pthread Libraries ##
if (WIN32)
    find_library(PTHREAD_LIBRARY libwinpthread.dll)
    set(W64_DLLS ${W64_DLLS} libwinpthread-1.dll)
else()
    find_library(PTHREAD_LIBRARY libpthread.so)
endif()

# Compiler Definitions
if (WIN32)
    add_definitions( -DWIN32 )
endif()

## CFLAGS ##
set(GCC_WARN_FLAGS "-W -Wall -Wextra -Werror -Wno-unused-parameter")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${GCC_WARN_FLAGS} -std=c++11 -mtune=native -fopenmp")
if (UNIX)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fPIC")
    #This is necessary because on linux matlab changes the library path so that a mex file will look
    #for the libstdc++.so in the matlab directory istead of the included one that the file is actually linked
    #against.  This does not appear to be a problem on windows.
    # Not sure if this is working or not.  Now I just match GCC to the matlab GCC recommended
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -static-libstdc++")
endif()

#Debug compiler options
set(CMAKE_CXX_FLAGS_DEBUG "-g -O")
#Release compiler options
set(CMAKE_CXX_FLAGS_RELEASE "-O3 -DARMA_NO_DEBUG -DNDEBUG")

#Link directories
if(UNIX)
    set(CMAKE_INSTALL_RPATH "\$ORIGIN/.:\$ORIGIN/../lib:\$ORIGIN/../../lib")
    set(CMAKE_INSTALL_RPATH_USE_LINK_PATH ON)
endif()


