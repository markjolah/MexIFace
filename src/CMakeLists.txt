# MexIFace: src/CMakeLists.txt

## Source Files ##
set(MexIFace_SRCS MexIFace.cpp MexUtils.cpp explore.cpp)
## Include Files ##
file(GLOB MexIFace_HEADERS *.h)

## Iface Core Object library. ##
set(MexIFace_LIB MexIFace)
add_library( ${MexIFace_LIB} SHARED ${MexIFace_SRCS})
message(STATUS "BacktraceException_LIBRARIES=${BacktraceException_LIBRARIES}")
message(STATUS "BacktraceException_STATIC_LIBRARIES=${BacktraceException_STATIC_LIBRARIES}")
message(STATUS "BacktraceException_SHARED_LIBRARIES=${BacktraceException_SHARED_LIBRARIES}")
target_link_libraries(${MexIFace_LIB} PUBLIC ${BacktraceException_LIBRARIES}) #Exception backtraces
# target_link_libraries(${MexIFace_LIB} PUBLIC ${LAPACK_LINKER_FLAGS} ${BLAS_LINKER_FLAGS} ${LAPACK_LIBRARIES} ${BLAS_LIBRARIES}) #BLAS + LAPACK
# target_link_libraries(${MexIFace_LIB} PUBLIC OpenMP::OpenMP_CXX)
# target_link_libraries(${MexIFace_LIB} PUBLIC ${PTHREAD_LIBRARY})
target_link_libraries(${MexIFace_LIB} PUBLIC ${MATLAB_LIBRARIES}) #Matlab Mex libraries
target_include_directories(${MexIFace_LIB} PUBLIC $<BUILD_INTERFACE:${MATLAB_INCLUDE}>) #Matlab headers required
target_include_directories(${MexIFace_LIB} PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}> $<INSTALL_INTERFACE:include/${PROJECT_NAME}>) #MexIFace public includes
set_target_properties(${MexIFace_LIB} PROPERTIES PUBLIC_HEADER "${MexIFace_HEADERS}")
target_compile_features(${MexIFace_LIB} PUBLIC cxx_std_11) #Declare C++11 required for building

set_property(GLOBAL APPEND PROPERTY FIXUP_LIBRARY_TARGETS ${MexIFace_LIB})

install(TARGETS ${MexIFace_LIB} EXPORT ${EXPORT_TARGETS_NAME}
    RUNTIME DESTINATION lib COMPONENT Runtime
    ARCHIVE DESTINATION lib COMPONENT Development
    LIBRARY DESTINATION lib COMPONENT Runtime
    PUBLIC_HEADER DESTINATION include/${PROJECT_NAME} COMPONENT Development)
#Install Cmake modules and helper files for development
install(DIRECTORY ${MexIFace_CMAKE_DIR}/
        DESTINATION ${SHARED_CMAKE_INSTALL_DIR} COMPONENT Development)
