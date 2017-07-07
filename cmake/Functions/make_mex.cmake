# make_mex.cmake
# Copyright 2013-2017 
# Author: Mark J. Olah
# Email: (mjo@cs.unm DOT edu)
#
# Variable Dependencies:
# MEX_ARCH_DIR - Arch and build dependent relative path for mex module installation

# X-Platform Mex function Linking function.
# useage: make_mex(MyModule) will compile MyModule.cpp into MyModule.${MEX_EXT} for the appropriate platform
# This is mainly done by linking against the MexIFace library
function(make_mex mexfile)
    include(GetPrerequisites)
    #MEX module link-time flags
    set(MEX_LINK_FLAGS "-Wl,-g" "-Wl,--no-undefined")
    if (WIN32)
        set(MEX_LINK_FLAGS ${MEX_LINK_FLAGS} "-Wl,--export-all-symbols")
    elseif(UNIX)
        set(MEX_LINK_FLAGS ${MEX_LINK_FLAGS} "-Wl,--version-script,${MATLAB_LINK_MAPFILE}")
    elseif(APPLE)
        set(MEX_LINK_FLAGS ${MEX_LINK_FLAGS} "-Wl,--export-all-symbols")
    endif()

    add_library(${mexfile} SHARED ${mexfile}.cpp)
    target_link_libraries(${mexfile} MexIFace) #This does most of the magic.
    target_link_libraries(${mexfile} ${MEX_LINK_FLAGS}) #Set link-time flags
    target_include_directories(${mexfile} PRIVATE ${MATLAB_INCLUDE}) #Matlab headers
    set_target_properties(${mexfile} PROPERTIES PREFIX "" DEBUG_POSTFIX "" SUFFIX .${MEX_EXT})
    set_property(TARGET ${mexfile} APPEND PROPERTY COMPILE_DEFINITIONS MATLAB_MEX_FILE) # define -DMATLAB_MEX_FILE
    if(UNIX)
        # RPATH config
        # $ORIGIN/../.. This will be lib/${PROJECT_NAME} - location of local libraries for project
        # $ORIGIN/../../.. This will be lib - location of global libraries for project and dependency libraries like MexIFace
        set_target_properties(${mexfile} PROPERTIES INSTALL_RPATH "\$ORIGIN/../..:\$ORIGIN/../../..") #link back to lib directory
        install(TARGETS ${mexfile} LIBRARY DESTINATION ${MEX_ARCH_DIR} COMPONENT Runtime)
        fixup_dependencies(${mexfile} COPY_DESTINATION "../../.." RPATH "../..") 
    elseif(WIN32)
        install(TARGETS ${mexfile} RUNTIME DESTINATION ${MEX_ARCH_DIR} COMPONENT Runtime)
        fixup_dependencies(${mexfile}) #No additional rpaths possible on windows.  have to fixup in-place :(
    elseif(APPLE)
        set_target_properties(${mexfile} PROPERTIES INSTALL_RPATH "@loader_path/../..:@loader_path/../../..") #link back to lib directory
        fixup_dependencies(${mexfile} COPY_DESTINATION "../../.." RPATH "../..") 
    endif()
    set_property(GLOBAL APPEND PROPERTY MEX_MODULES ${mexfile})
endfunction()

