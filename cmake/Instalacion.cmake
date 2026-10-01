# Reglas de instalacion y exportacion del paquete.
#
# El objetivo es que OTRO proyecto pueda escribir simplemente
#     find_package(telemetria 1.0 REQUIRED)
#     target_link_libraries(mi_app PRIVATE telemetria::telemetria)
# sin conocer rutas ni banderas: es el contrato de entrega de la biblioteca.

include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

install(TARGETS telemetria telemetria_calidad telemetria_cli
        EXPORT  telemetriaTargets
        RUNTIME       DESTINATION "${CMAKE_INSTALL_BINDIR}"     COMPONENT ejecutables
        LIBRARY       DESTINATION "${CMAKE_INSTALL_LIBDIR}"     COMPONENT biblioteca
        ARCHIVE       DESTINATION "${CMAKE_INSTALL_LIBDIR}"     COMPONENT desarrollo
        FILE_SET HEADERS DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}" COMPONENT desarrollo)

install(EXPORT telemetriaTargets
        FILE        telemetriaTargets.cmake
        NAMESPACE   telemetria::
        DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/telemetria"
        COMPONENT   desarrollo)

configure_package_config_file(
    "${CMAKE_CURRENT_LIST_DIR}/telemetria-config.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/telemetria-config.cmake"
    INSTALL_DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/telemetria")

write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/telemetria-config-version.cmake"
    VERSION       ${PROJECT_VERSION}
    COMPATIBILITY SameMajorVersion)     # contrato de compatibilidad semantica

install(FILES "${CMAKE_CURRENT_BINARY_DIR}/telemetria-config.cmake"
              "${CMAKE_CURRENT_BINARY_DIR}/telemetria-config-version.cmake"
        DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/telemetria"
        COMPONENT   desarrollo)

install(FILES "${CMAKE_SOURCE_DIR}/LICENSE"
        DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/doc/telemetria"
        COMPONENT   biblioteca)
