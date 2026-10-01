# Deriva la version del proyecto de la etiqueta de Git (fuente unica de verdad).
#
# Con esto una "release" deja de ser lo que alguien escriba a mano en un fichero
# y pasa a ser un hecho verificable del repositorio: todo binario publicado
# corresponde a un commit concreto y se puede reconstruir a partir de el.
#
#   version_desde_git(<var_semver> <var_trazable>)
#     <var_semver>   -> 1.4.2                     (para project(VERSION ...))
#     <var_trazable> -> 1.4.2-7-gab12cd3-sucio    (para --version y auditoria)

function(version_desde_git salida_semver salida_trazable)
    set(descripcion "")
    find_package(Git QUIET)
    if(Git_FOUND AND EXISTS "${CMAKE_SOURCE_DIR}/.git")
        execute_process(
            COMMAND "${GIT_EXECUTABLE}" describe --tags --dirty --always --match "v[0-9]*"
            WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
            OUTPUT_VARIABLE descripcion
            OUTPUT_STRIP_TRAILING_WHITESPACE
            ERROR_QUIET)
    endif()

    if(descripcion MATCHES "^v([0-9]+)\.([0-9]+)\.([0-9]+)")
        set(semver "${CMAKE_MATCH_1}.${CMAKE_MATCH_2}.${CMAKE_MATCH_3}")
        string(REGEX REPLACE "^v" "" trazable "${descripcion}")
        string(REPLACE "-dirty" "-sucio" trazable "${trazable}")
    else()
        # Todavia no hay etiquetas: se recurre al fichero VERSION del repositorio.
        file(STRINGS "${CMAKE_SOURCE_DIR}/VERSION" semver LIMIT_COUNT 1)
        if(descripcion)
            set(trazable "${semver}+${descripcion}")
        else()
            set(trazable "${semver}+sin-git")
        endif()
        message(STATUS "[version] sin etiqueta v*.*.*; se usa el fichero VERSION")
    endif()

    set(${salida_semver}   "${semver}"   PARENT_SCOPE)
    set(${salida_trazable} "${trazable}" PARENT_SCOPE)
endfunction()
