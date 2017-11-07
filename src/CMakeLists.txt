# MexIFace: src/CMakeLists.txt

## Source Files ##
set(MexIFace_SRCS MexIFace.cpp MexIFaceError.cpp MexUtils.cpp explore.cpp)
## Include Files ##
set(MexIFace_HEADERS MexIFace.h MexUtils.h MexIFaceError.h hypercube.h Handle.h explore.h)

## Iface Core Object library. ##
set(MexIFace_LIB MexIFace)
add_library( ${MexIFace_LIB} SHARED ${MexIFace_SRCS})
target_link_libraries(${MexIFace_LIB} ${LAPACK_LINKER_FLAGS} ${BLAS_LINKER_FLAGS} ${LAPACK_LIBRARIES} ${BLAS_LIBRARIES}) #BLAS + LAPACK
target_link_libraries(${MexIFace_LIB} ${OPENMP_LIBRARY} ${PTHREAD_LIBRARY}) #System dependent OpenMP and Pthread libs
target_link_libraries(${MexIFace_LIB} "${MATLAB_LIBRARIES}") #Matlab Mex libraries
target_include_directories(${MexIFace_LIB} PUBLIC $<BUILD_INTERFACE:${MATLAB_INCLUDE}>) #Matlab headers required
target_include_directories(${MexIFace_LIB} PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}> $<INSTALL_INTERFACE:include/${PROJECT_NAME}>) #MexIFace public includes
set_target_properties(${MexIFace_LIB} PROPERTIES PUBLIC_HEADER "${MexIFace_HEADERS}")
# set_target_properties(${MexIFace_LIB} PROPERTIES OUTPUT_NAME MexIFace${CMAKE_DEBUG_POSTFIX})
set_property(GLOBAL APPEND PROPERTY FIXUP_LIBRARY_TARGETS ${MexIFace_LIB})
#Install libraries and headers
if(UNIX)
    install(TARGETS ${MexIFace_LIB} EXPORT ${EXPORT_TARGETS_NAME}
            LIBRARY DESTINATION lib COMPONENT Runtime
            PUBLIC_HEADER DESTINATION include/${PROJECT_NAME} COMPONENT Development)
elseif(WIN32)
    install(TARGETS ${MexIFace_LIB} EXPORT ${EXPORT_TARGETS_NAME}
        RUNTIME DESTINATION lib COMPONENT Runtime
        ARCHIVE DESTINATION lib COMPONENT Development
        PUBLIC_HEADER DESTINATION include/${PROJECT_NAME} COMPONENT Development)
endif()
#Install Cmake modules and helper files for development
install(DIRECTORY ${MexIFace_CMAKE_DIR}/
        DESTINATION ${SHARED_CMAKE_INSTALL_DIR} COMPONENT Development)
fixup_dependencies(${MexIFace_LIB})
