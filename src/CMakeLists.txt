# MexIFace: src/
# Copyright 2013-2017 
# Author: Mark J. Olah
# Email: (mjo@cs.unm DOT edu)

## Source Files ##
set(MexIFace_SRCS MexIFace.cpp MexUtils.cpp explore.cpp)
## Include Files ##
set(MexIFace_HEADERS MexIFace.h MexUtils.h hypercube.h Handle.h explore.h)

## Iface Core Object library. ##
set(MexIFace_LIB MexIFace)
add_library( ${MexIFace_LIB} SHARED ${MexIFace_SRCS} )
target_include_directories(${MexIFace_LIB} PUBLIC ${MATLAB_INCLUDE})
set_target_properties(${MexIFace_LIB} PROPERTIES PUBLIC_HEADER "${MexIFace_HEADERS}")

target_link_libraries( MexIFace ${LAPACK_LINKER_FLAGS} ${LAPACK_LIBRARIES})
target_link_libraries( MexIFace ${BLAS_LINKER_FLAGS} ${BLAS_LIBRARIES})
target_link_libraries( MexIFace ${OPENMP_LIBRARY})
target_link_libraries( MexIFace ${PTHREAD_LIBRARY})
target_link_libraries( MexIFace "${MATLAB_LIBRARIES}")

# Package Configuration and Exports
include(CMakePackageConfigHelpers)
set(CONFIG_DIR ${CMAKE_CURRENT_BINARY_DIR}/config) #Directory for generated .cmake config file
set(EXPORT_TARGETS_NAME ${PROJECT_NAME}-targets)
set(PROJECT_CONFIG_NAME ${PROJECT_NAME}-config)
set(VERSION_CONFIG_FILE ${CONFIG_DIR}/${PROJECT_NAME}-config-version.cmake)
set(PROJECT_CONFIG_FILE ${CONFIG_DIR}/${PROJECT_CONFIG_NAME}.cmake)
set(PROJECT_CONFIG_TEMPLATE_FILE ${MexIFace_CMAKE_TEMPLATES_DIR}/${PROJECT_CONFIG_NAME}.cmake.in)
set(MexIFace_CONFIG_INSTALL_DIR lib/cmake/${PROJECT_NAME}) #Where to install project config .cmake files
set(MexIFace_CMAKE_INSTALL_DIR share/${PROJECT_NAME}/cmake)

## Generate Package Config files for downstream projects to utilize
#Generate: MexIFace-config-version.cmake
write_basic_package_version_file(${VERSION_CONFIG_FILE} COMPATIBILITY SameMajorVersion)

#Generate: MexIFace-config.cmake
configure_package_config_file(${PROJECT_CONFIG_TEMPLATE_FILE} ${PROJECT_CONFIG_FILE} 
                              INSTALL_DESTINATION ${MexIFace_CMAKE_INSTALL_DIR}
                              PATH_VARS MexIFace_CMAKE_INSTALL_DIR)

#Install libraries and headers
install(TARGETS ${MexIFace_LIB}
        EXPORT ${EXPORT_TARGETS_NAME}
        LIBRARY DESTINATION lib COMPONENT Runtime
        PUBLIC_HEADER DESTINATION include/${PROJECT_NAME} COMPONENT Development)
#Install Cmake modules and helper files for development
install(DIRECTORY ${MexIFace_CMAKE_DIR}/
        DESTINATION ${MexIFace_CMAKE_INSTALL_DIR} COMPONENT Development)
#Install package config files
install(FILES ${PROJECT_CONFIG_FILE} ${VERSION_CONFIG_FILE} 
        DESTINATION ${MexIFace_CONFIG_INSTALL_DIR} COMPONENT Development)
#Install MexIFace-targets exports
install(EXPORT ${EXPORT_TARGETS_NAME} 
        DESTINATION ${MexIFace_CONFIG_INSTALL_DIR} COMPONENT Development)

