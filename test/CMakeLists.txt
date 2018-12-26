# Tracker CMakeLists.txt
# Mark J. Olah [mjo@cs.unm DOT edu] 2018

file(GLOB SRCS *.cpp)

foreach(src IN LISTS SRCS)
        get_filename_component(target ${src} NAME_WE)
        message(STATUS "MakingMex: ${target}")
        mexiface_make_mex(MEXNAME ${target} SOURCES ${src})
endforeach()
