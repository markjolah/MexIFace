# MexIFace CMake build system
# Mark J. Olah (mjo@cs.unm DOT edu)
# 03-2014
#
# X-Platform .mex file generation


#MEX module link-time flags
set(MEX_LINK_FLAGS "-Wl,-g" "-Wl,--no-undefined")
if (WIN32)
    set(MEX_LINK_FLAGS ${MEX_LINK_FLAGS} "-Wl,--export-all-symbols")
elseif(UNIX)
    set(MEX_LINK_FLAGS ${MEX_LINK_FLAGS} "-Wl,--version-script,${MATLAB_LINK_MAPFILE}")
elseif(APPLE)
    set(MEX_LINK_FLAGS ${MEX_LINK_FLAGS} "-Wl,--export-all-symbols")
endif()

## X-Platform Mex function Linking!##
# useage: make_mex(MyModule) will compile MyModule.cpp into MyModule.${MEX_EXT} for the approriate platform
# This is mainly done by linking agains the MexIFace library
function(make_mex mexfile)
    add_library( ${mexfile} SHARED ${mexfile}.cpp )
    target_include_directories(${mexfile} INTERFACE ${MATLAB_INCLUDE}) #Matlab headers
    target_link_libraries( ${mexfile} ${MEX_LINK_FLAGS} ${MexIFace_LIBRARIES})
    set_property(TARGET ${mexfile} PROPERTY OUTPUT_NAME ${mexfile})
    set_property(TARGET ${mexfile} PROPERTY SUFFIX .${MEXEXT})
    set_property(TARGET ${mexfile} APPEND PROPERTY COMPILE_DEFINITIONS MATLAB_MEX_FILE) # define -DMATLAB_MEX_FILE
    if(UNIX)
        set_property(TARGET ${mexfile} PROPERTY INSTALL_RPATH "\$ORIGIN/../../lib") #link back to lib directory
        install(TARGETS ${mexfile} LIBRARY DESTINATION mex/mex.${MEX_EXT}${CMAKE_DEBUG_POSTFIX} COMPONENT Runtime)
    elseif(WIN32)
        install(TARGETS ${mexfile}
            RUNTIME DESTINATION .  COMPONENT Runtime
            LIBRARY DESTINATION .  COMPONENT Runtime)
    endif()
endfunction()
