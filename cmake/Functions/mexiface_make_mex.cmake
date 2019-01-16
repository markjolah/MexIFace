# mexiface_make_mex.cmake
# Copyright 2013-2017 
# Author: Mark J. Olah
# Email: (mjo@cs.unm DOT edu)
#
# Variable Dependencies:
# MEX_ARCH_DIR - Arch and build dependent relative path for mex module installation

# X-Platform Mex function Linking function.
# useage: make_mex(MyModule) will compile MyModule.cpp into MyModule.${MexIFace_MATLAB_SYSTEM_MEXEXT} for the appropriate platform
# This is mainly done by linking against the MexIFace library
## Options
## Single-Argument Keywords
# MEXNAME - name of mexfile [Defaults to ${SOURCE} base name]
# MATLAB_MEX_INSTALL_DIR - [Defualt: lib/${PACKAGE_NAME}/mex] Should be relative to CMAKE_INSTALL_PREFIX
## Multi-Argument Keywords
# SOURCES - source file. [Defaults to ${MEXNAME}.cpp].  Must specify either SOURCE or MEXNAME or both
# LINK_LIBRARIES - [optional] Additional target libraries to link to.
# MATLAB_LINK_LIBRARIES - [optional] Values:  ENG, MWBLAS, MWLAPACK, MATLAB_DATA_ARRAY MATLAB_ENGINE
#
include(FixupDependencies)

function(mexiface_make_mex)
    set(options)
    set(oneValueArgs MEXNAME MATLAB_MEX_INSTALL_DIR)
    set(multiValueArgs SOURCES LINK_LIBRARIES MATLAB_LINK_LIBRARIES)
    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}"  ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(SEND_ERROR "Unknown keywords given to mexiface_make_mex(): \"${ARG_UNPARSED_ARGUMENTS}\"")
    endif()
    if(NOT ARG_MEXNAME)
        set(ARG_MEXNAME ${PROJECT_NAME})
    endif()
    if(NOT ARG_SOURCES)
        message(SEND_ERROR "No sources given.")
    endif()

    if(NOT ARG_MATLAB_MEX_INSTALL_DIR)
        set(ARG_MATLAB_MEX_INSTALL_DIR lib/${PROJECT_NAME}/mex)
    elseif(IS_ABSOLUTE ARG_MATLAB_MEX_INSTALL_DIR)
        file(RELATIVE_PATH ARG_MATLAB_MEX_INSTALL_DIR ${CMAKE_INSTALL_PREFIX} ${ARG_MATLAB_MEX_INSTALL_DIR})
    endif()

    # Looks for options:
    #   OPT_FIXUP_DEPENDENCIES - Fixup dependencies.  Should be ON if crosscompiling.
    #   OPT_INSTALL_SYSTEM_DEPENDENCIES
    #   OPT_FIXUP_BUILD_TREE_DEPENDENCIES
    #   OPT_LINK_INSTALLED_LIBS
    #Args for fixup_dependencies.
    if(CMAKE_CROSSCOMPILING AND OPT_FIXUP_DEPENDENCIES)
        include(FixupDependencies)
        set(_fixup_args)
        if(OPT_FIXUP_BUILD_TREE_DEPENDENCIES)
            list(APPEND _fixup_args EXPORT_BUILD_TREE)
        endif()
        if(OPT_INSTALL_SYSTEM_DEPENDENCIES)
            list(APPEND _fixup_args COPY_SYSTEM_LIBS)
        endif()
        if(OPT_LINK_INSTALLED_LIBS)
            list(APPEND _fixup_args LINK_INSTALLED_LIBS)
        endif()
    elseif(CMAKE_CROSSCOMPILING)
        message(WARNING "  [MexIFace::make_mex()] Crosscompiling, but OPT_FIXUP_DEPENDENCIES is not set.  Dependencies may not be found correctly for mex files that link to external shared libraries.")
    endif()

    foreach(vers IN LISTS MexIFace_COMPATABLE_MATLAB_VERSION_STRINGS)
        set(mexfile ${ARG_MEXNAME}${vers})
        if(UNIX)
            set(mex_dir "${ARG_MATLAB_MEX_INSTALL_DIR}/glnxa64$<$<CONFIG:Debug>:.debug>")
        elseif(WIN32)
            set(mex_dir "${ARG_MATLAB_MEX_INSTALL_DIR}/win64$<$<CONFIG:Debug>:.debug>")
        endif()
        add_library(${mexfile} SHARED ${ARG_SOURCES} )
        target_link_libraries(${mexfile} PUBLIC MexIFace::MexIFace${vers}) #This does most of the magic.
        if(ARG_LINK_LIBRARIES)
            target_link_libraries(${mexfile} PUBLIC ${ARG_LINK_LIBRARIES}) #Additional libraries
        endif()
        if(ARG_MATLAB_LINK_LIBRARIES)
            target_link_libraries(${mexfile} PUBLIC ${MATLAB_LINK_LIBRARIES}) #Additional matlab libraries
        endif()
        set_target_properties(${mexfile} PROPERTIES PREFIX "" DEBUG_POSTFIX "" SUFFIX .${MexIFace_MATLAB_SYSTEM_MEXEXT})
        string(REGEX REPLACE "[^/]+" ".." relpath_install_prefix ${mex_dir})
        set(rpath ${relpath_install_prefix})
        get_target_property(_MATLAB_LIB_PATH MATLAB::${vers}::MEX_LIBRARIES INTERFACE_LINK_DIRECTORIES)
        if(UNIX)
            set_target_properties(${mexfile} PROPERTIES INSTALL_RPATH "\$ORIGIN/${rpath}/lib") #link back to lib directory
            install(TARGETS ${mexfile} LIBRARY DESTINATION ${mex_dir} COMPONENT Runtime)
            get_target_property(_build_rpath ${mexfile} BUILD_RPATH)

            if(CMAKE_CROSSCOMPILING AND OPT_FIXUP_DEPENDENCIES) #Fixup before install as otherwise the toolchain install override will auto-call fixup-dependencies
                get_target_property(_MATLAB_INCLUDE_PATH MATLAB::${vers}::MEX_LIBRARIES INTERFACE_INCLUDE_DIRECTORIES)
                get_filename_component(_matlab_executable "${_MATLAB_INCLUDE_PATH}/../../bin/${MexIFace_MATLAB_SYSTEM_ARCH}/MATLAB" ABSOLUTE)
                fixup_dependencies(TARGETS ${mexfile} TARGET_DESTINATION ${mex_dir} COPY_DESTINATION ${rpath}/lib PROVIDED_LIB_DIRS ${_MATLAB_LIB_PATH} PARENT_LIB ${_matlab_executable} ${_fixup_args})
            endif()
        elseif(WIN32)
            install(TARGETS ${mexfile} RUNTIME DESTINATION ${mex_dir} COMPONENT Runtime)
            if(CMAKE_CROSSCOMPILING AND OPT_FIXUP_DEPENDENCIES) #Fixup before install as otherwise the toolchain install override will auto-call fixup-dependencies
                fixup_dependencies(TARGETS ${mexfile} TARGET_DESTINATION ${mex_dir} COPY_DESTINATION "." PROVIDED_LIB_DIRS ${_MATLAB_LIB_PATH} ${_fixup_args})
            endif()
