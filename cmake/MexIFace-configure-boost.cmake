#Boost
set(Boost_USE_MULTITHREADED ON)
set(Boost_USE_STATIC_LIBS OFF)
if(WIN32)
    find_library(Boost_THREAD_LIBRARY_RELEASE libboost_thread_win32-mt.dll )
    set(W64_DLLS ${W64_DLLS} libboost_thread_win32-mt.dll libboost_system-mt.dll libboost_chrono-mt.dll)
endif()
find_package(Boost REQUIRED COMPONENTS system chrono thread)
add_definitions( -DBOOST_THREAD_USE_LIB )
