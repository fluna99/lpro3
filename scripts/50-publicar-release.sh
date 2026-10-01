#!/usr/bin/env bash
# Tarea 7 - Publicacion de una entrega mediante la API REST del servicio.
#
# Es la operacion que las herramientas auxiliares esconden detras de una orden:
# crear la publicacion asociada a la etiqueta y adjuntarle los artefactos. Se
# hace con dos llamadas HTTP, sin instalar nada. Conocerlas es lo que permite
# automatizar la entrega en cualquier otro servicio de alojamiento.
#
# Se ejecuta dentro del flujo .github/workflows/publicacion.yml, donde las tres
# variables de entorno ya vienen definidas. Para probarlo en local:
#
#   PUBLICAR_SIMULAR=1 GITHUB_REPOSITORY=EQUIPO/PROYECTO \
#   GITHUB_REF_NAME=v1.0.0 GITHUB_TOKEN=x ./scripts/50-publicar-release.sh
set -euo pipefail

PROYECTO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SIMULAR="${PUBLICAR_SIMULAR:-0}"
API="${GITHUB_API_URL:-https://api.github.com}"
SUBIDAS="${GITHUB_UPLOADS_URL:-https://uploads.github.com}"

: "${GITHUB_REPOSITORY:?falta GITHUB_REPOSITORY (formato ORGANIZACION/REPOSITORIO)}"
: "${GITHUB_REF_NAME:?falta GITHUB_REF_NAME (la etiqueta que se publica)}"
: "${GITHUB_TOKEN:?falta GITHUB_TOKEN}"

ETIQUETA="$GITHUB_REF_NAME"

# Artefactos que componen la entrega. El inventario de componentes (SBOM) se
# publica junto a los binarios: separarlos es la forma mas rapida de que dejen
# de corresponderse.
ADJUNTOS=()
while IFS= read -r fichero; do ADJUNTOS+=("$fichero"); done < <(
    find "$PROYECTO/build/artefactos" -maxdepth 1 \( -name '*.deb' -o -name '*.tar.gz' \) -type f 2>/dev/null | sort
)
for extra in build/informes/sbom.json build/informes/resumen.txt; do
    [ -f "$PROYECTO/$extra" ] && ADJUNTOS+=("$PROYECTO/$extra")
done

if [ "${#ADJUNTOS[@]}" -eq 0 ]; then
    echo "No hay artefactos que publicar. Ejecute antes scripts/20-pipeline.sh" >&2
    exit 1
fi

echo "==> Publicando $ETIQUETA en $GITHUB_REPOSITORY"
printf '    %s\n' "${ADJUNTOS[@]##*/}"

llamada() {
    if [ "$SIMULAR" = "1" ]; then
        printf '    [simulacion] curl %s\n' "$*" | cut -c1-140
        return 0
    fi
    curl --silent --show-error --fail-with-body "$@"
}

# --- 1. Crear la publicacion -------------------------------------------------
# generate_release_notes hace que el servicio redacte las notas a partir de las
# propuestas de cambio fusionadas desde la etiqueta anterior: el historial de
# revisiones se convierte solo en el registro de cambios de la entrega.
cuerpo=$(printf '{"tag_name":"%s","name":"%s","generate_release_notes":true}' "$ETIQUETA" "$ETIQUETA")

respuesta=$(llamada -X POST "$API/repos/$GITHUB_REPOSITORY/releases" \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    -d "$cuerpo")

if [ "$SIMULAR" = "1" ]; then
    ID="000000"
else
    ID=$(printf '%s' "$respuesta" | python3 -c 'import json,sys; print(json.load(sys.stdin)["id"])')
fi
echo "    publicacion creada (id $ID)"

# --- 2. Adjuntar cada artefacto ---------------------------------------------
for fichero in "${ADJUNTOS[@]}"; do
    nombre=$(basename "$fichero")
    llamada -X POST \
        "$SUBIDAS/repos/$GITHUB_REPOSITORY/releases/$ID/assets?name=$nombre" \
        -H "Authorization: Bearer $GITHUB_TOKEN" \
        -H "Content-Type: application/octet-stream" \
        --data-binary @"$fichero" > /dev/null
    echo "    adjuntado: $nombre"
done

echo
echo "Entrega publicada: https://github.com/$GITHUB_REPOSITORY/releases/tag/$ETIQUETA"
