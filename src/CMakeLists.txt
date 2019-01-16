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
if(CMAKE_CROSSCOMPILING AND OPT_INSTALL_DEPENDENCIES) #Fixup before install as otherwise the toolchain install override will auto-call fixup-dependencies
    set(_fixup_args)
    if(OPT_LINK_INSTALLED_LIBS)
        list(APPEND _fixup_args LINK_INSTALLED_LIBS)
    endif()
    if(OPT_INSTALL_GCC_DEPENDENCIES)
        list(APPEND _fixup_args COPY_GCC_LIBS)
    endif()
    if(OPT_BUILD_TREE_EXPORT)
        list(APPEND _fixup_args BUILD_TREE_EXPORT)
    endif()
endif()
foreach(idx RANGE ${niter})
    list(GET MexIFace_MATLAB_VERSIONS ${idx} ver)
    list(GET MexIFace_MATLAB_VERSION_STRINGS ${idx} vers)
    list(GET MexIFace_MATLAB_LINKER_MAP_FILES ${idx} map_file)
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
    if(UNIX OR (CMAKE_CROSSCOMPILING AND WIN32))
        #Sets visibility of symbols to only mexFunction and related interface
        #Can't have this be an interface property of MATLAB::X_Y::MEX_LIBRARIES as it would cause MexIFace to not export symbols needed by clients.
#         target_link_options(${lib} INTERFACE -Wl,--version-script,${map_file})
    endif()
    target_link_options(${lib} PUBLIC "-Wl,--as-needed")
    target_link_libraries(${lib} PUBLIC BacktraceException::BacktraceException) #Exception backtraces
    target_link_libraries(${lib} PUBLIC ${matlab_target}) #Matlab Mex libraries
    target_include_directories(${lib} PUBLIC $<BUILD_INTERFACE:${PUBLIC_HEADER_SRC_DIR}>
                                             $<INSTALL_INTERFACE:include>)
    target_compile_features(${lib} PUBLIC cxx_std_11) #Declare C++11 required for building
    install(TARGETS ${lib} EXPORT ${PROJECT_NAME}Targets
            RUNTIME DESTINATION lib COMPONENT Runtime
            ARCHIVE DESTINATION lib COMPONENT Development
            LIBRARY DESTINATION lib COMPONENT Runtime)
    get_target_property(_build_rpath ${lib} BUILD_RPATH)

    if(CMAKE_CROSSCOMPILING AND OPT_INSTALL_DEPENDENCIES)
        get_target_property(_MATLAB_LIB_PATH MATLAB::${vers}::MEX_LIBRARIES INTERFACE_LINK_DIRECTORIES)
        fixup_dependencies(TARGETS ${lib} TARGET_DESTINATION lib PROVIDED_LIB_DIRS ${_MATLAB_LIB_PATH} ${_fixup_args})
    endif()

    list(APPEND MexIFace_TARGETS MexIFace::${lib})
#     if(CMAKE_CROSSCOMPILING)
#         get_target_property(_MATLAB_LIB_PATH MATLAB::${vers}::MEX_LIBRARIES INTERFACE_LINK_DIRECTORIES)
#         fixup_dependencies(TARGETS ${lib} TARGET_DESTINATION lib PROVIDED_LIB_DIRS ${_MATLAB_LIB_PATH})
#     endif()
endforeach()

install(DIRECTORY ${PUBLIC_HEADER_SRC_DIR}/ DESTINATION include COMPONENT Development)

set(MexIFace_TARGETS ${MexIFace_TARGETS} PARENT_SCOPE)
