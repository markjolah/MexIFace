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
# LINK_LIBRARIES
# MATLAB_LINK_LIBRARIES - [optional] Values:  ENG, MWBLAS, MWLAPACK, MATLAB_DATA_ARRAY MATLAB_ENGINE
#
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
        install(TARGETS ${mexfile} LIBRARY DESTINATION ${mex_dir} COMPONENT Runtime)
        if(UNIX)
            # RPATH config
            # $ORIGIN/../../..: This will be lib - location of global libraries for project and dependency libraries like MexIFace
            set_target_properties(${mexfile} PROPERTIES INSTALL_RPATH "\$ORIGIN/../../..") #link back to lib directory
#             fixup_dependencies(${mexfile} COPY_DESTINATION "../../../.." RPATH "../../..")
        elseif(WIN32)
            install(TARGETS ${mexfile} RUNTIME DESTINATION ${mex_dir} COMPONENT Runtime)
            fixup_dependencies(${mexfile}) #No additional rpaths possible on windows.  have to fixup in-place :(
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
    message(STATUS "[MexIFace::make_mex] Computed relative path: ${binary_module_path}")
    set_property(GLOBAL APPEND PROPERTY MexIFace_MODULE_BUILD_DIRS ${binary_module_path}) #Record build directories for build-tree exports
endfunction()

