# MexIFace CMake build system
# Mark J. Olah (mjo@cs.unm DOT edu)
# 01-2018
#
# Toolchain for cross-compiling to a linux matlab9_3 (and earlier) compatable
# environment using gcc-4.9.4.  Using 
#
set(MATLAB9_3_ARCH x86_64-matlab9_3-linux-gnu)
#set(STAGING_PREFIX $ENV{MEXIFACE_STAGING_PREFIX})

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSROOT /usr/${MATLAB9_3_ARCH})
#set(CMAKE_STAGING_PREFIX ${STAGING_PREFIX})
set(CMAKE_C_COMPILER ${MATLAB9_3_ARCH}-gcc)
set(CMAKE_CXX_COMPILER ${MATLAB9_3_ARCH}-g++)

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
