# MexIFace CMake build system
# Mark J. Olah (mjo@cs.unm DOT edu)
# 03-2014
#
# Windows fixup/packaging script writing function  for "make install"

function(fixup_w64_libs install_dir install_dlls search_dirs)
    get_filename_component(install_dir "${install_dir}" ABSOLUTE)
    message(STATUS "fixup_linux_libs")
    message(STATUS "  install_dir=" ${install_dir})
    message(STATUS "  install_dlls=" ${install_dlls})
    message(STATUS "  search_dirs=" ${search_dirs})
    foreach(dllname ${install_dlls})
        find_file(${dllname}-file ${dllname} ${search_dirs})
        if( ${${dllname}-file} STREQUAL "${dllname}-file-NOTFOUND")
            message(STATUS "NOT Found: " ${dllname} )
        else()
            message(STATUS "Found: " ${dllname} " At: " ${${dllname}-file})
            set(dest "${install_dir}/${dllname}")
            if(NOT EXISTS ${dest})
                message(STATUS "Copying: " ${dllname} " --> " ${dest})
                execute_process(COMMAND ${CMAKE_COMMAND} -E copy "${${dllname}-file}" "${dest}")
            else()
                message(STATUS "Already Present: " ${dllname})
            endif()
        endif()
    endforeach()
endfunction()
