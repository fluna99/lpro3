# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Qué es esto

`telemetria` es un proyecto de ejemplo para un taller sobre **gestión y automatización de proyectos software en C/C++** (Laboratorio de Proyectos, Grado en Ingeniería Telemática, UMA). El código C++ en sí (una biblioteca de estadísticas de KPIs de red + una CLI) es deliberadamente sencillo; lo que realmente se practica es la **infraestructura de gestión** que lo rodea: el contrato de compilación con CMake, la continuidad/reflejo de dependencias, las puertas de calidad, el empaquetado, la generación de SBOM y la publicación de entregas — pensado para ejecutarse sobre el repositorio real del equipo en GitHub. Los comentarios, identificadores, documentación y convenciones de commit de este repositorio están en **español**; mantén el código/documentación nuevos coherentes con eso salvo que se indique lo contrario.

Nota sobre el estado del repositorio: el README describe una estructura `.github/` (CODEOWNERS, plantilla de pull request, workflows de integración y publicación) que forma parte del flujo de trabajo previsto del taller pero que **todavía no existe en este checkout** — no asumas su presencia sin comprobarlo primero.

## Órdenes de compilación y pruebas

```bash
./scripts/00-verificar-entorno.sh          # comprueba que estén instaladas las herramientas obligatorias/opcionales
cmake --preset desarrollo && cmake --build --preset desarrollo   # compilación del día a día (Debug, avisos como errores, clang-tidy activo)

ctest --preset desarrollo                     # todas las pruebas
ctest --preset desarrollo -L unidad           # solo pruebas unitarias (filtro por etiqueta)
ctest --preset desarrollo -L cli              # solo pruebas del contrato de la CLI
ctest --preset desarrollo -R percentil -VV    # una prueba concreta por nombre, con detalle

cmake --build build/desarrollo --target formato             # aplicar clang-format
cmake --build build/desarrollo --target formato-verificar    # puerta de estilo (dry-run --Werror)
cmake --build build/desarrollo --target analisis-estatico    # cppcheck

cmake --preset cobertura && cmake --build --preset cobertura \
  && cmake --build build/cobertura --target cobertura        # informe HTML de cobertura (gcovr)

./scripts/20-pipeline.sh entrega              # cadena de CI completa: configurar→estilo→compilar→probar→análisis estático→empaquetar (la misma que la CI)
python3 scripts/40-generar-sbom.py            # genera el SBOM CycloneDX a partir de dependencias.json
cmake --workflow --preset entrega             # configurar + compilar + probar + empaquetar (Release)
```

Las pruebas se registran una a una en CTest (ver [tests/CMakeLists.txt](tests/CMakeLists.txt)), no como un único binario monolítico — cada caso es `pruebas_kpi <caso>` despachado mediante nombres de prueba `unidad.<caso>`, más pruebas `cli.*` que ejercitan el binario instalado `telemetria_cli` (`--version`, `--json`, fallo sin argumentos).

Los objetivos `formato`, `formato-verificar`, `analisis-estatico` y `cobertura` solo se definen si la herramienta correspondiente (`clang-format`, `cppcheck`, `gcovr`) está instalada en la máquina; compruébalo primero con `./scripts/00-verificar-entorno.sh`.

## Gestión de dependencias — leer antes de tocar `umbral`

El proyecto depende de una segunda biblioteca C++, `umbral` (clasificación frente a umbrales), declarada y obtenida en [cmake/Dependencias.cmake](cmake/Dependencias.cmake). Este es el punto pedagógico central: **nunca se consume una dependencia de una rama móvil ni de una dirección no controlada — se fija una etiqueta exacta y se prefiere un espejo local sobre el origen remoto.** Orden de resolución:

1. Espejo local en `${TALLER_INFRA:-$HOME/taller-infra}/git/umbral.git` (creado con `git clone --mirror`)
2. Origen remoto `TELEMETRIA_UMBRAL_URL` (una URL real de GitHub, etiqueta `v1.2.0`)
3. Copia interna vendida en [terceros/umbral/](terceros/umbral/) (modo degradado, usado automáticamente si no hay ni espejo ni origen configurados)

Antes de compilar por primera vez en una copia nueva del repositorio, siembra el espejo local para que la compilación funcione sin red:
```bash
./scripts/10-espejo-continuidad.sh semilla     # publica terceros/umbral como dependencia local con etiqueta
./scripts/10-espejo-continuidad.sh ensayo      # prueba de recuperación: clona desde el espejo + compila + prueba contra él
```
Otras subórdenes: `crear <url>...` (crea espejo de repositorios arbitrarios), `actualizar` (refresca todos los espejos), `listar` (estado de las copias).

