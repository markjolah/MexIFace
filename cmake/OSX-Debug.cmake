# MexIFace CMake build system
# Mark J. Olah (mjo@cs.unm DOT edu)
# 06-2017
#
# OSX debug configuration

set(CMAKE_BUILD_TYPE Debug CACHE STRING "Build type (Debug|Release)" FORCE)
set(DEBUG_FILE_EXT ".debug" CACHE STRING "Directory extension for debug or release" FORCE)
set(CMAKE_TOOLCHAIN_FILE ../../../cmake/Toolchain-OSX.cmake CACHE FILEPATH "CrossCompile OSX Toolchain" FORCE)
set(CMAKE_INSTALL_PREFIX ../../../mex/mex.osx.debug CACHE FILEPATH "Install location" FORCE)
