# MexIFace CMake build system
# Mark J. Olah (mjo@cs.unm DOT edu)
# 03-2014
#
# w64 debug configuration
set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type (Debug|Release)" FORCE)
set(DEBUG_FILE_EXT ""  CACHE STRING "Directory extension for debug or release" FORCE)
set(CMAKE_TOOLCHAIN_FILE ../../../cmake/Toolchain-w64.cmake CACHE FILEPATH "CrossCompile Toolchain" FORCE)
set(CMAKE_INSTALL_PREFIX ../../../mex/mex.w64 CACHE FILEPATH "Install location" FORCE)
