cmake_minimum_required(VERSION 3.25)
project(umbral VERSION 1.2.0 LANGUAGES CXX
        DESCRIPTION "Clasificacion de medidas frente a umbrales de servicio")

add_library(umbral src/umbral.cpp)
add_library(umbral::umbral ALIAS umbral)

target_compile_features(umbral PUBLIC cxx_std_17)
target_sources(umbral
    PUBLIC FILE_SET HEADERS BASE_DIRS include FILES include/umbral/umbral.hpp)
set_target_properties(umbral PROPERTIES
    VERSION ${PROJECT_VERSION} SOVERSION ${PROJECT_VERSION_MAJOR}
    POSITION_INDEPENDENT_CODE ON)

include(GNUInstallDirs)
install(TARGETS umbral EXPORT umbralTargets
        RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}"
        LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"
        ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
        FILE_SET HEADERS DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}")

# Un paquete de terceros debe publicar su propio contrato de uso: quien lo
# instale podra escribir find_package(umbral) sin conocer rutas ni banderas.
include(CMakePackageConfigHelpers)

install(EXPORT umbralTargets
        FILE umbralTargets.cmake NAMESPACE umbral::
        DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/umbral")

configure_package_config_file(cmake/umbral-config.cmake.in
    "${CMAKE_CURRENT_BINARY_DIR}/umbral-config.cmake"
    INSTALL_DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/umbral")
write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/umbral-config-version.cmake"
    VERSION ${PROJECT_VERSION} COMPATIBILITY SameMajorVersion)

install(FILES "${CMAKE_CURRENT_BINARY_DIR}/umbral-config.cmake"
              "${CMAKE_CURRENT_BINARY_DIR}/umbral-config-version.cmake"
        DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/umbral")