#         elseif(APPLE)
#             set_target_properties(${mexfile} PROPERTIES INSTALL_RPATH "@loader_path/../../..:@loader_path/../../../..") #link back to lib directory
#             fixup_dependencies(${mexfile} COPY_DESTINATION "../../../.." RPATH "../../..")
        endif()


        set_property(GLOBAL APPEND PROPERTY MexIFace_MODULE_TARGETS ${mexfile})
        set(_Print_Properties TYPE INCLUDE_DIRECTORIES INTERFACE_INCLUDE_DIRECTORIES LINK_LIBRARIES INTERFACE_LINK_LIBRARIES LINK_DIRECTORIES INTERFACE_LINK_DIRECTORIES
                              COMPILE_FEATURES INTERFACE_COMPILE_FEATURES)
        set(_Config_Properties LIBRARY_OUTPUT_DIRECTORY LIBRARY_OUTPUT_NAME)
        set(_Config_Type RELEASE DEBUG RELWITHDEBINFO MINSIZEREL)
        foreach(prop IN LISTS _Config_Properties)
            foreach(type IN LISTS _Config_Types)
                list(APPEND _Print_Properties ${prop}_${type})
            endforeach()
        endforeach()
        foreach(prop IN LISTS _Print_Properties)
            get_target_property(v ${mexfile} ${prop})
            if(v)
                message(STATUS "[MexIFace::mexiface_make_mex] [${target}] ${prop}: ${v}")
            endif()
        endforeach()
    endforeach()
    file(RELATIVE_PATH binary_module_path ${CMAKE_BINARY_DIR} ${CMAKE_CURRENT_BINARY_DIR})
    set_property(GLOBAL APPEND PROPERTY MexIFace_MODULE_BUILD_DIRS ${binary_module_path}) #Record build directories for build-tree exports
endfunction()

