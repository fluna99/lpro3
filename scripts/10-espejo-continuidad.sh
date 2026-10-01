#!/usr/bin/env bash
# Tarea 4 - Continuidad: copia integra del repositorio y de sus dependencias.
#
# Alojar el repositorio del equipo en un servicio de terceros introduce un punto
# unico de fallo que debe figurar en el plan de riesgos. Una copia creada con
# `git clone --mirror` contiene todas las ramas, etiquetas y notas del original:
# no es un respaldo parcial, es un repositorio funcional que puede sustituirlo.
#
# Uso:
#   scripts/10-espejo-continuidad.sh crear <url>...   copia integra de cada repositorio
#   scripts/10-espejo-continuidad.sh actualizar       refresca todas las copias
#   scripts/10-espejo-continuidad.sh listar           estado de las copias
#   scripts/10-espejo-continuidad.sh ensayo           prueba de recuperacion
#   scripts/10-espejo-continuidad.sh semilla          publica terceros/umbral como
#                                                     dependencia local (uso en clase)
set -euo pipefail

PROYECTO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
INFRA="${TALLER_INFRA:-$HOME/taller-infra}"
ESPEJOS="$INFRA/git"

mkdir -p "$ESPEJOS"

TRABAJO=""
limpiar() { [ -n "$TRABAJO" ] && rm -rf "$TRABAJO"; return 0; }
trap limpiar EXIT

crear() {
    [ "$#" -gt 0 ] || { echo "Indique al menos una direccion de repositorio"; exit 1; }
    for url in "$@"; do
        nombre=$(basename "$url" .git).git
        destino="$ESPEJOS/$nombre"
        if [ -d "$destino" ]; then
            echo "==> $nombre ya existe; se actualiza"
            git -C "$destino" remote update --prune
        else
            echo "==> Creando copia integra de $url"
            git clone --mirror "$url" "$destino"
        fi
        printf '    ramas: %s   etiquetas: %s\n' \
            "$(git -C "$destino" for-each-ref --format='%(refname)' refs/heads | wc -l)" \
            "$(git -C "$destino" tag | wc -l)"
    done
}

actualizar() {
    local encontrados=0
    for destino in "$ESPEJOS"/*.git; do
        [ -d "$destino" ] || continue
        encontrados=$((encontrados + 1))
        echo "==> $(basename "$destino")"
        git -C "$destino" remote update --prune 2>&1 | sed 's/^/    /'
    done
    [ "$encontrados" -gt 0 ] || echo "No hay copias en $ESPEJOS"
}

listar() {
    printf '%-24s %8s %10s  %s\n' "REPOSITORIO" "RAMAS" "ETIQUETAS" "ULTIMA ACTUALIZACION"
    for destino in "$ESPEJOS"/*.git; do
        [ -d "$destino" ] || continue
        printf '%-24s %8s %10s  %s\n' \
            "$(basename "$destino")" \
            "$(git -C "$destino" for-each-ref --format='%(refname)' refs/heads | wc -l)" \
            "$(git -C "$destino" tag | wc -l)" \
            "$(date -r "$destino/FETCH_HEAD" -Is 2>/dev/null || date -r "$destino" -Is)"
    done
    return 0
}

# Prueba de recuperacion: clona DESDE la copia y comprueba que el resultado es
# utilizable. Un plan de contingencia que no se ha ensayado no es un plan.
ensayo() {
    local origen="$ESPEJOS/umbral.git"
    [ -d "$origen" ] || { echo "No hay copia de 'umbral'. Ejecute 'semilla' o 'crear <url>'"; exit 1; }
    TRABAJO=$(mktemp -d)
    echo "==> Clonando desde la copia integra"
    git clone --quiet "$origen" "$TRABAJO/umbral"
    echo "    etiquetas recuperadas: $(git -C "$TRABAJO/umbral" tag | tr '\n' ' ')"
    echo "==> Compilando el proyecto contra la copia local"
    ( cd "$PROYECTO" && TALLER_INFRA="$INFRA" cmake --preset desarrollo >/dev/null \
      && TALLER_INFRA="$INFRA" cmake --build --preset desarrollo >/dev/null \
      && TALLER_INFRA="$INFRA" ctest --preset desarrollo --output-on-failure >/dev/null )
    echo
    echo "Ensayo de recuperacion CORRECTO: el equipo puede seguir trabajando"
    echo "con el alojamiento remoto caido."
}

# Publica terceros/umbral como dependencia con etiqueta, sin salir de la maquina.
# Permite hacer el taller aunque el equipo no haya creado todavia el repositorio
# remoto de la dependencia.
semilla() {
    local destino="$ESPEJOS/umbral.git"
    if [ -d "$destino" ]; then
        echo "La dependencia local ya existe en $destino"; return 0
    fi
    echo "==> Publicando terceros/umbral como dependencia local v1.2.0"
    TRABAJO=$(mktemp -d)
    cp -r "$PROYECTO/terceros/umbral/." "$TRABAJO/"
    git -C "$TRABAJO" init --quiet --initial-branch=main
    git -C "$TRABAJO" add -A
    git -C "$TRABAJO" -c user.name="Proveedor" -c user.email="proveedor@example.org" \
        commit --quiet -m "umbral 1.2.0: version inicial publicada"
    git -C "$TRABAJO" tag -a v1.2.0 -m "Publicacion 1.2.0"
    git clone --mirror --quiet "$TRABAJO" "$destino"
    git -C "$destino" remote remove origin 2>/dev/null || true
    echo "    listo: $destino (etiqueta v1.2.0)"
}

case "${1:-}" in
    crear)      shift; crear "$@" ;;
    actualizar) actualizar ;;
    listar)     listar ;;
    ensayo)     ensayo ;;
    semilla)    semilla ;;
    *)          sed -n '2,16p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac
