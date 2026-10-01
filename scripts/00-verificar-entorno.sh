#!/usr/bin/env bash
# Tarea 0 - Comprobacion del entorno de trabajo.
#
# Un taller (o un proyecto) que empieza con "a mi no me compila" ya ha perdido
# media sesion. Esta comprobacion documenta el entorno minimo exigido y deja
# constancia escrita de lo que hay instalado en cada puesto.
set -uo pipefail

obligatorias=(git cmake ninja g++ ctest cpack)
opcionales=(clang-format clang-tidy cppcheck gcovr dpkg-deb dpkg-scanpackages
            python3 ssh curl)

faltan=0
echo "== Herramientas obligatorias =="
for h in "${obligatorias[@]}"; do
    if ruta=$(command -v "$h" 2>/dev/null); then
        version=$("$h" --version 2>&1 | head -1)
        printf '  [ OK ] %-18s %s\n' "$h" "$version"
    else
        printf '  [FALTA] %-18s (imprescindible)\n' "$h"
        faltan=$((faltan + 1))
    fi
done

echo
echo "== Herramientas opcionales (degradan funcionalidad, no la bloquean) =="
for h in "${opcionales[@]}"; do
    if command -v "$h" >/dev/null 2>&1; then
        printf '  [ OK ] %-18s\n' "$h"
    else
        printf '  [ -- ] %-18s no instalada\n' "$h"
    fi
done

echo
if [ "$faltan" -gt 0 ]; then
    cat <<'AYUDA'
Faltan herramientas obligatorias. En Debian/Ubuntu:
  sudo apt update
  sudo apt install -y build-essential cmake ninja-build git \
                      clang-format clang-tidy cppcheck gcovr dpkg-dev
AYUDA
    exit 1
fi
echo "Entorno correcto. CMake $(cmake --version | head -1 | awk '{print $3}')"
