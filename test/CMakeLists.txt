# Tracker CMakeLists.txt
# Mark J. Olah [mjo@cs.unm DOT edu] 2018
include(mexiface_make_mex)
file(GLOB SRCS *.cpp)

find_package(OpenMP)
foreach(src IN LISTS SRCS)
        get_filename_component(target ${src} NAME_WE)
        message("Target: ${target}")
        mexiface_make_mex(MEXNAME ${target} SOURCES ${src} LINK_LIBRARIES OpenMP::OpenMP_CXX)
endforeach()
