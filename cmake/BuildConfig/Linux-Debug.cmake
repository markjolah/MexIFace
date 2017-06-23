# MexIFace CMake build system
# Mark J. Olah (mjo@cs.unm DOT edu)
# 03-2014
#
# Linux debug configuration

set(CMAKE_BUILD_TYPE Debug CACHE STRING "Build type (Debug|Release)" FORCE)
set(CMAKE_CXX_COMPILER /usr/bin/g++-4.9.4 CACHE STRING "C++ compiler" FORCE) #This is the latest version used by MATLAB 2015a
set(CMAKE_INSTALL_PREFIX ./install CACHE FILEPATH "Install location" FORCE)
