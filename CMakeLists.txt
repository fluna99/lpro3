# =============================================================================
#  Taller: Gestion y automatizacion de proyectos software en C/C++
#  Laboratorio de Proyectos - Grado en Ingenieria Telematica (UMA)
#
#  Fichero raiz: describe QUE se construye. El COMO se configura en cada
#  maquina se declara aparte, en CMakePresets.json.
#
#  Que es CMake, en una frase: no compila nada por si mismo. Es un generador
#  de sistemas de construccion: lee estos ficheros ".cmake"/"CMakeLists.txt"
#  (escritos en el lenguaje propio de CMake, no en C++) y, a partir de ellos,
#  genera los ficheros que SI compilan (un Makefile, un proyecto de Ninja...).
#  Todo lo que hay aqui abajo, por tanto, no se "ejecuta" al compilar tu
#  programa: se ejecuta antes, cuando CMake prepara la receta de compilacion.
# =============================================================================

# Version minima de CMake que sabe entender este fichero. Si en tu maquina
# tienes una version mas antigua, CMake se para aqui con un error claro en
# lugar de fallar mas adelante de forma confusa.
cmake_minimum_required(VERSION 3.25)

# CMake solo conoce de fabrica un puñado de modulos (find_package, CTest...).
# Esta linea le dice "busca tambien modulos propios del proyecto dentro de la
# carpeta cmake/". Es lo que permite que mas abajo podamos escribir
# include(VersionDesdeGit) y que CMake encuentre cmake/VersionDesdeGit.cmake.
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/cmake")

# --- La version es un dato de gestion: se deriva de la etiqueta de Git -------
# include(...) es como un "#include" de C++, pero para trocitos de CMake: pega
# aqui el contenido de cmake/VersionDesdeGit.cmake (una funcion que calcula la
# version del proyecto a partir de "git describe").
include(VersionDesdeGit)
# Llamamos a la funcion que acabamos de cargar. Nos devuelve dos variables:
# la version "limpia" (p.ej. 1.4.2) y una version "trazable" que ademas indica
# el commit exacto (p.ej. 1.4.2-7-gab12cd3).
version_desde_git(TELEMETRIA_VERSION TELEMETRIA_VERSION_LARGA)

# project() es la orden mas importante de todo CMake: declara el nombre del
# proyecto, su version y, con LANGUAGES CXX, que vamos a compilar C++ (esto
# hace que CMake busque un compilador de C++ y compruebe que funciona).
# A partir de aqui quedan definidas variables automaticas como
# PROJECT_VERSION, PROJECT_VERSION_MAJOR, PROJECT_SOURCE_DIR, etc.
project(telemetria
        VERSION      ${TELEMETRIA_VERSION}
        DESCRIPTION  "Biblioteca de analisis de KPIs de red de acceso"
        HOMEPAGE_URL "https://www.uma.es/grado-en-ingenieria-telematica"
        LANGUAGES    CXX)

# message(STATUS ...) es el "print" de CMake: escribe una linea informativa
# en la salida de "cmake --preset ..." (no en la salida del programa).
message(STATUS "[telemetria] version del proyecto : ${PROJECT_VERSION}")
message(STATUS "[telemetria] version trazable     : ${TELEMETRIA_VERSION_LARGA}")

# --- Politica del proyecto (solo si se compila como proyecto principal) ------
# PROJECT_IS_TOP_LEVEL es ON cuando este CMakeLists.txt es el que el usuario
# ha configurado directamente (nuestro caso). Seria OFF si este proyecto se
# usara como dependencia dentro de otro (como nos pasa a nosotros con
# "umbral"): asi evitamos imponerle NUESTRAS normas de estilo a quien nos usa.
if(PROJECT_IS_TOP_LEVEL)
    # Variables globales de CMake (empiezan por CMAKE_) que configuran COMO
    # se compila todo el proyecto, no solo un objetivo concreto:
    set(CMAKE_CXX_STANDARD 17)             # usar el estandar C++17...
    set(CMAKE_CXX_STANDARD_REQUIRED ON)    # ...de forma obligatoria (si el
                                            # compilador no lo soporta, error)
    set(CMAKE_CXX_EXTENSIONS OFF)          # sin extensiones propias del
                                            # compilador (p.ej. gnu++17): C++17
                                            # a secas, para que el codigo sea
                                            # portable entre compiladores
    set(CMAKE_EXPORT_COMPILE_COMMANDS ON)      # base para clang-tidy e IDEs
    # Sin esto, cada compilador crea los binarios donde le parece dentro de
    # build/. Fijar estas tres rutas da una estructura predecible:
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")  # .exe / binarios
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")  # .so (dinamicas)
    set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")  # .a  (estaticas)
    include(CTest)                             # define BUILD_TESTING
endif()

# option() declara un interruptor ON/OFF configurable desde fuera, por ejemplo
# con "cmake --preset ... -DTELEMETRIA_CLANG_TIDY=ON" o, como aqui, fijado en
# CMakePresets.json. El tercer argumento es el valor por omision.
option(TELEMETRIA_AVISOS_COMO_ERRORES "Tratar los avisos del compilador como errores" OFF)
option(TELEMETRIA_COBERTURA           "Instrumentar para medir cobertura de pruebas"  OFF)
option(TELEMETRIA_CLANG_TIDY          "Ejecutar clang-tidy durante la compilacion"    OFF)

