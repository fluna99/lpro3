# Empaquetado con CPack: convierte el arbol instalado en artefactos entregables.
#
# Se generan dos formatos con proposito distinto:
#   TGZ -> distribucion generica, util para el repositorio de artefactos interno
#   DEB -> instalacion gestionada en las maquinas del laboratorio (apt)

set(CPACK_PACKAGE_NAME                "telemetria")
set(CPACK_PACKAGE_VENDOR              "ETSI Telecomunicacion - Universidad de Malaga")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "${PROJECT_DESCRIPTION}")
set(CPACK_PACKAGE_VERSION             "${PROJECT_VERSION}")
set(CPACK_PACKAGE_CONTACT             "equipo-telemetria@uma.es")
set(CPACK_RESOURCE_FILE_LICENSE       "${CMAKE_SOURCE_DIR}/LICENSE")
set(CPACK_PACKAGE_FILE_NAME
    "telemetria_${PROJECT_VERSION}_${CMAKE_SYSTEM_PROCESSOR}")
set(CPACK_PACKAGING_INSTALL_PREFIX    "/usr")
set(CPACK_GENERATOR                   "TGZ;DEB")

# Metadatos exigidos por la politica de Debian (equivalente a los metadatos que
# pide cualquier repositorio de artefactos corporativo).
set(CPACK_DEBIAN_PACKAGE_MAINTAINER  "Equipo Telemetria <equipo-telemetria@uma.es>")
set(CPACK_DEBIAN_PACKAGE_SECTION     "net")
set(CPACK_DEBIAN_PACKAGE_HOMEPAGE    "${PROJECT_HOMEPAGE_URL}")
set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS   ON)   # calcula dependencias reales del binario
set(CPACK_DEB_COMPONENT_INSTALL      OFF)

include(CPack)
