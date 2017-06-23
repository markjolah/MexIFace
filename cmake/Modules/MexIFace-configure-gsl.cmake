#TRNG
if(WIN32)
    find_library(GSL_LIBRARY libgsl-0.dll)
    set(W64_DLLS ${W64_DLLS} libgsl-0.dll)
else()
    find_library(GSL_LIBRARY libgsl.so)
endif()
