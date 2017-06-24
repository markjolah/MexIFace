#TRNG
if(WIN32)
    find_library(TRNG_LIBRARY libtrng4-0.dll)
else()
    find_library(TRNG_LIBRARY libtrng4.so)
endif()