## Arquitectura

- **[include/telemetria/kpi.hpp](include/telemetria/kpi.hpp) + [src/kpi.cpp](src/kpi.cpp)** — la biblioteca `telemetria::telemetria`. El tipo central es `SerieKPI` (un vector de muestras) con `media()`, `desviacion_tipica()`, `percentil(p)` (interpolación lineal), `disponibilidad(limite)` y `nivel_servicio(politica)`, que delega la clasificación en `umbral::clasificar` sobre el percentil 95. `cargar_csv()` carga CSVs de una columna o de la forma `instante,valor`, ignorando líneas vacías o que empiezan por `#` y tomando el último campo separado por comas.
- **[terceros/umbral/](terceros/umbral/)** — la dependencia de terceros vendida (también un paquete CMake completo con sus propias reglas de instalación/exportación), que aporta `umbral::Politica`, `umbral::Nivel` (Correcto/Degradado/Critico), `umbral::clasificar()`, `umbral::a_texto()`, `umbral::version()`.
- **[apps/main.cpp](apps/main.cpp)** — `telemetria_cli` (instalado como `telemetria`): lee un CSV e imprime/formatea en JSON la media, el p95, la disponibilidad y el nivel de servicio frente a los límites `--degradado`/`--critico`.
- **CMake está dividido por responsabilidad, no por objetivo** — cada fichero bajo [cmake/](cmake/) resuelve una cuestión de gestión distinta:
  - `VersionDesdeGit.cmake` — la versión del proyecto sale de `git describe --tags --match "v[0-9]*"` (recurre a [VERSION](VERSION) si no hay etiquetas); es la fuente única de verdad, consumida mediante el `telemetria/version.hpp` generado.
  - `Dependencias.cmake` — la resolución espejo/origen/vendida descrita arriba.
  - `Calidad.cmake` — define un único objetivo INTERFACE `telemetria_calidad` (avisos, `-Werror` cuando `TELEMETRIA_AVISOS_COMO_ERRORES`, banderas de cobertura, integración de clang-tidy) contra el que se enlazan todos los demás objetivos, de modo que la política del compilador vive en un único sitio; también define los objetivos auxiliares `formato`, `formato-verificar`, `analisis-estatico` y `cobertura`.
  - `Instalacion.cmake` — el contrato de instalación/exportación para `find_package(telemetria)` (`telemetriaTargets.cmake`, fichero de versión de paquete con compatibilidad `SameMajorVersion`).
  - `Empaquetado.cmake` — configuración de CPack que produce artefactos TGZ + DEB.
- **[CMakePresets.json](CMakePresets.json)** — la capa de "cómo se configura", deliberadamente separada del "qué se construye" de [CMakeLists.txt](CMakeLists.txt). Presets: `desarrollo` (Debug, avisos como errores, clang-tidy), `sanitizers` (ASan+UBSan), `cobertura`, `entrega` (Release, usado para la entrega/empaquetado real mediante el workflow preset `entrega`).
- **[scripts/](scripts/)** están numerados según la tarea del taller y corresponden aproximadamente a una etapa del pipeline: `00` comprobación del entorno, `10` continuidad/reflejo de dependencias, `20` cadena de CI completa (refleja lo que ejecuta la CI), `30` publicación en un repositorio APT local de artefactos, `40` generación de SBOM (CycloneDX 1.6, a partir de [dependencias.json](dependencias.json)), `50` publicación de la entrega en GitHub (`scripts/50-publicar-release.sh`, admite el modo de simulación `PUBLICAR_SIMULAR=1` que imprime las llamadas curl sin ejecutarlas).
- **[scripts/hooks/pre-commit](scripts/hooks/pre-commit)** — enganche de cliente de git que impide commits con infracciones de clang-format; no se instala automáticamente (ver la configuración inicial más abajo).

## Antes de usarlo en el repositorio real del equipo

Estos marcadores deben sustituirse (según [README.md](README.md)):
1. `@usuario1`, `@usuario2`, `@usuario3` en `.github/CODEOWNERS` → identificadores reales de GitHub con permiso de escritura.
2. `EQUIPO` en [dependencias.json](dependencias.json) y `TELEMETRIA_UMBRAL_URL` en [cmake/Dependencias.cmake](cmake/Dependencias.cmake) → la organización real.
3. Instalar el enganche de estilo en cada puesto: `install -m 755 scripts/hooks/pre-commit .git/hooks/pre-commit`
4. Configurar la protección de la rama principal; una vez que el flujo `integracion` se haya ejecutado al menos una vez, marcar el trabajo `construir` como comprobación obligatoria.
