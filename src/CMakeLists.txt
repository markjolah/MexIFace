# MexIFace: src/CMakeLists.txt
#
# build libMexIFaceX_Y.so for each X_Y version

## Source Files ##
set(MexIFace_SRCS MexIFace.cpp MexUtils.cpp explore.cpp)

set(PUBLIC_HEADER_SRC_DIR ${CMAKE_SOURCE_DIR}/include)

if(CMAKE_CROSSCOMPILING AND OPT_FIXUP_DEPENDENCIES) #Fixup before install as otherwise the toolchain install override will auto-call fixup-dependencies
    include(FixupDependencies)
    set(_fixup_args)
    if(OPT_FIXUP_DEPENDENCIES_COPY_GCC_LIBS)
        list(APPEND _fixup_args COPY_GCC_LIBS)
    endif()
    if(OPT_FIXUP_DEPENDENCIES_BUILD_TREE)
        list(APPEND _fixup_args EXPORT_BUILD_TREE)
    endif()
endif()

list(LENGTH MexIFace_MATLAB_ROOTS nroots)
math(EXPR niter "${nroots} - 1")
if(niter LESS 0)
    message(AUTHOR_WARNING "[Mexiface]: No valid MATLAB_ROOTS")
    set(MexIFace_TARGETS "" PARENT_SCOPE)
else()
    set(MexIFace_TARGETS)
    foreach(idx RANGE ${niter})
        #Create a per-matlab version MexIFaceX_Y library.
        list(GET MexIFace_MATLAB_VERSIONS ${idx} ver)
        list(GET MexIFace_MATLAB_VERSION_STRINGS ${idx} vers)
        list(GET MexIFace_MATLAB_LINKER_MAP_FILES ${idx} map_file)
        set(lib MexIFace${vers})
        set(matlab_target "MATLAB::${vers}::MEX_LIBRARIES")
        add_library(${lib} SHARED ${MexIFace_SRCS})
        if(ver VERSION_GREATER_EQUAL "9.4") #Add version file for R2018a+
            list(GET MexIFace_MATLAB_MEXAPI_VERSION_SOURCES ${idx} vers_src_file)
            target_sources(${lib} PRIVATE ${vers_src_file})
        endif()
        add_library(MexIFace::${lib} ALIAS ${lib})
        if(UNIX)
            #Sets visibility of symbols to only mexFunction and related interface
            if(${CMAKE_VERSION} VERSION_GREATER "3.13.0")
                target_link_options(${lib} INTERFACE $<$<NOT:$<CONFIG:Debug>>:-Wl,--version-script,${map_file}>)
            else()
                set_property(TARGET ${lib} APPEND PROPERTY INTERFACE_LINK_LIBRARIES $<$<NOT:$<CONFIG:Debug>>:-Wl,--version-script,${map_file}>) #Older CMAKE don't have INTERFACE_LINK_OPTIONS
            endif()
        endif()
        if(${CMAKE_VERSION} VERSION_GREATER "3.13.0")
            target_link_options(${lib} PUBLIC "-Wl,--as-needed")
        else()
            target_link_libraries(${lib} PUBLIC "-Wl,--as-needed") #Older CMake does not have LINK_OPTIONS
        endif()
        target_link_libraries(${lib} PUBLIC BacktraceException::BacktraceException) #Exception backtraces
        target_link_libraries(${lib} PUBLIC ${matlab_target}) #Matlab Mex libraries
        target_include_directories(${lib} PUBLIC $<BUILD_INTERFACE:${PUBLIC_HEADER_SRC_DIR}>
                                                $<INSTALL_INTERFACE:include>)
        target_compile_features(${lib} PUBLIC cxx_std_11) #Declare C++11 required for building

        if(OPT_MexIFace_PROFILE)
            target_link_libraries(${lib} PRIVATE GPerfTools::profiler)
            target_compile_definitions(${lib} PRIVATE MEXIFACE_ENABLE_PROFILER)
        endif()

        install(TARGETS ${lib} EXPORT ${PROJECT_NAME}Targets
                RUNTIME DESTINATION bin COMPONENT Runtime
                ARCHIVE DESTINATION lib COMPONENT Development
                LIBRARY DESTINATION lib COMPONENT Runtime)
        get_target_property(_build_rpath ${lib} BUILD_RPATH)

        #Copy in dependencies to build-tree / install-tree as necessary
        if(CMAKE_CROSSCOMPILING AND OPT_FIXUP_DEPENDENCIES)
            get_target_property(_MATLAB_LIB_PATH MATLAB::${vers}::MEX_LIBRARIES INTERFACE_LINK_DIRECTORIES)
            fixup_dependencies(TARGETS ${lib} PROVIDED_LIB_DIRS ${_MATLAB_LIB_PATH} ${_fixup_args})
        endif()

        list(APPEND MexIFace_TARGETS MexIFace::${lib})
    endforeach()

    install(DIRECTORY ${PUBLIC_HEADER_SRC_DIR}/ DESTINATION include COMPONENT Development)

    set(MexIFace_TARGETS ${MexIFace_TARGETS} PARENT_SCOPE)
endif()
