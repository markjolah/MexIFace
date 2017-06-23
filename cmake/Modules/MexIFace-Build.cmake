# MexIFace CMake build system
# Mark J. Olah (mjo@cs.unm DOT edu)
# 03-2014
# Core build script


#Create the C++ library
add_library( ${LIB_TARGET} SHARED ${LIB_SRCS})

#Create and link the test executable if provided
if(TEST_TARGET)
    add_executable( ${TEST_TARGET} ${TEST_SRCS} )
    target_link_libraries(${TEST_TARGET} ${LIB_TARGET})
    if(UNIX)
        set(FIXUP_BINARY ${TEST_TARGET} CACHE STRING "Binary to fixup")
    endif()
endif()

#Link OpenMP
if(WIN32)
    target_link_libraries(${LIB_TARGET} ${LIBGOMP_LIBRARY})
endif()

#Link Blas & Lapack
if(LAPACK_LIBRARIES)
    #BLAS + LAPACK linking
    target_link_libraries(${LIB_TARGET} ${BLAS_LIBRARIES} ${LAPACK_LIBRARIES} ${BLAS_LIBRARIES})
elseif(BLAS_LIBRARIES)
    #Just BLAS linking
    target_link_libraries(${LIB_TARGET} ${BLAS_LIBRARIES})
endif()

#Create IFace target
foreach(target  ${IFACE_TARGET})
    Make_mex( ${target} )
    target_link_libraries( ${target}  ${LIB_TARGET})
endforeach()

#Install
if(UNIX)
    install(TARGETS  ${LIB_TARGET}  ${TEST_TARGET}
            RUNTIME DESTINATION bin COMPONENT Runtime
            LIBRARY DESTINATION lib COMPONENT Runtime)

elseif(WIN32)
    # This prevents installation of the .dll.a files which are part of the ARCHIVE set
    install(TARGETS ${LIB_TARGET}
            RUNTIME DESTINATION .  COMPONENT Runtime
            LIBRARY DESTINATION .  COMPONENT Runtime)
endif()

set(FIXUP_LIBRARY ${LIB_TARGET} CACHE STRING "Library to fixup")

include(${LOCAL_CMAKE_DIR}/MexIFace-FixupBundle.cmake)
