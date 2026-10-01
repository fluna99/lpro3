#!/usr/bin/env bash
# Tarea 6 - Cadena de integracion completa, ejecutable en cualquier maquina.
#
# El mismo script se usa en el puesto del desarrollador y en el servidor. Esa es
# la propiedad importante desde el punto de vista de gestion: "en mi maquina
# funciona" deja de ser un argumento porque la maquina ejecuta lo mismo.
#
# Uso: scripts/20-pipeline.sh [preset]     (por omision: entrega)
set -uo pipefail

PROYECTO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PRESET="${1:-entrega}"
CONSTRUCCION="$PROYECTO/build/$PRESET"
INFORMES="$PROYECTO/build/informes"
RESUMEN="$INFORMES/resumen.txt"

cd "$PROYECTO"
mkdir -p "$INFORMES"
: > "$RESUMEN"

fallos=0
etapa() {
    local nombre="$1"; shift
    local critica="$1"; shift
    local inicio fin duracion estado
    printf '\n\033[1m== %s ==\033[0m\n' "$nombre"
    inicio=$(date +%s)
    if "$@"; then estado="OK"; else
        estado="FALLO"
        if [ "$critica" = "critica" ]; then fallos=$((fallos + 1)); else estado="AVISO"; fi
    fi
    fin=$(date +%s); duracion=$((fin - inicio))
    printf '%-24s %-6s %4s s\n' "$nombre" "$estado" "$duracion" >> "$RESUMEN"
    printf '   -> %s (%s s)\n' "$estado" "$duracion"
}

opcional() {   # ejecuta solo si la herramienta existe
    if command -v "$1" >/dev/null 2>&1; then shift; "$@"; else
        echo "   herramienta no disponible; etapa omitida"; return 0
    fi
}

etapa "1. Configuracion"     critica cmake --preset "$PRESET"
etapa "2. Estilo"            aviso   opcional clang-format \
      cmake --build "$CONSTRUCCION" --target formato-verificar
etapa "3. Compilacion"       critica cmake --build --preset "$PRESET"
etapa "4. Pruebas"           critica ctest --preset "$PRESET"
etapa "5. Analisis estatico" aviso   opcional cppcheck \
      cmake --build "$CONSTRUCCION" --target analisis-estatico
etapa "6. Empaquetado"       critica cpack --preset "$PRESET"

# --- Recopilacion de evidencias ---------------------------------------------
mkdir -p "$INFORMES"
cp -f "$CONSTRUCCION"/informes/pruebas-junit.xml "$INFORMES/" 2>/dev/null || true
cp -f "$CONSTRUCCION"/compile_commands.json      "$INFORMES/" 2>/dev/null || true

{
    echo
    echo "Version generada : $(git describe --tags --dirty --always 2>/dev/null || echo desconocida)"
    echo "Commit           : $(git rev-parse --short HEAD 2>/dev/null || echo desconocido)"
    echo "Fecha            : $(date -Is)"
    echo "Maquina          : $(uname -srm)"
    echo "Artefactos       : $(find "$PROYECTO/build/artefactos" -maxdepth 1 -type f -printf '%f ' 2>/dev/null)"
} >> "$RESUMEN"

echo
echo "===================== RESUMEN ====================="
cat "$RESUMEN"
echo "==================================================="
[ "$fallos" -eq 0 ] || { echo "Cadena FALLIDA: $fallos etapa(s) critica(s)"; exit 1; }
echo "Cadena COMPLETADA correctamente"
