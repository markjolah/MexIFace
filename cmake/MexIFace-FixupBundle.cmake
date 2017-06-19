# MexIFace CMake build system
# Mark J. Olah (mjo@cs.unm DOT edu)
# 03-2014
#
# Fixup Libraries is the CMake method of producing installable packages by listing all the
# dependencies of a library or executable and copying them into a specific directory.  This
# script combines with the FixBundle-*.cmake.in scripts to produce the effective fixup script
# for call on "make install" operation

#Create FixupBundle.cmake file
if(UNIX)
    configure_file(${LOCAL_CMAKE_DIR}/FixBundle-Linux.cmake.in ${CMAKE_BINARY_DIR}/FixBundle.cmake @ONLY)
elseif(WIN32)
    configure_file(${LOCAL_CMAKE_DIR}/FixBundle-W64.cmake.in ${CMAKE_BINARY_DIR}/FixBundle.cmake @ONLY)
endif()
#Register FixupBundle.cmake with installer
install (SCRIPT ${CMAKE_BINARY_DIR}/FixBundle.cmake)

