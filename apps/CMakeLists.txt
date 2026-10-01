add_executable(telemetria_cli main.cpp)

target_link_libraries(telemetria_cli
    PRIVATE telemetria::telemetria
            telemetria_calidad)

set_target_properties(telemetria_cli PROPERTIES OUTPUT_NAME "telemetria")