# Cargamos dos modulos propios mas (cmake/Dependencias.cmake y
# cmake/Calidad.cmake). Al incluirlos aqui, las variables y los "targets"
# (objetivos de compilacion, ver mas abajo) que definen quedan disponibles
# para el resto de este fichero, como si su contenido estuviera pegado aqui.
include(Dependencias)   # de donde salen las bibliotecas de terceros
include(Calidad)        # avisos, sanitizers, clang-tidy, cppcheck, formato, cobertura

# --- Artefacto 1: la biblioteca ---------------------------------------------
# configure_file() coge una plantilla de texto (cmake/version.hpp.in) y
# sustituye los marcadores tipo @PROJECT_VERSION@ por su valor real, generando
# un .hpp de verdad dentro de la carpeta de compilacion (no del codigo fuente:
# por eso "version.hpp" no aparece en include/, se crea solo al compilar).
# @ONLY limita la sustitucion a variables escritas como @NOMBRE@.
configure_file(cmake/version.hpp.in
               "${CMAKE_CURRENT_BINARY_DIR}/generado/telemetria/version.hpp" @ONLY)

# add_library() declara un "target": una unidad de compilacion con nombre
# (aqui, la biblioteca "telemetria") construida a partir de estos .cpp. Un
# target es el concepto central de CMake moderno: casi todo lo que sigue
# (target_sources, target_link_libraries, set_target_properties...) configura
# propiedades de ESTE target concreto.
add_library(telemetria src/kpi.cpp)
# Crea un alias "telemetria::telemetria" que apunta al mismo target. Es pura
# convencion (namespace::nombre) para que, cuando otro proyecto haga
# target_link_libraries(... telemetria::telemetria), quede claro a simple
# vista que es una dependencia externa y no un target cualquiera del propio
# proyecto.
add_library(telemetria::telemetria ALIAS telemetria)

# target_sources(... FILE_SET HEADERS ...) declara cuales son las cabeceras
# PUBLICAS de la biblioteca (las que necesitara quien la use) y desde que
# carpetas "base" se deben poder incluir (BASE_DIRS). Gracias a esto, cuando
# alguien enlace con telemetria::telemetria, CMake añade automaticamente
# include/ (y la carpeta con el version.hpp generado) a su ruta de busqueda
# de #include, sin tener que escribir target_include_directories a mano.
target_sources(telemetria
    PUBLIC FILE_SET HEADERS
           BASE_DIRS include "${CMAKE_CURRENT_BINARY_DIR}/generado"
           FILES include/telemetria/kpi.hpp
                 "${CMAKE_CURRENT_BINARY_DIR}/generado/telemetria/version.hpp")

# target_link_libraries() no solo "enlaza" en el sentido del linker: tambien
# propaga configuracion (includes, flags, otras dependencias) entre targets.
# La visibilidad importa:
#   PUBLIC  -> umbral es parte de nuestra interfaz publica (aparece en
#              kpi.hpp), asi que quien use telemetria TAMBIEN necesita ver
#              umbral. CMake se lo propaga automaticamente.
#   PRIVATE -> telemetria_calidad (avisos, sanitizers...) es solo cosa
#              nuestra: no debe imponerse a quien use la biblioteca.
target_link_libraries(telemetria PUBLIC  umbral::umbral
                                 PRIVATE telemetria_calidad)

# set_target_properties() ajusta atributos concretos del target ya creado:
set_target_properties(telemetria PROPERTIES
    VERSION   ${PROJECT_VERSION}         # version incrustada en el .so (p.ej. libtelemetria.so.1.4.2)
    SOVERSION ${PROJECT_VERSION_MAJOR}   # version de compatibilidad binaria (ABI): solo el numero mayor
    POSITION_INDEPENDENT_CODE ON)        # compilar con -fPIC, requisito para poder usarse como biblioteca dinamica (.so)

# --- Artefacto 2: la aplicacion de linea de ordenes -------------------------
# add_subdirectory() entra en apps/ y procesa su propio CMakeLists.txt (que
# define el ejecutable telemetria_cli). Es la forma de dividir un proyecto
# grande en varias carpetas sin perder un unico arbol de configuracion.
add_subdirectory(apps)

# --- Verificacion -----------------------------------------------------------
# BUILD_TESTING la define include(CTest) de mas arriba (ON por omision). Solo
# compilamos las pruebas si estamos probando Y si somos el proyecto principal
# (si telemetria se usara como dependencia de otro, sus pruebas no tendrian
# por que compilarse tambien).
if(BUILD_TESTING AND PROJECT_IS_TOP_LEVEL)
    add_subdirectory(tests)
endif()

# --- Entrega: instalacion y empaquetado -------------------------------------
# Estos dos modulos no crean targets nuevos: definen COMO se instala lo ya
# construido (cmake --install) y COMO se empaqueta en .deb/.tar.gz (cpack).
include(Instalacion)
include(Empaquetado)
