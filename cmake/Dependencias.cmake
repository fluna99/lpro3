# Gestion de dependencias con trazabilidad.
#
# Regla del taller: ninguna dependencia se consume de una rama movil ni de una
# direccion que el equipo no controle. Se fija una ETIQUETA EXACTA y se prefiere
# el ESPEJO LOCAL (copia integra creada con `git clone --mirror`) sobre el
# origen remoto. Asi la compilacion es reproducible y auditable, y sobrevive a
# que el alojamiento no este disponible.
#
# Orden de preferencia:
#   1. Espejo local            ~/taller-infra/git/umbral.git   (continuidad)
#   2. Origen remoto           TELEMETRIA_UMBRAL_URL           (GitHub)
#   3. Copia interna           terceros/umbral                 (modo degradado)

include(FetchContent)

if(DEFINED ENV{TALLER_INFRA})
    set(TELEMETRIA_INFRA "$ENV{TALLER_INFRA}")
else()
    set(TELEMETRIA_INFRA "$ENV{HOME}/taller-infra")
endif()

set(TELEMETRIA_ESPEJO "${TELEMETRIA_INFRA}/git/umbral.git"
    CACHE STRING "Espejo local (copia integra) de la dependencia 'umbral'")
set(TELEMETRIA_UMBRAL_URL "https://github.com/EQUIPO/umbral.git"
    CACHE STRING "Origen remoto de 'umbral'. Sustituya EQUIPO por su organizacion")
set(TELEMETRIA_UMBRAL_TAG "v1.2.0"
    CACHE STRING "Version EXACTA de 'umbral' que consume este proyecto")

if(EXISTS "${TELEMETRIA_ESPEJO}")
    message(STATUS "[dependencias] umbral ${TELEMETRIA_UMBRAL_TAG} desde el espejo local")
    FetchContent_Declare(umbral
        GIT_REPOSITORY "${TELEMETRIA_ESPEJO}"
        GIT_TAG        "${TELEMETRIA_UMBRAL_TAG}"
        SYSTEM)
elseif(NOT TELEMETRIA_UMBRAL_URL MATCHES "EQUIPO")
    message(STATUS "[dependencias] umbral ${TELEMETRIA_UMBRAL_TAG} desde ${TELEMETRIA_UMBRAL_URL}")
    FetchContent_Declare(umbral
        GIT_REPOSITORY "${TELEMETRIA_UMBRAL_URL}"
        GIT_TAG        "${TELEMETRIA_UMBRAL_TAG}"
        SYSTEM)
else()
    message(WARNING
        "[dependencias] Sin espejo local ni origen remoto configurado. "
        "Se usa la copia interna de terceros/umbral (modo degradado). "
        "Ejecute scripts/10-espejo-continuidad.sh semilla, o configure "
        "TELEMETRIA_UMBRAL_URL con la direccion del repositorio de la dependencia.")
    FetchContent_Declare(umbral SOURCE_DIR "${CMAKE_SOURCE_DIR}/terceros/umbral" SYSTEM)
endif()

FetchContent_MakeAvailable(umbral)
