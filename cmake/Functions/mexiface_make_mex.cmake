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
#  MEXNAME - name of mexfile [Defaults to ${SOURCE} base name]
## Multi-Argument Keywords
#  SOURCES - source file. [Defaults to ${MEXNAME}.cpp].  Must specify either SOURCE or MEXNAME or both
#   PUBLIC_LINK_LIBRARIES
#   MATLAB_LINK_LIBRARIES - [optional] Values:  ENG, MWBLAS, MWLAPACK, MATLAB_DATA_ARRAY MATLAB_ENGINE
#
function(mexiface_make_mex mexfile)
    set(options)
    set(oneValueArgs MEXFILE)
    set(multiValueArgs MATLAB_LIBS)
    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}"  ${ARGN})
    if(ARG_UNPARSED_ARGUMENTS)
        message(SEND_ERROR "Unknown keywords given to mexiface_make_mex(): \"${ARG_UNPARSED_ARGUMENTS}\"")
    endif()
    if(NOT ARG_MEXNAME)
        set(ARG_MEXNAME ${PROJECT_NAME})
    endif()
    if(NOT SOURCES)
        message(SEND_ERROR "No sources given.")
    endif()

    foreach(vers IN LISTS MexIFace_COMPATABLE_MATLAB_VERSION_STRINGS)
        if(UNIX)
            set(mexfile ${ARG_MEXNAME})
        elseif(WIN32)
            set(mexfile ${ARG_MEXNAME}${vers})
        endif()
        add_library(${mexfile} SHARED ${mexfile}.cpp )
        target_link_libraries(${mexfile} PUBLIC MexIFace::MexIFace${Vers}) #This does most of the magic.
        target_link_libraries(${mexfile} PUBLIC ${MEX_LINK_FLAGS}) #Set link-time flags
        set_target_properties(${mexfile} PROPERTIES PREFIX "" DEBUG_POSTFIX "" SUFFIX .${MexIFace_MATLAB_SYSTEM_MEXEXT})
        set_property(TARGET ${mexfile} APPEND PROPERTY COMPILE_DEFINITIONS MATLAB_MEX_FILE) # define -DMATLAB_MEX_FILE
        if(UNIX)
            # RPATH config
            # $ORIGIN/../../.. This will be lib/${PROJECT_NAME} - location of local libraries for project
            # $ORIGIN/../../../.. This will be lib - location of global libraries for project and dependency libraries like MexIFace
            set_target_properties(${mexfile} PROPERTIES INSTALL_RPATH "\$ORIGIN/../../..:\$ORIGIN/../../../..") #link back to lib directory
            install(TARGETS ${mexfile} LIBRARY DESTINATION ${MEX_ARCH_DIR} COMPONENT Runtime)
            fixup_dependencies(${mexfile} COPY_DESTINATION "../../../.." RPATH "../../..")
        elseif(WIN32)
            install(TARGETS ${mexfile} RUNTIME DESTINATION ${MEX_ARCH_DIR} COMPONENT Runtime)
            fixup_dependencies(${mexfile}) #No additional rpaths possible on windows.  have to fixup in-place :(
        elseif(APPLE)
            set_target_properties(${mexfile} PROPERTIES INSTALL_RPATH "@loader_path/../../..:@loader_path/../../../..") #link back to lib directory
            fixup_dependencies(${mexfile} COPY_DESTINATION "../../../.." RPATH "../../..")
        endif()
        set_property(GLOBAL APPEND PROPERTY MexIFace_MODULE_TARGETS ${mexfile})
    endforeach()
    file(RELATIVE_PATH binary_module_path ${CMAKE_BINARY_DIR} ${CMAKE_CURRENT_BINARY_DIR})
    message(STATUS "[MexIFace::max_mex] Computed relative path: ${binary_module_path}")
    set_property(GLOBAL APPEND PROPERTY MexIFace_MODULE_BUILD_DIRS ${binary_module_path}) #Record build directories for build-tree exports
endfunction()

