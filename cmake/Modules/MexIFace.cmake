# MexIFace.cmake
#
# A Cross-Platform C++ / MEX Object-based interface wrapper and CMake build tool.
#
# This is the main module to enable the MexIFace support.  This should be inlcuded by target projects
#
#
# Copyright 2013-2017 
# Author: Mark J. Olah 
# Email: (mjo@cs.unm DOT edu)
# 

include(MexIFace-configure) #Configure libraries and compile flags
include(MexIFace-makemex) #Import the make_mex function


# Install RPATHS
if(UNIX)
    set(CMAKE_INSTALL_RPATH "\$ORIGIN/.:\$ORIGIN/../lib")
    set(CMAKE_INSTALL_RPATH_USE_LINK_PATH ON)
endif()
