# Puertas de calidad automatizadas.
#
# Todas las reglas viven en un unico objetivo INTERFACE (telemetria_calidad).
# Cualquier objetivo que se enlace contra el hereda la politica del proyecto;
# nadie tiene que recordar que banderas poner.

add_library(telemetria_calidad INTERFACE)

# --- 1. Avisos del compilador ------------------------------------------------
if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    target_compile_options(telemetria_calidad INTERFACE
        -Wall -Wextra -Wpedantic -Wshadow -Wconversion -Wnon-virtual-dtor)
    if(TELEMETRIA_AVISOS_COMO_ERRORES)
        target_compile_options(telemetria_calidad INTERFACE -Werror)
    endif()
elseif(MSVC)
    target_compile_options(telemetria_calidad INTERFACE /W4)
    if(TELEMETRIA_AVISOS_COMO_ERRORES)
        target_compile_options(telemetria_calidad INTERFACE /WX)
    endif()
endif()

# --- 2. Cobertura de pruebas -------------------------------------------------
if(TELEMETRIA_COBERTURA AND CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    target_compile_options(telemetria_calidad INTERFACE --coverage -O0 -g)
    target_link_options(telemetria_calidad    INTERFACE --coverage)
endif()

# --- 3. Analisis estatico en tiempo de compilacion (clang-tidy) --------------
if(TELEMETRIA_CLANG_TIDY)
    find_program(CLANG_TIDY_EXE NAMES clang-tidy)
    if(CLANG_TIDY_EXE)
        # Calidad.cmake se incluye (no es una funcion), asi que la variable se
        # define en el ambito del directorio raiz y la heredan todos los objetivos.
        set(CMAKE_CXX_CLANG_TIDY "${CLANG_TIDY_EXE};--quiet")
        message(STATUS "[calidad] clang-tidy activo: ${CLANG_TIDY_EXE}")
    else()
        message(WARNING "[calidad] clang-tidy no encontrado; se omite")
    endif()
endif()

# --- 4. Objetivos auxiliares bajo demanda ------------------------------------
file(GLOB_RECURSE TELEMETRIA_FUENTES CONFIGURE_DEPENDS
     "${CMAKE_SOURCE_DIR}/src/*.cpp"   "${CMAKE_SOURCE_DIR}/include/*.hpp"
     "${CMAKE_SOURCE_DIR}/apps/*.cpp"  "${CMAKE_SOURCE_DIR}/tests/*.cpp")

find_program(CLANG_FORMAT_EXE NAMES clang-format)
if(CLANG_FORMAT_EXE)
    add_custom_target(formato
        COMMAND "${CLANG_FORMAT_EXE}" -i --style=file ${TELEMETRIA_FUENTES}
        COMMENT "Aplicando el estilo del proyecto (.clang-format)"
        VERBATIM)
    add_custom_target(formato-verificar
        COMMAND "${CLANG_FORMAT_EXE}" --dry-run --Werror --style=file ${TELEMETRIA_FUENTES}
        COMMENT "Verificando el estilo del proyecto (puerta de calidad)"
        VERBATIM)
endif()

find_program(CPPCHECK_EXE NAMES cppcheck)
if(CPPCHECK_EXE)
    add_custom_target(analisis-estatico
        COMMAND "${CPPCHECK_EXE}" --enable=warning,style,performance,portability
                --inline-suppr --error-exitcode=2 --std=c++17 --quiet
                --project="${CMAKE_BINARY_DIR}/compile_commands.json"
                --suppress=missingIncludeSystem
                "--suppress=*:${CMAKE_BINARY_DIR}/_deps/*"
        COMMENT "Analisis estatico con cppcheck"
        VERBATIM)
endif()

find_program(GCOVR_EXE NAMES gcovr)
if(GCOVR_EXE)
    add_custom_target(cobertura
        COMMAND "${CMAKE_CTEST_COMMAND}" --output-on-failure
        COMMAND "${CMAKE_COMMAND}" -E make_directory "${CMAKE_BINARY_DIR}/informes"
        COMMAND "${GCOVR_EXE}" --root "${CMAKE_SOURCE_DIR}" --filter "${CMAKE_SOURCE_DIR}/src"
                --html-details "${CMAKE_BINARY_DIR}/informes/cobertura.html"
                --xml "${CMAKE_BINARY_DIR}/informes/cobertura.xml"
                --print-summary
        WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
        COMMENT "Midiendo cobertura de pruebas (requiere el preset cobertura)"
        VERBATIM)
endif()
