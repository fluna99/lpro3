# Las pruebas se registran una a una en CTest: cada caso es un resultado
# independiente en el informe, no una linea perdida dentro de un unico binario.

add_executable(pruebas_kpi pruebas_kpi.cpp)
target_link_libraries(pruebas_kpi PRIVATE telemetria::telemetria telemetria_calidad)

set(CASOS
    media
    desviacion
    percentil
    disponibilidad
    nivel_servicio
    serie_vacia
    percentil_invalido
    carga_csv
    csv_inexistente)

foreach(caso IN LISTS CASOS)
    add_test(NAME unidad.${caso}
             COMMAND pruebas_kpi ${caso}
             WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")
    set_tests_properties(unidad.${caso} PROPERTIES
        LABELS  "unidad"
        TIMEOUT 20)
endforeach()

# Pruebas de la interfaz de linea de ordenes: verifican el contrato publico
# del ejecutable que se entrega al cliente.
add_test(NAME cli.version COMMAND telemetria_cli --version)
set_tests_properties(cli.version PROPERTIES
    LABELS "cli"
    PASS_REGULAR_EXPRESSION "telemetria [0-9]+\\.[0-9]+\\.[0-9]+")

add_test(NAME cli.resumen
         COMMAND telemetria_cli "${CMAKE_CURRENT_SOURCE_DIR}/datos/rtt.csv" --json)
set_tests_properties(cli.resumen PROPERTIES
    LABELS "cli"
    PASS_REGULAR_EXPRESSION "\"nivel\":\"(CORRECTO|DEGRADADO|CRITICO)\"")

add_test(NAME cli.sin_argumentos COMMAND telemetria_cli)
set_tests_properties(cli.sin_argumentos PROPERTIES LABELS "cli" WILL_FAIL TRUE)
