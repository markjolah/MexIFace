#TRNG
if(WIN32)
    find_library(TRNG_LIBRARY libtrng4-0.dll)
    set(W64_DLLS ${W64_DLLS} libtrng4-0.dll)
else()
    find_library(TRNG_LIBRARY libtrng4.so)
endif()
