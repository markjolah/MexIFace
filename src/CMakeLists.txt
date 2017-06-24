# MexIFace: src/
# Copyright 2013-2017 
# Author: Mark J. Olah
# Email: (mjo@cs.unm DOT edu)

## Source Files ##
set(MexIFace_SRCS MexIFace.cpp MexUtils.cpp explore.cpp)
## Include Files ##
set(MexIFace_HEADERS MexIFace.h MexUtils.h hypercube.h Handle.h explore.h)

## Iface Core Object library. ##
set(MexIFace_LIB MexIFace)
add_library( ${MexIFace_LIB} SHARED ${MexIFace_SRCS} )
target_include_directories(${MexIFace_LIB} PUBLIC ${MATLAB_INCLUDE})
set_target_properties(${MexIFace_LIB} PROPERTIES PUBLIC_HEADER "${MexIFace_HEADERS}")

target_link_libraries( MexIFace ${LAPACK_LINKER_FLAGS} ${LAPACK_LIBRARIES})
target_link_libraries( MexIFace ${BLAS_LINKER_FLAGS} ${BLAS_LIBRARIES})
target_link_libraries( MexIFace ${OPENMP_LIBRARY})
target_link_libraries( MexIFace ${PTHREAD_LIBRARY})
target_link_libraries( MexIFace "${MATLAB_LIBRARIES}")

#Install libraries and headers
install(TARGETS ${MexIFace_LIB}
        EXPORT ${EXPORT_TARGETS_NAME}
        LIBRARY DESTINATION lib COMPONENT Runtime
        PUBLIC_HEADER DESTINATION include/${PROJECT_NAME} COMPONENT Development)
#Install Cmake modules and helper files for development
install(DIRECTORY ${MexIFace_CMAKE_DIR}/
        DESTINATION ${SHARED_CMAKE_INSTALL_DIR} COMPONENT Development)
