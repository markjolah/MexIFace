# MexIFace CMake build system
# Mark J. Olah (mjo@cs.unm DOT edu)
# 03-2014
#
# W64 debug configuration
set(CMAKE_BUILD_TYPE Debug CACHE STRING "Build type (Debug|Release)" FORCE)
set(CMAKE_TOOLCHAIN_FILE ../../../cmake/Toolchain-w64.cmake CACHE FILEPATH "CrossCompile mingw64 Toolchain" FORCE)
set(CMAKE_INSTALL_PREFIX ../../../mex/mex.w64.debug CACHE FILEPATH "Install location" FORCE)
