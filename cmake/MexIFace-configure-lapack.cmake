# MexIFace CMake build system
# Mark J. Olah (mjo@cs.unm DOT edu)
# 03-2014
# Include this file to configure LAPACK integration with armadillo
if(WIN32)
    #These compiled libraries are provided by armadillo
    find_library(LAPACK_LIBRARIES liblapack.dll libblas.dll libquadmath-0.dll)
    set(W64_DLLS ${W64_DLLS} liblapack.dll libblas.dll libquadmath-0.dll)
else()
    find_package(LAPACK)
endif()
