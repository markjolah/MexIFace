# MexIFace: src/CMakeLists.txt

## Source Files ##
set(MexIFace_SRCS MexIFace.cpp MexUtils.cpp explore.cpp)
## MexIfaceCore Object library. ##
add_library(MexIFaceCore OBJECT ${MexIFace_SRCs})

set(PUBLIC_HEADER_DIR ${CMAKE_SOURCE_DIR}/include)

#Create a per-matlab version MexIFaceX_Y library.
foreach(vers in ${MATLAB_VERSION_STRINGS})
    set(lib MexIFace${vers})
    add_library(${lib} SHARED $<TARGET_OBJECTS:MexIFaceCore>)
    add_library(MexIFace::${lib} ALIAS ${lib})
    target_link_libraries(${lib} PUBLIC BacktraceException::BacktraceException) #Exception backtraces
    target_link_libraries(${lib} PUBLIC "MATLAB::${vers}::MEX_LIBRARIES") #Matlab Mex libraries
    target_include_directories(${lib} PUBLIC $<BUILD_INTERFACE:${PUBLIC_HEADER_DIR}>
                                             $<INSTALL_INTERFACE:include>)
    target_compile_features(${lib} PUBLIC cxx_std_11) #Declare C++11 required for building

    install(TARGETS ${lib} EXPORT ${PROJECT_NAME}Targets
            RUNTIME DESTINATION lib COMPONENT Runtime
            ARCHIVE DESTINATION lib COMPONENT Development
            LIBRARY DESTINATION lib COMPONENT Runtime)
endforeach()

install(DIRECTORY ${PUBLIC_HEADER_SRC_DIR}/ DESTINATION include COMPONENT Development)
