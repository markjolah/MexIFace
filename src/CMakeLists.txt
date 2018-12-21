# MexIFace: src/CMakeLists.txt

## Source Files ##
set(MexIFace_SRCS MexIFace.cpp MexUtils.cpp explore.cpp)
## MexIfaceCore Object library. ##
# add_library(MexIFaceCore OBJECT ${MexIFace_SRCS})

set(PUBLIC_HEADER_SRC_DIR ${CMAKE_SOURCE_DIR}/include)

#Create a per-matlab version MexIFaceX_Y library.
list(LENGTH MexIFace_MATLAB_ROOTS nroots)
math(EXPR niter "${nroots} - 1")
if(niter LESS 0)
    message(FATAL_ERROR "[Mexiface]: No valid MATLAB_ROOTS")
endif()
set(MexIFace_TARGETS)
foreach(idx RANGE ${niter})
    list(GET MexIFace_MATLAB_VERSIONS ${idx} ver)
    list(GET MexIFace_MATLAB_VERSION_STRINGS ${idx} vers)
    set(lib MexIFace${vers})
    set(matlab_target "MATLAB::${vers}::MEX_LIBRARIES")
    message(STATUS "lib:${lib} target:${matlab_target}")
    add_library(${lib} SHARED ${MexIFace_SRCS})
    #Add version file for R2018a+
    if(ver VERSION_GREATER_EQUAL "9.4")
        list(GET MexIFace_MATLAB_MEXAPI_VERSION_SOURCES ${idx} vers_src_file)
        target_sources(${lib} PRIVATE ${vers_src_file})
    endif()
    add_library(MexIFace::${lib} ALIAS ${lib})
    target_link_libraries(${lib} PUBLIC BacktraceException::BacktraceException) #Exception backtraces
    target_link_libraries(${lib} PUBLIC ${matlab_target}) #Matlab Mex libraries
    target_include_directories(${lib} PUBLIC $<BUILD_INTERFACE:${PUBLIC_HEADER_SRC_DIR}>
                                             $<INSTALL_INTERFACE:include>)
    target_compile_features(${lib} PUBLIC cxx_std_11) #Declare C++11 required for building

    install(TARGETS ${lib} EXPORT ${PROJECT_NAME}Targets
            RUNTIME DESTINATION lib COMPONENT Runtime
            ARCHIVE DESTINATION lib COMPONENT Development
            LIBRARY DESTINATION lib COMPONENT Runtime)
    list(APPEND MexIFace_TARGETS ${lib})
endforeach()

install(DIRECTORY ${PUBLIC_HEADER_SRC_DIR}/ DESTINATION include COMPONENT Development)

set(MexIFace_TARGETS ${MexIFace_TARGETS} PARENT_SCOPE)
