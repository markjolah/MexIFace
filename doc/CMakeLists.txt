# doc/CMakeLists.txt
# Doxygen integration

find_package(LATEX REQUIRED)
find_package(Doxygen REQUIRED)
if(DOXYGEN_FOUND)
    #Configure the doxyfile for the build directory
    set(DOXYFILE_IN ${CMAKE_CURRENT_SOURCE_DIR}/Doxyfile.in)
    set(DOXYFILE_OUT ${CMAKE_CURRENT_BINARY_DIR}/Doxyfile)
    set(DOXYGEN_PDF_DIR ${CMAKE_CURRENT_BINARY_DIR}/pdf)
    set(DOXYGEN_HTML_DIR ${CMAKE_CURRENT_BINARY_DIR}/html)
    set(DOXYGEN_PDF_NAME refman.pdf)
    set(PDF_DOC_NAME ${PROJECT_NAME}-${PROJECT_VERSION}-reference.pdf)
    set(DOC_INSTALL_DIR share/${PROJECT_NAME}/doc)
    file(GLOB SRC_FILES src/*.h src/*.cpp)
    configure_file(${DOXYFILE_IN} ${DOXYFILE_OUT} @ONLY)
    add_custom_target( doc VERBATIM
        COMMAND ${DOXYGEN_EXECUTABLE} ${DOXYFILE_OUT}
        DEPENDS ${DOXYFILE_OUT} ${SRC_FILES}
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
        COMMENT "Generate Doxygen Documentation")
    add_custom_target( pdf VERBATIM
        COMMAND make ${DOXYGEN_PDF_NAME}
        COMMAND mv ${DOXYGEN_PDF_NAME} ${PDF_DOC_NAME}
        DEPENDS ${DOXYGEN_PDF_DIR}/refman.tex ${DOXYGEN_PDF_DIR}/Makefile
        WORKING_DIRECTORY ${DOXYGEN_PDF_DIR}
        COMMENT "Build pdf documentation")
    add_dependencies(pdf doc)
    install(FILES ${DOXYGEN_PDF_DIR}/${PDF_DOC_NAME} DESTINATION ${DOC_INSTALL_DIR} COMPONENT Development)
    install(DIRECTORY ${DOXYGEN_HTML_DIR} DESTINATION ${DOC_INSTALL_DIR} COMPONENT Development)
else()
    message(WARNING "Doxygen not found. Cannot build documentation.")
endif()
