# telemetria — proyecto de ejemplo del taller

Biblioteca y aplicación de línea de órdenes para el análisis de KPIs de red,
usada como soporte del taller **Gestión y automatización de proyectos software
en C/C++** (Laboratorio de Proyectos, Grado en Ingeniería Telemática, UMA).

El código C++ es deliberadamente sencillo: lo que se practica es la
**infraestructura de gestión** que lo rodea, sobre el repositorio real del
equipo en GitHub.

## Puesta en marcha

```bash
./scripts/00-verificar-entorno.sh          # comprobar herramientas
./scripts/10-espejo-continuidad.sh semilla # dependencia local, para trabajar sin red
cmake --workflow --preset entrega          # configurar + compilar + probar + empaquetar
```

## Estructura

| Ruta | Contenido |
|---|---|
| `CMakeLists.txt` | Qué se construye: objetivos, dependencias y contrato de instalación |
| `CMakePresets.json` | Cómo se configura: presets de desarrollo, sanitizers, cobertura y entrega |
| `cmake/` | Módulos de versión, dependencias, calidad, instalación y empaquetado |
| `include/`, `src/` | Biblioteca `telemetria::telemetria` |
| `apps/` | Ejecutable `telemetria` |
| `tests/` | Pruebas registradas una a una en CTest |
| `terceros/umbral/` | Dependencia externa; se publica con etiqueta fija y se consume desde el espejo |
| `.github/CODEOWNERS` | Responsables por área del proyecto |
| `.github/pull_request_template.md` | Plantilla de propuesta de cambio |
| `.github/workflows/integracion.yml` | Cadena de integración en cada propuesta de cambio |
| `.github/workflows/publicacion.yml` | Publicación de artefactos al empujar una etiqueta `vX.Y.Z` |
| `scripts/` | Entorno, continuidad, cadena de integración, artefactos, SBOM y publicación |
| `scripts/hooks/pre-commit` | Enganche de cliente que verifica el estilo antes del commit |
| `dependencias.json` | Inventario declarado de dependencias |

## Antes de usarlo en el repositorio del equipo

1. Sustituya `@usuario1`, `@usuario2` y `@usuario3` en `.github/CODEOWNERS` por
   los identificadores reales de GitHub. Todos deben tener permiso de escritura.
2. Sustituya `EQUIPO` por su organización en `dependencias.json` y en
   `cmake/Dependencias.cmake` (`TELEMETRIA_UMBRAL_URL`).
3. Instale el enganche de estilo en cada puesto:
   `install -m 755 scripts/hooks/pre-commit .git/hooks/pre-commit`
4. Configure la regla de protección de la rama principal y, una vez que el flujo
   `integracion` se haya ejecutado al menos una vez, marque el trabajo
   `construir` como comprobación obligatoria.

## Órdenes de uso frecuente

```bash
cmake --preset desarrollo && cmake --build --preset desarrollo
ctest --preset desarrollo                     # todas las pruebas
ctest --preset desarrollo -L unidad           # solo pruebas unitarias
ctest --preset desarrollo -R percentil -VV    # una prueba concreta, con detalle

cmake --build build/desarrollo --target formato            # aplicar estilo
cmake --build build/desarrollo --target formato-verificar  # puerta de estilo
cmake --build build/desarrollo --target analisis-estatico
cmake --preset cobertura && cmake --build --preset cobertura \
  && cmake --build build/cobertura --target cobertura      # informe HTML

./scripts/20-pipeline.sh entrega              # cadena completa, la misma que la CI
./scripts/10-espejo-continuidad.sh ensayo     # prueba de recuperación
python3 scripts/40-generar-sbom.py            # inventario de componentes
./scripts/30-publicar-artefactos.sh           # repositorio APT local (ampliación)
```

## Entrega

```bash
git tag -a v1.0.0 -m "Primera entrega al cliente"
git push origin v1.0.0        # dispara el flujo de publicación
```

El flujo `publicacion.yml` construye los artefactos y llama a
`scripts/50-publicar-release.sh`, que crea la publicación y adjunta los
paquetes y el SBOM mediante la API REST del servicio. No hace falta ninguna
herramienta de línea de órdenes adicional. Para ver qué llamadas hace, sin
ejecutarlas:

```bash
PUBLICAR_SIMULAR=1 GITHUB_REPOSITORY=EQUIPO/PROYECTO \
GITHUB_REF_NAME=v1.0.0 GITHUB_TOKEN=x ./scripts/50-publicar-release.sh
```

## Licencia

MIT. Véase `LICENSE`.
